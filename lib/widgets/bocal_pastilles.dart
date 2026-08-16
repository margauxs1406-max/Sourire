import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/database_service.dart';
import '../models/note_model.dart';
import '../services/pastille_physics.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/theme/user_prefs.dart';

/// Part de saturation retirée aux billes du bocal.
///
/// Les couleurs de l'app ont été choisies très vives pour percer l'ancien
/// aplat blanc du bocal. Le verre étant devenu transparent, elles n'ont plus
/// rien à percer et virent au criard. On les adoucit donc — ICI SEULEMENT :
/// les notes, l'historique et les images partagées gardent les couleurs de
/// marque intactes.
///
/// La luminosité n'est pas touchée : la désaturer aussi ternirait les billes
/// au lieu de les calmer.
const double desaturationBilles = 0.4;

/// Couleur d'une bille : la couleur du souvenir, légèrement désaturée.
Color _couleurBille(String? colorLabel) {
  final HSLColor hsl = HSLColor.fromColor(SourireTheme.fromLabel(colorLabel).main);
  return hsl
      .withSaturation(
        (hsl.saturation * (1 - desaturationBilles)).clamp(0.0, 1.0),
      )
      .toColor();
}

/// Couche de pastilles à insérer DANS ton Stack existant (entre l'ombre
/// et l'image du bocal), en Positioned.fill, pour occuper exactement
/// bocalWidth x bocalHeight.
///
/// --- SYSTÈME "BOCAL PLEIN → NOUVEAU BOCAL" ---
/// Le bocal a une capacité limitée (`capaciteBocal`). [offsetBocal]
/// indique combien de souvenirs (du plus ancien au plus récent) sont
/// déjà "rangés" dans un bocal précédent, fermé — ils ne sont PLUS
/// affichés dans CE bocal, mais restent bien présents en base de données
/// (le tirage aléatoire continue donc de porter sur la TOTALITÉ des
/// souvenirs, jamais uniquement sur le bocal actuellement affiché).
///
/// Dès que le nombre de souvenirs à afficher dans la fenêtre courante
/// dépasse `capaciteBocal`, le widget :
/// 1. N'affiche que les `capaciteBocal` premiers (les plus anciens de la
///    fenêtre courante) — le bocal se remplit visuellement jusqu'au bord.
/// 2. Déclenche UNE SEULE FOIS [onBocalPlein], pour que l'écran parent
///    (Home) affiche la pop-up "Ton bocal est plein !".
///
/// C'est à l'écran parent de faire avancer [offsetBocal] (persisté dans
/// UserPrefs) quand l'utilisateur clique "Nouveau bocal", et de passer
/// une NOUVELLE Key à ce widget à ce moment-là (ex: `ValueKey(offsetBocal)`)
/// pour forcer une réinitialisation propre — le bocal reparaît alors vide,
/// avec les souvenirs excédentaires déjà placés dedans (pas d'animation
/// de chute pour ceux-là, ils apparaissent directement "posés").
class BocalPastilles extends StatefulWidget {
  /// Nombre maximum de souvenirs affichés dans CE bocal avant qu'il ne
  /// soit considéré comme plein.
  final int capaciteBocal;

  /// Nombre de souvenirs (chronologiquement, du plus ancien au plus
  /// récent) à ignorer car déjà rangés dans un bocal précédent fermé.
  final int offsetBocal;

  /// Appelé UNE SEULE FOIS (par instance de ce widget) quand le bocal
  /// vient d'atteindre sa capacité maximale avec encore des souvenirs en
  /// attente au-delà. Laisse le soin à l'écran parent d'afficher la
  /// pop-up et de gérer le passage au bocal suivant.
  final VoidCallback? onBocalPlein;

  /// Si `true`, la toute première fenêtre de souvenirs de CETTE instance
  /// est traitée comme des nouvelles arrivées qui TOMBENT (animées,
  /// étagées) plutôt que d'être placées instantanément déjà posées.
  /// À utiliser quand le bocal vient d'être réinitialisé PENDANT que
  /// l'utilisateur regarde (ex: clic sur "Nouveau bocal" après un import
  /// groupé) — pour un vrai démarrage à froid de l'app, laisse `false`
  /// (comportement historique : évite une longue cascade de chutes à
  /// chaque ouverture de l'app).
  final bool animerDemarrage;

  /// Affiche un rectangle semi-transparent représentant la zone de
  /// remplissage (avec le biseau) pour calibrer visuellement.
  final bool showDebugZone;

  const BocalPastilles({
    super.key,
    this.capaciteBocal = 45,
    this.offsetBocal = 0,
    this.onBocalPlein,
    this.animerDemarrage = false,
    this.showDebugZone = false,
  });

  @override
  State<BocalPastilles> createState() => _BocalPastillesState();
}

class _BocalPastillesState extends State<BocalPastilles> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double zoneLeft = 0.18;
  static const double zoneRight = 0.82;
  static const double zoneBottom = 0.89;

  /// Profondeur du creux du fond, en fraction de la hauteur — voir
  /// `ordonneeDuFond` dans pastille_physics.dart. Le placement initial doit
  /// utiliser la MÊME valeur que la physique, sinon le tas naîtrait plat
  /// avant de se réarranger sous les yeux de l'utilisateur.
  static const double creuxFond = 0.035;
  static const double zoneTop = 0.15;
  static const double maxInsetFraction = 0.33;
  static const double taperT = 0.38;

  late final PastillePhysicsWorld _world;
  late final Ticker _ticker;
  Duration _dernierTemps = Duration.zero;

  double _width = 0;
  double _height = 0;

  // Suivi des souvenirs déjà connus, pour détecter les ajouts/suppressions
  // sans jamais recréer/réinitialiser ceux déjà en place.
  final Set<Object> _idsConnus = {};
  bool _demarrageInitialise = false;

  // Empêche de redéclencher onBocalPlein plusieurs fois pour la même
  // instance du widget (donc pour le même bocal en cours).
  bool _popupDejaDeclenchee = false;

  // --- ÉTAGEMENT DES ARRIVÉES GROUPÉES ---
  // Les souvenirs importés en lot (ex: 10 photos d'un coup) sont insérés
  // en base UN PAR UN, ce qui déclenche plusieurs émissions successives
  // du stream très rapprochées dans le temps — pas un seul appel avec
  // les 10 d'un coup. Ce compteur ne se réinitialise que s'il y a eu une
  // vraie pause (> 400ms) depuis la dernière arrivée, pour que tout un
  // import groupé reste correctement étagé ensemble, même réparti sur
  // plusieurs appels à _synchroniserAvecNotes.
  int _compteurArriveesLotCourant = 0;
  DateTime? _dernierAjoutHorodatage;

  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _world = PastillePhysicsWorld(
      zoneLeft: zoneLeft,
      zoneRight: zoneRight,
      zoneTop: zoneTop,
      zoneBottom: zoneBottom,
      creuxFond: creuxFond,
      maxInsetFraction: maxInsetFraction,
      taperT: taperT,
    );

    _ticker = createTicker(_onTick)..start();

    // Fréquence de lecture raisonnable (pas besoin de plus pour un effet fluide).
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      // Si le rendu "à l'envers" te gêne au test, passe invertX/invertY à true.
      _world.updateGravityFromAccelerometer(event.x, event.y, invertX: true, invertY: true);
    });
  }

  void _onTick(Duration elapsed) {
    if (_dernierTemps == Duration.zero) {
      _dernierTemps = elapsed;
      return;
    }
    final double dt = (elapsed - _dernierTemps).inMicroseconds / 1e6;
    _dernierTemps = elapsed;

    // Sécurité : ignore les dt aberrants (ex: app remise au premier plan après veille)
    final double dtClamp = dt.clamp(0.0, 1 / 30);

    _world.updateBounds(_width, _height);
    _world.step(dtClamp);

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sauvegarderPositions(); // Filet de sécurité supplémentaire
    _ticker.dispose();
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Dès que l'app quitte le premier plan (mise en arrière-plan,
    // verrouillage, fermeture) — pas d'attente, on sauvegarde tout de
    // suite pour ne rien perdre même en cas de fermeture brutale par l'OS.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _sauvegarderPositions();
    }
  }

  /// Sauvegarde la position actuelle de chaque bille (en fractions de la
  /// largeur/hauteur du bocal, pour rester valable même si la taille
  /// d'écran diffère légèrement au prochain lancement).
  void _sauvegarderPositions() {
    if (_width == 0 || _height == 0 || _world.pastilles.isEmpty) return;
    final Map<String, dynamic> donnees = {
      for (final p in _world.pastilles) p.id.toString(): [p.x / _width, p.y / _height],
    };
    UserPrefs.positionsBocal = jsonEncode(donnees);
  }

  double _insetAt(double t, double zoneWidthPx) {
    if (t >= taperT) return 0.0;
    final double facteur = (taperT - t) / taperT;
    return maxInsetFraction * facteur * zoneWidthPx;
  }

  /// Calcule une position de repos initiale pour les souvenirs déjà
  /// présents au démarrage. PRIORITÉ à une position sauvegardée
  /// (mise en arrière-plan ou fermeture précédente) si elle existe pour
  /// ce souvenir — sinon, algorithme "tas de sable" comme avant, pour les
  /// souvenirs jamais encore affichés. [notes] doit être fourni du PLUS
  /// RÉCENT au PLUS ANCIEN.
  void _placerSouvenirsExistants(List<NoteSourire> notes, double width, double height) {
    final double pastilleSize = (width * 0.11).clamp(12.0, 26.0);
    final double radius = pastilleSize / 2;
    final double zoneWidth = (zoneRight - zoneLeft) * width;
    final double zoneTopPx = zoneTop * height;
    final double zoneBottomPx = zoneBottom * height;
    final double creuxPx = creuxFond * height;

    /// Fond du bocal sous l'abscisse [x] : la même parabole que la physique.
    double solA(double x) => ordonneeDuFond(
          x: x,
          zoneLeftPx: zoneLeft * width,
          zoneRightPx: zoneRight * width,
          fondPlatPx: zoneBottomPx,
          creuxPx: creuxPx,
        );

    final int resolution = max(10, (zoneWidth / (pastilleSize * 0.5)).floor());
    final double colWidth = zoneWidth / resolution;
    final List<double> heightMap = List.filled(resolution, 0.0);
    max(1, (pastilleSize * 0.7 / colWidth).ceil());

    Map<String, dynamic> positionsSauvegardees = {};
    try {
      final decoded = jsonDecode(UserPrefs.positionsBocal);
      if (decoded is Map<String, dynamic>) positionsSauvegardees = decoded;
    } catch (_) {
      positionsSauvegardees = {};
    }

    final chronological = notes.reversed.toList();

    for (final note in chronological) {
      final Object seed = note.id ?? note.hashCode;
      final rnd = Random(seed.hashCode);
      final dynamic positionSauvegardee = positionsSauvegardees[seed.toString()];

      double dx;
      double dy;

      if (positionSauvegardee is List && positionSauvegardee.length == 2) {
        // Position restaurée telle quelle (convertie depuis des
        // fractions, donc valable même si la taille d'écran a changé).
        dx = (positionSauvegardee[0] as num).toDouble() * width;
        dy = (positionSauvegardee[1] as num).toDouble() * height;

        final double t = ((dy - zoneTopPx) / (zoneBottomPx - zoneTopPx)).clamp(0.0, 1.0);
        final double inset = _insetAt(t, zoneWidth);
        final double minX = zoneLeft * width + inset + radius;
        final double maxX = zoneRight * width - inset - radius;
        dx = dx.clamp(minX, maxX);
        dy = dy.clamp(zoneTopPx + radius, solA(dx) - radius);

        // Met à jour la carte de hauteur locale pour que les souvenirs
        // NON sauvegardés (nouveaux) tiennent compte de cette bille lors
        // de leur propre placement "tas de sable" juste en dessous.
        final int colApprox = (((dx - zoneLeft * width) / colWidth).floor()).clamp(0, resolution - 1);
        // La hauteur du tas se mesure au-dessus du FOND LOCAL, pas d'une
        // horizontale : sinon les colonnes du centre paraîtraient déjà
        // remplies alors que le fond y descend plus bas.
        heightMap[colApprox] = max(heightMap[colApprox], solA(dx) - dy + radius * 0.32);
      } else {
        // Pas de position connue (souvenir jamais encore affiché) :
        // algorithme "tas de sable" habituel.
        const int candidates = 9;
        int bestCol = rnd.nextInt(resolution);
        double bestHeight = heightMap[bestCol];
        for (int c = 1; c < candidates; c++) {
          final col = rnd.nextInt(resolution);
          if (heightMap[col] < bestHeight) {
            bestHeight = heightMap[col];
            bestCol = col;
          }
        }

        final double jitterX = (rnd.nextDouble() - 0.5) * colWidth * 0.6;
        final double centerX = zoneLeft * width + (bestCol + 0.5) * colWidth + jitterX;
        dy = solA(centerX) - bestHeight - radius;
        dy = dy.clamp(zoneTopPx + radius, solA(centerX) - radius);

        final double t = ((dy - zoneTopPx) / (zoneBottomPx - zoneTopPx)).clamp(0.0, 1.0);
        final double inset = _insetAt(t, zoneWidth);
        final double minX = zoneLeft * width + inset + radius;
        final double maxX = zoneRight * width - inset - radius;
        dx = centerX.clamp(minX, maxX);

        heightMap[bestCol] = max(heightMap[bestCol], bestHeight + pastilleSize * 0.32);
      }

      _world.pastilles.add(Pastille(
        id: seed,
        x: dx,
        y: dy,
        radius: radius,
        baseColor: _couleurBille(note.colorLabel),
        zLayer: rnd.nextInt(3),
      ));
      _idsConnus.add(seed);
    }
  }

  /// Ajoute un souvenir tout nouveau : il apparaît au-dessus du bocal et
  /// tombe naturellement sous l'effet de la gravité simulée — plus besoin
  /// d'animation "fausse", la vraie physique donne le rebond.
  ///
  /// [indexDansLot] : position de cette bille dans le lot de nouvelles
  /// arrivées traitées lors de ce même passage. Sert à répartir les
  /// billes sur plusieurs "couloirs" horizontaux et à étager leur hauteur
  /// de départ — indispensable lors d'un IMPORT GROUPÉ (ex: 10 photos
  /// d'un coup) : sans ça, plusieurs billes démarraient quasiment au même
  /// endroit, provoquant un chevauchement initial énorme et un
  /// emballement de la simulation.
  void _ajouterNouveauSouvenir(NoteSourire note, double width, double height, int indexDansLot) {
    final double pastilleSize = (width * 0.11).clamp(12.0, 26.0);
    final double radius = pastilleSize / 2;
    final Object seed = note.id ?? note.hashCode;
    final rnd = Random(seed.hashCode);

    final double zoneWidth = (zoneRight - zoneLeft) * width;

    const int nombreCouloirs = 5;
    final int couloir = indexDansLot % nombreCouloirs;
    final double centreCouloir = zoneLeft * width + zoneWidth * ((couloir + 0.5) / nombreCouloirs);
    final double startX = centreCouloir + (rnd.nextDouble() - 0.5) * (zoneWidth / nombreCouloirs) * 0.5;

    final double startY = zoneTop * height - radius * (2 + rnd.nextDouble() * 3) - (indexDansLot * radius * 2.2);

    _world.pastilles.add(Pastille(
      id: seed,
      x: startX,
      y: startY,
      radius: radius,
      baseColor: _couleurBille(note.colorLabel),
      vx: (rnd.nextDouble() - 0.5) * 40,
      zLayer: rnd.nextInt(3),
    ));
    _idsConnus.add(seed);
  }

  /// [notesBrutes] est fourni par le stream, du PLUS RÉCENT au PLUS ANCIEN.
  void _synchroniserAvecNotes(List<NoteSourire> notesBrutes, double width, double height) {
    // Remise en ordre chronologique croissant (plus ancien en premier),
    // pour pouvoir appliquer proprement l'offset du bocal courant.
    final List<NoteSourire> chronologique = notesBrutes.reversed.toList();

    final List<NoteSourire> fenetreBocalActuel = widget.offsetBocal < chronologique.length
        ? chronologique.sublist(widget.offsetBocal)
        : <NoteSourire>[];

    final bool depassementCapacite = fenetreBocalActuel.length > widget.capaciteBocal;
    final List<NoteSourire> notesAffichees =
        depassementCapacite ? fenetreBocalActuel.sublist(0, widget.capaciteBocal) : fenetreBocalActuel;

    if (!_demarrageInitialise) {
      if (widget.animerDemarrage) {
        // Nouveau bocal déclenché EN SESSION (l'utilisateur regarde) :
        // on fait tomber chaque souvenir de la fenêtre initiale, étagé
        // comme un lot de nouvelles arrivées, plutôt que de les placer
        // instantanément déjà posés.
        int indexDansLot = 0;
        for (final note in notesAffichees) {
          _ajouterNouveauSouvenir(note, width, height, indexDansLot);
          indexDansLot++;
        }
      } else {
        // Démarrage à froid normal de l'app : placement instantané déjà
        // posé (évite une longue cascade de chutes à chaque ouverture).
        // _placerSouvenirsExistants attend une liste "plus récent
        // d'abord" (elle fait son propre .reversed en interne).
        _placerSouvenirsExistants(notesAffichees.reversed.toList(), width, height);
      }
      _demarrageInitialise = true;
    } else {
      final Set<Object> idsActuels = notesAffichees.map<Object>((n) => n.id ?? n.hashCode).toSet();

      _world.pastilles.removeWhere((p) => !idsActuels.contains(p.id));
      _idsConnus.removeWhere((id) => !idsActuels.contains(id));

      if (_world.pastilles.length < widget.capaciteBocal) {
        for (final note in notesAffichees) {
          final Object seed = note.id ?? note.hashCode;
          if (!_idsConnus.contains(seed)) {
            final DateTime maintenant = DateTime.now();
            if (_dernierAjoutHorodatage == null ||
                maintenant.difference(_dernierAjoutHorodatage!) > const Duration(milliseconds: 400)) {
              _compteurArriveesLotCourant = 0;
            }
            _dernierAjoutHorodatage = maintenant;

            _ajouterNouveauSouvenir(note, width, height, _compteurArriveesLotCourant);
            _compteurArriveesLotCourant++;

            if (_world.pastilles.length >= widget.capaciteBocal) break;
          }
        }
      }
    }

    // Le bocal est plein ET il reste des souvenirs en attente au-delà :
    // on prévient l'écran parent, une seule fois par bocal (jusqu'à ce
    // qu'une nouvelle Key recrée cette State, au moment du "Nouveau bocal").
    if (depassementCapacite && !_popupDejaDeclenchee) {
      _popupDejaDeclenchee = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onBocalPlein?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NoteSourire>>(
      stream: DatabaseService().getNotesStream(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];

        return LayoutBuilder(
          builder: (context, constraints) {
            _width = constraints.maxWidth;
            _height = constraints.maxHeight;

            if (snapshot.hasData) {
              _synchroniserAvecNotes(notes, _width, _height);
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (widget.showDebugZone) ..._buildDebugZone(_width, _height),
                CustomPaint(
                  size: Size(_width, _height),
                  painter: _PastillesPainter(List.of(_world.pastilles)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildDebugZone(double width, double height) {
    final double zoneWidthPx = (zoneRight - zoneLeft) * width;
    final double zoneHeightPx = (zoneBottom - zoneTop) * height;

    const int bandes = 12;
    List<Widget> widgets = [];
    for (int i = 0; i < bandes; i++) {
      final double t0 = i / bandes;
      final double inset0 = _insetAt(t0, zoneWidthPx);

      widgets.add(
        Positioned(
          left: zoneLeft * width + inset0,
          top: zoneTop * height + t0 * zoneHeightPx,
          width: zoneWidthPx - inset0 * 2,
          height: zoneHeightPx / bandes,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 0.5),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _PastillesPainter extends CustomPainter {
  final List<Pastille> pastilles;
  _PastillesPainter(this.pastilles);

  // Réglages de l'effet de profondeur par couche (index = zLayer : 0=arrière, 1=milieu, 2=avant)
  static const List<double> _echelleParCouche = [0.985, 1.0, 1.015];

  /// Gonflement visuel GLOBAL (appliqué à toutes les couches de la même
  /// façon) : le rayon AFFICHÉ est plus grand que le rayon physique réel.
  static const double _facteurChevauchementGlobal = 1.07;

  static const List<double> _assombrissementSupplementaire = [0.20, 0.0, 0.0];
  static const List<double> _eclaircissementSupplementaire = [0.0, 0.0, 0.10];

  @override
  void paint(Canvas canvas, Size size) {
    final List<Pastille> triees = List<Pastille>.from(pastilles)
      ..sort((a, b) => a.zLayer.compareTo(b.zLayer));

    for (final p in triees) {
      final int couche = p.zLayer.clamp(0, 2);
      final double echelle = _echelleParCouche[couche] * _facteurChevauchementGlobal;
      final double rayonAffiche = p.radius * echelle;

      Color highlight = Color.lerp(p.baseColor, Colors.white, 0.55)!;
      Color shade = Color.lerp(p.baseColor, Colors.black, 0.30)!;
      Color base = p.baseColor;

      final double assombrir = _assombrissementSupplementaire[couche];
      if (assombrir > 0) {
        highlight = Color.lerp(highlight, Colors.black, assombrir)!;
        shade = Color.lerp(shade, Colors.black, assombrir)!;
        base = Color.lerp(base, Colors.black, assombrir)!;
      }

      final double eclaircir = _eclaircissementSupplementaire[couche];
      if (eclaircir > 0) {
        highlight = Color.lerp(highlight, Colors.white, eclaircir)!;
      }

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);

      final Rect rect = Rect.fromCircle(center: Offset.zero, radius: rayonAffiche);
      final Paint fillPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.9,
          colors: [highlight, base, shade],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, rayonAffiche, fillPaint);

      final Paint borderPaint = Paint()
        ..color = shade.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(Offset.zero, rayonAffiche, borderPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PastillesPainter oldDelegate) => true;
}
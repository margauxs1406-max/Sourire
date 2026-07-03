import 'dart:math';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/note_model.dart';
import 'package:sourire/theme/tokens.dart';

/// Couche de pastilles à insérer DANS ton Stack existant (entre l'ombre
/// et l'image du bocal), en Positioned.fill, pour occuper exactement
/// bocalWidth x bocalHeight.
class BocalPastilles extends StatefulWidget {
  /// Nombre de souvenirs correspondant à un bocal plein.
  final int maxCapacity;

  /// Passe à `true` pour afficher un rectangle semi-transparent
  /// représentant la zone de remplissage actuelle (avec le rétrécissement
  /// en haut simulant le col du bocal) : ça te permet d'ajuster les
  /// constantes en te fiant à ce que tu vois par-dessus ton vrai PNG.
  /// Repasse à `false` une fois calibré.
  final bool showDebugZone;

  const BocalPastilles({
    super.key,
    this.maxCapacity = 50,
    this.showDebugZone = true,
  });

  @override
  State<BocalPastilles> createState() => _BocalPastillesState();
}

class _BocalPastillesState extends State<BocalPastilles> {
  // --- ZONE DE REMPLISSAGE ---
  // Rectangle fractionnel représentant la partie "creuse" (transparente)
  // de assets/bocal_new.png. Valeurs à AJUSTER via showDebugZone: true.
  // 0 = bord gauche/haut du SizedBox bocalWidth x bocalHeight, 1 = bord droit/bas.
  static const double zoneLeft = 0.16;
  static const double zoneRight = 0.84;
  static const double zoneBottom = 0.89; // bas du bocal, juste au-dessus du socle
  static const double zoneTop = 0.15; // hauteur max quand le bocal est plein

  // --- RÉTRÉCISSEMENT EN HAUT (forme du col/épaule du bocal) ---
  // Le bocal n'est pas un rectangle parfait : il se resserre vers le col.
  // maxInsetFraction = à quel point on resserre au tout début (t=0),
  // exprimé en fraction de la largeur totale de la zone.
  // taperT = jusqu'à quelle fraction de la hauteur ce resserrement
  // s'applique (au-delà, la largeur redevient pleine, le "corps" du bocal).
  // Ajuste ces deux valeurs à l'œil avec showDebugZone: true.
  static const double maxInsetFraction = 0.33;
  static const double taperT = 0.38;

  // Ne fait tomber-rebondir que les souvenirs ajoutés APRÈS le premier
  // chargement de cette session — les souvenirs déjà présents au démarrage
  // s'affichent directement figés à leur position finale.
  Set<Object> _idsDejaPresentsAuDemarrage = {};
  bool _demarrageInitialise = false;

  double _insetPourT(double t, double zoneWidthPx) {
    if (t >= taperT) return 0.0;
    final double facteur = (taperT - t) / taperT; // 1 en haut, 0 à la jonction
    return maxInsetFraction * facteur * zoneWidthPx;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NoteSourire>>(
      stream: DatabaseService().getNotesStream(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];

        // Au tout premier chargement réel de données (une seule fois par
        // session), on mémorise quels souvenirs existaient déjà : eux ne
        // seront jamais animés, même si le widget se reconstruit ensuite.
        if (!_demarrageInitialise && snapshot.hasData) {
          _idsDejaPresentsAuDemarrage =
              notes.map<Object>((n) => n.id ?? n.hashCode).toSet();
          _demarrageInitialise = true;
        }

        final count = notes.length;
        final cappedCount = count > widget.maxCapacity ? widget.maxCapacity : count;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (widget.showDebugZone)
                  ..._buildDebugZone(width, height),
                ..._buildPastilles(cappedCount, width, height, notes),
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

    // On dessine plusieurs bandes horizontales pour visualiser le
    // resserrement progressif, plutôt qu'un simple rectangle plein.
    const int bandes = 12;
    List<Widget> widgets = [];
    for (int i = 0; i < bandes; i++) {
      final double t0 = i / bandes;
      final double t1 = (i + 1) / bandes;
      final double inset0 = _insetPourT(t0, zoneWidthPx);
      final double insetMoyen = inset0; // approximation par bande

      widgets.add(
        Positioned(
          left: zoneLeft * width + insetMoyen,
          top: zoneTop * height + t0 * zoneHeightPx,
          width: zoneWidthPx - insetMoyen * 2,
          height: zoneHeightPx / bandes,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 0.5),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildPastilles(
    int count,
    double width,
    double height,
    List<NoteSourire> notes,
  ) {
    final zoneWidth = (zoneRight - zoneLeft) * width;
    final zoneBottomPx = zoneBottom * height;
    final zoneTopPx = zoneTop * height;

    final double pastilleSize = (width * 0.11).clamp(12.0, 26.0);

    final int resolution = max(10, (zoneWidth / (pastilleSize * 0.5)).floor());
    final double colWidth = zoneWidth / resolution;
    final List<double> heightMap = List.filled(resolution, 0.0);
    final int footprintCols = max(1, (pastilleSize / 2 / colWidth).ceil());

    final chronological = notes.reversed.toList();
    final buildList = chronological.take(count).toList();

    const double overlapFactor = 0.45;

    List<Widget> pastilles = [];

    for (int i = 0; i < buildList.length; i++) {
      final note = buildList[i];
      final Object seed = note.id ?? note.hashCode;
      final rnd = Random(seed.hashCode);

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

      final rotationDeg = (rnd.nextDouble() - 0.5) * 30;
      final jitterX = (rnd.nextDouble() - 0.5) * colWidth * 1.2;

      final centerX = zoneLeft * width + (bestCol + 0.5) * colWidth + jitterX;
      double dx = centerX - pastilleSize / 2;

      double dy = zoneBottomPx - bestHeight - pastilleSize;
      dy = dy.clamp(zoneTopPx, zoneBottomPx - pastilleSize);

      // Resserrement horizontal selon la hauteur, pour suivre la forme
      // en biseau du bocal (col plus étroit que le corps).
      final double t = ((dy - zoneTopPx) / (zoneBottomPx - zoneTopPx - pastilleSize))
          .clamp(0.0, 1.0);
      final double inset = _insetPourT(t, zoneWidth);
      final double minX = zoneLeft * width + inset;
      final double maxX = zoneRight * width - inset - pastilleSize;
      if (minX < maxX) {
        dx = dx.clamp(minX, maxX);
      }

      final newHeight = bestHeight + pastilleSize * overlapFactor;
      for (int k = bestCol - footprintCols; k <= bestCol + footprintCols; k++) {
        if (k >= 0 && k < resolution) {
          heightMap[k] = max(heightMap[k], newHeight);
        }
      }

      final baseColor = SourireTheme.fromLabel(note.colorLabel).main;
      final highlight = Color.lerp(baseColor, Colors.white, 0.55)!;
      final shade = Color.lerp(baseColor, Colors.black, 0.30)!;

      final bool estDejaPresentAuDemarrage =
          _idsDejaPresentsAuDemarrage.contains(seed);

      final Widget pastilleVisuelle = Transform.rotate(
        angle: rotationDeg * pi / 180,
        child: Container(
          width: pastilleSize,
          height: pastilleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.35),
              radius: 0.9,
              colors: [highlight, baseColor, shade],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(color: shade.withOpacity(0.6), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 3,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ),
      );

      pastilles.add(
        Positioned(
          left: dx,
          top: dy,
          child: estDejaPresentAuDemarrage
              // Souvenir déjà existant au démarrage : affiché directement,
              // figé, sans chute ni rebond.
              ? pastilleVisuelle
              // Nouveau souvenir ajouté durant cette session : anime la
              // chute avec rebond, comme avant.
              : TweenAnimationBuilder<double>(
                  key: ValueKey('pastille_$seed'),
                  tween: Tween(begin: -(pastilleSize * 6), end: 0.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.bounceOut,
                  builder: (context, fallOffset, child) {
                    return Transform.translate(
                      offset: Offset(0, fallOffset),
                      child: child,
                    );
                  },
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (context, opacity, child) => Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                    child: pastilleVisuelle,
                  ),
                ),
        ),
      );
    }

    return pastilles;
  }
}
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/database_service.dart';
import '../models/note_model.dart';
import '../services/pastille_physics.dart';
import 'package:sourire/theme/tokens.dart';

/// Couche de pastilles à insérer DANS ton Stack existant (entre l'ombre
/// et l'image du bocal), en Positioned.fill, pour occuper exactement
/// bocalWidth x bocalHeight.
///
/// Cette version utilise une VRAIE simulation physique (gravité pilotée
/// par l'inclinaison du téléphone, collisions bille-bille et bille-paroi)
/// au lieu de positions statiques calculées une fois.
class BocalPastilles extends StatefulWidget {
  final int maxCapacity;

  /// Affiche un rectangle semi-transparent représentant la zone de
  /// remplissage (avec le biseau) pour calibrer visuellement.
  final bool showDebugZone;

  const BocalPastilles({
    super.key,
    this.maxCapacity = 50,
    this.showDebugZone = false,
  });

  @override
  State<BocalPastilles> createState() => _BocalPastillesState();
}

class _BocalPastillesState extends State<BocalPastilles> with SingleTickerProviderStateMixin {
  static const double zoneLeft = 0.18;
  static const double zoneRight = 0.82;
  static const double zoneBottom = 0.89;
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

  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _world = PastillePhysicsWorld(
      zoneLeft: zoneLeft,
      zoneRight: zoneRight,
      zoneTop: zoneTop,
      zoneBottom: zoneBottom,
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
    _ticker.dispose();
    _accelSub?.cancel();
    super.dispose();
  }

  double _insetAt(double t, double zoneWidthPx) {
    if (t >= taperT) return 0.0;
    final double facteur = (taperT - t) / taperT;
    return maxInsetFraction * facteur * zoneWidthPx;
  }

  /// Calcule une position de repos initiale (méthode "tas de sable", comme
  /// dans l'ancienne version statique) pour les souvenirs déjà présents au
  /// démarrage — ils doivent apparaître déjà installés, pas tomber du ciel.
  void _placerSouvenirsExistants(List<NoteSourire> notes, double width, double height) {
    final double pastilleSize = (width * 0.11).clamp(12.0, 26.0);
    final double radius = pastilleSize / 2;
    final double zoneWidth = (zoneRight - zoneLeft) * width;
    final double zoneTopPx = zoneTop * height;
    final double zoneBottomPx = zoneBottom * height;

    final int resolution = max(10, (zoneWidth / (pastilleSize * 0.5)).floor());
    final double colWidth = zoneWidth / resolution;
    final List<double> heightMap = List.filled(resolution, 0.0);
    max(1, (pastilleSize * 0.7 / colWidth).ceil());

    final chronological = notes.reversed.toList();

    for (final note in chronological) {
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

      final double jitterX = (rnd.nextDouble() - 0.5) * colWidth * 0.6;
      final double centerX = zoneLeft * width + (bestCol + 0.5) * colWidth + jitterX;
      double dy = zoneBottomPx - bestHeight - radius;
      dy = dy.clamp(zoneTopPx + radius, zoneBottomPx - radius);

      final double t = ((dy - zoneTopPx) / (zoneBottomPx - zoneTopPx)).clamp(0.0, 1.0);
      final double inset = _insetAt(t, zoneWidth);
      final double minX = zoneLeft * width + inset + radius;
      final double maxX = zoneRight * width - inset - radius;
      final double dx = centerX.clamp(minX, maxX);

      heightMap[bestCol] = max(heightMap[bestCol], bestHeight + pastilleSize * 0.32);

      _world.pastilles.add(Pastille(
        id: seed,
        x: dx,
        y: dy,
        radius: radius,
        baseColor: SourireTheme.fromLabel(note.colorLabel).main,
      ));
      _idsConnus.add(seed);
    }
  }

  /// Ajoute un souvenir tout nouveau : il apparaît au-dessus du bocal et
  /// tombe naturellement sous l'effet de la gravité simulée — plus besoin
  /// d'animation "fausse", la vraie physique donne le rebond.
  void _ajouterNouveauSouvenir(NoteSourire note, double width, double height) {
    final double pastilleSize = (width * 0.11).clamp(12.0, 26.0);
    final double radius = pastilleSize / 2;
    final Object seed = note.id ?? note.hashCode;
    final rnd = Random(seed.hashCode);

    final double zoneWidth = (zoneRight - zoneLeft) * width;
    final double startX = zoneLeft * width + zoneWidth * (0.3 + rnd.nextDouble() * 0.4);
    final double startY = zoneTop * height - radius * (2 + rnd.nextDouble() * 3);

    _world.pastilles.add(Pastille(
      id: seed,
      x: startX,
      y: startY,
      radius: radius,
      baseColor: SourireTheme.fromLabel(note.colorLabel).main,
      vx: (rnd.nextDouble() - 0.5) * 40,
    ));
    _idsConnus.add(seed);
  }

  void _synchroniserAvecNotes(List<NoteSourire> notes, double width, double height) {
    if (!_demarrageInitialise) {
      final int cappedCount = notes.length > widget.maxCapacity ? widget.maxCapacity : notes.length;
      _placerSouvenirsExistants(notes.take(cappedCount).toList(), width, height);
      _demarrageInitialise = true;
      return;
    }

    final Set<Object> idsActuels = notes.map<Object>((n) => n.id ?? n.hashCode).toSet();

    // Suppressions
    _world.pastilles.removeWhere((p) => !idsActuels.contains(p.id));
    _idsConnus.removeWhere((id) => !idsActuels.contains(id));

    // Ajouts (uniquement si sous la capacité max)
    if (_world.pastilles.length < widget.maxCapacity) {
      for (final note in notes) {
        final Object seed = note.id ?? note.hashCode;
        if (!_idsConnus.contains(seed)) {
          _ajouterNouveauSouvenir(note, width, height);
          if (_world.pastilles.length >= widget.maxCapacity) break;
        }
      }
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
              color: Colors.red.withOpacity(0.12),
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 0.5),
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

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pastilles) {
      final Color highlight = Color.lerp(p.baseColor, Colors.white, 0.55)!;
      final Color shade = Color.lerp(p.baseColor, Colors.black, 0.30)!;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);

      final Rect rect = Rect.fromCircle(center: Offset.zero, radius: p.radius);
      final Paint fillPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.9,
          colors: [highlight, p.baseColor, shade],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, p.radius, fillPaint);

      final Paint borderPaint = Paint()
        ..color = shade.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(Offset.zero, p.radius, borderPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PastillesPainter oldDelegate) => true;
}
import 'dart:math';
import 'package:flutter/material.dart';

/// Explosion de confettis dorés qui se joue une seule fois à l'apparition
/// du widget, puis s'immobilise (transparente) une fois terminée.
/// N'intercepte aucun tap (IgnorePointer), donc peut être posé par-dessus
/// n'importe quel contenu interactif sans le bloquer.
class ConfettiExplosion extends StatefulWidget {
  final int particleCount;
  final Duration duration;
  final double yOffset; // 💡 Nouveau : 0.0 (haut) à 1.0 (bas)

  const ConfettiExplosion({
    super.key,
    this.particleCount = 120,
    this.duration = const Duration(milliseconds: 2500),
    this.yOffset = 0.8, // 💡 Par défaut, on le place vers le bas
  });

  @override
  State<ConfettiExplosion> createState() => _ConfettiExplosionState();
}

class _Particule {
  final double angle; // direction d'éjection, en radians
  final double vitesse;
  final double taille;
  final double rotationInitiale;
  final double vitesseRotation;
  final Color couleur;

  _Particule({
    required this.angle,
    required this.vitesse,
    required this.taille,
    required this.rotationInitiale,
    required this.vitesseRotation,
    required this.couleur,
  });
}

class _ConfettiExplosionState extends State<ConfettiExplosion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particule> _particules;

  // Palette dorée : plusieurs nuances pour un effet plus riche qu'une
  // seule couleur plate.
  static const List<Color> _palette = [
    Color(0xFFFFD700), // or classique
    Color(0xFFFFC93C), // or plus chaud
    Color(0xFFFFF3B0), // or pâle / highlight
    Color(0xFFE8B923), // or plus profond
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();

    final rnd = Random();
    _particules = List.generate(widget.particleCount, (i) {
      // Éjection sur un arc vers le haut plutôt qu'à 360° uniforme, pour
      // un effet "explosion vers le ciel" plutôt que "pluie".
      // (0° = droite, -90° = vers le haut dans ce repère)
      final double angle = (-160 + rnd.nextDouble() * 140) * pi / 180;
      return _Particule(
        angle: angle,
        vitesse: 300 + rnd.nextDouble() * 400,
        taille: 5 + rnd.nextDouble() * 6,
        rotationInitiale: rnd.nextDouble() * 2 * pi,
        vitesseRotation: (rnd.nextDouble() - 0.5) * 10,
        couleur: _palette[rnd.nextInt(_palette.length)],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particules: _particules,
              progress: _controller.value,
              yOffset: widget.yOffset, // 💡 On passe l'offset au peintre
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particule> particules;
  final double progress;
  final double yOffset; // 💡

  _ConfettiPainter({required this.particules, required this.progress, required this.yOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // 💡 L'origine est maintenant calculée dynamiquement
    final Offset origine = Offset(size.width / 2, size.height * yOffset);
    const double gravite = 250; // Un peu plus de gravité pour que ça retombe après la montée

    for (final p in particules) {
      final double t = progress;
      final double dx = cos(p.angle) * p.vitesse * t;
      final double dy = sin(p.angle) * p.vitesse * t + 0.5 * gravite * t * t;

      final double opacite = (1 - t).clamp(0.0, 1.0);
      if (opacite <= 0) continue;

      final Offset position = origine + Offset(dx, dy);
      final double rotation = p.rotationInitiale + p.vitesseRotation * t * 2 * pi;

      final Paint paint = Paint()..color = p.couleur.withValues(alpha: opacite);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.taille, height: p.taille * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
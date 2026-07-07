import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Une bille physique : position, vitesse, rotation visuelle, couleur.
class Pastille {
  final Object id;
  double x, y;
  double vx, vy;
  double angle, angularVelocity;
  final double radius;
  final Color baseColor;

  Pastille({
    required this.id,
    required this.x,
    required this.y,
    required this.radius,
    required this.baseColor,
    this.vx = 0,
    this.vy = 0,
    this.angle = 0,
    this.angularVelocity = 0,
  });
}

/// Simulation physique 2D simple : gravité inclinable (venant du capteur
/// d'inclinaison), collisions bille-bille, et collisions avec les parois
/// du bocal (en tenant compte du rétrécissement en biseau vers le col).
class PastillePhysicsWorld {
  final List<Pastille> pastilles = [];

  // Direction de gravité normalisée (-1..1), mise à jour depuis le capteur.
  double gravityX = 0;
  double gravityY = 1; // vers le bas par défaut, tant qu'aucune inclinaison connue

  // --- Réglages physiques ---
  static const double gravityMagnitude = 800; // px/s², ajuste pour + ou - de "poids"
  static const double damping = 0.900; // freinage naturel (frottement de l'air/verre)
  static const double restitutionBilleBille = 0.55; // "rebond" entre deux billes
  static const double restitutionParoi = 0.55; // "rebond" contre le verre

  // --- Zone de remplissage (identique à l'ancienne version statique) ---
  final double zoneLeft;
  final double zoneRight;
  final double zoneTop;
  final double zoneBottom;
  final double maxInsetFraction;
  final double taperT;

  double width = 0;
  double height = 0;

  PastillePhysicsWorld({
    this.zoneLeft = 0.16,
    this.zoneRight = 0.84,
    this.zoneTop = 0.15,
    this.zoneBottom = 0.89,
    this.maxInsetFraction = 0.33,
    this.taperT = 0.38,
  });

  void updateBounds(double newWidth, double newHeight) {
    width = newWidth;
    height = newHeight;
  }

  double _insetAt(double t) {
    if (t >= taperT) return 0.0;
    final double facteur = (taperT - t) / taperT;
    return maxInsetFraction * facteur * (zoneRight - zoneLeft) * width;
  }

  /// À appeler avec la lecture brute de l'accéléromètre (axes x, y en m/s²).
  /// Les signes peuvent avoir besoin d'être inversés selon le ressenti —
  /// ajuste [invertX]/[invertY] si le mouvement semble inversé au test.
  void updateGravityFromAccelerometer(double sensorX, double sensorY, {bool invertX = false, bool invertY = false}) {
    const double g = 9.8;
    double gx = (sensorX / g).clamp(-1.0, 1.0);
    double gy = (-sensorY / g).clamp(-1.0, 1.0);
    if (invertX) gx = -gx;
    if (invertY) gy = -gy;
    gravityX = gx;
    gravityY = gy;
  }

  void step(double dt) {
    if (width == 0 || height == 0 || pastilles.isEmpty) return;

    final double zoneTopPx = zoneTop * height;
    final double zoneBottomPx = zoneBottom * height;
    final double zoneLeftPx = zoneLeft * width;
    final double zoneRightPx = zoneRight * width;

    // 1. Gravité + intégration
    for (final p in pastilles) {
      p.vx += gravityX * gravityMagnitude * dt;
      p.vy += gravityY * gravityMagnitude * dt;
      p.vx *= damping;
      p.vy *= damping;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }

    // 2. Collisions bille-bille (O(n²) — largement suffisant pour ~60-100 billes)
    for (int i = 0; i < pastilles.length; i++) {
      for (int j = i + 1; j < pastilles.length; j++) {
        _resoudreCollisionPaire(pastilles[i], pastilles[j]);
      }
    }

    // 3. Collisions avec les parois (avec biseau vers le col)
    for (final p in pastilles) {
      final double t = ((p.y - zoneTopPx) / (zoneBottomPx - zoneTopPx)).clamp(0.0, 1.0);
      final double inset = _insetAt(t);
      final double minX = zoneLeftPx + inset + p.radius;
      final double maxX = zoneRightPx - inset - p.radius;
      final double minY = zoneTopPx + p.radius;
      final double maxY = zoneBottomPx - p.radius;

      if (p.x < minX) {
        p.x = minX;
        p.vx = -p.vx * restitutionParoi;
      } else if (p.x > maxX) {
        p.x = maxX;
        p.vx = -p.vx * restitutionParoi;
      }

      if (p.y < minY) {
        p.y = minY;
        p.vy = -p.vy * restitutionParoi;
      } else if (p.y > maxY) {
        p.y = maxY;
        p.vy = -p.vy * restitutionParoi;
      }

      // Rotation visuelle liée à la vitesse horizontale (effet "roulement").
      p.angularVelocity = p.radius > 0 ? (p.vx / p.radius) * 0.3 : 0;
      p.angle += p.angularVelocity * dt;
    }
  }

  void _resoudreCollisionPaire(Pastille a, Pastille b) {
    final double dx = b.x - a.x;
    final double dy = b.y - a.y;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double minDist = a.radius + b.radius;
    if (dist == 0 || dist >= minDist) return;

    final double nx = dx / dist;
    final double ny = dy / dist;
    final double overlap = minDist - dist;

    // Séparation positionnelle (moitié chacune, pour ne pas favoriser l'une)
    a.x -= nx * overlap / 2;
    a.y -= ny * overlap / 2;
    b.x += nx * overlap / 2;
    b.y += ny * overlap / 2;

    // Échange de vitesse le long de la normale de collision (avec restitution)
    final double relVx = b.vx - a.vx;
    final double relVy = b.vy - a.vy;
    final double relDot = relVx * nx + relVy * ny;
    if (relDot > 0) return; // s'éloignent déjà, rien à faire

    final double impulse = -(1 + restitutionBilleBille) * relDot / 2;
    a.vx -= impulse * nx;
    a.vy -= impulse * ny;
    b.vx += impulse * nx;
    b.vy += impulse * ny;
  }
}
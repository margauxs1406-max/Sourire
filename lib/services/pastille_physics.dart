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

  /// Couche de profondeur PUREMENT VISUELLE (0 = arrière-plan, 1 = milieu,
  /// 2 = premier plan). N'affecte JAMAIS la physique (position, collisions,
  /// gravité) — uniquement l'ordre de dessin et un léger effet de taille/
  /// luminosité, pour recréer une impression de "3D" sans rien changer à
  /// la simulation 2D stabilisée.
  final int zLayer;

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
    this.zLayer = 1,
  });
}

/// Simulation physique 2D simple : gravité inclinable (venant du capteur
/// d'inclinaison), collisions bille-bille, et collisions avec les parois
/// du bocal (en tenant compte du rétrécissement en biseau vers le col).
///
/// --- STABILITÉ DU BOCAL PLEIN vs REBOND DES NOUVELLES BILLES ---
/// Deux réglages clés permettent de dissocier ces deux comportements,
/// qui se marchaient dessus dans la version précédente :
///
/// 1. `collisionIterations` : plusieurs passes de résolution des
///    chevauchements PAR FRAME (au lieu d'une seule). Avec beaucoup de
///    billes tassées (bocal plein), une seule passe ne suffit jamais à
///    tout résoudre d'un coup, ce qui "fuit" un peu d'énergie à chaque
///    frame et fait s'emballer le tas. Plusieurs passes convergent
///    correctement et stabilisent un tas dense, SANS avoir besoin de
///    réduire la gravité ou le rebond général.
///
/// 2. `vitesseSeuilRebond` : le rebond (restitution) ne s'applique QUE
///    si la vitesse d'impact dépasse ce seuil. En dessous, la collision
///    devient inélastique (pas de rebond) — exactement ce qu'on veut
///    pour des billes déjà presque immobiles dans un tas (pas de
///    "vibration perpétuelle"), tout en gardant un vrai rebond visible
///    pour une bille qui vient de tomber avec de la vitesse.
class PastillePhysicsWorld {
  final List<Pastille> pastilles = [];

  // Direction de gravité normalisée (-1..1), mise à jour depuis le capteur.
  double gravityX = 0;
  double gravityY = 1; // vers le bas par défaut, tant qu'aucune inclinaison connue

  // --- Réglages physiques ---
  static const double gravityMagnitude = 1600; // px/s², ajuste pour + ou - de "poids"
  static const double damping = 0.995; // freinage naturel (frottement de l'air/verre)
  static const double restitutionBilleBille = 0.25; // "rebond" entre deux billes (réduit pour un tas plus calme)
  static const double restitutionParoi = 0.40; // "rebond" contre le verre (inchangé, préserve le rebond des nouvelles billes)

  /// En dessous de cette vitesse d'impact (px/s), le rebond est désactivé
  /// (collision inélastique) — évite qu'un tas déjà posé ne vibre à l'infini.
  /// Augmente si le bocal plein bouge encore trop ; diminue si les
  /// nouvelles billes rebondissent trop peu.
  static const double vitesseSeuilRebond = 40.0;

  /// Nombre de passes de résolution des collisions par frame. Plus haut =
  /// tas plus stable (surtout à haute densité), mais légèrement plus coûteux.
  /// 4 est un bon compromis pour ~60-100 billes sur mobile.
  static const int collisionIterations = 4;

  /// En dessous de cette vitesse globale, on "endort" complètement la
  /// bille (vitesse mise à 0) pour éliminer tout micro-tremblement
  /// résiduel une fois posée.
  static const double vitesseSommeil = 12.0;

  /// Filet de sécurité : aucune bille ne peut jamais dépasser cette
  /// vitesse, peu importe la cause (chevauchement initial important lors
  /// d'un import groupé, instabilité ponctuelle, etc.). Empêche tout
  /// emballement numérique de s'auto-amplifier indéfiniment ("bocal
  /// possédé"). Bien au-dessus de la vitesse d'une chute normale, donc
  /// invisible en usage normal.
  static const double vitesseMaximale = 2200.0;

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

  /// Facteur de lissage (0 < x ≤ 1) appliqué à chaque nouvelle lecture du
  /// capteur d'inclinaison, AVANT qu'elle n'influence la physique. Plus la
  /// valeur est PETITE, plus le filtrage est fort (les micro-tremblements
  /// de la main sont ignorés), mais plus l'app met de temps à réagir à une
  /// vraie inclinaison volontaire. Ne touche en rien à la vitesse ou au
  /// rebond de la chute d'une nouvelle bille (gérés par gravityMagnitude
  /// et les constantes de restitution, totalement indépendants de ceci).
  static const double filtragePenteAccelerometre = 0.10;

  /// À appeler avec la lecture brute de l'accéléromètre (axes x, y en m/s²).
  void updateGravityFromAccelerometer(double sensorX, double sensorY, {bool invertX = false, bool invertY = false}) {
    const double g = 9.8;
    double gx = (sensorX / g).clamp(-1.0, 1.0);
    double gy = (-sensorY / g).clamp(-1.0, 1.0);
    if (invertX) gx = -gx;
    if (invertY) gy = -gy;

    // Filtre passe-bas (moyenne mobile exponentielle) : chaque nouvelle
    // lecture ne compte que pour une petite fraction de la valeur finale,
    // le reste vient de la valeur précédente déjà lissée. Ça absorbe les
    // à-coups très rapides (tremblement de la main) tout en laissant
    // passer les inclinaisons volontaires, plus lentes et plus amples.
    gravityX = gravityX + (gx - gravityX) * filtragePenteAccelerometre;
    gravityY = gravityY + (gy - gravityY) * filtragePenteAccelerometre;
  }

  void step(double dt) {
    if (width == 0 || height == 0 || pastilles.isEmpty) return;

    final double zoneTopPx = zoneTop * height;
    final double zoneBottomPx = zoneBottom * height;
    final double zoneLeftPx = zoneLeft * width;
    final double zoneRightPx = zoneRight * width;

    // 1. Gravité + intégration (une seule fois par frame)
    for (final p in pastilles) {
      p.vx += gravityX * gravityMagnitude * dt;
      p.vy += gravityY * gravityMagnitude * dt;
      p.vx *= damping;
      p.vy *= damping;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }

    // 2. Résolution des collisions en PLUSIEURS passes — c'est ce qui
    // stabilise un tas dense (bocal plein) sans avoir à toucher à la
    // gravité ou au rebond général.
    for (int iter = 0; iter < collisionIterations; iter++) {
      for (int i = 0; i < pastilles.length; i++) {
        for (int j = i + 1; j < pastilles.length; j++) {
          _resoudreCollisionPaire(pastilles[i], pastilles[j]);
        }
      }
      for (final p in pastilles) {
        _resoudreCollisionParoi(p, zoneLeftPx, zoneRightPx, zoneTopPx, zoneBottomPx);
      }
    }

    // 3. Rotation visuelle + mise en sommeil des billes quasi immobiles
    // + plafond de vitesse (filet de sécurité anti-emballement)
    for (final p in pastilles) {
      final double vitesse = math.sqrt(p.vx * p.vx + p.vy * p.vy);
      if (vitesse < vitesseSommeil) {
        p.vx = 0;
        p.vy = 0;
      } else if (vitesse > vitesseMaximale) {
        final double facteur = vitesseMaximale / vitesse;
        p.vx *= facteur;
        p.vy *= facteur;
      }
      p.angularVelocity = p.radius > 0 ? (p.vx / p.radius) * 0.3 : 0;
      p.angle += p.angularVelocity * dt;
    }
  }

  void _resoudreCollisionParoi(Pastille p, double zoneLeftPx, double zoneRightPx, double zoneTopPx, double zoneBottomPx) {
    final double t = ((p.y - zoneTopPx) / (zoneBottomPx - zoneTopPx)).clamp(0.0, 1.0);
    final double inset = _insetAt(t);
    final double minX = zoneLeftPx + inset + p.radius;
    final double maxX = zoneRightPx - inset - p.radius;
    final double minY = zoneTopPx + p.radius;
    final double maxY = zoneBottomPx - p.radius;

    if (p.x < minX) {
      final double vitesseImpact = -p.vx;
      p.x = minX;
      p.vx = vitesseImpact > vitesseSeuilRebond ? vitesseImpact * restitutionParoi : 0.0;
    } else if (p.x > maxX) {
      final double vitesseImpact = p.vx;
      p.x = maxX;
      p.vx = vitesseImpact > vitesseSeuilRebond ? -vitesseImpact * restitutionParoi : 0.0;
    }

    if (p.y < minY) {
      final double vitesseImpact = -p.vy;
      p.y = minY;
      p.vy = vitesseImpact > vitesseSeuilRebond ? vitesseImpact * restitutionParoi : 0.0;
    } else if (p.y > maxY) {
      final double vitesseImpact = p.vy;
      p.y = maxY;
      p.vy = vitesseImpact > vitesseSeuilRebond ? -vitesseImpact * restitutionParoi : 0.0;
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

    // Séparation positionnelle : TOUJOURS appliquée (même à vitesse nulle)
    // pour éliminer le chevauchement — c'est elle qui, répétée sur
    // plusieurs passes, stabilise vraiment le tas.
    a.x -= nx * overlap / 2;
    a.y -= ny * overlap / 2;
    b.x += nx * overlap / 2;
    b.y += ny * overlap / 2;

    final double relVx = b.vx - a.vx;
    final double relVy = b.vy - a.vy;
    final double relDot = relVx * nx + relVy * ny;
    if (relDot > 0) return; // s'éloignent déjà, rien à faire

    // Rebond seulement si l'impact est assez rapide — sinon collision
    // inélastique (les deux billes se "collent", pas de vibration).
    final double vitesseImpact = -relDot;
    final double restitution = vitesseImpact > vitesseSeuilRebond ? restitutionBilleBille : 0.0;

    final double impulse = -(1 + restitution) * relDot / 2;
    a.vx -= impulse * nx;
    a.vy -= impulse * ny;
    b.vx += impulse * nx;
    b.vy += impulse * ny;
  }
}
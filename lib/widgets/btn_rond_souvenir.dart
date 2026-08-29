import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

/// Pastille ronde blanche posée PAR-DESSUS un souvenir : partager, réécrire,
/// changer de décor.
///
/// Le fond blanc translucide garde l'icône lisible aussi bien sur une photo
/// sombre que sur une note claire. L'icône est TOUJOURS orange, jamais de la
/// couleur du souvenir : ce sont des actions de l'application, pas des
/// propriétés de ce qu'on regarde.
class BtnRondSouvenir extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;

  const BtnRondSouvenir({
    required this.icone,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Material.elevation ne permet pas de choisir le décalage : on dessine
      // l'ombre nous-mêmes pour la porter légèrement sur la droite plutôt que
      // vers le bas.
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: black.withValues(alpha: 0.18),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Material(
        color: white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          // Le GestureDetector de l'historique referme la fenêtre au moindre
          // tap : en consommant le geste ici, on l'empêche de remonter.
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icone, color: orange, size: 22),
          ),
        ),
      ),
    );
  }
}

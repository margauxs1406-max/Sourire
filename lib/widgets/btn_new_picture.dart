import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class BtnNewPicture extends StatelessWidget {
  final VoidCallback onTap;

  const BtnNewPicture({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    // Diamètre du cercle, proportionnel À L'ÉCRAN MAIS BORNÉ. Mêmes bornes
    // que `BtnNewNote`, dont ce bouton est le jumeau : les deux sont posés
    // côte à côte, ils doivent grandir et s'arrêter ensemble.
    double buttonSize = (screenWidth * 0.2).clamp(64.0, 96.0);
    // Calcul de l'icône proportionnelle
    double iconSize = buttonSize * 0.46;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: const BoxDecoration(
          color: orange,
          shape: BoxShape.circle,
          boxShadow: shadowDrop,
        ),
        child: Icon(
          Icons.image_outlined,
          color: white,
          size: iconSize,
        ),
      ),
    );
  }
}
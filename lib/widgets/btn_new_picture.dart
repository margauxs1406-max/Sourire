import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class BtnNewPicture extends StatelessWidget {
  final VoidCallback onTap;

  const BtnNewPicture({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    // Calcul de la dimension responsive (diamètre du cercle)
    double buttonSize = screenWidth * 0.2; 
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
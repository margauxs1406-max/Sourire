import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class BtnNewNote extends StatelessWidget {
  final VoidCallback onTap;

  const BtnNewNote({required this.onTap, super.key});

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
          Icons.edit_outlined,
          color: white,
          size: iconSize,
        ),
      ),
    );
  }
}
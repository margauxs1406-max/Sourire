import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class BtnNewNote extends StatelessWidget {
  final VoidCallback onTap;

  const BtnNewNote({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    // Diamètre du cercle, proportionnel À L'ÉCRAN MAIS BORNÉ.
    //
    // Un cinquième de la largeur donnait 75 points sur un téléphone — la
    // valeur pour laquelle le bouton a été dessiné — mais 167 sur un iPad en
    // portrait et 236 en paysage, soit un palet de cinq centimètres. Un
    // bouton d'action ne grandit pas avec la dalle : la main qui le vise
    // reste la même. Les bornes laissent les téléphones exactement où ils
    // étaient et arrêtent la dérive au-delà.
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
          Icons.edit_outlined,
          color: white,
          size: iconSize,
        ),
      ),
    );
  }
}
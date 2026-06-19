import 'package:flutter/material.dart';
import 'package:sourire/main.dart'; 
import 'package:sourire/theme/tokens.dart';

class BtnCategorisation extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;
  final bool isSecondary; 
  final double? fontSize;
  final double? widthFactor; // Permet de définir une largeur proportionnelle (ex: 0.8 pour 80% de l'écran)

  const BtnCategorisation({
    required this.text,
    required this.onTap,
    this.isActive = true,
    this.isSecondary = false, 
    this.fontSize,
    this.widthFactor, // Si null, prendra toute la largeur disponible
    super.key, // L'intrus 'required Color color' a été supprimé d'ici
  });

  @override
  Widget build(BuildContext context) {
    // Récupération des dimensions de l'écran
    final Size screenSize = MediaQuery.of(context).size;
    
    // Calcul d'une hauteur proportionnelle (ex: ~5.5% de la hauteur de l'écran)
    // avec des limites (min 45, max 65) pour éviter que ce soit trop petit ou trop grand
    final double hauteurDynamique = (screenSize.height * 0.065).clamp(45.0, 65.0);

    // Taille de police adaptative basée sur la largeur de l'écran si non spécifiée
    final double tailleTexteDynamique = fontSize ?? (screenSize.width * 0.04).clamp(14.0, 18.0);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentThemeMode, child) {
        final bool isDarkMode = currentThemeMode == ThemeMode.dark;

        Color couleurContenu;
        Color couleurFond;
        Color couleurBordure;

        if (!isSecondary) {
          couleurContenu = Colors.white;
          couleurFond = isActive ? orange : orange.withOpacity(0.5);
          couleurBordure = Colors.transparent;
        } else {
          final Color orangeActuel = isActive ? orange : orange.withOpacity(0.5);
          couleurContenu = orangeActuel;
          couleurBordure = orangeActuel;
          couleurFond = isDarkMode ? Colors.transparent : white;
        }

        return GestureDetector(
          onTap: isActive ? onTap : null,
          child: Container(
            // Gestion de la largeur proportionnelle ou occupation totale de l'espace parent
            width: widthFactor != null ? screenSize.width * widthFactor! : double.infinity,
            height: hauteurDynamique,
            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04), // Padding interne adaptatif
            decoration: BoxDecoration(
              color: couleurFond,
              borderRadius: BorderRadius.circular(hauteurDynamique / 2), // Reste parfaitement arrondi peu importe la hauteur
              border: isSecondary 
                  ? Border.all(color: couleurBordure, width: 2) 
                  : null,
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: couleurContenu,
                  fontWeight: FontWeight.bold,
                  fontSize: tailleTexteDynamique,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
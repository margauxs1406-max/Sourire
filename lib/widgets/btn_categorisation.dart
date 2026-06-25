import 'package:flutter/material.dart';
import 'package:sourire/main.dart'; 
import 'package:sourire/theme/tokens.dart';

class BtnCategorisation extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;
  final bool isSecondary; 
  final double? fontSize;
  final double? widthFactor; 

  const BtnCategorisation({
    required this.text,
    required this.onTap,
    this.isActive = true,
    this.isSecondary = false, 
    this.fontSize,
    this.widthFactor, 
    super.key, 
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double hauteurDynamique = (screenSize.height * 0.065).clamp(45.0, 65.0);
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
          couleurFond = isActive ? orange : orange.withOpacity(0.35); // Réduit pour un meilleur feedback inactif
          couleurBordure = Colors.transparent;
        } else {
          // Gère maintenant proprement l'opacité du bouton secondaire quand il est désactivé
          final Color orangeActuel = isActive ? orange : orange.withOpacity(0.35);
          couleurContenu = orangeActuel;
          couleurBordure = orangeActuel;
          couleurFond = isDarkMode ? Colors.transparent : white;
        }

        return GestureDetector(
          onTap: isActive ? onTap : null,
          child: Container(
            width: widthFactor != null ? screenSize.width * widthFactor! : double.infinity,
            height: hauteurDynamique,
            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04), 
            decoration: BoxDecoration(
              color: couleurFond,
              borderRadius: BorderRadius.circular(hauteurDynamique / 2), 
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
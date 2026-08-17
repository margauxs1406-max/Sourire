import 'package:flutter/material.dart';
import 'package:sourire/main.dart'; 
import 'package:sourire/theme/tokens.dart';

class BtnAction extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;
  final Color color; 
  final bool isNegative; 
  final double? fontSize; // Permet de rendre la taille du texte responsive

  const BtnAction({
    required this.text,
    required this.onTap,
    this.isActive = true,
    this.color = orange, 
    this.isNegative = false, 
    this.fontSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentThemeMode, child) {
        final bool isDarkMode = currentThemeMode == ThemeMode.system
    ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
    : (currentThemeMode == ThemeMode.dark);

        final Color couleurContenu = isNegative 
            ? (isDarkMode 
                ? Colors.white 
                : (isActive ? orange : orange.withValues(alpha: 0.5)))
            : Colors.white;

        final Color couleurFond = isNegative 
            ? (isDarkMode ? Colors.transparent : white) 
            : (isActive ? color : color.withValues(alpha: 0.5));

        final Color couleurBordure = isNegative
            ? (isDarkMode 
                ? darkSeparateur 
                : (isActive ? orange : orange.withValues(alpha: 0.5)))
            : (isActive ? orange : orange.withValues(alpha: 0.5));

        return GestureDetector(
          onTap: isActive ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              color: couleurFond,
              borderRadius: BorderRadius.circular(30),
              border: isNegative 
                  ? Border.all(color: couleurBordure, width: isDarkMode ? 1 : 2) 
                  : null,
            ),
            // CORRECTION : Suppression du padding vertical fixe pour obéir strictement à la hauteur du parent
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: couleurContenu,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize ?? 16, // Utilise la taille responsive ou 16 par défaut
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:sourire/main.dart'; 
import 'package:sourire/theme/tokens.dart';

class BtnCategorisationDynamique extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color themeColor; // Reçoit widget.theme.main (la couleur aléatoire)
  final bool isSecondary; 
  final bool isActive;
  final double? fontSize;

  const BtnCategorisationDynamique({
    required this.text,
    required this.onTap,
    required this.themeColor,
    this.isSecondary = false, 
    this.isActive = true,
    this.fontSize,
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

        // Si isActive est faux, on applique une opacité pour signifier le blocage
        final Color couleurActive = isActive ? themeColor : themeColor.withOpacity(0.35);

        if (!isSecondary) {
          couleurContenu = Colors.white;
          couleurFond = couleurActive;
          couleurBordure = Colors.transparent;
        } else {
          couleurContenu = couleurActive;
          couleurBordure = couleurActive;
          couleurFond = isDarkMode ? Colors.transparent : white;
        }

        return GestureDetector(
          // Si isActive est faux, on ignore complètement le clic
          onTap: isActive ? onTap : null,
          child: Container(
            width: double.infinity,
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
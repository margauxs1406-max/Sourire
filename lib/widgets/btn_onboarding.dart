import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class BtnOnboarding extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const BtnOnboarding({
    required this.text,
    required this.onTap,
    this.isActive = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Gestion du texte (Orange si actif, Orange à 50% d'opacité si inactif)
    final Color couleurContenu = isActive ? orange : orange.withOpacity(0.5);

    // 2. Gestion du fond (Toujours blanc)
    final Color couleurFond = white;

    // 3. Gestion de la bordure (Orange si actif, Orange à 50% d'opacité si inactif)
    final Color couleurBordure = isActive ? orange : orange.withOpacity(0.5);

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: couleurFond,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: couleurBordure, width: 2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: couleurContenu,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
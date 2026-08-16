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
    // Le CTA est plein orange sur le fond clair de l'onboarding : c'est lui
    // l'élément le plus fort de l'écran. À l'état inactif, c'est le fond qui
    // s'estompe, pas le texte — il reste ainsi lisible.
    //
    // Aucune bordure : elle se superposait au fond translucide de l'état
    // inactif et y dessinait un liseré plus foncé. Les boutons primaires de
    // la catégorisation n'en ont pas non plus — même alpha (0,35) qu'eux,
    // pour que les deux écrans se ressemblent.
    const Color couleurContenu = white;
    final Color couleurFond = isActive ? orange : orange.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: couleurFond,
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
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
import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class BtnProfil extends StatelessWidget {
  final VoidCallback onTap;

  const BtnProfil({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.transparent, // Ou white si tu veux un fond
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_outline, // L'icône de profil
          color: white,
          size: 30,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class BtnHistorique extends StatelessWidget {
  final VoidCallback onTap;

  const BtnHistorique({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Icon(
          Icons.notes_rounded, // Icône évoquant l'historique/les notes
          color: orange,
          size: 30,
        ),
      ),
    );
  }
}
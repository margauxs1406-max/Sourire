import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class BtnChevronDroite extends StatelessWidget {
  final VoidCallback onTap;
  const BtnChevronDroite({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(
        Icons.chevron_right_rounded,
        // Orange, comme tout ce qui se touche dans l'app. Le gris disait
        // « décoration » alors que ce chevron ouvre un écran.
        color: orange,
        size: 32,
      ),
    );
  }
}
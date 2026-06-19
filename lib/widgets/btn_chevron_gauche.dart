import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class BtnChevronGauche extends StatelessWidget {
  final VoidCallback onTap;
  const BtnChevronGauche({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(
        Icons.chevron_left_rounded,
        color: grey, // A6A6A6
        size: 32,
      ),
    );
  }
}
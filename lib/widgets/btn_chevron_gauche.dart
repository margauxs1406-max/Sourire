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
        // Orange, comme le chevron droit et comme tout ce qui se touche dans
        // l'app. En gris, il se lisait comme une décoration : on le voyait
        // sans comprendre qu'il ramenait en arrière.
        color: orange,
        size: 32,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

/// Chevron de repli du volet d'historique.
///
/// Orange, comme tout ce qui se touche dans l'application : en gris clair, il
/// se lisait comme une décoration de poignée alors qu'il referme le volet.
class BtnChevronBas extends StatelessWidget {
  final VoidCallback onTap;
  const BtnChevronBas({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: orange,
        size: 32,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class LogoSourire extends StatelessWidget {
  final Color color; // Permet de choisir entre blanc et orange

  const LogoSourire({
    this.color = white, // Blanc par défaut
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Sourire',
      style: styleLogo.copyWith(color: color),
    );
  }
}
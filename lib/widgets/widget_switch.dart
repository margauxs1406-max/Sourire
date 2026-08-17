import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class WidgetSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isNegative; // Garde la compatibilité avec ton style onboarding si besoin

  const WidgetSwitch({
    required this.value,
    required this.onChanged,
    this.isNegative = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Détermination des couleurs selon le thème choisi
    final Color trackColor = isNegative 
        ? white 
        : (value ? orange : orange.withValues(alpha: 0.3));

    final Color thumbColor = isNegative
        ? (value ? orange : const Color(0xFFFCE4D6))
        : white;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: thumbColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
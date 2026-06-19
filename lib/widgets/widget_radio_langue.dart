import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class WidgetRadioLangue extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const WidgetRadioLangue({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // Fond grisé comme tes champs
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: black,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Le cercle radio personnalisé
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: orange,
                  width: 2,
                ),
                color: isSelected ? orange : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
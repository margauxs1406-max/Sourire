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
    // Ce widget ne recevait pas d'indicateur de thème et restait gris clair à
    // texte noir, même en mode sombre. La luminosité du ThemeData suffit :
    // c'est `MyApp.themeNotifier` qui la pilote.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        // Plancher plutôt que hauteur figée, pour ne pas rogner le libellé
        // aux grands réglages d'accessibilité.
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Blanc et non le gris F5F5F5 : ce gris tirait au froid contre le
          // fond lightOrange de l'écran.
          color: isDark ? darkSurface : white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: styleCorps.copyWith(color: texteFort(isDark)),
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
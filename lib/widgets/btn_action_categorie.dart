import 'package:flutter/material.dart';

class BoutonActionCategorie extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool hasCircle;
  final bool isDarkMode;
  final bool useThemeStyleForText;
  final VoidCallback onTap;

  const BoutonActionCategorie({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.hasCircle,
    required this.isDarkMode,
    required this.useThemeStyleForText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final double adaptiveFontSize = (screenWidth * 0.045).clamp(14.0, 22.0);

    // Récupération sécurisée du style textuel par défaut ou global
    final TextStyle baseStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, 
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.transparent, 
              width: 0.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasCircle ? color : Colors.transparent,
                border: hasCircle 
                    ? null 
                    : Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: hasCircle ? Colors.white : color,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: useThemeStyleForText
                    ? TextStyle(
                        fontFamily: baseStyle.fontFamily,
                        fontSize: 14.0, // Suppression : taille fixe plus petite
                        fontWeight: FontWeight.normal, 
                        color: color, 
                      )
                    : baseStyle.copyWith(
                        fontSize: adaptiveFontSize, // Nouvelle catégorie : taille adaptative
                        color: isDarkMode ? Colors.white70 : Colors.grey[700], 
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
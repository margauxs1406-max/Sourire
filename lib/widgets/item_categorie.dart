import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/checkbox_sourire.dart';

class ItemCategorie extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final Color color;
  final bool isDarkMode;

  const ItemCategorie({
    required this.label,
    required this.isSelected,
    required this.onSelectionChanged,
    this.color = orange,
    this.isDarkMode = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Calcul de la taille de police adaptative (Base 16 sur écran standard de 375px)
    final double adaptiveFontSize = (screenWidth * 0.045).clamp(14.0, 22.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? darkBg : white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? darkSeparateur : lightGrey,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: screenWidth * 0.69,
            child: Text(
              label,
              style: styleCategorie.copyWith(
                fontSize: adaptiveFontSize, // <-- APPLICATION DE LA TAILLE RESPONSIVE
                color: isSelected 
                    ? color 
                    : (isDarkMode ? Colors.white70 : grey), 
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          CheckboxSourire(
            initialValue: isSelected,
            onChanged: onSelectionChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }
}
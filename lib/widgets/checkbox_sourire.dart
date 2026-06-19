import 'package:flutter/material.dart';
import 'package:sourire/main.dart';
import 'package:sourire/theme/tokens.dart';

class CheckboxSourire extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  final Color activeColor; 

  const CheckboxSourire({
    this.initialValue = false,
    required this.onChanged,
    this.activeColor = orange, 
    super.key,
  });

  @override
  State<CheckboxSourire> createState() => _CheckboxSourireState();
}

class _CheckboxSourireState extends State<CheckboxSourire> {
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    isChecked = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant CheckboxSourire oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        isChecked = widget.initialValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Calcul de la taille adaptative de la checkbox (Base 32 sur écran standard de 375px)
    final double adaptiveBoxSize = (screenWidth * 0.07).clamp(26.0, 42.0);
    // L'icône conserve un ratio proportionnel à la taille de sa boîte parente (Base 24 sur 32)
    final double adaptiveIconSize = (adaptiveBoxSize * 0.75);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentThemeMode, child) {
        final bool isDarkMode = currentThemeMode == ThemeMode.dark;

        return GestureDetector(
          onTap: () {
            setState(() {
              isChecked = !isChecked;
            });
            widget.onChanged(isChecked);
          },
          child: Container(
            width: adaptiveBoxSize,   // <-- LARGEUR RESPONSIVE
            height: adaptiveBoxSize,  // <-- HAUTEUR RESPONSIVE
            decoration: BoxDecoration(
              color: isChecked 
                  ? widget.activeColor 
                  : (isDarkMode ? darkBg : white), 
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.activeColor, 
                width: 2,
              ),
            ),
            child: isChecked
                ? Icon(
                    Icons.check_rounded,
                    color: white,
                    size: adaptiveIconSize, // <-- TAILLE DE L'ICÔNE RESPONSIVE
                  )
                : null,
          ),
        );
      },
    );
  }
}
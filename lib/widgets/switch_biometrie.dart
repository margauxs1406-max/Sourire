import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class SwitchBiometrie extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  final bool isNegative; // true pour fond orange (onboarding), false pour fond clair (profil)

  const SwitchBiometrie({
    this.initialValue = false,
    required this.onChanged,
    this.isNegative = false, // Par défaut, style normal pour le profil
    super.key,
  });

  @override
  State<SwitchBiometrie> createState() => _SwitchBiometrieState();
}

class _SwitchBiometrieState extends State<SwitchBiometrie> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    // Détermination des couleurs selon le thème choisi
    final Color trackColor = widget.isNegative 
        ? white 
        : (_isActive ? orange : orange.withValues(alpha: 0.3));

    final Color thumbColor = widget.isNegative
        ? (_isActive ? orange : const Color(0xFFFCE4D6))
        : white;

    return GestureDetector(
      onTap: () {
        setState(() => _isActive = !_isActive);
        widget.onChanged(_isActive);
      },
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
          alignment: _isActive ? Alignment.centerRight : Alignment.centerLeft,
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
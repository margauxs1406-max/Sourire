import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class SwitchPassword extends StatefulWidget {
  final bool isPasswordVisible;
  final ValueChanged<bool> onToggle;

  const SwitchPassword({
    this.isPasswordVisible = false,
    required this.onToggle,
    super.key,
  });

  @override
  State<SwitchPassword> createState() => _SwitchPasswordState();
}

class _SwitchPasswordState extends State<SwitchPassword> {
  late bool _isVisible;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.isPasswordVisible;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isVisible = !_isVisible);
        widget.onToggle(_isVisible);
      },
      child: Icon(
        // Alterne entre l'œil barré et l'œil ouvert de ton design
        _isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: orange,
        size: 28,
      ),
    );
  }
}
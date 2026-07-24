import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sourire/main.dart';
import 'package:sourire/theme/tokens.dart';

/// Bouton de l'écran de catégorisation note (couleur de thème dynamique).
///
/// Mêmes corrections anti double-tap que [BtnCategorisation] :
/// retour visuel immédiat à la pose du doigt, haptique, état [isLoading]
/// qui bloque tout nouveau tap.
class BtnCategorisationDynamique extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  /// Reçoit widget.theme.main (la couleur aléatoire du souvenir).
  final Color themeColor;

  final bool isSecondary;
  final bool isActive;

  /// Enregistrement en cours : affiche un indicateur et ignore les taps.
  final bool isLoading;

  /// Petite vibration à la pose du doigt.
  final bool enableHaptic;

  final double? fontSize;

  const BtnCategorisationDynamique({
    required this.text,
    required this.onTap,
    required this.themeColor,
    this.isSecondary = false,
    this.isActive = true,
    this.isLoading = false,
    this.enableHaptic = true,
    this.fontSize,
    super.key,
  });

  @override
  State<BtnCategorisationDynamique> createState() =>
      _BtnCategorisationDynamiqueState();
}

class _BtnCategorisationDynamiqueState
    extends State<BtnCategorisationDynamique> {
  bool _isPressed = false;

  bool get _isTappable => widget.isActive && !widget.isLoading;

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() => _isPressed = value);
  }

  @override
  void didUpdateWidget(covariant BtnCategorisationDynamique oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isTappable && _isPressed) {
      _isPressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double hauteurDynamique = (screenSize.height * 0.065).clamp(45.0, 65.0);
    final double tailleTexteDynamique =
        widget.fontSize ?? (screenSize.width * 0.04).clamp(14.0, 18.0);
    final double tailleIndicateur = (hauteurDynamique * 0.40).clamp(16.0, 24.0);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentThemeMode, child) {
        final bool isDarkMode = currentThemeMode == ThemeMode.system
            ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
            : (currentThemeMode == ThemeMode.dark);

        final bool estEnfonce = _isPressed && _isTappable;

        final double opaciteEtat = !_isTappable
            ? 0.35
            : estEnfonce
                ? 0.70
                : 1.0;

        final Color couleurActive = widget.themeColor.withOpacity(opaciteEtat);

        Color couleurContenu;
        Color couleurFond;
        Color couleurBordure;

        if (!widget.isSecondary) {
          couleurContenu = Colors.white;
          couleurFond = couleurActive;
          couleurBordure = Colors.transparent;
        } else {
          couleurContenu = couleurActive;
          couleurBordure = couleurActive;
          couleurFond = estEnfonce
              ? widget.themeColor.withOpacity(isDarkMode ? 0.16 : 0.10)
              : (isDarkMode ? Colors.transparent : white);
        }

        return Semantics(
          button: true,
          enabled: _isTappable,
          label: widget.text,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _isTappable
                ? (_) {
                    _setPressed(true);
                    if (widget.enableHaptic) {
                      HapticFeedback.selectionClick();
                    }
                  }
                : null,
            onTapUp: _isTappable ? (_) => _setPressed(false) : null,
            onTapCancel: _isTappable ? () => _setPressed(false) : null,
            onTap: _isTappable
                ? () {
                    _setPressed(false);
                    widget.onTap();
                  }
                : null,
            child: AnimatedScale(
              scale: estEnfonce ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                width: double.infinity,
                height: hauteurDynamique,
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
                decoration: BoxDecoration(
                  color: couleurFond,
                  borderRadius: BorderRadius.circular(hauteurDynamique / 2),
                  border: widget.isSecondary
                      ? Border.all(color: couleurBordure, width: 2)
                      : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: widget.isLoading
                        ? SizedBox(
                            key: const ValueKey<String>('__loader__'),
                            width: tailleIndicateur,
                            height: tailleIndicateur,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(couleurContenu),
                            ),
                          )
                        : Text(
                            widget.text,
                            key: ValueKey<String>(widget.text),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: couleurContenu,
                              fontWeight: FontWeight.bold,
                              fontSize: tailleTexteDynamique,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
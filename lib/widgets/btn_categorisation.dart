import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sourire/main.dart';
import 'package:sourire/theme/tokens.dart';

/// Bouton de l'écran de catégorisation photo.
///
/// Corrections anti double-tap (écrans 120 Hz) :
///  - retour visuel IMMÉDIAT à la pose du doigt (onTapDown) : le bouton se
///    rétracte et s'assombrit, sans attendre le moindre setState de l'écran
///    parent ni la fin de l'enregistrement en base ;
///  - retour haptique léger à l'appui ;
///  - état [isLoading] : le libellé est remplacé par un indicateur de
///    chargement et le bouton n'accepte plus aucun tap.
class BtnCategorisation extends StatefulWidget {
  final String text;
  final bool isActive;

  /// Enregistrement en cours : affiche un indicateur et ignore les taps.
  final bool isLoading;

  /// Petite vibration à la pose du doigt.
  final bool enableHaptic;

  final VoidCallback onTap;
  final bool isSecondary;
  final double? fontSize;
  final double? widthFactor;

  const BtnCategorisation({
    required this.text,
    required this.onTap,
    this.isActive = true,
    this.isLoading = false,
    this.enableHaptic = true,
    this.isSecondary = false,
    this.fontSize,
    this.widthFactor,
    super.key,
  });

  @override
  State<BtnCategorisation> createState() => _BtnCategorisationState();
}

class _BtnCategorisationState extends State<BtnCategorisation> {
  bool _isPressed = false;

  /// Le bouton n'est réellement cliquable que s'il est actif ET qu'aucun
  /// enregistrement n'est en cours.
  bool get _isTappable => widget.isActive && !widget.isLoading;

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() => _isPressed = value);
  }

  @override
  void didUpdateWidget(covariant BtnCategorisation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le bouton devient inactif alors que le doigt est encore posé,
    // on relâche l'état enfoncé pour ne pas le figer.
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

        // Opacité de l'orange selon l'état : normal / enfoncé / désactivé.
        final double opaciteEtat = !_isTappable
            ? 0.35
            : estEnfonce
                ? 0.70
                : 1.0;

        final Color orangeActuel = orange.withOpacity(opaciteEtat);

        Color couleurContenu;
        Color couleurFond;
        Color couleurBordure;

        if (!widget.isSecondary) {
          couleurContenu = Colors.white;
          couleurFond = orangeActuel;
          couleurBordure = Colors.transparent;
        } else {
          couleurContenu = orangeActuel;
          couleurBordure = orangeActuel;
          // Le secondaire n'a pas de fond plein : on matérialise l'appui par
          // un léger voile orangé, sinon rien ne bougerait à l'écran.
          couleurFond = estEnfonce
              ? orange.withOpacity(isDarkMode ? 0.16 : 0.10)
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
                width: widget.widthFactor != null
                    ? screenSize.width * widget.widthFactor!
                    : double.infinity,
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
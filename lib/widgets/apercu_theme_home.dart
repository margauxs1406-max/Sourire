import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/theme/tokens.dart';

/// Reconstitution miniature de l'écran d'accueil sous un thème donné.
///
/// Remplace les vignettes PNG, qui posaient trois problèmes : une image par
/// thème à dessiner et à maintenir, un rendu qui dérivait dès qu'on retouchait
/// la home, et rien qui suive le mode sombre. Ici il n'y a plus d'image à
/// tenir à jour — la miniature EST la home, dessinée à petite échelle avec les
/// mêmes données.
///
/// Trois écarts volontaires avec la vraie home :
/// - pas de bandeau supérieur : il est identique d'un thème à l'autre et ne
///   dit donc rien sur le thème ;
/// - pas de prénom : la vignette est vue avant l'inscription dans certains
///   parcours, et un prénom manquant laisserait un trou ;
/// - la question est en écriture inclusive, indépendamment du réglage
///   d'accord du compte, puisqu'elle ne s'adresse ici à personne en
///   particulier.
class ApercuThemeHome extends StatelessWidget {
  final ThemeApp theme;
  final bool sombre;

  const ApercuThemeHome({
    required this.theme,
    required this.sombre,
    super.key,
  });

  /// Dimensions de référence de la home, les mêmes que celles sur lesquelles
  /// sont calés les ratios de position des icônes de fond.
  static const double _largeurBase = 393.0;
  static const double _hauteurBase = 852.0;

  /// Corps de la question, et hauteur d'une de ses lignes.
  static const double _tailleQuestion = _largeurBase * 0.07;
  static const double _hauteurLigne = _tailleQuestion * facteurLora * 1.2;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations mots = AppLocalizations.of(context)!;

    // La home entière est dessinée à sa taille réelle, puis réduite d'un bloc.
    // Tout ce qui suit peut donc raisonner en pixels de la vraie home, sans
    // aucun facteur d'échelle à traîner — c'est le FittedBox qui s'en charge.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _largeurBase,
          height: _hauteurBase,
          child: ColoredBox(
            color: sombre ? darkBg : lightOrange,
            child: Stack(
              children: [
                // 1. LE DÉCOR DU THÈME.
                ...theme.homeIcons.map((config) {
                  final Widget icone = SvgPicture.asset(
                    config.assetPath,
                    width: config.getWidth(_largeurBase),
                    height: config.getHeight(_hauteurBase),
                    colorFilter: ColorFilter.mode(
                      (theme.homeIconColor ?? orange)
                          .withValues(alpha: theme.homeIconOpacity),
                      BlendMode.srcIn,
                    ),
                  );

                  return Positioned(
                    left: config.getX(_largeurBase),
                    top: config.getY(_hauteurBase),
                    child: config.rotation == 0.0
                        ? icone
                        : Transform.rotate(
                            angle: config.rotation * math.pi / 180,
                            child: icone,
                          ),
                  );
                }),

                // 2. LA QUESTION D'ACCUEIL.
                //
                // Descendue de trois lignes par rapport à la home : celle-ci
                // affiche d'abord « Bonjour Margaux », que la miniature n'a
                // pas. Sans ce décalage, la question occuperait la place du
                // salut et le haut de la vignette paraîtrait déséquilibré.
                Positioned(
                  top: _hauteurBase * 0.15 + _hauteurLigne * 3,
                  left: _largeurBase * 0.1,
                  right: _largeurBase * 0.1,
                  child: Text(
                    mots.themePreviewQuestion,
                    style: styleTitreLora.copyWith(
                      color: texteTitre(sombre),
                      fontSize: tailleLora(_tailleQuestion),
                      height: 1.2,
                    ),
                  ),
                ),

                // 3. LE BOCAL, posé où il l'est sur la home.
                Positioned(
                  bottom: _hauteurBase * 0.24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      height: _hauteurBase * 0.35,
                      width: _hauteurBase * 0.35 * 0.85,
                      child: Image.asset(
                        'assets/bocal_verre.png',
                        fit: BoxFit.contain,
                        color: sombre
                            ? const Color(0xBFFFFFFF)
                            : const Color(0xB81E1408),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

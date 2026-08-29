import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/services/badges_service.dart';
import 'package:sourire/theme/user_prefs.dart';

class ScreenMesBadges extends StatelessWidget {
  final bool isDarkMode;

  const ScreenMesBadges({super.key, required this.isDarkMode});

  void _ouvrirBadgeAgrandi(BuildContext context, int palier) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        final texte = texteBadgePourPalier(palier, l10n);
        final String badgeAsset = badgeAssetPourPalier(palier) ?? badgeAssetParPalier[5000]!;
        final double screenWidth = MediaQuery.of(dialogContext).size.width;
        final double dialogWidth = (screenWidth * 0.82).clamp(260.0, 420.0);

        final Color couleurFond = isDarkMode ? const Color(0xFF1E1E1E) : white;
        final Color couleurTitre = isDarkMode ? white : black;
        final Color couleurTexte = isDarkMode ? Colors.white70 : grey;

        // Pas de bouton "Continuer" : on ferme en touchant n'importe où.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: dialogWidth,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: dialogWidth * 0.08,
                  vertical: dialogWidth * 0.09,
                ),
                decoration: BoxDecoration(
                  color: couleurFond,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      badgeAsset,
                      width: dialogWidth * 0.25,
                      height: dialogWidth * 0.25,
                    ),
                    SizedBox(height: dialogWidth * 0.08),
                    Text(
                      texte.name,
                      textAlign: TextAlign.center,
                      style: styleTitreRecit.copyWith(
                        color: couleurTitre,
                        // Une serif a besoin de plus de corps : on monte le coefficient
                        // avant de repasser par tailleLora.
                        fontSize: tailleLora((dialogWidth * 0.085).clamp(20.0, 28.0)),
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: dialogWidth * 0.04),
                    Text(
                      texte.phrase,
                      textAlign: TextAlign.center,
                      style: styleSecondaire.copyWith(
                        color: couleurTexte,
                        fontSize: (dialogWidth * 0.05).clamp(14.0, 18.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isDarkMode ? darkBg : lightOrange;
    final Color textColor = isDarkMode ? white : black;
    final Color headerBgColor = isDarkMode ? darkSurface : lightOrange;

    final double titleFontSize = tailleAdaptee(context, 18);

    final List<int> paliersOrdonnes = badgeAssetParPalier.keys.toList()..sort();

    // On se base sur le plus haut palier JAMAIS atteint (persistant, ne fait
    // qu'augmenter) plutôt que sur le total ACTUEL de souvenirs — sinon,
    // supprimer des souvenirs après coup ferait "reverrouiller" à tort un
    // badge pourtant déjà mérité.
    final int dernierPalierAtteint = UserPrefs.dernierPalierCelebre;

    // Quatre colonnes sur téléphone. Sur tablette, garder quatre colonnes
    // donnerait quatre badges gigantesques : on en met davantage pour que
    // chaque vignette conserve à peu près sa taille de lecture.
    final int colonnesBadges = estTablette(context) ? 6 : 4;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER FIXE — identique à ScreenChoixThemes
            Container(
              color: headerBgColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    child: BtnChevronGauche(
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const LogoSourire(color: orange),
                ],
              ),
            ),

            // CONTENU SCROLLABLE
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 30, right: 30, top: 20, bottom: 30),
                // Un peu plus large que la colonne de lecture courante : une
                // grille de vignettes supporte mieux l'étalement qu'un texte.
                child: ContenuCentre(
                  largeurMax: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.myBadgesTitle,
                        style: styleSection.copyWith(
                          fontSize: titleFontSize,
                          color: textColor,
                        ),
                      ),

                      const SizedBox(height: 25),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: paliersOrdonnes.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: colonnesBadges,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final int palier = paliersOrdonnes[index];
                          final bool debloque = palier <= dernierPalierAtteint;
                          final String assetPath = badgeAssetParPalier[palier]!;

                          return GestureDetector(
                            onTap: debloque ? () => _ouvrirBadgeAgrandi(context, palier) : null,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double taille = constraints.maxWidth;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: debloque ? white : orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: debloque
                                        ? Padding(
                                            padding: EdgeInsets.all(taille * 0.15),
                                            child: SvgPicture.asset(assetPath),
                                          )
                                        : Icon(
                                            Icons.star,
                                            color: Colors.white.withValues(alpha: 0.5),
                                            size: taille * 0.45,
                                          ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
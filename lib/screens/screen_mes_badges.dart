import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/services/badges_service.dart';
import 'package:sourire/models/note_model.dart';

class ScreenMesBadges extends StatelessWidget {
  final bool isDarkMode;

  const ScreenMesBadges({super.key, required this.isDarkMode});

  void _ouvrirBadgeAgrandi(BuildContext context, int palier) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
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
                      color: Colors.black.withOpacity(0.25),
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
                      style: TextStyle(
                        color: couleurTitre,
                        fontWeight: FontWeight.bold,
                        fontSize: (dialogWidth * 0.075).clamp(18.0, 26.0),
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: dialogWidth * 0.04),
                    Text(
                      texte.phrase,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: couleurTexte,
                        fontSize: (dialogWidth * 0.05).clamp(14.0, 18.0),
                        height: 1.4,
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
    final Color bgColor = isDarkMode ? darkBg : white;
    final Color textColor = isDarkMode ? white : black;
    final Color headerBgColor = isDarkMode ? darkSurface : white;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = (screenWidth * 18) / 390;

    final List<int> paliersOrdonnes = badgeAssetParPalier.keys.toList()..sort();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.myBadgesTitle,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    // --- OUTIL DE TEST : force l'affichage de tous les
                    // badges comme débloqués, sans créer réellement des
                    // milliers de souvenirs. Visible uniquement pendant
                    // la phase de test (voir `phaseDeTestActive` dans
                    // tokens.dart) — à retirer ou masquer ensuite.
                    if (phaseDeTestActive) ...[
                      const SizedBox(height: 14),
                      ValueListenableBuilder<bool>(
                        valueListenable: debloquerTousBadgesTestNotifier,
                        builder: (context, forceTout, _) {
                          return GestureDetector(
                            onTap: () {
                              debloquerTousBadgesTestNotifier.value = !forceTout;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: (forceTout ? orange : Colors.grey).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: forceTout ? orange : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.science_outlined,
                                    size: 16,
                                    color: forceTout ? orange : (isDarkMode ? lightGrey : grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    forceTout
                                        ? 'Test : tous les badges débloqués !'
                                        : 'Test : débloquer tous les badges',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: forceTout ? orange : (isDarkMode ? lightGrey : grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 25),
                    ValueListenableBuilder<bool>(
                      valueListenable: debloquerTousBadgesTestNotifier,
                      builder: (context, forceTout, _) {
                        return StreamBuilder<List<NoteSourire>>(
                          stream: DatabaseService().getNotesStream(),
                          builder: (context, snapshot) {
                            final int total = snapshot.data?.length ?? 0;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: paliersOrdonnes.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                              itemBuilder: (context, index) {
                                final int palier = paliersOrdonnes[index];
                                final bool debloque = forceTout || total >= palier;
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
                                                  color: Colors.white.withOpacity(0.5),
                                                  size: taille * 0.45,
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
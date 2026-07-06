import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/confetti_explosion.dart';
import 'package:sourire/services/badges_service.dart';
import 'package:sourire/l10n/app_localizations.dart';

/// Affiche la pop-up de félicitations pour le palier atteint, avec le
/// badge SVG correspondant et son nom mis en gras dans le texte.
Future<void> afficherPopupPalier(
  BuildContext context,
  int palier, {
  required bool isDark,
}) async {
  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (context) => PopupPalier(palier: palier, isDark: isDark),
  );
}

class PopupPalier extends StatelessWidget {
  final int palier;
  final bool isDark;

  const PopupPalier({required this.palier, required this.isDark, super.key});

  /// Renvoie (nom du badge, phrase inspirante) pour ce palier, via les
  /// clés l10n générées. Si jamais un palier sans badge défini arrivait
  /// ici (ne devrait pas se produire), on retombe sur le badge 5000.
  ({String name, String phrase}) _texteBadge(AppLocalizations l10n) {
    switch (palier) {
      case 10:
        return (name: l10n.badge10Name, phrase: l10n.badge10Phrase);
      case 50:
        return (name: l10n.badge50Name, phrase: l10n.badge50Phrase);
      case 100:
        return (name: l10n.badge100Name, phrase: l10n.badge100Phrase);
      case 200:
        return (name: l10n.badge200Name, phrase: l10n.badge200Phrase);
      case 500:
        return (name: l10n.badge500Name, phrase: l10n.badge500Phrase);
      case 1000:
        return (name: l10n.badge1000Name, phrase: l10n.badge1000Phrase);
      case 1500:
        return (name: l10n.badge1500Name, phrase: l10n.badge1500Phrase);
      case 2000:
        return (name: l10n.badge2000Name, phrase: l10n.badge2000Phrase);
      case 2500:
        return (name: l10n.badge2500Name, phrase: l10n.badge2500Phrase);
      case 3000:
        return (name: l10n.badge3000Name, phrase: l10n.badge3000Phrase);
      case 3500:
        return (name: l10n.badge3500Name, phrase: l10n.badge3500Phrase);
      case 4000:
        return (name: l10n.badge4000Name, phrase: l10n.badge4000Phrase);
      case 4500:
        return (name: l10n.badge4500Name, phrase: l10n.badge4500Phrase);
      case 5000:
      default:
        return (name: l10n.badge5000Name, phrase: l10n.badge5000Phrase);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = (screenWidth * 0.82).clamp(260.0, 420.0);
    final l10n = AppLocalizations.of(context)!;
    final texte = _texteBadge(l10n);
    final String badgeAsset = badgeAssetPourPalier(palier) ?? badgeAssetParPalier[5000]!;

    final Color couleurFond = isDark ? const Color(0xFF1E1E1E) : white;
    final Color couleurTitre = isDark ? white : black;
    final Color couleurTexte = isDark ? Colors.white70 : grey;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: dialogWidth,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // 1. COUCHE ARRIÈRE : Confettis en arrière-plan (derrière la pop-up)
            Positioned.fill(
              child: ConfettiExplosion(
                particleCount: 60,
                yOffset: 0.28, // 💡 Jaillit du SVG
              ),
            ),

            // 2. LE CONTENEUR DE LA POP-UP
            Container(
              margin: const EdgeInsets.only(top: 20),
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
                  // Le nom du badge : grand, gras, centré.
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
                  // Phrase inspirante seule, sans répéter le nom du badge.
                  Text(
                    texte.phrase,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: couleurTexte,
                      fontSize: (dialogWidth * 0.05).clamp(14.0, 18.0),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: dialogWidth * 0.08),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        padding: EdgeInsets.symmetric(vertical: dialogWidth * 0.045),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.btnContinuerPalier,
                        style: const TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. COUCHE AVANT : Confettis en avant-plan (devant la pop-up)
            Positioned.fill(
              child: ConfettiExplosion(
                particleCount: 70,
                yOffset: 0.28, // 💡 Jaillit du SVG
              ),
            ),
          ],
        ),
      ),
    );
  }
}
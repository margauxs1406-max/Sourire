import 'package:sourire/l10n/app_localizations.dart';

/// Association palier -> chemin de l'asset SVG du badge correspondant.
const Map<int, String> badgeAssetParPalier = {
  10: 'assets/badges/chercheur_etoiles.svg',
  50: 'assets/badges/cueilleur_beaute.svg',
  100: 'assets/badges/gardien_instants.svg',
  200: 'assets/badges/conteur_souvenirs.svg',
  500: 'assets/badges/emanateur_joie.svg',
  1000: 'assets/badges/alchimiste_bonheur.svg',
  1500: 'assets/badges/fee_lumiere.svg',
  2000: 'assets/badges/archiviste_coeur.svg',
  2500: 'assets/badges/orfevre_emotions.svg',
  3000: 'assets/badges/horloger_instants.svg',
  3500: 'assets/badges/veilleur_lumiere.svg',
  4000: 'assets/badges/gardien_eternite.svg',
  4500: 'assets/badges/mage_souvenirs.svg',
  5000: 'assets/badges/legende_sourire.svg',
};

/// Renvoie le chemin du badge pour un palier donné, ou `null` si ce
/// palier n'a pas de badge défini.
String? badgeAssetPourPalier(int palier) => badgeAssetParPalier[palier];

/// Renvoie (nom du badge, phrase inspirante) pour un palier donné, via
/// les clés l10n générées. Fonction partagée entre popup_palier.dart et
/// screen_mes_badges.dart pour éviter la duplication.
({String name, String phrase}) texteBadgePourPalier(int palier, AppLocalizations l10n) {
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
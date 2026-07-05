/// Association palier -> chemin de l'asset SVG du badge correspondant.
/// Vérifie que ces noms de fichiers correspondent exactement à ceux
/// présents dans ton dossier assets/badges/ (accents, underscores...).
const Map<int, String> badgeAssetParPalier = {
  10: 'assets/badges/chercheur_etoiles.svg',
  50: 'assets/badges/cueilleur_aurore.svg',
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
/// palier n'a pas de badge défini (ne devrait jamais arriver puisque
/// aucun palier au-delà de 5000 n'est généré par milestones_service.dart).
String? badgeAssetPourPalier(int palier) => badgeAssetParPalier[palier];
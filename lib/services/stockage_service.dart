import 'dart:io';

import 'package:flutter/foundation.dart';

import '../services/database_service.dart';
import '../services/photo_service.dart';

/// Place réellement occupée par le bocal sur le téléphone.
///
/// Les tailles étaient auparavant SIMULÉES : 1,4 Mo forfaitaire par photo et
/// 1,2 Ko par note. Depuis que les photos sont réduites à l'import, elles
/// pèsent trois à cinq fois moins, et le profil annonçait donc un poids sans
/// rapport avec la réalité. On mesure maintenant les vrais fichiers.
class StockageService {
  static Future<Map<String, String>> calculerEspaceOccupe() async {
    try {
      final toutesLesNotes = await DatabaseService().getAllNotesAsync();

      int octetsPhotos = 0;
      int octetsNotes = 0;

      for (final souvenir in toutesLesNotes) {
        final String? chemin = souvenir.photoPath?.trim();
        if (chemin != null && chemin.isNotEmpty) {
          // Le fichier peut manquer : photo effacée à la main, restauration
          // partielle. On compte alors zéro plutôt que d'inventer un poids.
          final File? fichier = await PhotoService.fichierPhoto(chemin);
          if (fichier != null) octetsPhotos += await fichier.length();
        }

        final String? texte = souvenir.text;
        if (texte != null && texte.isNotEmpty) {
          // Le texte vit dans la base, pas dans un fichier : on compte ses
          // octets UTF-8, plus une marge forfaitaire pour la ligne SQLite qui
          // le porte (date, couleur, catégories, index).
          octetsNotes += texte.runes.fold<int>(
                0,
                (int total, int rune) => total + (rune < 0x80 ? 1 : 2),
              ) +
              120;
        }
      }

      return {
        'photos': _formaterTaille(octetsPhotos),
        'notes': _formaterTaille(octetsNotes),
      };
    } catch (e) {
      debugPrint("Erreur lors du calcul de l'espace occupé : $e");
      return {'photos': '0 Ko', 'notes': '0 Ko'};
    }
  }

  static String _formaterTaille(int octets) {
    if (octets <= 0) return "0 Ko";
    if (octets < 1024 * 1024) {
      return "${(octets / 1024).toStringAsFixed(1)} Ko";
    }
    return "${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo";
  }
}

import 'package:flutter/foundation.dart';

import 'package:sourire/services/database_service.dart';
import 'package:sourire/services/photo_service.dart';
import 'package:sourire/theme/user_prefs.dart';

/// Efface le bocal, en entier et pour de bon.
///
/// Deux chemins y mènent, et ils doivent faire exactement la même chose :
/// le bouton « effacer tous mes souvenirs » du profil, et la réinitialisation
/// de mot de passe sur un appareil sans biométrie, où effacer est la seule
/// façon honnête de rendre l'accès sans laisser n'importe qui entrer.
///
/// Rien n'est récupérable ensuite. C'est à l'appelant de demander
/// confirmation, deux fois plutôt qu'une.
class EffacementService {
  EffacementService._();

  /// Supprime les souvenirs, les catégories personnalisées, les fichiers
  /// photo, et remet à zéro tout ce qui décrivait le contenu du bocal.
  ///
  /// Ce qui SURVIT volontairement : le prénom, la langue, le thème et les
  /// réglages de rappel. L'utilisateur vide son bocal, il ne redevient pas
  /// un inconnu.
  static Future<void> toutEffacer() async {
    try {
      await DatabaseService().viderLeBocal();
      await PhotoService.supprimerToutesLesPhotos();
      await UserPrefs.reinitialiserApresEffacement();
      debugPrint("--- EFFACEMENT : bocal vidé, photos supprimées ---");
    } catch (e) {
      debugPrint("Échec de l'effacement : $e");
      rethrow;
    }
  }
}

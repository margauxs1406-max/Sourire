import 'package:flutter/material.dart';
import '../models/theme_app.dart';
import '../theme/user_prefs.dart'; // <-- Ne pas oublier l'import de tes UserPrefs

class ThemeService {
  /// Thème du DÉCOR : le fond de la home. Réglé dans Profil >
  /// Personnalisation.
  static final ValueNotifier<ThemeApp> themeVisuelNotifier = ValueNotifier<ThemeApp>(
    ThemeRepository.themeClassique
  );

  /// Thème des NOTES, choisi à la baguette au moment d'écrire.
  ///
  /// Distinct du précédent depuis que la baguette existe : le thème d'une note
  /// est une décision prise note par note, celui de la home une ambiance qu'on
  /// installe une fois. Les deux restent débloqués par le même achat premium.
  static final ValueNotifier<ThemeApp> themeNoteNotifier = ValueNotifier<ThemeApp>(
    ThemeRepository.themeClassique
  );

  /// Anciens identifiants de thèmes, et ce qu'ils sont devenus.
  ///
  /// L'identifiant d'un thème n'est pas qu'une clé de code : il est écrit dans
  /// les préférences ET sur chaque souvenir en base (`themeLabel`). Le
  /// renommer sans rattrapage ferait basculer au thème classique toutes les
  /// notes déjà écrites sous l'ancien nom.
  static const Map<String, String> _anciensIdentifiants = <String, String>{
    'floral': 'nature',
  };

  /// Retrouve un thème par son identifiant, ou le thème classique.
  ///
  /// POINT DE PASSAGE UNIQUE. Le souvenir de l'historique, le souvenir tiré au
  /// sort et l'image de partage refaisaient chacun leur propre `firstWhere` :
  /// trois copies de la même recherche, qu'un renommage d'identifiant laissait
  /// derrière lui. Elles passent toutes par ici.
  static ThemeApp parId(String id) {
    final String cle = id.toLowerCase();
    final String identifiant = _anciensIdentifiants[cle] ?? cle;
    return ThemeRepository.tousLesThemes.firstWhere(
      (t) => t.id.toLowerCase() == identifiant,
      orElse: () => ThemeRepository.themeClassique,
    );
  }

  /// Statut Premium, en lecture seule.
  ///
  /// Le setter a disparu avec le faux achat : le Premium n'est plus une case
  /// qu'on coche depuis l'interface, c'est une échéance que seule la boutique
  /// repousse. Voir UserPrefs.confirmerPremium et AchatService.
  static bool get estUtilisateurPremium => UserPrefs.isPremium;

  /// À APPELER DANS LE MAIN.DART JUSTE APRÈS UserPrefs.init()
  /// Permet de charger le thème sauvegardé au démarrage de l'application
  static void chargerThemeSauvegarde() {
    themeVisuelNotifier.value = parId(UserPrefs.themeId);
    themeNoteNotifier.value = parId(UserPrefs.themeNoteId);
  }

  /// Mémorise le thème choisi à la baguette comme défaut des prochaines notes.
  ///
  /// Ne touche PAS au thème de la home : c'est tout l'intérêt de la séparation.
  static bool changerThemeNote(ThemeApp nouveauTheme) {
    if (nouveauTheme.isPremium && !estUtilisateurPremium) return false;
    UserPrefs.themeNoteId = nouveauTheme.id;
    themeNoteNotifier.value = nouveauTheme;
    return true;
  }

  /// Tente de changer le thème visuel de l'application
  static bool changerThemeVisuel(ThemeApp nouveauTheme) {
    // Sécurité : Si le thème est premium et l'utilisateur ne l'est pas, on bloque
    if (nouveauTheme.isPremium && !estUtilisateurPremium) {
      return false; 
    }

    // 1. SAUVEGARDE PERSISTANTE : On enregistre l'ID dans SharedPreferences
    UserPrefs.themeId = nouveauTheme.id;

    // 2. MISE À JOUR DE L'ÉTAT : L'UI réagit immédiatement
    themeVisuelNotifier.value = nouveauTheme;
    return true; 
  }


}

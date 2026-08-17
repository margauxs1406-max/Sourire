import 'package:flutter/material.dart';
import '../models/theme_app.dart';
import '../theme/user_prefs.dart'; // <-- Ne pas oublier l'import de tes UserPrefs

class ThemeService {
  // Le ValueNotifier initialisé par défaut
  static final ValueNotifier<ThemeApp> themeVisuelNotifier = ValueNotifier<ThemeApp>(
    ThemeRepository.themeClassique
  );

  // Synchronise le statut Premium avec les UserPrefs
  static bool get estUtilisateurPremium => UserPrefs.isPremium;
  static set estUtilisateurPremium(bool value) => UserPrefs.isPremium = value;

  /// À APPELER DANS LE MAIN.DART JUSTE APRÈS UserPrefs.init()
  /// Permet de charger le thème sauvegardé au démarrage de l'application
  static void chargerThemeSauvegarde() {
    final String idSauvegarde = UserPrefs.themeId;
    
    // On cherche le thème correspondant dans ton Repository
    // (Adapte 'ThemeRepository.tousLesThemes' selon le nom de ta liste de thèmes)
    final themeAssocie = ThemeRepository.tousLesThemes.firstWhere(
      (t) => t.id == idSauvegarde,
      orElse: () => ThemeRepository.themeClassique,
    );

    themeVisuelNotifier.value = themeAssocie;
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

  /// Déverrouille les thèmes (appelé après un achat réussi).
  ///
  /// Ne force plus de rebuild global : l'ancienne version appelait
  /// `themeVisuelNotifier.notifyListeners()` depuis l'extérieur, une API que
  /// Flutter marque comme protégée. C'était inutile — les deux appelants
  /// (l'écran des thèmes et la modale d'achat de la Home) rafraîchissent
  /// déjà ce qu'ils affichent, et le statut premium est relu à la demande
  /// partout ailleurs.
  static void deverrouillerPremium() {
    estUtilisateurPremium = true;
  }
}
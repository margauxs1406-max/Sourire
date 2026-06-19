import 'package:flutter/material.dart';
import '../models/theme_app.dart';

class ThemeService {
  // Le ValueNotifier qui stocke le thème visuel actuel (par défaut au démarrage)
  static final ValueNotifier<ThemeApp> themeVisuelNotifier = ValueNotifier<ThemeApp>(
    ThemeRepository.themeClassique
  );

  // Simulation du statut Premium (À connecter plus tard avec vos achats In-App)
  static bool estUtilisateurPremium = false;

  /// Tente de changer le thème visuel de l'application
  static bool changerThemeVisuel(ThemeApp nouveauTheme) {
    // Sécurité : Si le thème est premium et l'utilisateur ne l'est pas, on bloque
    if (nouveauTheme.isPremium && !estUtilisateurPremium) {
      return false; // Échec du changement (permettra d'ouvrir la pop-up d'achat dans l'UI)
    }

    // Mise à jour de l'état : tous les écrans qui écoutent vont se synchroniser
    themeVisuelNotifier.value = nouveauTheme;
    return true; // Succès
  }

  /// Déverrouille les thèmes (Appelé après un achat réussi)
  static void deverrouillerPremium() {
    estUtilisateurPremium = true;
    // On force une notification au cas où l'écran de sélection doit enlever les cadenas
    themeVisuelNotifier.notifyListeners(); 
  }
}
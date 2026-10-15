import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/l10n/app_localizations_en.dart';
import 'package:sourire/l10n/app_localizations_es.dart';
import 'package:sourire/l10n/app_localizations_fr.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/theme/user_prefs.dart';

/// Dépôt des cinq souvenirs d'amorçage du bocal, dans la langue de
/// l'utilisateur.
///
/// Ce code vivait dans `main()`, avant `runApp`. Il y était au mauvais
/// endroit : les cinq textes sont TRADUITS, et au tout premier lancement la
/// langue n'est pas encore connue — l'utilisateur la choisit à la première
/// page de l'onboarding, donc après. `UserPrefs.langue` renvoyait alors son
/// défaut, "fr", et les cinq souvenirs partaient en français même pour
/// quelqu'un qui venait de choisir l'anglais ou l'espagnol.
///
/// Le dépôt est donc sorti de `main()` pour être appelé à deux moments, et
/// deux seulement :
///
///  * à la toute fin de l'onboarding, quand la langue est choisie (cas du
///    nouvel arrivant) ;
///  * dans `main()` pour les installations déjà existantes, qui ne reverront
///    jamais l'onboarding (cas de la mise à jour).
///
/// L'appel est idempotent : il ne fait rien si l'amorçage a déjà eu lieu, et
/// `DatabaseService.amorcerBocal` renonce de son côté dès que le bocal
/// contient le moindre souvenir.
class AmorcageService {
  AmorcageService._();

  /// Les cinq textes d'amorçage, dans la langue enregistrée.
  ///
  /// Les classes `AppLocalizationsXx` sont instanciées à la main parce qu'on
  /// n'a pas forcément de `BuildContext` sous la main ici, donc pas de
  /// `AppLocalizations.of(context)`.
  static AppLocalizations _textes() => switch (UserPrefs.langue) {
        'en' => AppLocalizationsEn(),
        'es' => AppLocalizationsEs(),
        _ => AppLocalizationsFr(),
      };

  /// Dépose les cinq souvenirs d'amorçage si ça n'a pas déjà été fait.
  ///
  /// À appeler AVANT d'ouvrir la home : `amorcerBocal` rafraîchit le cache du
  /// `DatabaseService` avant de rendre la main, donc l'écran d'accueil trouve
  /// les cinq souvenirs déjà en place et n'a pas à les voir apparaître.
  static Future<void> deposerSiNecessaire() async {
    if (UserPrefs.amorcageEffectue) return;

    final AppLocalizations textes = _textes();

    await DatabaseService().amorcerBocal(
      <String>[
        textes.amorceVoyage,
        textes.amorceFouRire,
        textes.amorceCadeau,
        textes.amorceToi,
        textes.amorceFierte,
      ],
      // Les souvenirs d'amorçage sont des notes : ils portent le thème des
      // NOTES, pas celui du décor de la home.
      UserPrefs.themeNoteId,
    );

    UserPrefs.amorcageEffectue = true;
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/l10n/app_localizations_en.dart';
import 'package:sourire/l10n/app_localizations_es.dart';
import 'package:sourire/l10n/app_localizations_fr.dart';
import 'package:sourire/l10n/langues.dart';
import 'package:sourire/screens/home.dart';
import 'package:sourire/screens/screen_boot.dart'; 
import 'package:sourire/screens/screen_lock.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/services/notifications_service.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/services/timezone_service.dart';
import 'package:sourire/theme/theme_service.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/services/photo_service.dart';
import 'package:sourire/widgets/bocal_preloader.dart';

// Variables globales
NoteSourire? souvenirEnAttenteGlobal;
final ValueNotifier<int?> idSouvenirEnCacheGlobal = ValueNotifier<int?>(null);
bool bocalVideEnCacheGlobal = false; 

// On démarre verrouillé par défaut pour laisser le ScreenBoot décider
final ValueNotifier<bool> isAppLockedNotifier = ValueNotifier<bool>(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En release, on coupe toute sortie console. Contrairement à une idée
  // répandue, ni print() ni debugPrint() ne sont supprimés par le compilateur :
  // sans ça, les logs de l'app partent dans logcat sur le téléphone des
  // utilisateurs, y compris ceux qui contiennent des noms de catégories
  // qu'ils ont eux-mêmes saisis.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await UserPrefs.init();

  // Le rappel de gratitude devient réglable (fréquence, jour, heure). Bascule
  // unique de tout le monde sur le nouveau défaut : hebdomadaire, dimanche 20h.
  await UserPrefs.appliquerNouveauDefautGratitude();

  // « Tous les 2 jours » est retiré, et le jour unique devient une liste de
  // jours cochés. Bascule unique, sans effet ensuite.
  await UserPrefs.migrerVersJoursMultiples();

  // Cinq souvenirs d'amorçage au tout premier lancement : le bocal n'est pas
  // vide, on peut tirer immédiatement, et ce sont autant d'invitations à
  // écrire. Sans effet si le bocal contient déjà quelque chose.
  if (!UserPrefs.amorcageEffectue) {
    // Traductions choisies à la main : on est avant `runApp`, donc sans
    // contexte ni `AppLocalizations.of`.
    final AppLocalizations textes = switch (UserPrefs.langue) {
      'en' => AppLocalizationsEn(),
      'es' => AppLocalizationsEs(),
      _ => AppLocalizationsFr(),
    };

    await DatabaseService().amorcerBocal(
      [
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

  // Fuseau horaire de l'APPAREIL, lu via la couche native (identifiant IANA).
  // Doit être fait avant NotificationService.init(), qui planifie des rappels
  // en tz.TZDateTime : sans ça, tous les utilisateurs hors du fuseau codé en
  // dur recevaient leurs rappels décalés.
  await TimezoneService.initialiser();

  ThemeService.chargerThemeSauvegarde();

  if (!UserPrefs.biomatrieActive && UserPrefs.password.isEmpty) {
    isAppLockedNotifier.value = false;
  }
  
  // Deux thèmes à restaurer, et non plus un : le décor de la home et celui
  // des notes vivent séparément depuis que la baguette existe.
  ThemeService.chargerThemeSauvegarde();

  // IMPORTANT : NotificationService.init() se contente de préparer le
  // plugin et de créer les canaux Android — ça ne demande AUCUNE
  // permission et ne peut donc jamais bloquer le lancement. Toutes les
  // vraies DEMANDES de permission (notification simple + alarme exacte,
  // qui peut ouvrir un écran de réglages système complet) sont désormais
  // faites APRÈS l'affichage de l'app (voir MyApp.initState ci-dessous),
  // pour ne jamais empêcher runApp() de s'exécuter si l'utilisateur
  // refuse, tarde à répondre, ou revient en arrière sans répondre.
  await NotificationService.init();

  // Passe unique de réduction des photos importées avant que le
  // redimensionnement n'existe. Volontairement SANS await : elle peut durer
  // plusieurs secondes sur une grosse bibliothèque et n'a aucune raison de
  // retarder l'affichage.
  unawaited(PhotoService.reduireLesAnciennes());

  runApp(const MyApp());
}

/// Police d'interface par défaut, appliquée aux deux ThemeData.
///
/// Android seulement : la police système y est Roboto, qu'Inclusive Sans
/// remplace avantageusement. Sur iOS on garde `null`, donc San Francisco —
/// elle est dessinée pour l'écran des iPhone et toute substitution s'y voit.
///
/// `defaultTargetPlatform` plutôt que `Platform.isAndroid` : il respecte la
/// surcharge de plateforme des tests et n'oblige pas à importer dart:io.
final String? _policeInterface =
    defaultTargetPlatform == TargetPlatform.android ? 'Inclusive Sans' : null;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(
    Langues.parCode(UserPrefs.langue).locale,
  );

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _timeWhenPaused;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _navigationNotificationEnCours = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.configurerClic((payload) {
        _navigationNotificationEnCours = true;
        _analyserPayload(payload);
      });

      // Demande des permissions + planification des rappels — APRÈS le
      // premier affichage de l'app, jamais avant. L'app reste
      // pleinement utilisable que l'utilisateur accepte, refuse, ou
      // ignore ces demandes.
      NotificationService.demanderPermissionsEtPlanifier();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _analyserPayload(String? payload) async {
    if (payload == null) {
      _navigationNotificationEnCours = false;
      return;
    }
    debugPrint("=== 🚨 CLIC NOTIFICATION DETECTÉ : $payload ===");

    // 1. Sauvegarde des données en tâche de fond (Indispensable Android/iOS)
    if (payload == "action:bocal_vide_erreur") {
      bocalVideEnCacheGlobal = true; 
    } else if (payload == "action:tirer_souvenir_aleatoire") {
      try {
        final NoteSourire? souvenirAleatoire = await DatabaseService().getRandomNote(
          categoriesCibles: UserPrefs.categoriesSouvenirs,
        );
        if (souvenirAleatoire != null) {
          debugPrint("=== 💾 ÉCRITURE SOUVENIR ID : ${souvenirAleatoire.id} ===");
          await UserPrefs.setSouvenirNotificationId(souvenirAleatoire.id!);
        }
      } catch (e) {
        debugPrint("Erreur récupération souvenir : $e");
      }
    }

    // 2. Attente de la disponibilité du Navigator
    while (_navigatorKey.currentState == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // 3. Calcul du temps d'absence pour le verrouillage
    bool doitVerrouiller = false;
    if (_timeWhenPaused != null) {
      final deconnexionDuration = DateTime.now().difference(_timeWhenPaused!);
      if (deconnexionDuration.inSeconds >= 3) {
        doitVerrouiller = true;
      }
    }
    
    final bool secuActivee = UserPrefs.biomatrieActive || UserPrefs.password.isNotEmpty;

    // 4. Aiguillage et routage natif Android historique
    if (secuActivee && (isAppLockedNotifier.value || doitVerrouiller)) {
      debugPrint("=== 🔒 ÉTAT : Activation du verrou via Notification ===");
      isAppLockedNotifier.value = true;
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    } else {
      debugPrint("=== 🚀 NAV : Accès direct Home via Notification ===");
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const BocalPreloader(child: Home())), // ← modifié
        (route) => false,
      );
    }

    _timeWhenPaused = null;
    _navigationNotificationEnCours = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timeWhenPaused = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      // Le fuseau a pu changer pendant que l'app était en arrière-plan :
      // voyage, changement d'heure, réglage manuel de l'horloge système.
      // On resynchronise AVANT tout autre traitement, et indépendamment du
      // verrou de sécurité — sinon un utilisateur qui voyage garderait des
      // rappels calés sur son fuseau de départ.
      _resynchroniserFuseauHoraire();

      if (!UserPrefs.biomatrieActive && UserPrefs.password.isEmpty) return;

      // Si le callback de notification est déjà en train de s'exécuter, on n'applique pas le verrou standard
      if (_navigationNotificationEnCours) {
        debugPrint("=== 🛡️ Cycle de vie avorté : Notification prioritaire ===");
        return;
      }

      if (_timeWhenPaused != null) {
        final deconnexionDuration = DateTime.now().difference(_timeWhenPaused!);
        
        if (deconnexionDuration.inSeconds >= 30) {
          debugPrint("=== 🔒 ÉTAT : Activation du verrou via Cycle de Vie classique ===");
          isAppLockedNotifier.value = true;
        }
        _timeWhenPaused = null;
      }
    }
  }

  /// Recale le fuseau sur celui de l'appareil et, s'il a changé, replanifie
  /// les rappels déjà programmés (qui pointaient sur l'ancien fuseau).
  Future<void> _resynchroniserFuseauHoraire() async {
    try {
      final bool fuseauModifie = await TimezoneService.resynchroniser();
      if (fuseauModifie) {
        debugPrint(
          "=== 🌍 Fuseau horaire modifié (${TimezoneService.identifiantActuel}) "
          "→ replanification des rappels ===",
        );
        await NotificationService.replanifierTout();
      }
    } catch (e) {
      debugPrint("Erreur lors de la resynchronisation du fuseau horaire : $e");
    }
  }

  void _surAuthentificationReussie() {
    debugPrint("=== 🔓 Déverrouillage réussi, l'état reconstruit la Home instantanément ===");
    isAppLockedNotifier.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: MyApp.localeNotifier,
          builder: (context, Locale currentLocale, _) { 
            return MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'Sourire',
              debugShowCheckedModeBanner: false,
              locale: currentLocale,
              themeMode: currentMode,
              theme: ThemeData(
                brightness: Brightness.light,
                primarySwatch: Colors.orange,
                scaffoldBackgroundColor: Colors.white,
                fontFamily: _policeInterface,
                colorScheme: ColorScheme.fromSeed(seedColor: orange, primary: orange, brightness: Brightness.light),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primarySwatch: Colors.orange,
                scaffoldBackgroundColor: const Color(0xFF121212),
                fontFamily: _policeInterface,
                colorScheme: ColorScheme.fromSeed(seedColor: orange, primary: orange, brightness: Brightness.dark),
              ),
              localizationsDelegates: const [
                AppLocalizations.delegate, 
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: Langues.locales,
              
              home: ValueListenableBuilder<bool>(
                valueListenable: isAppLockedNotifier,
                builder: (context, isLocked, child) {
                  if (isLocked) {
                    return ScreenLock(onAuthenticated: _surAuthentificationReussie);
                  }
                  if (UserPrefs.password.isNotEmpty || UserPrefs.biomatrieActive) {
                    return const BocalPreloader(child: Home()); // ← modifié
                  }
                  return const ScreenBoot(); 
                },
              ),
            );
          },
        );
      },
    );
  }
}
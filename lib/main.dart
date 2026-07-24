import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/screens/home.dart';
import 'package:sourire/screens/screen_boot.dart'; 
import 'package:sourire/screens/screen_lock.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/services/notifications_service.dart';
import 'package:sourire/models/note_model.dart';      
import 'package:timezone/data/latest.dart' as tz; 
import 'package:timezone/timezone.dart' as tz;      
import 'package:sourire/theme/theme_service.dart'; 
import 'package:sourire/services/database_service.dart';
import 'package:sourire/widgets/bocal_preloader.dart';

// Variables globales
NoteSourire? souvenirEnAttenteGlobal;
final ValueNotifier<int?> idSouvenirEnCacheGlobal = ValueNotifier<int?>(null);
bool bocalVideEnCacheGlobal = false; 

// On démarre verrouillé par défaut pour laisser le ScreenBoot décider
final ValueNotifier<bool> isAppLockedNotifier = ValueNotifier<bool>(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await UserPrefs.init(); 
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Pacific/Noumea'));
  ThemeService.chargerThemeSauvegarde();

  if (!UserPrefs.biomatrieActive && UserPrefs.password.isEmpty) {
    isAppLockedNotifier.value = false;
  }
  
  final String savedThemeId = UserPrefs.themeId;
  final themeSauvegarde = ThemeRepository.tousLesThemes.firstWhere(
    (t) => t.id == savedThemeId,
    orElse: () => ThemeRepository.themeClassique,
  );
  
  ThemeService.themeVisuelNotifier.value = themeSauvegarde;

  // IMPORTANT : NotificationService.init() se contente de préparer le
  // plugin et de créer les canaux Android — ça ne demande AUCUNE
  // permission et ne peut donc jamais bloquer le lancement. Toutes les
  // vraies DEMANDES de permission (notification simple + alarme exacte,
  // qui peut ouvrir un écran de réglages système complet) sont désormais
  // faites APRÈS l'affichage de l'app (voir MyApp.initState ci-dessous),
  // pour ne jamais empêcher runApp() de s'exécuter si l'utilisateur
  // refuse, tarde à répondre, ou revient en arrière sans répondre.
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    Locale(UserPrefs.langue == 'en' ? 'en' : 'fr', UserPrefs.langue == 'en' ? 'US' : 'FR'),
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
                colorScheme: ColorScheme.fromSeed(seedColor: orange, primary: orange, brightness: Brightness.light),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primarySwatch: Colors.orange,
                scaffoldBackgroundColor: const Color(0xFF121212),
                colorScheme: ColorScheme.fromSeed(seedColor: orange, primary: orange, brightness: Brightness.dark),
              ),
              localizationsDelegates: const [
                AppLocalizations.delegate, 
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
              
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
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
import 'package:permission_handler/permission_handler.dart';
import 'package:sourire/theme/theme_service.dart'; 
import 'package:sourire/services/database_service.dart';

// Variables globales
NoteSourire? souvenirEnAttenteGlobal;
final ValueNotifier<int?> idSouvenirEnCacheGlobal = ValueNotifier<int?>(null);
bool bocalVideEnCacheGlobal = false; 

// On démarre verrouillé par défaut pour laisser le ScreenBoot décider
final ValueNotifier<bool> isAppLockedNotifier = ValueNotifier<bool>(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. FORCER LE MODE PORTRAIT EXCLUSIVEMENT
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2. INITIALISATION DES PRÉFÉRENCES DISQUE ET TIMEZONES
  await UserPrefs.init(); 
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Pacific/Noumea'));
  ThemeService.chargerThemeSauvegarde();

  debugPrint("""
  ==================================================
  ===> CONFIGURATION DES RAPPELS IPHONE (DEBUG) <===
  Langue active : ${UserPrefs.langue}
  Rappel Gratitude Actif : ${UserPrefs.rappelGratitudeActive} à ${UserPrefs.heureRappelGratitude}h${UserPrefs.minuteRappelGratitude}
  Rappel Souvenirs Actif : ${UserPrefs.rappelSouvenirsActive} à ${UserPrefs.heureRappelSouvenirs}h${UserPrefs.minuteRappelSouvenirs}
  Fréquence Souvenirs : ${UserPrefs.frequenceSouvenirs}
  Fuseau Horaire Détecté : ${tz.local.name}
  ==================================================
  """);

  // SÉCURITÉ AU DÉMARRAGE
  if (!UserPrefs.biomatrieActive && UserPrefs.password.isEmpty) {
    isAppLockedNotifier.value = false;
  }
  
  // RECHARGER LE THEME SAUVEGARDÉ...
  final String savedThemeId = UserPrefs.themeId;
  final themeSauvegarde = ThemeRepository.tousLesThemes.firstWhere(
    (t) => t.id == savedThemeId,
    orElse: () => ThemeRepository.themeClassique,
  );
  
  ThemeService.themeVisuelNotifier.value = themeSauvegarde;
  await NotificationService.init();

  // Permissions et rappels...
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  final statusExact = await Permission.scheduleExactAlarm.status;
  if (statusExact.isDenied || statusExact.isPermanentlyDenied) {
    await Permission.scheduleExactAlarm.request();
  }

  await NotificationService.planifierRappelGratitude();
  await NotificationService.planifierRappelSouvenirs();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(_initialiseThemeInitial());
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    Locale(UserPrefs.langue == 'en' ? 'en' : 'fr', UserPrefs.langue == 'en' ? 'US' : 'FR'),
  );

  static ThemeMode _initialiseThemeInitial() {
    return ThemeMode.system; 
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _timeWhenPaused;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.configurerClic((payload) {
        _analyserPayload(payload);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _analyserPayload(String? payload) async {
    if (payload == null) return;

    debugPrint("=== NOTIFICATION PAYLOAD REÇU : $payload ===");

    if (payload == 'rappel_gratitude') {
      if (!isAppLockedNotifier.value) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Home()),
          (route) => false,
        );
      }
    } 
    else if (payload == "action:tirer_souvenir_aleatoire") {
      try {
        final NoteSourire? souvenirAleatoire = await DatabaseService().getRandomNote(
          categoriesCibles: UserPrefs.categoriesSouvenirs,
        );

        if (souvenirAleatoire == null) {
          bocalVideEnCacheGlobal = true;
          idSouvenirEnCacheGlobal.value = null; // Mise à jour ici
        } else {
          bocalVideEnCacheGlobal = false;
          // On injecte l'ID, ce qui va réveiller instantanément les écouteurs actifs
          idSouvenirEnCacheGlobal.value = souvenirAleatoire.id; 
          debugPrint("=== NOTIF === ID stocké dans le notifier : ${souvenirAleatoire.id}");
        }
      } catch (e) {
        debugPrint("Erreur récupération souvenir au clic : $e");
        bocalVideEnCacheGlobal = true;
        idSouvenirEnCacheGlobal.value = null;
      }

      // Redirection native vers la Home
      if (!isAppLockedNotifier.value) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const Home(),
            settings: const RouteSettings(name: 'HomeFromNotification'),
          ),
          (route) => false,
        );
      }
    }
  }


  void _surAuthentificationReussie() {
    isAppLockedNotifier.value = false;
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Home()),
      (route) => false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      MyApp.themeNotifier.value = ThemeMode.system; 
    }

    if (!UserPrefs.biomatrieActive && UserPrefs.password.isEmpty) return;

    if (state == AppLifecycleState.paused) {
      _timeWhenPaused = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      if (_timeWhenPaused != null) {
        final deconnexionDuration = DateTime.now().difference(_timeWhenPaused!);
        if (deconnexionDuration.inSeconds >= 30) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!isAppLockedNotifier.value) {
              isAppLockedNotifier.value = true;
              _navigatorKey.currentState?.push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'ScreenLock'),
                  builder: (context) => ScreenLock(onAuthenticated: _surAuthentificationReussie),
                ),
              );
            }
          });
        }
        _timeWhenPaused = null;
      }
    }
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
              home: const ScreenBoot(),
            );
          },
        );
      },
    );
  }
}
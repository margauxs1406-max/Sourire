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
  await NotificationService.init();

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

    // 1. Sauvegarde des données en tâche de fond
    if (payload == "action:bocal_vide_erreur") {
      bocalVideEnCacheGlobal = true; 
    } else if (payload == "action:tirer_souvenir_aleatoire") {
      try {
        final NoteSourire? souvenirAleatoire = await DatabaseService().getRandomNote(
          categoriesCibles: UserPrefs.categoriesSouvenirs,
        );
        if (souvenirAleatoire != null) {
          await UserPrefs.setSouvenirNotificationId(souvenirAleatoire.id!);
        }
      } catch (e) {
        debugPrint("Erreur récupération souvenir : $e");
      }
    }

    // 2. Attente du Navigator
    while (_navigatorKey.currentState == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // 3. Calcul du temps d'absence
    bool doitVerrouiller = false;
    if (_timeWhenPaused != null) {
      final deconnexionDuration = DateTime.now().difference(_timeWhenPaused!);
      if (deconnexionDuration.inSeconds >= 3) {
        doitVerrouiller = true;
      }
    }
    
    final bool secuActivee = UserPrefs.biomatrieActive || UserPrefs.password.isNotEmpty;

    // 4. AIGUILLAGE PAR L'ÉTAT GLOBALE
    if (secuActivee && (isAppLockedNotifier.value || doitVerrouiller)) {
      debugPrint("=== 🔒 ÉTAT : Activation du verrou via Notification ===");
      isAppLockedNotifier.value = true;
      
      // On nettoie la pile existante pour forcer le retour à l'état propre sous le verrou
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    } else {
      debugPrint("=== 🚀 NAV : Accès direct Home via Notification ===");
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Home()),
        (route) => false,
      );
    }

    _timeWhenPaused = null;
    await Future.delayed(const Duration(milliseconds: 300));
    _navigationNotificationEnCours = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!UserPrefs.biomatrieActive && UserPrefs.password.isEmpty) return;

    if (state == AppLifecycleState.paused) {
      _timeWhenPaused = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      // Si la notification gère le réveil, on coupe court à 100%
      if (_navigationNotificationEnCours) {
        debugPrint("=== 🛡️ Cycle de vie avorté : Notification prioritaire ===");
        return;
      }

      if (_timeWhenPaused != null) {
        final deconnexionDuration = DateTime.now().difference(_timeWhenPaused!);
        
        if (deconnexionDuration.inSeconds >= 3) {
          debugPrint("=== 🔒 ÉTAT : Activation du verrou via Cycle de Vie classique ===");
          // 🌟 MAGIE : On change juste la valeur, le MaterialApp s'occupe du reste sans dupliquer de push !
          isAppLockedNotifier.value = true;
        }
        _timeWhenPaused = null;
      }
    }
  }

  void _surAuthentificationReussie() {
  debugPrint("=== 🔓 Déverrouillage réussi, l'état reconstruit la Home instantanément ===");
  // Le simple fait de passer à false va reconstruire le MaterialApp directement sur la Home 
  // sans aucun push manuel ni écran blanc !
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
              
              // 🌟 LA PROTECTION ULTIME UNIQUE ICI :
              // On écoute l'état de verrouillage directement à la racine de la structure.
              // Si isAppLockedNotifier est true, l'application affiche invariablement LE ScreenLock, et rien d'autre.
              home: ValueListenableBuilder<bool>(
  valueListenable: isAppLockedNotifier,
  builder: (context, isLocked, child) {
    if (isLocked) {
      return ScreenLock(onAuthenticated: _surAuthentificationReussie);
    }
    // Si l'application a un mot de passe configuré, cela signifie qu'elle a déjà été 
    // initialisée au moins une fois. Après déverrouillage, on l'envoie direct sur Home.
    if (UserPrefs.password.isNotEmpty || UserPrefs.biomatrieActive) {
      return const Home();
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
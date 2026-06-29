import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/services/database_service.dart'; 
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/l10n/app_localizations_en.dart';
import 'package:sourire/l10n/app_localizations_fr.dart';

// 🌟 AJOUT INDISPENSABLE POUR IPHONE EN ARRIÈRE-PLAN :
// Cette fonction doit obligatoirement être globale (top-level), en dehors de toute classe.
@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse notificationResponse) async {
  final payload = notificationResponse.payload;
  if (payload == "action:tirer_souvenir_aleatoire") {
    debugPrint("=== 🍏 iOS NATIVE BACKGROUND CLICK DETECTED ===");
    try {
      // On force la récupération immédiate du souvenir pendant qu'iOS réveille l'application
      final souvenirAleatoire = await DatabaseService().getRandomNote(
        categoriesCibles: UserPrefs.categoriesSouvenirs,
      );
      if (souvenirAleatoire != null) {
        // On l'écrit directement en mémoire. Les UserPrefs seront prêts au moment du déverrouillage !
        await UserPrefs.setSouvenirNotificationId(souvenirAleatoire.id!);
        debugPrint("=== 🍏 iOS BACKGROUND : ID écrit en cache avec succès (${souvenirAleatoire.id}) ===");
      }
    } catch (e) {
      debugPrint("Erreur récupération souvenir background iOS : $e");
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static Function(String?)? _onNotificationTap;
  static String? _initialPayload;

  /// Détermine dynamiquement la classe de traduction à utiliser selon les préférences
  static AppLocalizations _obtenirTraductions() {
    final String codeLangue = UserPrefs.langue; 
    return codeLangue == 'en' ? AppLocalizationsEn() : AppLocalizationsFr();
  }

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    // Correction Android : Utiliser l'heure locale de l'appareil pour éviter les décalages du Doze Mode.
    final String timeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Pacific/Noumea'));
    }

    final localizations = _obtenirTraductions();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (_onNotificationTap != null) {
          _onNotificationTap!(response.payload);
        } else if (response.payload != null) {
          _initialPayload = response.payload;
        }
      },
      // 🌟 LA PIÈCE MANQUANTE POUR TON IPHONE :
      // On lie la fonction d'arrière-plan pour intercepter le clic natif d'iOS
      onDidReceiveBackgroundNotificationResponse: onNotificationTapBackground,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidPlugin != null) {
      final AndroidNotificationChannel channelGratitude = AndroidNotificationChannel(
        'rappel_gratitude_id',
        localizations.notifGratitudeChannelName,
        description: localizations.notifGratitudeChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channelGratitude);

      final AndroidNotificationChannel channelSouvenirs = AndroidNotificationChannel(
        'rappel_souvenirs_id',
        localizations.notifSouvenirsChannelName,
        description: localizations.notifSouvenirsChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channelSouvenirs);

      await androidPlugin.requestNotificationsPermission();
    }
  }

  static Future<void> configurerClic(Function(String?) callback) async {
    _onNotificationTap = callback;

    if (_initialPayload != null) {
      _onNotificationTap!(_initialPayload);
      _initialPayload = null;
      return;
    }

    final NotificationAppLaunchDetails? appLaunchDetails =
        await _plugin.getNotificationAppLaunchDetails();
    
    if (appLaunchDetails != null && appLaunchDetails.didNotificationLaunchApp) {
      final payload = appLaunchDetails.notificationResponse?.payload;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_onNotificationTap != null && payload != null) {
          _onNotificationTap!(payload);
        }
      });
    }
  }

  /// Planification du rappel quotidien de gratitude
  static Future<void> planifierRappelGratitude() async {
    const int notifId = 1;

    if (!UserPrefs.rappelGratitudeActive) { 
      await _plugin.cancel(notifId);
      return;
    }

    final localizations = _obtenirTraductions();
    
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(AndroidNotificationChannel(
        'rappel_gratitude_id',
        localizations.notifGratitudeChannelName,
        description: localizations.notifGratitudeChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ));
    }

    final maintenant = tz.TZDateTime.now(tz.local);
    
    var instantPlanifie = tz.TZDateTime(
      tz.local,
      maintenant.year,
      maintenant.month,
      maintenant.day,
      UserPrefs.heureRappelGratitude,
      UserPrefs.minuteRappelGratitude,
    );
    
    if (instantPlanifie.isBefore(maintenant.add(const Duration(minutes: 1)))) {
      instantPlanifie = instantPlanifie.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      notifId,
      localizations.notifGratitudeTitle, 
      localizations.notifGratitudeBody,  
      instantPlanifie,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'rappel_gratitude_id',
          localizations.notifGratitudeChannelName,
          channelDescription: localizations.notifGratitudeChannelDesc,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'rappel_gratitude',
    );
  }

  /// Planification du rappel de souvenirs (Pérenne & Léger)
  static Future<void> planifierRappelSouvenirs() async {
    const int notifId = 2;
    await _plugin.cancel(notifId);

    if (!UserPrefs.rappelSouvenirsActive) return;

    final localizations = _obtenirTraductions();
    String notifTitle = localizations.notifSouvenirsDefaultTitle;
    String notifAllBody = localizations.notifSouvenirsAllBody; 
    String payloadData = "action:tirer_souvenir_aleatoire";

    String corpsTexteFinal = notifAllBody;

    try {
      final toutesLesNotes = await DatabaseService().getAllNotesAsync();
      final categoriesCibles = UserPrefs.categoriesSouvenirs;
      
      if (toutesLesNotes.isEmpty) {
        notifTitle = localizations.notifSouvenirsEmptyTitle; 
        corpsTexteFinal = localizations.notifSouvenirsEmptyBody; 
        payloadData = "action:bocal_vide_total_erreur";
      } 
      else {
        final bool veutTout = categoriesCibles.contains("all_categories") || categoriesCibles.isEmpty;

        final notesFiltrees = veutTout 
            ? toutesLesNotes 
            : toutesLesNotes.where((note) => note.categories.any((cat) => categoriesCibles.contains(cat))).toList();

        if (notesFiltrees.isEmpty) {
          notifTitle = localizations.notifBocalVideTitle;
          corpsTexteFinal = localizations.notifBocalVideBody; 
          payloadData = "action:bocal_vide_erreur";
        } else {
          notifTitle = localizations.notifSouvenirsDefaultTitle;
          corpsTexteFinal = notifAllBody; 
          payloadData = "action:tirer_souvenir_aleatoire";
        }
      }
      
    } catch (e) {
      debugPrint("Erreur décompte rapide souvenirs : $e");
      corpsTexteFinal = notifAllBody; 
    }

    final maintenant = tz.TZDateTime.now(tz.local);
    var instantPlanifie = tz.TZDateTime(
      tz.local,
      maintenant.year,
      maintenant.month,
      maintenant.day,
      UserPrefs.heureRappelSouvenirs,
      UserPrefs.minuteRappelSouvenirs,
    );

    if (instantPlanifie.isBefore(maintenant.add(const Duration(minutes: 1)))) {
      if (UserPrefs.frequenceSouvenirs == "Tous les jours") {
        instantPlanifie = instantPlanifie.add(const Duration(days: 1));
      }
    }

    DateTimeComponents? matchComponents;
    if (UserPrefs.frequenceSouvenirs == "Tous les jours") {
      if (instantPlanifie.isBefore(maintenant)) {
        instantPlanifie = instantPlanifie.add(const Duration(days: 1));
      }
      matchComponents = DateTimeComponents.time;
    } 
    else if (UserPrefs.frequenceSouvenirs == "Tous les 2 jours") {
      if (instantPlanifie.isBefore(maintenant)) {
        instantPlanifie = instantPlanifie.add(const Duration(days: 2));
      }
      matchComponents = null; 
    } 
    else if (UserPrefs.frequenceSouvenirs == "Toutes les semaines") {
      final Map<String, int> joursMapping = {
        "Lundi": DateTime.monday, "Mardi": DateTime.tuesday, "Mercredi": DateTime.wednesday,
        "Jeudi": DateTime.thursday, "Vendredi": DateTime.friday, "Samedi": DateTime.saturday,
        "Dimanche": DateTime.sunday,
      };
      int jourCible = joursMapping[UserPrefs.jourSemaineSouvenirs] ?? DateTime.monday;
      if (instantPlanifie.weekday == jourCible && instantPlanifie.isBefore(maintenant)) {
        instantPlanifie = instantPlanifie.add(const Duration(days: 7));
      } else {
        while (instantPlanifie.weekday != jourCible || instantPlanifie.isBefore(maintenant)) {
          instantPlanifie = instantPlanifie.add(const Duration(days: 1));
        }
      }
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    }

    await _plugin.zonedSchedule(
      notifId,
      notifTitle,
      corpsTexteFinal, 
      instantPlanifie,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'rappel_souvenirs_id',
          localizations.notifSouvenirsChannelName,
          channelDescription: localizations.notifSouvenirsChannelDesc,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents, 
      payload: payloadData,
    );
  }

  static FlutterLocalNotificationsPlugin get plugin => _plugin;
}
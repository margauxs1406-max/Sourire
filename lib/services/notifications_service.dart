import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/l10n/app_localizations_en.dart';
import 'package:sourire/l10n/app_localizations_fr.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static Function(String?)? _onNotificationTap;

  /// Détermine dynamiquement la classe de traduction à utiliser selon les préférences
  static AppLocalizations _obtenirTraductions() {
    final String codeLangue = UserPrefs.langue; 
    return codeLangue == 'en' ? AppLocalizationsEn() : AppLocalizationsFr();
  }

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Pacific/Noumea'));

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
        }
      },
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

    final NotificationAppLaunchDetails? appLaunchDetails =
        await _plugin.getNotificationAppLaunchDetails();
    
    if (appLaunchDetails != null && appLaunchDetails.didNotificationLaunchApp) {
      final payload = appLaunchDetails.notificationResponse?.payload;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_onNotificationTap != null) {
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
    
    if (instantPlanifie.isBefore(maintenant)) {
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
        // CORRECTION : Ajout obligatoire des détails iOS pour réveiller le device
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Rappel quotidien régulier
      payload: 'rappel_gratitude',
    );
  }

  /// Planification du rappel de souvenirs (Pérenne & Léger)
  static Future<void> planifierRappelSouvenirs() async {
    const int notifId = 2;

    await _plugin.cancel(notifId);

    if (!UserPrefs.rappelSouvenirsActive) { 
      return;
    }

    final localizations = _obtenirTraductions();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(AndroidNotificationChannel(
        'rappel_souvenirs_id',
        localizations.notifSouvenirsChannelName,
        description: localizations.notifSouvenirsChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ));
    }

    // PLUS DE REQUÊTE SQLICI ! Le texte devient générique et invitant.
    String notifTitle = localizations.notifSouvenirsDefaultTitle;
    String notifBody = localizations.notifSouvenirsPhotoBody; // Ex: "Ouvrez votre bocal pour redécouvrir un moment heureux !"
    
    // Le payload devient une action universelle
    String payloadData = "action:tirer_souvenir_aleatoire";

    final maintenant = tz.TZDateTime.now(tz.local);
    
    var instantPlanifie = tz.TZDateTime(
      tz.local,
      maintenant.year,
      maintenant.month,
      maintenant.day,
      UserPrefs.heureRappelSouvenirs,
      UserPrefs.minuteRappelSouvenirs,
    );

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
        "Lundi": DateTime.monday,
        "Mardi": DateTime.tuesday,
        "Mercredi": DateTime.wednesday,
        "Jeudi": DateTime.thursday,
        "Vendredi": DateTime.friday,
        "Samedi": DateTime.saturday,
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
      notifBody,
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
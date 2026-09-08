import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
// La base IANA est chargée par TimezoneService, plus besoin de l'importer ici.
import 'package:timezone/timezone.dart' as tz;
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/services/timezone_service.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/l10n/app_localizations_en.dart';
import 'package:sourire/l10n/app_localizations_fr.dart';

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
    // Le fuseau horaire est géré par TimezoneService (appelé depuis main()
    // avant cette méthode ; l'appel ci-dessous est idempotent et sert de filet).
    //
    // Ne PAS le régler ici « à la main » : l'ancienne détection reposait sur
    // DateTime.now().timeZoneName, qui renvoie une ABRÉVIATION ("CEST",
    // "GMT+2", "+11") et non un identifiant IANA. tz.getLocation() échouait
    // donc toujours, et le catch retombait sur un fuseau codé en dur.
    await TimezoneService.initialiser();

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

      // La demande de permission elle-même se fait désormais UNIQUEMENT
      // dans demanderPermissionsEtPlanifier() (appelée après runApp()) —
      // plus de doublon ici, et surtout, init() ne demande plus jamais
      // aucune permission (donc jamais bloquant avant l'affichage de l'app).
    }
  }

  /// Demande la permission de notification, PUIS planifie les rappels.
  /// À appeler UNIQUEMENT après le premier affichage de l'app, jamais avant
  /// runApp().
  ///
  /// L'alarme EXACTE n'est plus demandée. Google Play réserve
  /// `SCHEDULE_EXACT_ALARM` aux réveils, agendas et alarmes, et exige une
  /// justification pour tout le reste : un rappel de gratitude hebdomadaire
  /// n'en fait pas partie et exposait à un refus de publication. Les rappels
  /// passent donc en mode inexact, qui les déclenche à quelques minutes près.
  /// Personne ne verra la différence sur un rappel « dimanche à 20h », et la
  /// batterie s'en portera mieux.
  static Future<void> demanderPermissionsEtPlanifier() async {
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint("Erreur lors de la demande de permissions notifications : $e");
    }

    // Peu importe la réponse de l'utilisateur (accepté, refusé, ignoré),
    // on tente quand même de planifier — si la permission est refusée,
    // les notifications ne s'afficheront simplement pas, sans jamais
    // bloquer le reste de l'app.
    try {
      await planifierRappelGratitude();
      await planifierRappelSouvenirs();
    } catch (e) {
      debugPrint("Erreur lors de la planification des rappels : $e");
    }
  }

  /// Replanifie les deux rappels sur le fuseau horaire courant.
  ///
  /// Appelée quand l'appareil change de fuseau : les notifications déjà
  /// programmées l'ont été en tz.TZDateTime sur l'ancienne zone et se
  /// déclencheraient à la mauvaise heure locale.
  static Future<void> replanifierTout() async {
    try {
      await planifierRappelGratitude();
      await planifierRappelSouvenirs();
    } catch (e) {
      debugPrint("Erreur lors de la replanification des rappels : $e");
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

  // --- OUTILS DE PLANIFICATION PARTAGÉS ---------------------------------------

  static const Map<String, int> _joursSemaine = {
    "Lundi": DateTime.monday,
    "Mardi": DateTime.tuesday,
    "Mercredi": DateTime.wednesday,
    "Jeudi": DateTime.thursday,
    "Vendredi": DateTime.friday,
    "Samedi": DateTime.saturday,
    "Dimanche": DateTime.sunday,
  };

  /// Prochaine occurrence de [heure]:[minute] strictement dans le futur, en
  /// avançant de [pas] tant qu'elle est déjà passée.
  static tz.TZDateTime _prochaineOccurrence(int heure, int minute, Duration pas) {
    final maintenant = tz.TZDateTime.now(tz.local);
    var instant = tz.TZDateTime(
      tz.local,
      maintenant.year,
      maintenant.month,
      maintenant.day,
      heure,
      minute,
    );
    // Marge d'une minute : on ne programme pas un rappel pour « dans 3 secondes ».
    while (!instant.isAfter(maintenant.add(const Duration(minutes: 1)))) {
      instant = instant.add(pas);
    }
    return instant;
  }

  /// Prochaine occurrence de [heure]:[minute] tombant sur [jour].
  static tz.TZDateTime _prochaineOccurrenceHebdomadaire(String jour, int heure, int minute) {
    final maintenant = tz.TZDateTime.now(tz.local);
    final int jourCible = _joursSemaine[jour] ?? DateTime.sunday;
    var instant = tz.TZDateTime(
      tz.local,
      maintenant.year,
      maintenant.month,
      maintenant.day,
      heure,
      minute,
    );
    while (instant.weekday != jourCible ||
        !instant.isAfter(maintenant.add(const Duration(minutes: 1)))) {
      instant = instant.add(const Duration(days: 1));
    }
    return instant;
  }

  // --- IDENTIFIANTS DE NOTIFICATION ---------------------------------------------
  //
  // Chaque rappel a un identifiant principal (répétition native) et une plage
  // dédiée pour les occurrences programmées d'avance en mode « tous les 2
  // jours ». Les plages sont disjointes pour qu'un rappel n'annule jamais
  // l'autre.
  static const int _idGratitude = 1;
  static const int _idGratitudeSerieBase = 1001;

  static const int _idSouvenirs = 2;
  static const int _idSouvenirsSerieBase = 2001;

  /// Un rappel hebdomadaire peut couvrir jusqu'à 7 jours cochés, donc 7
  /// notifications distinctes à annuler avant chaque replanification.
  static const int _maxJoursSemaine = 7;

  /// Annule un rappel : l'occurrence principale ET toute la série avancée.
  /// Indispensable avant chaque replanification, sinon un changement de
  /// fréquence laisserait traîner les rappels de l'ancien réglage.
  static Future<void> _annulerRappel(int idPrincipal, int idSerieBase) async {
    await _plugin.cancel(idPrincipal);
    for (int i = 0; i < _maxJoursSemaine; i++) {
      await _plugin.cancel(idSerieBase + i);
    }
  }

  /// Programme un rappel récurrent selon la fréquence choisie.
  ///
  /// Les deux rythmes s'appuient sur la répétition NATIVE du système
  /// (`matchDateTimeComponents`) : une fois programmées, les notifications se
  /// rejouent indéfiniment, même si l'utilisateur n'ouvre jamais l'app.
  ///
  /// En hebdomadaire, une notification distincte est programmée par jour
  /// coché — c'est la seule façon de couvrir plusieurs jours, le système ne
  /// sachant répéter que sur un seul jour de la semaine à la fois.
  static Future<void> _programmerRappelRecurrent({
    required int idPrincipal,
    required int idSerieBase,
    required String frequence,
    required List<String> jours,
    required int heure,
    required int minute,
    required String titre,
    required String corps,
    required String payload,
    required NotificationDetails details,
  }) async {
    if (frequence == UserPrefs.frequenceHebdomadaire) {
      // Garde-fou : une liste vide laisserait l'utilisateur sans aucun rappel
      // alors qu'il a laissé le réglage activé.
      final List<String> joursRetenus =
          jours.isEmpty ? const [UserPrefs.jourLundi] : jours;

      for (int i = 0; i < joursRetenus.length && i < _maxJoursSemaine; i++) {
        await _plugin.zonedSchedule(
          idSerieBase + i,
          titre,
          corps,
          _prochaineOccurrenceHebdomadaire(joursRetenus[i], heure, minute),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }
      return;
    }

    await _plugin.zonedSchedule(
      idPrincipal,
      titre,
      corps,
      _prochaineOccurrence(heure, minute, const Duration(days: 1)),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // --- RAPPEL DE GRATITUDE -----------------------------------------------------

  /// Le texte du rappel s'adapte à la fréquence choisie.
  static String _corpsGratitude(AppLocalizations l, String frequence) {
    return frequence == UserPrefs.frequenceHebdomadaire
        ? l.notifGratitudeBodyWeekly
        : l.notifGratitudeBodyDaily;
  }

  /// Planification du rappel de gratitude (quotidien, tous les 2 jours ou
  /// hebdomadaire, à l'heure choisie par l'utilisateur).
  static Future<void> planifierRappelGratitude() async {
    await _annulerRappel(_idGratitude, _idGratitudeSerieBase);

    if (!UserPrefs.rappelGratitudeActive) return;

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

    final String frequence = UserPrefs.frequenceGratitude;

    await _programmerRappelRecurrent(
      idPrincipal: _idGratitude,
      idSerieBase: _idGratitudeSerieBase,
      frequence: frequence,
      jours: UserPrefs.joursGratitude,
      heure: UserPrefs.heureRappelGratitude,
      minute: UserPrefs.minuteRappelGratitude,
      titre: localizations.notifGratitudeTitle,
      corps: _corpsGratitude(localizations, frequence),
      payload: 'rappel_gratitude',
      details: NotificationDetails(
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
    );
  }

  // --- RAPPEL DE SOUVENIRS -----------------------------------------------------

  /// Planification du rappel de souvenirs (Pérenne & Léger).
  ///
  /// Même mécanique que le rappel de gratitude : répétition native en
  /// quotidien / hebdomadaire, série d'occurrences programmées d'avance en
  /// « tous les 2 jours ».
  static Future<void> planifierRappelSouvenirs() async {
    await _annulerRappel(_idSouvenirs, _idSouvenirsSerieBase);

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

    // Le texte reflète l'état du bocal au moment de la planification. Il est
    // recalculé à chaque ouverture de l'app, comme la série d'occurrences.
    await _programmerRappelRecurrent(
      idPrincipal: _idSouvenirs,
      idSerieBase: _idSouvenirsSerieBase,
      frequence: UserPrefs.frequenceSouvenirs,
      jours: UserPrefs.joursSouvenirs,
      heure: UserPrefs.heureRappelSouvenirs,
      minute: UserPrefs.minuteRappelSouvenirs,
      titre: notifTitle,
      corps: corpsTexteFinal,
      payload: payloadData,
      details: NotificationDetails(
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
    );
  }

  static FlutterLocalNotificationsPlugin get plugin => _plugin;
}
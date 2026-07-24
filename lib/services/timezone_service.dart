import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Point d'entrée UNIQUE pour le fuseau horaire de l'application.
///
/// Avant : le fuseau était écrit en dur (`Pacific/Noumea`) dans `main.dart`, et
/// la détection tentée dans `NotificationService.init()` reposait sur
/// `DateTime.now().timeZoneName`, qui renvoie une ABRÉVIATION ("CEST", "GMT+2",
/// "+11"…) et non un identifiant IANA. `tz.getLocation("CEST")` échouait donc
/// systématiquement et le code retombait sur Nouméa : tous les utilisateurs
/// hors Nouvelle-Calédonie recevaient leurs rappels à la mauvaise heure.
///
/// Ici on interroge la couche native via `flutter_timezone`, qui renvoie bien
/// un identifiant IANA ("Europe/Paris", "America/New_York"…).
class TimezoneService {
  TimezoneService._();

  /// Identifiant IANA actuellement appliqué (null tant que non initialisé).
  static String? _identifiantActuel;
  static String? get identifiantActuel => _identifiantActuel;

  static bool _baseChargee = false;

  /// À appeler une fois au démarrage, avant toute planification de notification.
  static Future<void> initialiser() async {
    if (!_baseChargee) {
      // `latest_all` (et non `latest`) : inclut les alias historiques
      // ("Asia/Calcutta", "US/Pacific"…) que certains appareils renvoient encore.
      tzdata.initializeTimeZones();
      _baseChargee = true;
    }
    await _appliquerFuseauDeLAppareil();
  }

  /// À appeler quand l'app revient au premier plan.
  ///
  /// Retourne `true` si le fuseau a changé depuis la dernière application —
  /// l'appelant doit alors replanifier les notifications, sinon les rappels
  /// resteraient calés sur l'ancien fuseau (voyage, changement manuel de
  /// l'heure système, passage à l'heure d'été dans certains cas).
  static Future<bool> resynchroniser() async {
    final String? precedent = _identifiantActuel;
    await initialiser();
    return _identifiantActuel != precedent;
  }

  static Future<void> _appliquerFuseauDeLAppareil() async {
    String? identifiant;

    try {
      // flutter_timezone >= 5 renvoie un TimezoneInfo ; .identifier contient
      // l'identifiant IANA ("Europe/Paris", "America/New_York"…).
      final info = await FlutterTimezone.getLocalTimezone();
      identifiant = info.identifier;
    } catch (e) {
      debugPrint("Fuseau horaire : lecture native impossible ($e)");
    }

    if (identifiant != null && identifiant.isNotEmpty) {
      try {
        tz.setLocalLocation(tz.getLocation(identifiant));
        _identifiantActuel = identifiant;
        debugPrint("Fuseau horaire appliqué : $identifiant");
        return;
      } catch (e) {
        debugPrint("Fuseau '$identifiant' absent de la base IANA ($e)");
      }
    }

    _appliquerRepliParDecalage();
  }

  /// Repli : aucun identifiant exploitable. Plutôt que de figer un fuseau
  /// arbitraire, on cherche une zone dont le décalage correspond à celui que
  /// le système rapporte. L'utilisateur aura la bonne HEURE, même si le nom de
  /// la zone n'est pas exactement le sien.
  static void _appliquerRepliParDecalage() {
    final int decalageSysteme = DateTime.now().timeZoneOffset.inMilliseconds;

    try {
      for (final zone in tz.timeZoneDatabase.locations.values) {
        if (zone.currentTimeZone.offset == decalageSysteme) {
          tz.setLocalLocation(zone);
          _identifiantActuel = zone.name;
          debugPrint(
            "Fuseau horaire : repli sur ${zone.name} (même décalage que le système)",
          );
          return;
        }
      }
    } catch (e) {
      debugPrint("Fuseau horaire : repli par décalage impossible ($e)");
    }

    // Dernier recours : UTC. Jamais un fuseau codé en dur.
    tz.setLocalLocation(tz.getLocation('UTC'));
    _identifiantActuel = 'UTC';
    debugPrint("Fuseau horaire : repli sur UTC");
  }
}
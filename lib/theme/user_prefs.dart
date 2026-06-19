import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static SharedPreferences? _prefs;

  // Cette méthode doit être appelée une seule fois dans le main.dart
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- ANCIENNES VARIABLES CONVERTIES EN STATIC SANS CASSER LE RESTE DE L'APP ---
  static String get prenom => _prefs?.getString('prenom') ?? "";
  static set prenom(String value) => _prefs?.setString('prenom', value);

  static String get genre => _prefs?.getString('genre') ?? "";
  static set genre(String value) => _prefs?.setString('genre', value);

  static String get email => _prefs?.getString('email') ?? "";
  static set email(String value) => _prefs?.setString('email', value);

  static String get password => _prefs?.getString('password') ?? "";
  static set password(String value) => _prefs?.setString('password', value);

  static bool get biomatrieActive => _prefs?.getBool('biomatrieActive') ?? false;
  static set biomatrieActive(bool value) => _prefs?.setBool('biomatrieActive', value);

  static bool get isDark => _prefs?.getBool('isDark') ?? false;
  static set isDark(bool value) => _prefs?.setBool('isDark', value);

  static String get langue => _prefs?.getString('langue') ?? "fr";
  static set langue(String value) => _prefs?.setString('langue', value);

  static bool get modeDemoAffiche => _prefs?.getBool('modeDemoAffiche') ?? false;
  static set modeDemoAffiche(bool value) => _prefs?.setBool('modeDemoAffiche', value);

  static String get accordHeureux => (genre == "Une femme") ? "heureuse" : "heureux";

  static Future<void> setLangue(String value) async {
    langue = value;
  }

  // --- VARIABLES DE NOTIFICATIONS PERSISTANTES ---
  static bool get rappelGratitudeActive => _prefs?.getBool('rappelGratitudeActive') ?? true;
  static set rappelGratitudeActive(bool value) => _prefs?.setBool('rappelGratitudeActive', value);

  static bool get rappelSouvenirsActive => _prefs?.getBool('rappelSouvenirsActive') ?? true;
  static set rappelSouvenirsActive(bool value) => _prefs?.setBool('rappelSouvenirsActive', value);

  static int get heureRappelGratitude => _prefs?.getInt('heureRappelGratitude') ?? 20;
  static set heureRappelGratitude(int value) => _prefs?.setInt('heureRappelGratitude', value);

  static int get minuteRappelGratitude => _prefs?.getInt('minuteRappelGratitude') ?? 0;
  static set minuteRappelGratitude(int value) => _prefs?.setInt('minuteRappelGratitude', value);

  static String get frequenceSouvenirs => _prefs?.getString('frequenceSouvenirs') ?? "Tous les jours";
  static set frequenceSouvenirs(String value) => _prefs?.setString('frequenceSouvenirs', value);

  static String get jourSemaineSouvenirs => _prefs?.getString('jourSemaineSouvenirs') ?? "Lundi";
  static set jourSemaineSouvenirs(String value) => _prefs?.setString('jourSemaineSouvenirs', value);

  static int get heureRappelSouvenirs => _prefs?.getInt('heureRappelSouvenirs') ?? 9;
  static set heureRappelSouvenirs(int value) => _prefs?.setInt('heureRappelSouvenirs', value);

  static int get minuteRappelSouvenirs => _prefs?.getInt('minuteRappelSouvenirs') ?? 00;
  static set minuteRappelSouvenirs(int value) => _prefs?.setInt('minuteRappelSouvenirs', value);

  static List<String> get categoriesSouvenirs => _prefs?.getStringList('categoriesSouvenirs') ?? ["Toutes catégories"];
  static set categoriesSouvenirs(List<String> value) => _prefs?.setStringList('categoriesSouvenirs', value);

  // --- PERSISTANCE DU THÈME VISUEL ---
  static String get themeId => _prefs?.getString('themeId') ?? "classique";
  static set themeId(String value) => _prefs?.setString('themeId', value);
}
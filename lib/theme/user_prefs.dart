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

  // --- GENRE ----------------------------------------------------------------
  // Stocké sous forme de CODE ('f' / 'h') et non plus du libellé traduit :
  // l'ancien stockage ("Une femme" / "A woman") cassait l'accord dès que
  // l'utilisateur changeait la langue de l'app après l'onboarding.
  static const String genreMasculin = 'h';
  static const String genreFeminin = 'f';

  /// Aucun des deux : l'accord se fait alors en écriture inclusive.
  static const String genreNeutre = 'n';

  static String get genre => _prefs?.getString('genre') ?? "";
  static set genre(String value) => _prefs?.setString('genre', value);

  /// Code normalisé du genre. Lecture tolérante : accepte les codes actuels
  /// comme les anciens libellés traduits enregistrés par les versions
  /// précédentes de l'onboarding.
  static String get codeGenre {
    final g = genre.trim().toLowerCase();
    if (g == genreFeminin || g == "une femme" || g == "a woman") {
      return genreFeminin;
    }
    if (g == genreNeutre) return genreNeutre;
    return genreMasculin;
  }

  static set codeGenre(String value) => genre = value;

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

  /// Accord de l'adjectif « heureux » utilisé dans les textes français.
  ///
  /// Le genre neutre donne la forme inclusive « heureux·se », avec un point
  /// médian (U+00B7) et non un point ordinaire : c'est la forme recommandée,
  /// et les lecteurs d'écran la restituent correctement.
  static String get accordHeureux {
    switch (codeGenre) {
      case genreFeminin:
        return "heureuse";
      case genreNeutre:
        return "heureux·se";
      default:
        return "heureux";
    }
  }

  // --- LIMITE DE LA VERSION GRATUITE ----------------------------------------
  /// Nombre total de souvenirs (notes ET photos confondues) autorisés sans
  /// Premium — la moitié d'un bocal plein.
  static const int limiteSouvenirsGratuits = 25;

  static Future<void> setLangue(String value) async {
    langue = value;
  }

  // --- VARIABLES DE NOTIFICATIONS PERSISTANTES ---

  // Libellés de fréquence effectivement stockés en préférences. Ce sont des
  // clés internes (jamais affichées telles quelles) : l'UI passe par
  // _getFrequencyDisplayLabel / _getDayDisplayLabel pour les traduire.
  static const String frequenceQuotidienne = "Tous les jours";
  static const String frequenceHebdomadaire = "Toutes les semaines";

  /// Ancienne fréquence, supprimée : ni Android ni iOS ne savent répéter un
  /// rappel tous les 2 jours. Conservée uniquement pour la migration.
  static const String frequenceDeuxJoursObsolete = "Tous les 2 jours";

  static const String jourLundi = "Lundi";
  static const String jourDimanche = "Dimanche";

  /// Ordre d'affichage des jours, du lundi au dimanche.
  static const List<String> joursSemaine = [
    "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche",
  ];

  static bool get rappelGratitudeActive => _prefs?.getBool('rappelGratitudeActive') ?? true;
  static set rappelGratitudeActive(bool value) => _prefs?.setBool('rappelGratitudeActive', value);

  static bool get rappelSouvenirsActive => _prefs?.getBool('rappelSouvenirsActive') ?? true;
  static set rappelSouvenirsActive(bool value) => _prefs?.setBool('rappelSouvenirsActive', value);

  static int get heureRappelGratitude => _prefs?.getInt('heureRappelGratitude') ?? 20;
  static set heureRappelGratitude(int value) => _prefs?.setInt('heureRappelGratitude', value);

  static int get minuteRappelGratitude => _prefs?.getInt('minuteRappelGratitude') ?? 0;
  static set minuteRappelGratitude(int value) => _prefs?.setInt('minuteRappelGratitude', value);

  /// Fréquence du rappel de gratitude. Par défaut hebdomadaire, le dimanche.
  static String get frequenceGratitude =>
      _prefs?.getString('frequenceGratitude') ?? frequenceHebdomadaire;
  static set frequenceGratitude(String value) =>
      _prefs?.setString('frequenceGratitude', value);

  /// Jours cochés pour le rappel hebdomadaire de gratitude.
  static List<String> get joursGratitude =>
      _prefs?.getStringList('joursGratitude') ?? const [jourDimanche];
  static set joursGratitude(List<String> value) =>
      _prefs?.setStringList('joursGratitude', value);

  static String get frequenceSouvenirs =>
      _prefs?.getString('frequenceSouvenirs') ?? frequenceQuotidienne;
  static set frequenceSouvenirs(String value) => _prefs?.setString('frequenceSouvenirs', value);

  /// Jours cochés pour le rappel hebdomadaire de souvenirs.
  static List<String> get joursSouvenirs =>
      _prefs?.getStringList('joursSouvenirs') ?? const [jourLundi];
  static set joursSouvenirs(List<String> value) =>
      _prefs?.setStringList('joursSouvenirs', value);

  static int get heureRappelSouvenirs => _prefs?.getInt('heureRappelSouvenirs') ?? 9; 
  static set heureRappelSouvenirs(int value) => _prefs?.setInt('heureRappelSouvenirs', value);

  static int get minuteRappelSouvenirs => _prefs?.getInt('minuteRappelSouvenirs') ?? 00;
  static set minuteRappelSouvenirs(int value) => _prefs?.setInt('minuteRappelSouvenirs', value);

  static List<String> get categoriesSouvenirs => _prefs?.getStringList('categoriesSouvenirs') ?? [];
  static set categoriesSouvenirs(List<String> value) => _prefs?.setStringList('categoriesSouvenirs', value);

  /// La passe de réduction des photos déjà importées a-t-elle été jouée ?
  /// Voir PhotoService.reduireLesAnciennes().
  static bool get photosDejaReduites =>
      _prefs?.getBool('photosDejaReduites') ?? false;
  static set photosDejaReduites(bool value) =>
      _prefs?.setBool('photosDejaReduites', value);

  /// Les souvenirs d'amorçage n'ont-ils déjà été déposés ?
  static bool get amorcageEffectue => _prefs?.getBool('amorcageEffectue') ?? false;
  static set amorcageEffectue(bool value) =>
      _prefs?.setBool('amorcageEffectue', value);

  /// Bascule unique vers le nouveau réglage du rappel de gratitude.
  ///
  /// Jusqu'ici le rappel était forcément quotidien ; il devient réglable, avec
  /// pour nouveau défaut « toutes les semaines, le dimanche à 20h ». Les
  /// utilisateurs déjà installés sont alignés sur ce défaut une seule fois —
  /// ensuite leurs réglages leur appartiennent et ne sont plus touchés.
  static Future<void> appliquerNouveauDefautGratitude() async {
    if (_prefs?.getBool('migrationGratitudeReglable') ?? false) return;

    frequenceGratitude = frequenceHebdomadaire;
    joursGratitude = const [jourDimanche];
    heureRappelGratitude = 20;
    minuteRappelGratitude = 0;

    await _prefs?.setBool('migrationGratitudeReglable', true);
  }

  /// Bascule unique vers les jours multiples.
  ///
  /// « Tous les 2 jours » disparaît : aucune des deux plateformes ne sait
  /// répéter ce rythme, il fallait reprogrammer des occurrences à la main et
  /// le rappel s'éteignait dès que l'utilisateur n'ouvrait plus l'app. Les
  /// personnes concernées basculent sur le quotidien, le rythme le plus proche.
  static Future<void> migrerVersJoursMultiples() async {
    if (_prefs?.getBool('migrationJoursMultiples') ?? false) return;

    if (frequenceGratitude == frequenceDeuxJoursObsolete) {
      frequenceGratitude = frequenceQuotidienne;
    }
    if (frequenceSouvenirs == frequenceDeuxJoursObsolete) {
      frequenceSouvenirs = frequenceQuotidienne;
    }

    // Le jour unique enregistré par les versions précédentes devient une
    // liste d'un seul élément.
    if (_prefs?.getStringList('joursGratitude') == null) {
      joursGratitude = [_prefs?.getString('jourSemaineGratitude') ?? jourDimanche];
    }
    if (_prefs?.getStringList('joursSouvenirs') == null) {
      joursSouvenirs = [_prefs?.getString('jourSemaineSouvenirs') ?? jourLundi];
    }

    await _prefs?.setBool('migrationJoursMultiples', true);
  }

  // --- NOUVELLES MÉTHODES : GESTION DU SOUVENIR DE LA NOTIFICATION ---
  
  /// Récupère l'ID du souvenir stocké (-1 si aucun souvenir n'attend d'être affiché)
  static int getSouvenirNotificationId() {
    return _prefs?.getInt('souvenir_notif_id') ?? -1;
  }

  /// Écrit de manière asynchrone l'ID du souvenir pioché lors du clic
  static Future<void> setSouvenirNotificationId(int value) async {
    await _prefs?.setInt('souvenir_notif_id', value);
  }

  // --- PERSISTANCE DU THÈME VISUEL ---
  static String get themeId => _prefs?.getString('themeId') ?? "classique";
  static set themeId(String value) => _prefs?.setString('themeId', value);

  // --- PERSISTANCE DU STATUT PREMIUM ---
  static bool get isPremium => _prefs?.getBool('isPremium') ?? false;
  static set isPremium(bool value) => _prefs?.setBool('isPremium', value);

  // --- GAMIFICATION : PALIERS DE SOUVENIRS ---
static int get dernierPalierCelebre => _prefs?.getInt('dernierPalierCelebre') ?? 0;
static set dernierPalierCelebre(int value) => _prefs?.setInt('dernierPalierCelebre', value);

static bool get gamificationInitialisee => _prefs?.getBool('gamificationInitialisee') ?? false;
static set gamificationInitialisee(bool value) => _prefs?.setBool('gamificationInitialisee', value);

/// Nombre de souvenirs (chronologiquement, du plus ancien au plus
/// récent) déjà rangés dans un bocal précédent, fermé. Avance de
/// `capaciteBocal` à chaque fois que l'utilisateur clique "Nouveau bocal".
static int get bocalResetOffset => _prefs?.getInt('bocalResetOffset') ?? 0;
static set bocalResetOffset(int value) => _prefs?.setInt('bocalResetOffset', value);

/// Position sauvegardée de chaque bille du bocal (JSON), écrite juste
/// avant que l'app ne passe en arrière-plan ou ne se ferme. Permet de
/// restaurer exactement le même rendu au retour, plutôt que de tout
/// recalculer.
static String get positionsBocal => _prefs?.getString('positionsBocal') ?? '{}';
static set positionsBocal(String value) => _prefs?.setString('positionsBocal', value);
}
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
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

  // --- MOT DE PASSE ---------------------------------------------------------
  //
  // Le mot de passe n'est PAS conservé. On garde son empreinte SHA-256, salée
  // avec seize octets tirés au hasard à la création. Vérifier une saisie
  // consiste à la resaler et à comparer les empreintes.
  //
  // Il était auparavant écrit en clair dans les préférences : lisible sur un
  // appareil rooté, et présent tel quel dans les sauvegardes iCloud et iTunes.
  // Pour une app qui promet que rien ne sort du téléphone, c'était le maillon
  // faible.

  static const String _cleEmpreinte = 'motDePasseEmpreinte';
  static const String _cleSel = 'motDePasseSel';

  /// Ancienne clé, en clair. Conservée uniquement pour la migration.
  static const String _cleMotDePasseEnClair = 'password';

  /// Un mot de passe a-t-il été défini ?
  static bool get aUnMotDePasse =>
      (_prefs?.getString(_cleEmpreinte) ?? "").isNotEmpty;

  static String _empreinte(String motDePasse, String sel) =>
      sha256.convert(utf8.encode('$sel|$motDePasse')).toString();

  /// Enregistre [motDePasse]. Un mot de passe vide revient à en supprimer un.
  static Future<void> definirMotDePasse(String motDePasse) async {
    final String propre = motDePasse.trim();
    if (propre.isEmpty) {
      await supprimerMotDePasse();
      return;
    }

    // `Random.secure` et non `Random` : le sel doit être imprévisible.
    final Random alea = Random.secure();
    final String sel = List<int>.generate(16, (_) => alea.nextInt(256))
        .map((int octet) => octet.toRadixString(16).padLeft(2, '0'))
        .join();

    await _prefs?.setString(_cleSel, sel);
    await _prefs?.setString(_cleEmpreinte, _empreinte(propre, sel));
    await _prefs?.remove(_cleMotDePasseEnClair);
  }

  static Future<void> supprimerMotDePasse() async {
    await _prefs?.remove(_cleEmpreinte);
    await _prefs?.remove(_cleSel);
    await _prefs?.remove(_cleMotDePasseEnClair);
  }

  /// `true` si [saisie] correspond au mot de passe enregistré.
  static bool verifierMotDePasse(String saisie) {
    final String empreinte = _prefs?.getString(_cleEmpreinte) ?? "";
    final String sel = _prefs?.getString(_cleSel) ?? "";
    if (empreinte.isEmpty || sel.isEmpty) return false;
    return _empreinte(saisie.trim(), sel) == empreinte;
  }

  /// Convertit un mot de passe enregistré en clair par une version
  /// précédente. Jouée une fois au démarrage, sans effet ensuite.
  static Future<void> migrerMotDePasseEnClair() async {
    final String ancien = _prefs?.getString(_cleMotDePasseEnClair) ?? "";
    if (ancien.isEmpty) return;
    await definirMotDePasse(ancien);
  }

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
  /// Thème visuel de la HOME — le décor de fond, réglé dans
  /// Profil > Personnalisation.
  static String get themeId => _prefs?.getString('themeId') ?? "classique";
  static set themeId(String value) => _prefs?.setString('themeId', value);

  /// Thème visuel des NOTES, choisi à la baguette au moment d'écrire.
  ///
  /// Séparé de [themeId] : décorer son bocal et décorer ses post-it sont deux
  /// envies distinctes, et rien n'oblige à vouloir la même ambiance pour les
  /// deux. Sert de valeur par défaut à chaque nouvelle note — celui qui aime
  /// le thème floral le retrouve sans rien refaire, et peut y déroger d'une
  /// note à l'autre.
  static String get themeNoteId =>
      _prefs?.getString('themeNoteId') ?? "classique";
  static set themeNoteId(String value) =>
      _prefs?.setString('themeNoteId', value);

  // --- PREMIUM : UN ABONNEMENT, DONC UNE ÉCHÉANCE ---------------------------
  //
  // Ce n'est plus un booléen « acheté, donc acquis ». Un abonnement mensuel se
  // résilie : le garder en booléen reviendrait à offrir le Premium à vie à qui
  // s'abonne un mois.
  //
  // On enregistre donc une DATE LIMITE, repoussée chaque fois que la boutique
  // confirme que l'abonnement court toujours — c'est-à-dire à chaque lancement
  // de l'application avec du réseau. Entre deux confirmations,
  // [dureeGracePremium] laisse vivre quelqu'un qui voyage ou qui n'a pas de
  // réseau : personne ne perd ses décors parce qu'il a pris l'avion.
  //
  // Conséquence, et elle est voulue : une résiliation met jusqu'à deux
  // semaines à se voir. C'est le prix de l'absence de serveur, et il est
  // largement du bon côté — mieux vaut deux semaines offertes à un ancien
  // abonné qu'un abonné en règle privé de ce qu'il paie.

  static const Duration dureeGracePremium = Duration(days: 14);

  static const String _clePremiumJusquA = 'premiumJusquA';

  /// Ancien drapeau, posé par le faux achat des versions de test.
  static const String _clePremiumFactice = 'isPremium';

  /// Jusqu'à quand le Premium est acquis. `null` si jamais confirmé.
  static DateTime? get premiumJusquA {
    final int? ms = _prefs?.getInt(_clePremiumJusquA);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Le Premium est-il actif à cet instant ?
  ///
  /// Lu partout dans l'application. Reste un simple booléen pour les
  /// appelants : c'est ici, et ici seulement, que vit la notion d'échéance.
  static bool get isPremium {
    final DateTime? echeance = premiumJusquA;
    return echeance != null && echeance.isAfter(DateTime.now());
  }

  /// La boutique vient de confirmer un abonnement actif : on repousse
  /// l'échéance d'autant.
  static Future<void> confirmerPremium() async {
    await _prefs?.setInt(
      _clePremiumJusquA,
      DateTime.now().add(dureeGracePremium).millisecondsSinceEpoch,
    );
  }

  /// Retire le Premium sur-le-champ. Réservé aux tests : en usage normal,
  /// l'échéance s'éteint d'elle-même faute de confirmation.
  static Future<void> retirerPremium() async {
    await _prefs?.remove(_clePremiumJusquA);
  }

  /// Bascule unique : efface le Premium donné par l'ANCIEN FAUX ACHAT.
  ///
  /// Pendant la phase de test, le bouton « Passer Premium » écrivait
  /// `isPremium = true` sans rien facturer. Ce drapeau serait resté pour
  /// toujours sur les téléphones concernés, y compris le tien. On l'efface une
  /// bonne fois : les vrais abonnés, eux, sont reconnus au lancement suivant
  /// par la boutique elle-même (voir AchatService.verifierAbonnement).
  static Future<void> migrerPremiumFactice() async {
    if (_prefs?.getBool(_clePremiumFactice) == null) return;
    await _prefs?.remove(_clePremiumFactice);
  }

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

  /// Remet à zéro tout ce qui décrit le contenu du bocal, après un
  /// effacement complet des souvenirs.
  ///
  /// Sans cela, l'app garderait le décompte des paliers déjà célébrés, les
  /// positions de billes disparues et le décalage des bocaux précédents :
  /// l'utilisateur repartirait d'un bocal vide, mais avec la mémoire de
  /// l'ancien.
  static Future<void> reinitialiserApresEffacement() async {
    await _prefs?.setInt('bocalResetOffset', 0);
    await _prefs?.setString('positionsBocal', '{}');
    await _prefs?.setInt('dernierPalierCelebre', 0);
    await _prefs?.setBool('gamificationInitialisee', false);
    await _prefs?.setInt('souvenir_notif_id', -1);
  }
}
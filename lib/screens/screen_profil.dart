import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/l10n/langues.dart';
import 'package:sourire/main.dart';
import 'package:sourire/screens/screen_choix_themes.dart';
import 'package:sourire/screens/screen_template_reglages.dart';
import 'package:sourire/services/biometric_service.dart';
import 'package:sourire/services/notifications_service.dart';
import 'package:sourire/services/sauvegarde_service.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/widgets/btn_chevron_droite.dart';   
import 'package:sourire/widgets/switch_biometrie.dart';    
import 'package:sourire/widgets/switch_password.dart';
import 'package:sourire/widgets/widget_radio_langue.dart';  
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/widgets/widget_switch.dart';
import 'package:sourire/services/stockage_service.dart';
import 'package:sourire/services/database_service.dart';  
import 'package:sourire/screens/screen_mes_badges.dart';
import 'package:sourire/screens/screen_reset_password.dart'; 

class ScreenProfil extends StatefulWidget {
  const ScreenProfil({super.key});
  // Déclaration globale de l'état de l'autorisation (accessible depuis la Home)
  static bool accesGalerieActive = true;
  
  /// Réglage « Animations douces ».
  ///
  /// C'est un notifier et non un simple booléen : l'écran d'accessibilité est
  /// poussé sur une route à part, qui ne se reconstruit pas quand le profil
  /// appelle son propre setState. Avant, le seul moyen de faire bouger la case
  /// du switch était de forcer un rebuild global via
  /// `MyApp.themeNotifier.notifyListeners()` — une API protégée par Flutter.
  static final ValueNotifier<bool> animationsDoucesNotifier =
      ValueNotifier<bool>(false);

  /// Raccourci de lecture, pour les appelants qui n'ont pas besoin d'écouter.
  static bool get animationsDoucesActive => animationsDoucesNotifier.value;
  @override
  State<ScreenProfil> createState() => _ScreenProfilState();
}

class _ScreenProfilState extends State<ScreenProfil> {
  // Déclaration des contrôleurs et états locaux
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late bool _biometrieActive; // Initialisé dans le initState
  // --- ÉTATS DES NOTIFICATIONS ---
  String _taillePhotos = "Calcul...";
  String _tailleNotes = "Calcul...";
  // Instance pour la récupération dynamique des catégories
  final DatabaseService _databaseService = DatabaseService();


  @override
  void initState() {
    super.initState();
    
    // 1. Remplissage et nettoyage du Prénom (Met la première lettre en majuscule dès le départ)
    // Plus de valeur de repli codée en dur : un champ vide vaut mieux que le
    // prénom ou l'email de quelqu'un d'autre affiché à un nouvel utilisateur.
    final String prenomBrut = UserPrefs.prenom.trim();
    _prenomController.text = prenomBrut.isEmpty
        ? ""
        : prenomBrut[0].toUpperCase() + prenomBrut.substring(1).toLowerCase();

    // 2. Remplissage de l'email
    _emailController.text = UserPrefs.email.trim();

    // 3. Initialisation du mot de passe en mode masqué
    _passwordController.text = "••••••••••••";

    // 4. Synchronisation de la biométrie avec l'onboarding
    _biometrieActive = UserPrefs.biomatrieActive;


    // Sauvegarde le prénom en temps réel dans les préférences de l'appareil dès que l'utilisateur tape dedans
    _prenomController.addListener(() {
      UserPrefs.prenom = _prenomController.text.trim();
    });

    // Idem pour l'email, désormais modifiable.
    _emailController.addListener(() {
      UserPrefs.email = _emailController.text.trim();
    });
    
    _calculerEspaceOccupe(); // Lance le calcul réel
  }

  // Nouvelle méthode de l'écran qui appelle ton service externe
  Future<void> _calculerEspaceOccupe() async {
    Map<String, String> tailles = await StockageService.calculerEspaceOccupe();
    setState(() {
      _taillePhotos = tailles['photos'] ?? '0';
      _tailleNotes = tailles['notes'] ?? '0';
    });
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  void _afficherAlerteGalerie(BuildContext context, VoidCallback onConfirmer, bool currentIsDark) {
    final localizations = AppLocalizations.of(context);
    final Color couleurTextePopup = currentIsDark ? white : black;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          // Surface d'écran : le même blanc chaud que la home. Le blanc pur
          // reste réservé à ce qui PORTE des souvenirs (volet historique,
          // vignettes), pour que les couleurs de note s'en détachent.
          backgroundColor: currentIsDark ? darkBg : lightOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations?.alertWarningTitle ?? "Attention",
                      style: styleTitreAction.copyWith(color: couleurTextePopup),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  localizations?.profilAlertGalleryMessage ?? "Attention, si tu décides de supprimer l'accès à ta galerie photo, tu ne pourras plus enregistrer de photos dans tes souvenirs.",
                  style: styleSecondaire.copyWith(color: texteDoux(currentIsDark)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      onConfirmer();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      localizations?.profilAlertBtnDisable ?? "Désactiver l'accès",
                      style: styleCorps.copyWith(color: white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCategoryDisplayLabel(String key) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return key;

    switch (key) {
      case "all_categories":
        return localizations.notifAllCategories;
      case "self_love":
        return localizations.catSelfLove;
      case "friendship":
        return localizations.catFriendship;
      case "couple":
        return localizations.catCouple;
      case "family":
        return localizations.catFamily;
      case "leisure":
        return localizations.catLeisure;
      case "work":
        return localizations.catWork;
      case "unclassified": 
        return localizations.catUnclassified;
      default:
        return key;
    }
  }

  /// Sélecteur d'heure adapté à la plateforme.
  ///
  /// Le cadran Material est déroutant sur iPhone, où l'on attend des rouleaux.
  /// On garde donc `showTimePicker` sur Android et on présente un
  /// `CupertinoDatePicker` sur iOS, avec les mêmes entrées et la même sortie.
  Future<TimeOfDay?> _choisirHeure(
    BuildContext context,
    TimeOfDay initiale,
    bool isDark,
  ) async {
    final localizations = AppLocalizations.of(context);
    final bool format24h = MediaQuery.of(context).alwaysUse24HourFormat;

    if (Platform.isIOS) {
      TimeOfDay choisie = initiale;

      final bool? valide = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: isDark ? darkSurface : white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: SizedBox(
              height: 300,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          localizations?.btnCancel ?? "Annuler",
                          style: TextStyle(color: isDark ? lightGrey : grey),
                        ),
                      ),
                      CupertinoButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          localizations?.btnValidate ?? "Valider",
                          style: const TextStyle(
                            color: orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: isDark ? Brightness.dark : Brightness.light,
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: format24h,
                        initialDateTime: DateTime(
                          2000, 1, 1, initiale.hour, initiale.minute,
                        ),
                        onDateTimeChanged: (DateTime valeur) {
                          choisie = TimeOfDay(
                            hour: valeur.hour,
                            minute: valeur.minute,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      return valide == true ? choisie : null;
    }

    if (!context.mounted) return null;
    return showTimePicker(
      context: context,
      initialTime: initiale,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: orange,
              onPrimary: white,
              surface: isDark ? const Color(0xFF1E1E1E) : white,
              onSurface: isDark ? white : black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: orange),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  String _getFrequencyDisplayLabel(String key) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return key;

    switch (key) {
      case "Tous les jours":
        return localizations.notifFreqEveryDay;
      case "Toutes les semaines":
        return localizations.notifFreqEveryWeek;
      default:
        return key;
    }
  }

  String _getDayDisplayLabel(String key) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return key;

    switch (key) {
      case "Lundi":
        return localizations.notifDayMonday;
      case "Mardi":
        return localizations.notifDayTuesday;
      case "Mercredi":
        return localizations.notifDayWednesday;
      case "Jeudi":
        return localizations.notifDayThursday;
      case "Vendredi":
        return localizations.notifDayFriday;
      case "Samedi":
        return localizations.notifDaySaturday;
      case "Dimanche":
        return localizations.notifDaySunday;
      default:
        return key;
    }
  }

  @override
Widget build(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  // On branche l'écran complet sur le notifier global du thème
  return ValueListenableBuilder<ThemeMode>(
    valueListenable: MyApp.themeNotifier,
    builder: (context, currentMode, _) {
      // LOGIQUE CORRIGÉE : Si on est en "system", on regarde le téléphone, sinon on suit le choix forcé (clair ou sombre)
      final bool isDark = currentMode == ThemeMode.system
          ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
          : (currentMode == ThemeMode.dark);
      
      // Surface d'écran : le blanc chaud de la home. Le blanc pur reste
      // réservé à ce qui PORTE des souvenirs — volet historique et vignettes.
      final Color couleurFond = isDark ? const Color(0xFF121212) : lightOrange;
      final Color couleurHeaderEtConteneur = isDark ? const Color(0xFF1E1E1E) : lightOrange;
      final Color couleurTextePrincipal = isDark ? white : black;
      // Champ blanc sur fond chaud : il se lit comme creusé dans la page.
      // L'ancien gris F5F5F5 tirait au froid contre le lightOrange.
      final Color couleurInputFond = isDark ? const Color(0xFF2A2A2A) : white;
      final Color couleurSeparateur = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEEEEEE);

      return Scaffold(
          backgroundColor: couleurFond,
          body: SafeArea(
            child: Column(
              children: [
                //  HEADER FIXE
                Container(
                  color: couleurHeaderEtConteneur,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        child: BtnChevronGauche(
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      const LogoSourire(color: orange),
                    ],
                  ),
                ),
                //  CONTENU SCROLLABLE
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 30, right: 30, top: 20, bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- SECTION 1 : DONNÉES PERSONNELLES ---
                        Text(
                          localizations?.personalData ?? "Données personnelles",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: couleurTextePrincipal,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: localizations?.firstName ?? "Prénom",
                          controller: _prenomController,
                          readOnly: false,
                          couleurInputFond: couleurInputFond,
                          couleurTextePrincipal: couleurTextePrincipal,
                        ),
                        const SizedBox(height: 16),
                        _buildGenreField(
                          localizations: localizations,
                          couleurInputFond: couleurInputFond,
                          couleurTextePrincipal: couleurTextePrincipal,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: localizations?.email ?? "Email",
                          controller: _emailController,
                          readOnly: false,
                          couleurInputFond: couleurInputFond,
                          couleurTextePrincipal: couleurTextePrincipal,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                localizations?.password ?? "Mot de passe",
                                style: styleCorps.copyWith(color: grey),
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: couleurInputFond,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _passwordController,
                                        readOnly: true,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(color: grey, fontSize: 15),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    SwitchPassword(
                                      isPasswordVisible: !_obscurePassword,
                                      onToggle: (bool isVisible) {
                                        setState(() {
                                          _obscurePassword = !isVisible;
                                          final String mdpReel = UserPrefs.password.isEmpty ? "••••••••" : UserPrefs.password;
                                          _passwordController.text = _obscurePassword ? "••••••••••••" : mdpReel;
                                        });
                                      },
                                    ),
                                    // Le mot de passe ne se modifie pas au clavier
                                    // ici : on passe par l'écran dédié, qui
                                    // impose la double saisie.
                                    GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ScreenResetPassword(),
                                          ),
                                        );
                                        if (!mounted) return;
                                        setState(() {
                                          _obscurePassword = true;
                                          _passwordController.text = "••••••••••••";
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 12),
                                        child: Icon(Icons.edit_outlined, color: orange, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localizations?.biometrics ?? "Biométrie",
                              style: const TextStyle(fontSize: 16, color: grey, fontWeight: FontWeight.w500),
                            ),
                            SwitchBiometrie(
                              initialValue: _biometrieActive,
                              onChanged: (bool val) async {
                                if (val) {
                                  bool succes = await BiometricService.authentifier();
                                  setState(() {
                                    _biometrieActive = succes;
                                    UserPrefs.biomatrieActive = succes;
                                  });
                                } else {
                                  setState(() {
                                    _biometrieActive = false;
                                    UserPrefs.biomatrieActive = false;
                                  });
                                }
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),
                        Divider(height: 1, color: couleurSeparateur),
                        const SizedBox(height: 30),
                        // --- SECTION 2 : PARAMÈTRES DU COMPTE ---
                        Text(
                          localizations?.accountSettings ?? "Paramètres du compte",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: couleurTextePrincipal,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 1. PERSONNALISATION (thèmes visuels)
                    // Auparavant enfouie dans Apparence > Thèmes : les testeurs
                    // ne la trouvaient pas. Elle est maintenant au premier niveau.
                    _buildMenuRow(
                      icon: Icons.auto_fix_high,
                      title: localizations?.personalization ?? "Personnalisation",
                      couleurTextePrincipal: couleurTextePrincipal,
                      onTap: () {
                        final ThemeMode currentMode = MyApp.themeNotifier.value;
                        final bool isDarkPerso = currentMode == ThemeMode.system
                            ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
                            : (currentMode == ThemeMode.dark);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScreenChoixThemes(isDarkMode: isDarkPerso),
                          ),
                        );
                      },
                    ),

                    // 2. NOTIFICATIONS
_buildMenuRow(
  icon: Icons.notifications_none_outlined,
  title: localizations?.notifications ?? "Notifications",
  couleurTextePrincipal: couleurTextePrincipal,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setLocalState) => ScreenTemplateReglages(
            isDarkMode: isDark,
            titre: localizations?.notifications ?? "Notifications",
            content: [
              // --- SWITCH 1 : GRATITUDE ---
              _buildRowWithSwitch(
                localizations?.notifLabelTitleGratitude ?? "Rappel de gratitude",
                localizations?.notifLabelSubGratitude ?? "Me rappeler de noter un souvenir positif",
                UserPrefs.rappelGratitudeActive, 
                isDark: isDark,
                (val) async {
                  UserPrefs.rappelGratitudeActive = val;
                  setLocalState(() {}); 
                  await NotificationService.planifierRappelGratitude();
                },
              ),
              
              if (UserPrefs.rappelGratitudeActive) ...[
                const SizedBox(height: 10),
                // HARMONISATION : Suit la couleur du switch
                Text(
                  localizations?.notifLabelTime ?? "Heure du rappel", 
                  style: styleSecondaire.copyWith(color: texteDoux(isDark))
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final TimeOfDay? picked = await _choisirHeure(
                      context,
                      TimeOfDay(
                        hour: UserPrefs.heureRappelGratitude,
                        minute: UserPrefs.minuteRappelGratitude,
                      ),
                      isDark,
                    );
                    if (picked != null) {
                      UserPrefs.heureRappelGratitude = picked.hour;
                      UserPrefs.minuteRappelGratitude = picked.minute;
                      setLocalState(() {});
                      await NotificationService.planifierRappelGratitude();
                    }
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: couleurInputFond,
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Center(
                      child: Text(
                        "${UserPrefs.heureRappelGratitude.toString().padLeft(2, '0')}:${UserPrefs.minuteRappelGratitude.toString().padLeft(2, '0')}",
                        style: TextStyle(fontWeight: FontWeight.bold, color: couleurTextePrincipal)
                      )
                    ),
                  ),
                ),

                // FRÉQUENCE DU RAPPEL DE GRATITUDE
                const SizedBox(height: 16),
                Text(
                  localizations?.notifLabelFreqSettings ?? "Réglages de la fréquence",
                  style: styleSecondaire.copyWith(color: texteDoux(isDark))
                ),
                const SizedBox(height: 10),
                _buildDropdownButton<String>(
                  value: UserPrefs.frequenceGratitude,
                  items: const [
                    UserPrefs.frequenceQuotidienne,
                    UserPrefs.frequenceHebdomadaire,
                  ],
                  isDark: isDark,
                  itemTranslator: _getFrequencyDisplayLabel,
                  onChanged: (val) async {
                    if (val != null) {
                      UserPrefs.frequenceGratitude = val;
                      setLocalState(() {});
                      await NotificationService.planifierRappelGratitude();
                    }
                  },
                ),

                // JOUR DE LA SEMAINE (uniquement en hebdomadaire)
                if (UserPrefs.frequenceGratitude == UserPrefs.frequenceHebdomadaire) ...[
                  const SizedBox(height: 12),
                  Text(
                    localizations?.notifLabelDayOfWeek ?? "Jours de la semaine",
                    style: styleSecondaire.copyWith(color: texteDoux(isDark))
                  ),
                  const SizedBox(height: 8),
                  _buildSelecteurJours(
                    joursCoches: UserPrefs.joursGratitude,
                    isDark: isDark,
                    onChanged: (jours) async {
                      UserPrefs.joursGratitude = jours;
                      setLocalState(() {});
                      await NotificationService.planifierRappelGratitude();
                    },
                  ),
                ],
              ],
              const SizedBox(height: 25),
              Divider(color: couleurSeparateur),
              const SizedBox(height: 15),

              // --- SWITCH 2 : SOUVENIRS ---
              _buildRowWithSwitch(
                localizations?.notifLabelTitleSouvenirs ?? "Fréquence des souvenirs tirés",
                localizations?.notifLabelSubSouvenirs ?? "Me proposer un vieux souvenir à revoir",
                UserPrefs.rappelSouvenirsActive, 
                isDark: isDark,
                (val) async {
                  UserPrefs.rappelSouvenirsActive = val;
                  setLocalState(() {});
                  await NotificationService.planifierRappelSouvenirs();
                }
              ),
              
              if (UserPrefs.rappelSouvenirsActive) ...[
                const SizedBox(height: 10),
                // HARMONISATION : Suit la couleur du switch
                Text(
                  localizations?.notifLabelTime ?? "Heure du rappel", 
                  style: styleSecondaire.copyWith(color: texteDoux(isDark))
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final TimeOfDay? picked = await _choisirHeure(
                      context,
                      TimeOfDay(
                        hour: UserPrefs.heureRappelSouvenirs,
                        minute: UserPrefs.minuteRappelSouvenirs,
                      ),
                      isDark,
                    );
                    if (picked != null) {
                      UserPrefs.heureRappelSouvenirs = picked.hour;
                      UserPrefs.minuteRappelSouvenirs = picked.minute;
                      setLocalState(() {});
                      await NotificationService.planifierRappelSouvenirs();
                    }
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: couleurInputFond,
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Center(
                      child: Text(
                        "${UserPrefs.heureRappelSouvenirs.toString().padLeft(2, '0')}:${UserPrefs.minuteRappelSouvenirs.toString().padLeft(2, '0')}",
                        style: TextStyle(fontWeight: FontWeight.bold, color: couleurTextePrincipal)
                      )
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // HARMONISATION : Suit la couleur du switch
                Text(
                  localizations?.notifLabelFreqSettings ?? "Réglages de la fréquence", 
                  style: styleSecondaire.copyWith(color: texteDoux(isDark))
                ),
                const SizedBox(height: 10),
                _buildDropdownButton<String>(
                  value: UserPrefs.frequenceSouvenirs,
                  items: const [
                    UserPrefs.frequenceQuotidienne,
                    UserPrefs.frequenceHebdomadaire,
                  ],
                  isDark: isDark,
                  itemTranslator: _getFrequencyDisplayLabel,
                  onChanged: (val) async {
                    if (val != null) {
                      UserPrefs.frequenceSouvenirs = val;
                      setLocalState(() {});
                      await NotificationService.planifierRappelSouvenirs();
                    }
                  },
                ),
                if (UserPrefs.frequenceSouvenirs == UserPrefs.frequenceHebdomadaire) ...[
                  const SizedBox(height: 12),
                  Text(
                    localizations?.notifLabelDayOfWeek ?? "Jours de la semaine",
                    style: styleSecondaire.copyWith(color: texteDoux(isDark))
                  ),
                  const SizedBox(height: 8),
                  _buildSelecteurJours(
                    joursCoches: UserPrefs.joursSouvenirs,
                    isDark: isDark,
                    onChanged: (jours) async {
                      UserPrefs.joursSouvenirs = jours;
                      setLocalState(() {});
                      await NotificationService.planifierRappelSouvenirs();
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // HARMONISATION : Suit la couleur du switch
                Text(
                  localizations?.notifLabelCategoriesIncluded ?? "Catégories incluses",
                  style: styleSecondaire.copyWith(color: texteDoux(isDark))
                ),
                const SizedBox(height: 8),

                StreamBuilder<List<String>>(
                  stream: _databaseService.getCategoriesStream(),
                  builder: (context, snapshot) {
                    final List<String> categoriesBDD = snapshot.data ?? [];
                    final List<String> optionsMenu = ["all_categories", "unclassified", ...categoriesBDD];
                    List<String> categoriesSelectionnees = List.from(UserPrefs.categoriesSouvenirs);
                    
                    if (snapshot.hasData) {
                      categoriesSelectionnees.removeWhere((cat) => 
                        cat != "all_categories" && 
                        cat != "unclassified" && 
                        !categoriesBDD.contains(cat)
                      );
                      
                      if (categoriesSelectionnees.isEmpty) {
                        categoriesSelectionnees = ["all_categories"];
                        UserPrefs.categoriesSouvenirs = categoriesSelectionnees;
                      }
                    }

                    for (var cat in categoriesSelectionnees) {
                      if (!optionsMenu.contains(cat)) {
                        optionsMenu.add(cat);
                      }
                    }

                    return _buildMultiSelectDropdownButton(
                      selectedValues: categoriesSelectionnees,
                      items: optionsMenu,
                      isDark: isDark,
                      itemTranslator: _getCategoryDisplayLabel,
                      menuMaxHeight: 240.0,
                      onChanged: (List<String> nouvellesValeurs) async {
                        UserPrefs.categoriesSouvenirs = nouvellesValeurs;
                        setLocalState(() {});
                        await NotificationService.planifierRappelSouvenirs();
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  },
),

                    // 3. AUTORISATIONS
                    _buildMenuRow(
                      icon: Icons.lock_open_outlined,
                      title: localizations?.permissions ?? "Autorisations",
                      couleurTextePrincipal: couleurTextePrincipal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StatefulBuilder(
                              builder: (context, setLocalState) => ScreenTemplateReglages(
                                isDarkMode: isDark,
                                titre: localizations?.permissions ?? "Autorisations",
                                content: [
                                  _buildRowWithSwitch(
                                    localizations?.photoGalleryAccess ?? "Accès à la galerie photo",
                                    localizations?.photoGallerySubtitle ?? "Indispensable pour ajouter des photos de tes moments précieux.",
                                    ScreenProfil.accesGalerieActive,
                                    isDark: isDark,
                                    (val) {
                                      if (val == false) {
                                        _afficherAlerteGalerie(context, () {
                                          setState(() => ScreenProfil.accesGalerieActive = false);
                                          setLocalState(() {});
                                        }, isDark);
                                      } else {
                                        setState(() => ScreenProfil.accesGalerieActive = true);
                                        setLocalState(() {});
                                      }
                                    }
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // 3. ARCHIVAGE
                    _buildMenuRow(
                      icon: Icons.inventory_2_outlined,
                      title: localizations?.archiving ?? "Archivage",
                      couleurTextePrincipal: couleurTextePrincipal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StatefulBuilder(
                              builder: (context, setLocalState) => ScreenTemplateReglages(
                                isDarkMode: isDark,
                                titre: localizations?.archiving ?? "Archivage",
                                content: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildRowReglageText(
                                          localizations?.secureLocalStorage ?? "Stockage local sécurisé",
                                          localizations?.secureStorageSubtitle ?? "Tes souvenirs sont automatiquement sauvegardés localement sur ton espace de stockage privé.",
                                          isDark: isDark,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        localizations?.active ?? "Actif",
                                        style: const TextStyle(
                                          color: orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    localizations?.spaceOccupied ?? "Espace occupé",
                                    style: TextStyle(color: couleurTextePrincipal, fontWeight: FontWeight.w500, fontSize: 16)
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: couleurInputFond,
                                      borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.storage, color: grey, size: 20),
                                        const SizedBox(width: 10),
                                        Text(
                                          localizations?.storageCounter(_taillePhotos, _tailleNotes) ?? "Photos : $_taillePhotos  |  Notes : $_tailleNotes",
                                          style: const TextStyle(color: grey, fontSize: 13, fontWeight: FontWeight.w600)
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 30),
                                  _buildActionSauvegarde(
                                    icone: Icons.file_download_outlined,
                                    titre: localizations?.backupExportTitle ?? "Exporter mes souvenirs",
                                    sousTitre: localizations?.backupExportSub ?? "",
                                    isDark: isDark,
                                    onTap: _exporterSauvegarde,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildActionSauvegarde(
                                    icone: Icons.file_upload_outlined,
                                    titre: localizations?.backupImportTitle ?? "Restaurer une sauvegarde",
                                    sousTitre: localizations?.backupImportSub ?? "",
                                    isDark: isDark,
                                    onTap: () async {
                                      await _importerSauvegarde();
                                      setLocalState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  // Ramène les six catégories par défaut que
                                  // l'utilisateur aurait supprimées. Action non
                                  // destructive : elle ne fait que lever les
                                  // masquages, aucun souvenir n'est touché.
                                  // Recréer « Famille » à la main donnerait une
                                  // catégorie en texte brut, qui resterait
                                  // française même en anglais — d'où ce bouton.
                                  _buildActionSauvegarde(
                                    icone: Icons.label_outline,
                                    titre: localizations?.restoreDefaultCategoriesTitle
                                        ?? "Restaurer les catégories par défaut",
                                    sousTitre: localizations?.restoreDefaultCategoriesSub ?? "",
                                    isDark: isDark,
                                    onTap: () async {
                                      await _databaseService.restaurerCategoriesParDefaut();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            localizations?.restoreDefaultCategoriesDone
                                                ?? "Catégories par défaut restaurées.",
                                          ),
                                          backgroundColor: orange,
                                        ),
                                      );
                                      setLocalState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // 4. APPARENCE
                    _buildMenuRow(
                      icon: Icons.accessibility_new_outlined,
                      title: localizations?.accessibility ?? "Accessibilité",
                      couleurTextePrincipal: couleurTextePrincipal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return ValueListenableBuilder<ThemeMode>(
                                valueListenable: MyApp.themeNotifier,
                                builder: (context, currentMode, _) {
                                  // Si aucun forçage temporaire n'est configuré (ThemeMode.system), on regarde la luminosité du système
                                  final bool localIsDark = currentMode == ThemeMode.system
                                      ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
                                      : (currentMode == ThemeMode.dark);
                                  
                                  return ScreenTemplateReglages(
                                    isDarkMode: localIsDark,
                                    titre: localizations?.accessibility ?? "Accessibilité",
                                    content: [
                                      // MODE SOMBRE (Version session temporaire)
                                      _buildRowWithSwitch(
                                        localizations?.darkMode ?? "Mode sombre",
                                        localizations?.darkModeSubtitle ?? "Bascule l'interface dans des tons sombres pour reposer tes yeux le soir.",
                                        localIsDark,
                                        isDark: localIsDark,
                                        (val) {
                                          // On met directement à jour le notificateur global du MaterialApp
                                          MyApp.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                                          
                                          // On force la page actuelle à se redessiner avec la nouvelle valeur de localIsDark
                                          setState(() {});
                                        }
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // ANIMATIONS DOUCES
                                      // Le switch s'abonne au notifier : c'est
                                      // lui qui redessine la case, sans passer
                                      // par un rebuild global forcé.
                                      ValueListenableBuilder<bool>(
                                        valueListenable: ScreenProfil.animationsDoucesNotifier,
                                        builder: (context, doucesActives, _) {
                                          return _buildRowWithSwitch(
                                            localizations?.smoothAnimations ?? "Animations douces",
                                            localizations?.smoothAnimationsSubtitle ?? "Remplace l'effet tornade du bocal par une apparition en fondu plus légère.",
                                            doucesActives,
                                            isDark: localIsDark,
                                            (val) {
                                              ScreenProfil.animationsDoucesNotifier.value = val;
                                            },
                                          );
                                        },
                                      ),

                                      // Les thèmes ont quitté cette section :
                                      // ils sont désormais accessibles depuis
                                      // Profil > Personnalisation.
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),

                    // 5. LANGUES
_buildMenuRow(
  icon: Icons.chat_bubble_outline_rounded,
  title: localizations?.langues ?? "Langues",
  couleurTextePrincipal: couleurTextePrincipal,
  onTap: () {
    String langueSelectionnee = UserPrefs.langue;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ValueListenableBuilder<Locale>(
          valueListenable: MyApp.localeNotifier,
          builder: (context, currentLocale, _) {
            final localLocalizations = AppLocalizations.of(context);
            
            return ScreenTemplateReglages(
              isDarkMode: isDark,
              titre: localLocalizations?.langues ?? "Langues",
              // Une ligne par langue du catalogue. Le libellé vient de
              // `langue.nom` et non des traductions : chaque langue s'écrit
              // dans sa propre langue, sinon quelqu'un qui a mis l'app en
              // espagnol par erreur ne saurait plus retrouver la sienne.
              content: <Widget>[
                for (final LangueApp langue in Langues.toutes) ...<Widget>[
                  WidgetRadioLangue(
                    label: langue.nom,
                    isSelected: langueSelectionnee == langue.code,
                    onTap: () async {
                      langueSelectionnee = langue.code;
                      await UserPrefs.setLangue(langue.code);
                      MyApp.localeNotifier.value = langue.locale;

                      // Les notifications sont programmées côté OS avec leur
                      // texte figé : sans reprogrammation, elles arriveraient
                      // encore dans l'ancienne langue.
                      await NotificationService.planifierRappelGratitude();
                      await NotificationService.planifierRappelSouvenirs();
                    },
                  ),
                  if (langue != Langues.toutes.last) const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  },
),

                    // 6. AIDE
                    _buildMenuRow(
                      icon: Icons.help_outline_rounded,
                      title: localizations?.help ?? "Aide",
                      couleurTextePrincipal: couleurTextePrincipal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScreenTemplateReglages(
                              isDarkMode: isDark,
                              titre: localizations?.helpFaq ?? "Aide / FAQ",
                              content: [
                                _buildFAQItem(
                                  localizations?.faqQuestion1 ?? "Où sont stockés mes souvenirs ?", 
                                  localizations?.faqAnswer1 ?? "Ils restent localement dans le dossier sécurisé de ton téléphone, personne d'autre n'y a accès.", 
                                  isDark
                                ),
                                _buildFAQItem(
                                  localizations?.faqQuestion2 ?? "Comment fonctionne le tirage au sort ?",
                                  // La secousse n'a jamais été branchée : la
                                  // réponse promettait un geste qui ne marche
                                  // pas.
                                  localizations?.faqAnswer2 ?? "Clique sur le bocal pour faire remonter un souvenir au hasard.",
                                  isDark
                                ),
                                _buildFAQItem(
                                  localizations?.faqQuestion3 ?? "Comment catégoriser des souvenirs ?",
                                  localizations?.faqAnswer3 ?? "Va dans l'historique et appuie longuement sur un souvenir. Tu pourras alors en sélectionner plusieurs et choisir 'Catégoriser'.",
                                  isDark
                                ),
                                // Juste après la catégorisation par lot : c'est
                                // en la découvrant qu'on se demande comment
                                // faire autrement.
                                _buildFAQItem(
                                  localizations?.faqQuestion5 ?? "Comment catégoriser mes souvenirs un par un ?",
                                  localizations?.faqAnswer5 ?? "Pour catégoriser tes souvenirs un par un, tu as 2 options :\n1- Importe tes souvenirs un par un.\n2- Depuis l'écran de catégorisation du lot de souvenirs sélectionnés, clique sur la photo qui porte la pastille : un carrousel de tes souvenirs apparaît, avec l'option « Catégoriser 1 par 1 ».",
                                  isDark
                                ),
                                // Les catégories avant les souvenirs : on
                                // regroupe ce qui parle de rangement, et la
                                // suppression des souvenirs reste en dernier.
                                _buildFAQItem(
                                  localizations?.faqQuestion6 ?? "Comment supprimer des catégories de souvenirs ?",
                                  localizations?.faqAnswer6 ?? "Dans l'écran de sélection des catégories, fais glisser la catégorie que tu veux supprimer vers la gauche.",
                                  isDark
                                ),
                                _buildFAQItem(
                                  localizations?.faqQuestion4 ?? "Comment supprimer des souvenirs ?", 
                                  localizations?.faqAnswer4 ?? "Va dans l'historique, fais un appui long sur le souvenir, sélectionne-le et appuie sur le bouton 'Supprimer'.", 
                                  isDark
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
const SizedBox(height: 25),
Divider(height: 1, color: couleurSeparateur),
const SizedBox(height: 30),
// --- SECTION 3 : RÉCOMPENSES ---
Text(
  localizations?.rewardsSectionTitle ?? "Récompenses",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: couleurTextePrincipal,
  ),
),
const SizedBox(height: 15),
_buildMenuRow(
  icon: Icons.emoji_events_outlined,
  title: localizations?.myBadgesTitle ?? "Mes badges",
  couleurTextePrincipal: couleurTextePrincipal,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenMesBadges(isDarkMode: isDark),
      ),
    );
  },
),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: couleurSeparateur),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool readOnly,
    required Color couleurInputFond,
    required Color couleurTextePrincipal,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: styleCorps.copyWith(color: grey),
          ),
        ),
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: couleurInputFond,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: readOnly,
                    style: TextStyle(
                      color: readOnly ? grey : couleurTextePrincipal,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Sélecteur de genre, aligné visuellement sur [_buildInputField].
  ///
  /// Le genre n'était réglable qu'à l'onboarding alors qu'il pilote l'accord
  /// de « heureux » dans toute l'app. Il est stocké sous forme de code
  /// ('h' / 'f' / 'n') et non du libellé traduit, pour que l'accord survive à
  /// un changement de langue.
  Widget _buildGenreField({
    required AppLocalizations? localizations,
    required Color couleurInputFond,
    required Color couleurTextePrincipal,
  }) {
    final Map<String, String> libelles = {
      UserPrefs.genreMasculin: localizations?.onboardingGenderMale ?? "Un homme",
      UserPrefs.genreFeminin: localizations?.onboardingGenderFemale ?? "Une femme",
      UserPrefs.genreNeutre: localizations?.onboardingGenderNone ?? "Aucun",
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            localizations?.gender ?? "Genre",
            style: styleCorps.copyWith(color: grey),
          ),
        ),
        Expanded(
          child: Container(
            height: 44,
            // Même retrait que _buildInputField : le libellé du genre doit
            // s'aligner exactement sur le prénom et l'email.
            padding: const EdgeInsets.only(left: 16, right: 8),
            decoration: BoxDecoration(
              color: couleurInputFond,
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: UserPrefs.codeGenre,
                isExpanded: true,
                isDense: true,
                dropdownColor: couleurInputFond,
                icon: Icon(Icons.arrow_drop_down, color: couleurTextePrincipal),
                style: TextStyle(color: couleurTextePrincipal, fontSize: 15),
                items: libelles.entries
                    .map((e) => DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: TextStyle(color: couleurTextePrincipal, fontSize: 15),
                          ),
                        ))
                    .toList(),
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() {
                    UserPrefs.codeGenre = value;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Rangée de sept pastilles cochables (L M M J V S D).
  ///
  /// Un menu déroulant multi-sélection serait pénible pour sept jours qu'on
  /// veut cocher d'un geste. On empêche de tout décocher : un rappel
  /// hebdomadaire actif sans aucun jour serait un réglage qui ne sonne jamais.
  Widget _buildSelecteurJours({
    required List<String> joursCoches,
    required bool isDark,
    required Future<void> Function(List<String>) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: UserPrefs.joursSemaine.map((String jour) {
        final bool coche = joursCoches.contains(jour);
        final String libelle = _getDayDisplayLabel(jour);
        final String initiale = libelle.isEmpty ? "?" : libelle[0].toUpperCase();

        return Semantics(
          label: libelle,
          selected: coche,
          button: true,
          child: GestureDetector(
            onTap: () {
              final List<String> maj = List<String>.from(joursCoches);
              if (coche) {
                if (maj.length == 1) return; // jamais zéro jour coché
                maj.remove(jour);
              } else {
                maj.add(jour);
              }
              // Réordonné du lundi au dimanche : l'ordre de stockage ne doit
              // pas dépendre de l'ordre des clics.
              maj.sort((a, b) => UserPrefs.joursSemaine
                  .indexOf(a)
                  .compareTo(UserPrefs.joursSemaine.indexOf(b)));
              onChanged(maj);
            },
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: coche ? orange : Colors.transparent,
                // Toujours orange : coché, la pastille est pleine ; décochée,
                // elle n'est plus qu'un contour. C'est le remplissage qui dit
                // l'état, pas un passage au gris.
                border: Border.all(color: orange, width: 1.5),
              ),
              child: Text(
                initiale,
                style: TextStyle(
                  color: coche ? white : orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Fabrique l'archive de sauvegarde et la remet à la feuille de partage.
  Future<void> _exporterSauvegarde() async {
    final l10n = AppLocalizations.of(context);

    final RenderBox? boite = context.findRenderObject() as RenderBox?;
    final Rect? origineIpad = boite != null && boite.hasSize
        ? boite.localToGlobal(Offset.zero) & boite.size
        : null;

    final bool succes = await SauvegardeService.exporter(origineIpad: origineIpad);

    if (!succes && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.backupExportError ?? "L'export n'a pas pu aboutir."),
        ),
      );
    }
  }

  /// Restaure une archive. L'opération est additive : rien n'est supprimé.
  Future<void> _importerSauvegarde() async {
    final l10n = AppLocalizations.of(context);
    final ResultatImport? resultat = await SauvegardeService.importer();

    // null = l'utilisateur a refermé le sélecteur, ce n'est pas une erreur.
    if (resultat == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultat.succes
              ? (l10n?.backupImportDone(resultat.ajoutes, resultat.dejaPresents) ??
                  "${resultat.ajoutes} souvenir(s) restauré(s).")
              : (l10n?.backupImportError ?? "Archive illisible."),
        ),
      ),
    );

    if (resultat.succes) _calculerEspaceOccupe();
  }

  /// Ligne d'action de la section Archivage : une icône, un titre, une
  /// explication. Le texte compte autant que le bouton — l'utilisateur doit
  /// comprendre où part son archive avant d'appuyer.
  Widget _buildActionSauvegarde({
    required IconData icone,
    required String titre,
    required String sousTitre,
    required bool isDark,
    required Future<void> Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: orange, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: styleCorps.copyWith(
                    fontWeight: FontWeight.w600,
                    color: texteFort(isDark),
                  ),
                ),
                if (sousTitre.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sousTitre,
                    style: styleMention.copyWith(
                      fontWeight: FontWeight.normal,
                      color: texteDoux(isDark),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required Color couleurTextePrincipal,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: orange, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: couleurTextePrincipal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            BtnChevronDroite(onTap: onTap),
          ],
        ),
      ),
    );
  }

  Widget _buildRowReglageText(String titre, String sousTitre, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? white : black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sousTitre,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? lightGrey : grey,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildRowWithSwitch(
  String title, 
  String description, 
  bool value, 
  ValueChanged<bool> onChanged, {
  required bool isDark, // On le passe en requis pour s'assurer de ne jamais utiliser de valeur obsolète
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600, 
                color: isDark ? white : black, // Utilisation directe
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 13, 
                color: isDark ? lightGrey : grey, // Utilisation directe
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 24),
      WidgetSwitch(
        value: value,
        onChanged: onChanged,
      ),
    ],
  );
}

  Widget _buildFAQItem(String question, String reponse, bool isDark) {
    final Color couleurTexte = isDark ? white : black;
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(color: couleurTexte, fontWeight: FontWeight.w500),
      ),
      iconColor: couleurTexte,
      collapsedIconColor: couleurTexte,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            reponse,
            style: TextStyle(color: isDark ? lightGrey : grey),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectDropdownButton({
    required List<String> selectedValues,
    required List<String> items,
    required bool isDark,
    required String Function(String) itemTranslator,
    required Function(List<String>) onChanged,
    double? menuMaxHeight,
  }) {
    final vraiesCategories = items.where((cat) => cat != "all_categories").toList();
    final Map<String, StateSetter> menuStates = {};

    // CORRECTION : On travaille sur une copie locale pour isoler les changements graphiques instantanés
    final List<String> valeursLocales = List.from(selectedValues);

    final bool toutEstCoche = valeursLocales.contains("all_categories") || 
        (valeursLocales.length == vraiesCategories.length && valeursLocales.isNotEmpty);

    final String texteBandeau = toutEstCoche
        ? itemTranslator("all_categories")
        : valeursLocales.isEmpty
            ? "Aucune catégorie"
            : valeursLocales.map((e) => itemTranslator(e)).join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        // Blanc et non le gris F5F5F5 : ce gris neutre tirait au froid contre
        // le fond lightOrange de l'écran. Le blanc, lui, se lit comme un
        // champ creusé dans la page — même traitement que les autres champs.
        color: isDark ? darkSurface : white,
        borderRadius: BorderRadius.circular(radiusDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          menuMaxHeight: menuMaxHeight,
          dropdownColor: isDark ? darkSurface : white,
          icon: Icon(Icons.arrow_drop_down, color: isDark ? white : black),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          hint: Text(
            texteBandeau,
            style: TextStyle(color: isDark ? white : black, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          initialValue: null, 
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  menuStates[item] = menuSetState;

                  final bool isChecked = item == "all_categories"
                      ? valeursLocales.contains("all_categories") || (valeursLocales.length == vraiesCategories.length && valeursLocales.isNotEmpty)
                      : (valeursLocales.contains(item) || valeursLocales.contains("all_categories"));

                  void gererLogiqueSelection(bool cocher) {
                    if (item == "all_categories") {
                      if (cocher) {
                        valeursLocales.clear();
                        valeursLocales.add("all_categories");
                      } else {
                        valeursLocales.clear();
                      }
                    } else {
                      if (valeursLocales.contains("all_categories")) {
                        valeursLocales.clear();
                        valeursLocales.addAll(vraiesCategories);
                      }
                      
                      if (cocher) {
                        valeursLocales.add(item);
                        if (valeursLocales.length == vraiesCategories.length) {
                          valeursLocales.clear();
                          valeursLocales.add("all_categories");
                        }
                      } else {
                        valeursLocales.remove("all_categories");
                        valeursLocales.remove(item);
                      }
                    }

                    // Rafraîchit l'item cliqué
                    menuSetState(() {});
                    
                    // Rafraîchit l'item "all_categories" si on clique sur une autre
                    if (item != "all_categories" && menuStates.containsKey("all_categories")) {
                      menuStates["all_categories"]!(() {});
                    }
                    
                    // Rafraîchit toute la liste si on clique sur "all_categories"
                    if (item == "all_categories") {
                      for (var setter in menuStates.values) {
                        setter(() {});
                      }
                    }
                    
                    // CORRECTION : Renvoie la nouvelle liste propre vers UserPrefs via le callback parent
                    onChanged(valeursLocales);
                  }

                  return InkWell(
                    onTap: () => gererLogiqueSelection(!isChecked),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isChecked,
                            activeColor: orange,
                            checkColor: white,
                            onChanged: (bool? checked) {
                              if (checked != null) {
                                gererLogiqueSelection(checked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            itemTranslator(item),
                            style: TextStyle(
                              color: isDark ? white : black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildDropdownButton<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
    required String Function(T) itemTranslator,
    double? menuMaxHeight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        // Blanc et non le gris F5F5F5 : ce gris neutre tirait au froid contre
        // le fond lightOrange de l'écran. Le blanc, lui, se lit comme un
        // champ creusé dans la page — même traitement que les autres champs.
        color: isDark ? darkSurface : white,
        borderRadius: BorderRadius.circular(radiusDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: isDark ? darkSurface : white,
          icon: Icon(Icons.arrow_drop_down, color: isDark ? white : black),
          isExpanded: true,
          menuMaxHeight: menuMaxHeight,
          items: items.map((T item) {
            final String affichage = itemTranslator(item);

            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                affichage,
                style: TextStyle(
                  color: isDark ? white : black,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

}
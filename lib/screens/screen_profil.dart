import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/main.dart';
import 'package:sourire/screens/screen_choix_themes.dart';
import 'package:sourire/screens/screen_template_reglages.dart';
import 'package:sourire/services/biometric_service.dart';
import 'package:sourire/services/notifications_service.dart';
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

class ScreenProfil extends StatefulWidget {
  const ScreenProfil({super.key});
  // Déclaration globale de l'état de l'autorisation (accessible depuis la Home)
  static bool accesGalerieActive = true;
  
  // Déclaration tri-état : null = auto (suit _estLaNuit), true = sombre forcé, false = clair forcé
  static bool? isDarkMode;
  static bool animationsDoucesActive = false;
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
  String _frequenceSouvenirs = "Tous les jours"; // Stocke la clé interne brute ou la valeur par défaut
  String _jourSemaineSouvenirs = "Lundi"; // Stocke la clé interne brute ou la valeur par défaut
  List<String> _categoriesSouvenirs = ["Toutes catégories"]; // Mutation en liste pour la multi-sélection
  String _taillePhotos = "Calcul...";
  String _tailleNotes = "Calcul...";
  // Instance pour la récupération dynamique des catégories
  final DatabaseService _databaseService = DatabaseService();

  // Simule ou récupère l'état de la nuit automatique
  bool _estLaNuit() {
    final hour = DateTime.now().hour;
    return hour < 6 || hour >= 22;
  }

  @override
  void initState() {
    super.initState();
    
    // 1. Remplissage et nettoyage du Prénom (Met la première lettre en majuscule dès le départ)
    String prenomBrut = UserPrefs.prenom.trim();
    if (prenomBrut.isEmpty) prenomBrut = "Margaux";
    _prenomController.text = prenomBrut[0].toUpperCase() + prenomBrut.substring(1).toLowerCase();
    
    // 2. Remplissage de l'email
    _emailController.text = UserPrefs.email.trim().isEmpty ? "margaux.silva@hotmail.fr" : UserPrefs.email.trim();
    
    // 3. Initialisation du mot de passe en mode masqué
    _passwordController.text = "••••••••••••";
    
    // 4. Synchronisation de la biométrie avec l'onboarding
    _biometrieActive = UserPrefs.biomatrieActive;
    
    
    // Sauvegarde le prénom en temps réel dans les préférences de l'appareil dès que l'utilisateur tape dedans
    _prenomController.addListener(() {
      UserPrefs.prenom = _prenomController.text.trim();
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
          backgroundColor: currentIsDark ? const Color(0xFF1E1E1E) : white,
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: couleurTextePopup),
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
                  style: TextStyle(fontSize: 14, color: currentIsDark ? lightGrey : grey, height: 1.4),
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
                      style: const TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 15),
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
      case "Toutes catégories":
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
      default:
        return key;
    }
  }

  String _getFrequencyDisplayLabel(String key) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return key;

    switch (key) {
      case "Tous les jours":
        return localizations.notifFreqEveryDay;
      case "Tous les 2 jours":
        return localizations.notifFreqEveryTwoDays;
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
        // Détermination finale et dynamique de l'affichage du mode sombre
        final bool isDark = ScreenProfil.isDarkMode ?? _estLaNuit();
        
        final Color couleurFond = isDark ? const Color(0xFF121212) : white;
        final Color couleurHeaderEtConteneur = isDark ? const Color(0xFF1E1E1E) : white;
        final Color couleurTextePrincipal = isDark ? white : black;
        final Color couleurInputFond = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
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
                        _buildInputField(
                          label: localizations?.email ?? "Email",
                          controller: _emailController,
                          readOnly: true,
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: grey,
                                  fontWeight: FontWeight.w500,
                                ),
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

                    // 1. NOTIFICATIONS
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
                                    localizations?.notifLabelTitleGratitude ?? "Rappel quotidien de gratitude",
                                    localizations?.notifLabelSubGratitude ?? "Me rappeler de noter un souvenir positif",
                                    UserPrefs.rappelGratitudeActive, 
                                    isDark: isDark,
                                    (val) async {
                                      // On met directement à jour la configuration globale
                                      UserPrefs.rappelGratitudeActive = val;
                                      
                                      // On force le rafraîchissement visuel de la boîte de dialogue
                                      setLocalState(() {}); 
                                      
                                      // Planification centralisée via le Service
                                      await NotificationService.planifierRappelGratitude();
                                    },
                                  ),
                                  
                                  if (UserPrefs.rappelGratitudeActive) ...[
                                    const SizedBox(height: 10),
                                    Text(localizations?.notifLabelTime ?? "Heure du rappel", style: const TextStyle(color: grey, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        TimeOfDay? picked = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay(
                                            hour: UserPrefs.heureRappelGratitude, 
                                            minute: UserPrefs.minuteRappelGratitude
                                          ),
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
                                        if (picked != null) {
                                          // Sauvegarde complète dans les préférences globales
                                          UserPrefs.heureRappelGratitude = picked.hour;
                                          UserPrefs.minuteRappelGratitude = picked.minute;
                                          
                                          setLocalState(() {});
                                          
                                          // Relance la planification à la nouvelle heure
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
                                            // Formatage dynamique basé sur la valeur stockée
                                            "${UserPrefs.heureRappelGratitude.toString().padLeft(2, '0')}:${UserPrefs.minuteRappelGratitude.toString().padLeft(2, '0')}",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: couleurTextePrincipal)
                                          )
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 25),
                                  Divider(color: couleurSeparateur),
                                  const SizedBox(height: 15),

                                  // --- SWITCH 2 : SOUVENIRS ---
                                  _buildRowWithSwitch(
                                    localizations?.notifLabelTitleSouvenirs ?? "Fréquence des souvenirs tirés",
                                    localizations?.notifLabelSubSouvenirs ?? "Me proposer un vieux souvenir à revoir",
                                    UserPrefs.rappelSouvenirsActive, // Se base sur la variable globale
                                    isDark: isDark,
                                    (val) async {
                                      UserPrefs.rappelSouvenirsActive = val;
                                      setLocalState(() {});
                                      
                                      // Planification réelle
                                      await NotificationService.planifierRappelSouvenirs();
                                    }
                                  ),
                                  
                                  if (UserPrefs.rappelSouvenirsActive) ...[
                                    const SizedBox(height: 10),
                                    Text(localizations?.notifLabelFreqSettings ?? "Réglages de la fréquence", style: const TextStyle(color: grey, fontSize: 14)),
                                    const SizedBox(height: 10),
                                    _buildDropdownButton<String>(
                                      value: _frequenceSouvenirs,
                                      items: const ["Tous les jours", "Tous les 2 jours", "Toutes les semaines"],
                                      isDark: isDark,
                                      itemTranslator: _getFrequencyDisplayLabel,
                                      onChanged: (val) async {
                                        if (val != null) {
                                          setState(() => _frequenceSouvenirs = val);
                                          setLocalState(() {});

                                          UserPrefs.frequenceSouvenirs = val;
                                          
                                          // Recalcule le calendrier du rappel suite au changement de fréquence
                                          await NotificationService.planifierRappelSouvenirs();
                                        }
                                      },
                                    ),
                                    if (_frequenceSouvenirs == "Toutes les semaines") ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        localizations?.notifLabelDayOfWeek ?? "Jour de la semaine",
                                        style: TextStyle(color: isDark ? lightGrey : grey, fontSize: 14)
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDropdownButton<String>(
                                        value: _jourSemaineSouvenirs,
                                        items: const ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"],
                                        isDark: isDark,
                                        itemTranslator: _getDayDisplayLabel,
                                        onChanged: (val) async {
                                          if (val != null) {
                                            setState(() => _jourSemaineSouvenirs = val);
                                            setLocalState(() {});

                                            UserPrefs.jourSemaineSouvenirs = val;
                                            
                                            // Recalcule le calendrier du rappel suite au changement de jour choisi
                                            await NotificationService.planifierRappelSouvenirs();
                                          }
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Text(
                                      localizations?.notifLabelCategoriesIncluded ?? "Catégories incluses",
                                      style: TextStyle(color: isDark ? lightGrey : grey, fontSize: 14)
                                    ),
                                    const SizedBox(height: 8),

                                    StreamBuilder<List<String>>(
                                      stream: _databaseService.getCategoriesStream(),
                                      builder: (context, snapshot) {
                                        final List<String> categoriesBDD = snapshot.data ?? _databaseService.getAllCategories();
                                        final List<String> optionsMenu = ["Toutes catégories", ...categoriesBDD];

                                        _categoriesSouvenirs.removeWhere((cat) => cat != "Toutes catégories" && !categoriesBDD.contains(cat));
                                        if (_categoriesSouvenirs.isEmpty) {
                                          _categoriesSouvenirs = ["Toutes catégories"];
                                        }

                                        return _buildMultiSelectDropdownButton(
                                          selectedValues: _categoriesSouvenirs,
                                          items: optionsMenu,
                                          isDark: isDark,
                                          itemTranslator: _getCategoryDisplayLabel,
                                          menuMaxHeight: 240.0,
                                          onChanged: (List<String> nouvellesValeurs) async {
                                            setState(() {
                                              _categoriesSouvenirs = nouvellesValeurs;
                                            });
                                            setLocalState(() {});

                                            UserPrefs.categoriesSouvenirs = nouvellesValeurs;
                                            
                                            // Recalcule et adapte le tirage par rapport au nouveau filtre de catégories
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

                    // 2. AUTORISATIONS
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
                      icon: Icons.file_download_outlined,
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
                      title: localizations?.accessibility ?? "Apparence",
                      couleurTextePrincipal: couleurTextePrincipal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return ValueListenableBuilder<ThemeMode>(
                                valueListenable: MyApp.themeNotifier,
                                builder: (context, currentMode, _) {
                                  final bool localIsDark = currentMode == ThemeMode.dark;
                                  
                                  return ScreenTemplateReglages(
                                    isDarkMode: localIsDark,
                                    titre: localizations?.accessibility ?? "Accessibilité",
                                    content: [
                                      // MODE SOMBRE
                                      _buildRowWithSwitch(
                                        localizations?.darkMode ?? "Mode sombre",
                                        localizations?.darkModeSubtitle ?? "Bascule l'interface dans des tons sombres pour reposer tes yeux le soir.",
                                        localIsDark,
                                        isDark: localIsDark,
                                        (val) {
                                          setState(() {
                                            // Force l'état d'enregistrement explicite
                                            ScreenProfil.isDarkMode = val;
                                          });
                                          MyApp.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                                        }
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // ANIMATIONS DOUCES
                                      _buildRowWithSwitch(
                                        localizations?.smoothAnimations ?? "Animations douces",
                                        localizations?.smoothAnimationsSubtitle ?? "Remplace l'effet tornade du bocal par une apparition en fondu plus légère.",
                                        ScreenProfil.animationsDoucesActive,
                                        isDark: localIsDark,
                                        (val) {
                                          setState(() {
                                            ScreenProfil.animationsDoucesActive = val;
                                          });
                                          // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                                          MyApp.themeNotifier.notifyListeners(); 
                                        }
                                      ),

                                      const SizedBox(height: 24),

                                      // THÈMES
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ScreenChoixThemes(isDarkMode: localIsDark),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    AppLocalizations.of(context)!.themesTitle,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600, // Identique à _buildRowWithSwitch
                                                      color: localIsDark ? white : black,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    AppLocalizations.of(context)!.themesDescription,
                                                    style: TextStyle(
                                                      fontSize: 13, // Identique à _buildRowWithSwitch
                                                      color: localIsDark ? lightGrey : grey,
                                                      height: 1.3, // Identique à _buildRowWithSwitch
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 24), // Même espacement qu'avec le switch
                                            BtnChevronDroite(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ScreenChoixThemes(isDarkMode: localIsDark),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
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
                                  content: [
                                    WidgetRadioLangue(
                                      label: localLocalizations?.francais ?? "Français",
                                      isSelected: langueSelectionnee == "fr",
                                      onTap: () async {
                                        langueSelectionnee = "fr";
                                        await UserPrefs.setLangue("fr");
                                        MyApp.localeNotifier.value = const Locale('fr', 'FR');
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    WidgetRadioLangue(
                                      label: localLocalizations?.anglais ?? "English",
                                      isSelected: langueSelectionnee == "en",
                                      onTap: () async {
                                        langueSelectionnee = "en";
                                        await UserPrefs.setLangue("en");
                                        MyApp.localeNotifier.value = const Locale('en', 'US');
                                      },
                                    ),
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
                                  localizations?.faqAnswer2 ?? "Secoue ton téléphone ou clique sur le bocal pour faire remonter un souvenir au hasard.", 
                                  isDark
                                ),
                                _buildFAQItem(
                                  localizations?.faqQuestion3 ?? "Comment catégoriser des souvenirs ?", 
                                  localizations?.faqAnswer3 ?? "Va dans l'historique et appuie longuement sur un souvenir. Tu pourras alors en sélectionner plusieurs et choisir 'Catégoriser'.", 
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
            style: const TextStyle(
              fontSize: 16,
              color: grey,
              fontWeight: FontWeight.w500,
            ),
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
    bool? isDark,
  }) {
    final bool effectiveIsDark = isDark ?? (ScreenProfil.isDarkMode ?? _estLaNuit());
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
                  color: effectiveIsDark ? white : black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13, 
                  color: effectiveIsDark ? lightGrey : grey,
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
    final vraiesCategories = items.where((cat) => cat != "Toutes catégories").toList();
    final Map<String, StateSetter> menuStates = {};

    final bool toutEstCoche = selectedValues.contains("Toutes catégories") || 
        (selectedValues.length == vraiesCategories.length && selectedValues.isNotEmpty);

    final String texteBandeau = toutEstCoche
        ? itemTranslator("Toutes catégories")
        : selectedValues.isEmpty
            ? "Aucune catégorie"
            : selectedValues.map((e) => itemTranslator(e)).join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? darkSurface : const Color(0xFFF5F5F5),
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

                  final bool isChecked = item == "Toutes catégories"
                      ? selectedValues.contains("Toutes catégories") || (selectedValues.length == vraiesCategories.length && selectedValues.isNotEmpty)
                      : (selectedValues.contains(item) || selectedValues.contains("Toutes catégories"));

                  void gererLogiqueSelection(bool cocher) {
                    if (item == "Toutes catégories") {
                      if (cocher) {
                        selectedValues.clear();
                        selectedValues.add("Toutes catégories");
                      } else {
                        selectedValues.clear();
                      }
                    } else {
                      if (selectedValues.contains("Toutes catégories")) {
                        selectedValues.clear();
                        selectedValues.addAll(vraiesCategories);
                      }
                      
                      if (cocher) {
                        selectedValues.add(item);
                        if (selectedValues.length == vraiesCategories.length) {
                          selectedValues.clear();
                          selectedValues.add("Toutes catégories");
                        }
                      } else {
                        selectedValues.remove("Toutes catégories");
                        selectedValues.remove(item);
                      }
                    }

                    menuSetState(() {});
                    
                    if (item != "Toutes catégories" && menuStates.containsKey("Toutes catégories")) {
                      menuStates["Toutes catégories"]!(() {});
                    }
                    
                    if (item == "Toutes catégories") {
                      for (var setter in menuStates.values) {
                        setter(() {});
                      }
                    }
                    
                    onChanged(selectedValues);
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
        color: isDark ? darkSurface : const Color(0xFFF5F5F5),
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
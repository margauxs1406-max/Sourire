import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour contrôler impérativement les styles système
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/main.dart';
import 'package:sourire/screens/screen_profil.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/header_app.dart';
import 'package:sourire/widgets/btn_new_note.dart';
import 'package:sourire/widgets/btn_new_picture.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:sourire/screens/screen_categorisation_photo.dart';
import 'package:sourire/screens/screen_new_note.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/widgets/souvenir_tirage.dart';
import 'package:sourire/widgets/widget_historique.dart';
import 'package:sourire/theme/user_prefs.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_svg/flutter_svg.dart'; // AJOUT : Requis pour afficher les thèmes vectoriels
import 'package:sourire/models/theme_app.dart'; // AJOUT : Accès aux modèles
import 'package:sourire/theme/theme_service.dart'; // AJOUT : Accès à l'état du thème visuel
import 'dart:ui';
import 'package:sourire/models/note_model.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  static bool? isDarkMode;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final DraggableScrollableController _historyController = DraggableScrollableController();

  final GlobalKey _cleBoutonPhoto = GlobalKey();
  final GlobalKey _cleBoutonNote = GlobalKey();
  final GlobalKey _cleBocal = GlobalKey(); 
  final GlobalKey _cleBurger = GlobalKey(); 

  final List<TargetFocus> _targets = [];
  int _tentativesCalculTaille = 0; // Sécurité anti-boucle pour le tutoriel

  dynamic _dernierIdTire; // AJOUT : Stocke l'ID du dernier souvenir affiché
  SourireTheme? _derniereCouleurNote; // AJOUT : Stocke la dernière couleur de note générée

  // Dans le fichier de ta Home
@override
void initState() {
  super.initState();
  _appliquerStyleZoneProtegee();
  debugPrint("===> HOME : Initialisation");
  
  isAppLockedNotifier.addListener(_verifierEtDeclencherSouvenir);

  // On attend que l'écran soit construit, puis on vérifie
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _verifierEtDeclencherSouvenir();
    }

    if (!UserPrefs.modeDemoAffiche) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _tenterLancementDemo();
      });
    }
  });
}

@override
void dispose() {
  isAppLockedNotifier.removeListener(_verifierEtDeclencherSouvenir);
  super.dispose();
}

void _verifierEtDeclencherSouvenir() async {
  if (isAppLockedNotifier.value) {
    debugPrint("===> HOME : Blocage immédiat, le verrou est actif.");
    return;
  }

  // 🌟 AJUSTEMENT TIMING IPHONE : On augmente légèrement le délai (de 150ms à 350ms)
  // pour laisser le temps au calque de verrouillage iOS de disparaître complètement
  await Future.delayed(const Duration(milliseconds: 350));
  if (!mounted || isAppLockedNotifier.value) return;

  final int idTarget = UserPrefs.getSouvenirNotificationId();
  if (idTarget == -1) return;

  try {
    final toutesLesNotes = await DatabaseService().getAllNotesAsync();
    final souvenir = toutesLesNotes.firstWhere(
      (note) => note.id == idTarget,
      orElse: () => NoteSourire(id: -1, text: '', themeLabel: 'orange', colorLabel: 'orange', categories: [], date: DateTime.now()),
    );

    if (souvenir.id != -1 && mounted) {
      if (!isAppLockedNotifier.value) {
        debugPrint("===> HOME : 🎉 Affichage propre du bocal.");
        
        // On consomme/nettoie l'ID SEULEMENT si le bocal s'affiche pour de bon !
        await UserPrefs.setSouvenirNotificationId(-1);
        
        afficherSouvenirBocal(context, souvenir);
      }
    }
  } catch (e) {
    debugPrint("Erreur bocal Home : $e");
  }
}

  void _appliquerStyleZoneProtegee() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,         
      statusBarIconBrightness: Brightness.light,  
      statusBarBrightness: Brightness.dark,       
      systemNavigationBarColor: Colors.transparent, 
    ));
  }

  void _tenterLancementDemo() {
    try {
      final RenderBox? boxPhoto = _cleBoutonPhoto.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? boxNote = _cleBoutonNote.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? boxBocal = _cleBocal.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? boxBurger = _cleBurger.currentContext?.findRenderObject() as RenderBox?;

      if (boxPhoto == null || boxNote == null || boxBocal == null || boxBurger == null || !boxBocal.hasSize) {
        _tentativesCalculTaille++;
        if (_tentativesCalculTaille > 3) {
          debugPrint("🛑 HOME : Abandon du tutoriel suite à des clés d'affichage introuvables.");
          return;
        }
        debugPrint("⚠️ HOME WARNING : Les dimensions des composants ne sont pas prêtes. Report.");
        WidgetsBinding.instance.addPostFrameCallback((_) => _tenterLancementDemo());
        return;
      }

      debugPrint("===> HOME : Initialisation et affichage du tutoriel.");
      _initialiserConfigurationDemo();
      _afficherSequenceDemo();
    } catch (demoError, stackTrace) {
      debugPrint("❌ ERREUR CAPTURÉE : Échec tutoriel global : $demoError");
      debugPrint("$stackTrace");
    }
  }

  void _initialiserConfigurationDemo() {
    _targets.clear();
    final l10n = AppLocalizations.of(context)!;

    _targets.add(
      TargetFocus(
        identify: "TargetPhoto",
        keyTarget: _cleBoutonPhoto,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (BuildContext context, TutorialCoachMarkController controller) {
              return _buildBulledAide(
                titre: l10n.demoPhotoTitle,
                description: l10n.demoPhotoDesc,
                texteBouton: l10n.demoBtnNext,
                onTap: () => controller.next(),
              );
            },
          ),
        ],
      ),
    );

    _targets.add(
      TargetFocus(
        identify: "TargetNote",
        keyTarget: _cleBoutonNote,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (BuildContext context, TutorialCoachMarkController controller) {
              return _buildBulledAide(
                titre: l10n.demoNoteTitle,
                description: l10n.demoNoteDesc,
                texteBouton: l10n.demoBtnNext,
                onTap: () => controller.next(),
              );
            },
          ),
        ],
      ),
    );

    _targets.add(
      TargetFocus(
        identify: "TargetBocal",
        keyTarget: _cleBocal,
        contents: [
          TargetContent(
            align: ContentAlign.top, 
            builder: (BuildContext context, TutorialCoachMarkController controller) {
              return _buildBulledAide(
                titre: l10n.demoBocalTitle,
                description: l10n.demoBocalDesc,
                texteBouton: l10n.demoBtnNext,
                onTap: () => controller.next(),
              );
            },
          ),
        ],
      ),
    );

    _targets.add(
      TargetFocus(
        identify: "TargetBurger",
        keyTarget: _cleBurger,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (BuildContext context, TutorialCoachMarkController controller) {
              return _buildBulledAide(
                titre: l10n.demoBurgerTitle,
                description: l10n.demoBurgerDesc,
                texteBouton: l10n.demoBtnFinish,
                onTap: () => controller.skip(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBulledAide({
    required String titre,
    required String description,
    required String texteBouton,
    required VoidCallback onTap,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutBack, 
      switchOutCurve: Curves.easeIn,      
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: Column(
        key: ValueKey<String>(titre),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(fontWeight: FontWeight.bold, color: white, fontSize: 20),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(color: white, fontSize: 16),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(backgroundColor: white, foregroundColor: orange),
            child: Text(texteBouton),
          )
        ],
      ),
    );
  }

  void _afficherSequenceDemo() {
    final l10n = AppLocalizations.of(context)!;
    
    TutorialCoachMark(
      targets: _targets,
      colorShadow: black.withOpacity(0.85),
      textSkip: l10n.demoSkip,
      textStyleSkip: const TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 14),
      paddingFocus: 8,
      opacityShadow: 0.8,
      focusAnimationDuration: Duration.zero,
      unFocusAnimationDuration: Duration.zero,
      onFinish: () {
        if (mounted) {
          setState(() {
            UserPrefs.modeDemoAffiche = true;
          });
        }
      },
      onSkip: () {
        if (mounted) {
          setState(() {
            UserPrefs.modeDemoAffiche = true;
          });
        }
        return true;
      },
    ).show(context: context);
  }

  void _tirerSouvenir(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final databaseService = DatabaseService();

  // CORRECTION SQLITE : Remplacement par la version Async
  final tousLesSouvenirs = await databaseService.getAllNotesAsync();

  if (tousLesSouvenirs.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.emptyJarMessage),
        duration: const Duration(seconds: 2),
      ),
    );
    return;
  }

  // Filtrer la liste pour exclure le dernier souvenir tiré
  List<NoteSourire> filteredSouvenirs = List.from(tousLesSouvenirs);
  if (tousLesSouvenirs.length > 1 && _dernierIdTire != null) {
    filteredSouvenirs = tousLesSouvenirs.where((note) => note.id != _dernierIdTire).toList();
  }

  filteredSouvenirs.shuffle();
  final souvenirAleatoire = filteredSouvenirs.first;
  _dernierIdTire = souvenirAleatoire.id;

  if (!context.mounted) return;
  afficherSouvenirBocal(context, souvenirAleatoire);
}

  Future<void> _ouvrirGalerieSelectionMultiple(BuildContext context) async {
    try {
      final DatabaseService databaseService = DatabaseService();

      // 1. On récupère toutes les notes existantes
      final toutesLesNotes = await databaseService.getAllNotesAsync();
      
      // 2. On compte précisément le nombre de PHOTOS
      final int nombrePhotosActuelles = toutesLesNotes.where((note) => note.photoPath != null && note.photoPath!.isNotEmpty).length;

      const int limiteMaximaleGratuite = 10;

      // 3. CORRECTION : Blocage ou calcul de quota basé sur la persistance de UserPrefs
      if (!UserPrefs.isPremium && nombrePhotosActuelles >= limiteMaximaleGratuite) {
        if (!context.mounted) return;
        _ouvrirAlerteAchat(context, estPourPhotos: true);
        return;
      }

      // 4. On calcule le Quota restant pour le sélecteur d'assets
      // CORRECTION : Utilisation de UserPrefs.isPremium ici aussi
      final int photosAutoriseesRestantes = UserPrefs.isPremium 
          ? 10 
          : (limiteMaximaleGratuite - nombrePhotosActuelles);

      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: photosAutoriseesRestantes > 10 ? 10 : photosAutoriseesRestantes,
          requestType: RequestType.image,
          textDelegate: const FrenchAssetPickerTextDelegate(),
          gridThumbnailSize: const ThumbnailSize.square(240),
          dragToSelect: false,
          pickerTheme: AssetPicker.themeData(orange).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: orange,
              secondary: orange,
            ),
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return orange; 
                }
                return Colors.white.withOpacity(0.2); 
              }),
              checkColor: WidgetStateProperty.all(Colors.white),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: orange, 
                foregroundColor: Colors.white, 
                disabledBackgroundColor: Colors.grey[800], 
              ),
            ),
          ),
        ),
      );

      if (result != null && result.isNotEmpty) {
        if (!context.mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenCategorisationPhoto(photos: result),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur : $e");
    }
  }

  void _ouvrirAlerteActivationGalerie(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final ThemeMode currentMode = MyApp.themeNotifier.value;
        
        final bool isDark = currentMode == ThemeMode.dark || 
            (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

        final Color couleurFond = isDark ? const Color(0xFF1E1E1E) : white;
        final Color couleurTitre = isDark ? white : black;
        final Color couleurDescription = isDark ? Colors.white70 : grey; 

        return Dialog(
          backgroundColor: couleurFond,
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
                      l10n.alertWarningTitle,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: couleurTitre),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: grey), 
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.galleryDisabledMessage,
                  style: TextStyle(fontSize: 14, color: couleurDescription, height: 1.4),
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
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScreenProfil()),
                      );
                    },
                    child: Text(
                      l10n.btnEnableAccess,
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

  void _ouvrirAlerteAchat(BuildContext context, {bool estPourPhotos = false}) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final ThemeMode currentMode = MyApp.themeNotifier.value;
        
        final bool isDark = currentMode == ThemeMode.dark || 
            (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

        final Color couleurFond = isDark ? const Color(0xFF1E1E1E) : white;
        final Color couleurTitre = isDark ? white : black;
        final Color couleurDescription = isDark ? Colors.white70 : grey; 

        final String texteMessage = estPourPhotos
            ? l10n.purchaseAlertPhotosMessage
            : l10n.purchaseAlertNotesMessage;

        return Dialog(
          backgroundColor: couleurFond,
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
                      l10n.purchaseAlertTitle,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: couleurTitre),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: grey), 
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  texteMessage,
                  style: TextStyle(fontSize: 14, color: couleurDescription, height: 1.4),
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
                      Navigator.of(context).pop(); // Ferme la boîte de dialogue d'alerte
                      
                      // 1. CORRECTION : Sauvegarde locale persistante pour valider l'achat sur le disque
                      UserPrefs.isPremium = true; 

                      // 2. Active l'ensemble des droits premium de l'application en mémoire vive
                      ThemeService.deverrouillerPremium();
                      
                      // Feedback visuel sur la Home
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.notesPurchaseSuccessSnackBar),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Text(
                      l10n.btnGoPremium,
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

  void _ouvrirHistoriqueDepuisBurger(BuildContext context) {
    if (_historyController.isAttached) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: UserPrefs.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: UserPrefs.isDark ? Brightness.dark : Brightness.light,
      ));

      _historyController.animateTo(
        1.0, 
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
Widget build(BuildContext context) {
  
  double screenWidth = MediaQuery.of(context).size.width;
  final l10n = AppLocalizations.of(context)!;

  String prenomBrut = UserPrefs.prenom.trim();
  if (prenomBrut.isEmpty) prenomBrut = "Etranger";
  final String prenomAffiche = prenomBrut[0].toUpperCase() + prenomBrut.substring(1).toLowerCase();

  final String accordAffiche = UserPrefs.accordHeureux;
  final DatabaseService databaseService = DatabaseService();

  double responsiveWelcomeFontSize = screenWidth * 0.05; 
  double responsiveQuestionFontSize = screenWidth * 0.07; 

  return Container(
    color: orange,
    child: Scaffold(
      backgroundColor: Colors.transparent, 
      resizeToAvoidBottomInset: false,     
      body: Stack( 
        children: [
          // 1. RENDU DYNAMIQUE DES ICÔNES DE FOND
Positioned.fill(
  child: SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        return ValueListenableBuilder<ThemeApp>(
          valueListenable: ThemeService.themeVisuelNotifier,
          builder: (context, themeActuel, child) {
            if (themeActuel.homeIcons.isEmpty) {
              return const SizedBox.shrink();
            }

            return Stack(
              children: themeActuel.homeIcons.map((iconConfig) {
                final double iconWidth = iconConfig.getWidth(width);
                final double iconHeight = iconConfig.getHeight(height);

                Widget iconCore = SvgPicture.asset(
                  iconConfig.assetPath,
                  width: iconWidth,
                  height: iconHeight,
                  colorFilter: themeActuel.homeIconColor != null
                      ? ColorFilter.mode(
                          themeActuel.homeIconColor!.withOpacity(themeActuel.homeIconOpacity),
                          BlendMode.srcIn,
                        )
                      : null,
                );

                // S'ASSURER QUE LA ROTATION EST APPLIQUÉE
                // Remplace 'iconConfig.angle' ou 'iconConfig.rotation' par le nom exact de ta propriété.
                // Si elle est stockée en degrés, utilise : iconConfig.rotation * math.pi / 180
                if (iconConfig.rotation != 0) {
                  iconCore = Transform.rotate(
                    angle: iconConfig.rotation, // attend des radians
                    child: iconCore,
                  );
                }

                return Positioned(
                  left: iconConfig.getX(width),
                  top: iconConfig.getY(height),
                  child: iconCore,
                );
              }).toList(),
            );
          },
        );
      },
    ),
  ),
),

          // 2. LE BLOC HOME CONTENU
          Positioned.fill(
            child: SafeArea(
              bottom: false, 
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double heightScreen = constraints.maxHeight;
                  
                  double spaceBottomToButtons = heightScreen * 0.08; 
                  double spaceBottomToBocal = heightScreen * 0.24;   
                  double bocalHeight = heightScreen * 0.35;
                  double bocalWidth = bocalHeight * 0.85; 

                  return SizedBox(
                    width: double.infinity,
                    height: heightScreen,
                    child: Stack( 
                      children: [
                        Positioned(
                          top: heightScreen * 0.15, 
                          left: screenWidth * 0.1,
                          right: screenWidth * 0.1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.welcomeMessage(prenomAffiche),
                                style: styleNoteLarge.copyWith(
                                  color: white, 
                                  fontSize: responsiveWelcomeFontSize,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.mainQuestion(accordAffiche), 
                                style: styleNoteLarge.copyWith(
                                  color: white, 
                                  fontSize: responsiveQuestionFontSize,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Positioned(
                          bottom: spaceBottomToBocal,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              key: _cleBocal, 
                              height: bocalHeight, 
                              width: bocalWidth,   
                              child: GestureDetector(
                                onTap: () => _tirerSouvenir(context), 
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      left: 8.0,   
                                      top: 4.0,    
                                      right: -8.0,
                                      bottom: -4.0,
                                      child: ImageFiltered(
                                        imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0, tileMode: TileMode.decal),
                                        child: Image(
                                          image: const AssetImage('assets/bocal@2x.png'),
                                          fit: BoxFit.contain,
                                          color: black.withOpacity(0.20), 
                                          colorBlendMode: BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                    const Positioned.fill(
                                      child: Image(
                                        image: AssetImage('assets/bocal@2x.png'),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: spaceBottomToButtons,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BtnNewPicture(
                                key: _cleBoutonPhoto, 
                                onTap: () async {
                                  if (!ScreenProfil.accesGalerieActive) {
                                    _ouvrirAlerteActivationGalerie(context);
                                  } else {
                                    final int nombrePhotosActuelles = await DatabaseService().getPhotoNotesCount();
                                    
                                    if (!ThemeService.estUtilisateurPremium && nombrePhotosActuelles >= 10) {
                                      if (!context.mounted) return;
                                      _ouvrirAlerteAchat(context, estPourPhotos: true);
                                    } else {
                                      if (!context.mounted) return;
                                      _ouvrirGalerieSelectionMultiple(context);
                                    }
                                  }
                                },
                              ),
                              
                              const SizedBox(width: 40),
BtnNewNote(
  key: _cleBoutonNote, 
  onTap: () async {
    final int nombreNotesPures = await DatabaseService().getTextNotesCount();

    // CORRECTION : Détection automatique et persistante du premium via UserPrefs
    if (!UserPrefs.isPremium && nombreNotesPures >= 5) {
      if (!context.mounted) return;
      _ouvrirAlerteAchat(context, estPourPhotos: false);
    } else {
      List<SourireTheme> couleursDisponibles = List.from(SourireTheme.tousLesThemes);

      if (couleursDisponibles.length > 1 && _derniereCouleurNote != null) {
        couleursDisponibles.removeWhere((theme) => theme.label == _derniereCouleurNote!.label);
      }

      couleursDisponibles.shuffle();
      final SourireTheme couleurChoisie = couleursDisponibles.first;
      _derniereCouleurNote = couleurChoisie;

      final ThemeApp themeVisuelSelectionne = ThemeService.themeVisuelNotifier.value;

      if (!context.mounted) return;
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => ScreenNewNote(
            couleur: couleurChoisie,
            themeVisuel: themeVisuelSelectionne,
          ),
        ),
      );
    }
  },
),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. L'HISTORIQUE GLOBAL EN STREAMBUILDER
          // Répare l'erreur 4 et 5 en écoutant les changements de la baseSQLite automatiquement
          StreamBuilder<List<NoteSourire>>(
            stream: databaseService.getNotesStream(),
            builder: (context, snapshot) {
              final notesFluides = snapshot.data ?? [];
              return Positioned.fill(
                child: WidgetHistorique(
                  key: ValueKey(UserPrefs.isDark), 
                  notes: notesFluides,
                  controller: _historyController,
                  isDark: UserPrefs.isDark,
                  onNotesChanged: () {
                    // Le StreamBuilder reconstruit déjà l'UI automatiquement lors des changements !
                  },
                ),
              );
            },
          ),

          // 4. LE HEADER AU PREMIER PLAN ABSOLU
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: HeaderApp(
                keyBurger: _cleBurger,
                onBurgerTap: () => _ouvrirHistoriquePermanente(context),
                onProfilTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScreenProfil()),
                  ).then((_) {
                    if (mounted) {
                      setState(() {});
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  void _ouvrirHistoriquePermanente(BuildContext context) => _ouvrirHistoriqueDepuisBurger(context);
}
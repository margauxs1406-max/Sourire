import 'dart:async';

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
import 'package:sourire/widgets/bocal_pastilles.dart';
import 'package:sourire/services/milestones_service.dart';
import 'package:sourire/widgets/modale_premium.dart';
import 'package:sourire/widgets/popup_palier.dart';
// --- LE VERRE DU BOCAL --------------------------------------------------------
//
// Deux calques, et l'ordre compte : la STRUCTURE passe derrière les billes,
// les REFLETS passent devant. C'est ce second calque qui fait qu'on lit une
// paroi de verre plutôt qu'un simple dessin autour des billes.
//
// Les deux PNG ne sont que des masques de forme, blancs : ce sont ces
// couleurs-ci qui décident de l'intensité. Baisse l'alpha pour un bocal plus
// discret, monte-le pour une paroi plus présente.

/// Traits et arêtes du bocal, derrière les billes.
const Color _verreClair = Color(0xB81E1408); // encre chaude, 72 %
const Color _verreSombre = Color(0xBFFFFFFF); // lumière froide, 75 %

/// Hautes lumières du verre, devant les billes.
///
/// En mode CLAIR le reflet est un blanc franc : posé sur un fond crème, il se
/// lit comme de la lumière. En mode SOMBRE le même blanc à la même opacité
/// devient une source lumineuse en soi — il crève l'écran et efface les
/// billes qu'il traverse. On y descend donc l'opacité et on quitte le blanc
/// pur pour un gris bleuté : le reflet redevient de la lumière AMBIANTE
/// renvoyée par la paroi, et non une lampe allumée derrière le bocal.
const Color _refletClair = Color(0xB2FFFFFF); // blanc pur, 70 %
const Color _refletSombre = Color(0x73C6D2DE); // gris bleuté, 45 %

class Home extends StatefulWidget {
  const Home({super.key});

  static bool? isDarkMode;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final DraggableScrollableController _historyController = DraggableScrollableController();

  final GlobalKey _cleBoutonPhoto = GlobalKey();
  final GlobalKey _cleBoutonNote = GlobalKey();
  final GlobalKey _cleBocal = GlobalKey(); 
  final GlobalKey _cleBurger = GlobalKey(); 

  final List<TargetFocus> _targets = [];
  int _tentativesCalculTaille = 0; // Sécurité anti-boucle pour le tutoriel
  int? _palierEnAttente;
  dynamic _dernierIdTire; // AJOUT : Stocke l'ID du dernier souvenir affiché
  SourireTheme? _derniereCouleurNote; // AJOUT : Stocke la dernière couleur de note générée

  /// Accès unique à la base. `DatabaseService` est un singleton : cette
  /// référence sert simplement à ne pas le réécrire partout.
  final DatabaseService databaseService = DatabaseService();

  /// Abonnement dédié à la vérification des paliers. Voir initState.
  StreamSubscription<List<NoteSourire>>? _abonnementPaliers;

  static const int _capaciteBocal = 45;
  bool _bocalPleinEnAttente = false;
  bool _prochainBocalDoitAnimerDemarrage = false;

  // Dans le fichier de ta Home
@override
void initState() {
  super.initState();
  _appliquerStyleZoneProtegee();
  debugPrint("===> HOME : Initialisation");
  
  // Écoute du verrou global pour déclencher le souvenir dès le déverrouillage
  isAppLockedNotifier.addListener(_verifierEtDeclencherSouvenir);

  // Les paliers se vérifient sur le FLUX, pas dans le `build`.
  //
  // Ce contrôle écrit dans les préférences (`dernierPalierCelebre`) : le
  // faire pendant la construction d'un widget est fragile, et le faisait
  // tourner à chaque image. Ici il ne s'exécute qu'aux vrais changements.
  _abonnementPaliers = databaseService.getNotesStream().listen((notes) {
    if (!mounted) return;
    // Les souvenirs d'amorçage ne sont pas de l'utilisateur : ils ne doivent
    // pas lui faire franchir de palier.
    _verifierPalier(notes.where((n) => !n.estAmorce).length, context);
  });

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      // Premier contrôle sur le cache : le flux, lui, n'émettra qu'au
      // prochain changement, et il faut bien initialiser la gamification.
      _verifierPalier(
        databaseService.notesEnCache.where((n) => !n.estAmorce).length,
        context,
      );
      _verifierEtDeclencherSouvenir();
    }
    if (!UserPrefs.modeDemoAffiche) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _tenterLancementDemo();
      });
    }
  });
}

void _verifierPalier(int total, BuildContext context) {
  if (!UserPrefs.gamificationInitialisee) {
    UserPrefs.dernierPalierCelebre = plusHautPalierAtteint(total);
    UserPrefs.gamificationInitialisee = true;
    return;
  }

  final int? nouveauPalier = prochainPalierFranchi(total, UserPrefs.dernierPalierCelebre);
  if (nouveauPalier != null) {
    // Mis à jour immédiatement pour éviter tout doublon, MÊME si l'affichage
    // effectif de la pop-up doit attendre que la Home soit au premier plan.
    UserPrefs.dernierPalierCelebre = nouveauPalier;
    _palierEnAttente = nouveauPalier;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tenterAfficherPalierEnAttente(context);
    });
  }
}

/// Affiche la pop-up de palier UNIQUEMENT si la Home est bien l'écran
/// actif au premier plan (pas caché derrière un écran de catégorisation
/// en cours de fermeture, par exemple). Sinon, réessaie au frame suivant.
void _tenterAfficherPalierEnAttente(BuildContext context) {
  if (_palierEnAttente == null) return;

  if (ModalRoute.of(context)?.isCurrent != true) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tenterAfficherPalierEnAttente(context);
    });
    return;
  }

  final int palier = _palierEnAttente!;
  _palierEnAttente = null;
  afficherPopupPalier(context, palier, isDark: UserPrefs.isDark);
}

@override
void dispose() {
  // On retire l'écouteur proprement
  isAppLockedNotifier.removeListener(_verifierEtDeclencherSouvenir);
  _abonnementPaliers?.cancel();
  super.dispose();
}

// 🌟 didChangeAppLifecycleState ENTIÈREMENT SUPPRIMÉ : 
// Le cycle de vie est désormais centralisé et géré uniquement par le main.dart

void _verifierEtDeclencherSouvenir() async {
  // Si l'application est verrouillée, on bloque immédiatement toute lecture
  if (isAppLockedNotifier.value) {
    debugPrint("===> HOME : Blocage immédiat, le verrou est actif.");
    return;
  }

  // Lecture directe de l'ID stocké dans les préférences
  final int idTarget = UserPrefs.getSouvenirNotificationId();
  debugPrint("===> HOME LECTURE ID : ID trouvé = $idTarget");
  if (idTarget == -1) return;

  // Si l'utilisateur a cliqué sur la notif depuis un sous-écran (ex: Profil), on ferme tout pour revenir à la Home
  if (ModalRoute.of(context)?.isCurrent == false) {
    debugPrint("===> HOME : Souvenir détecté depuis un sous-écran. Fermeture de l'ancien écran.");
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Un infime délai pour laisser l'animation de fermeture de l'écran se terminer avant la boîte de dialogue
    await Future.delayed(const Duration(milliseconds: 200));
  }

  if (!mounted || isAppLockedNotifier.value) return;

  try {
    final toutesLesNotes = await DatabaseService().getAllNotesAsync();
    final souvenir = toutesLesNotes.firstWhere(
      (note) => note.id == idTarget,
      orElse: () => NoteSourire(id: -1, text: '', themeLabel: 'orange', colorLabel: 'orange', categories: [], date: DateTime.now()),
    );

    if (souvenir.id != -1 && mounted) {
      if (!isAppLockedNotifier.value) {
        debugPrint("===> HOME : 🎉 Affichage propre du bocal.");
        // Consommation immédiate de l'ID pour éviter les double-ouvertures
        await UserPrefs.setSouvenirNotificationId(-1);
        // Le `mounted` testé plus haut date d'AVANT cet await : l'écran a pu
        // être démonté entre-temps. On revérifie avant de toucher au context.
        if (!mounted) return;
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
      colorShadow: black.withValues(alpha: 0.85),
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

      // 1. Le quota gratuit porte désormais sur le TOTAL de souvenirs, notes
      //    et photos confondues, et non plus sur deux compteurs séparés.
      final int souvenirsActuels = await databaseService.getTotalNotesCount();

      if (!UserPrefs.isPremium &&
          souvenirsActuels >= UserPrefs.limiteSouvenirsGratuits) {
        if (!context.mounted) return;
        _ouvrirAlerteAchat(context);
        return;
      }

      // 2. Le sélecteur affiche "X/10" par défaut, mais le plafond descend dès
      //    qu'il reste moins de 10 places avant la limite des 25 : à 20
      //    souvenirs enregistrés, le compteur devient "X/5".
      const int maxPhotosParLot = 10;
      final int placesRestantes =
          UserPrefs.limiteSouvenirsGratuits - souvenirsActuels;
      final int maxAssetsAutorises = UserPrefs.isPremium
          ? maxPhotosParLot
          : (placesRestantes < maxPhotosParLot ? placesRestantes : maxPhotosParLot);

      // getTotalNotesCount() ci-dessus est un await : l'écran a pu être démonté
      // depuis. On revérifie avant de passer le context au sélecteur.
      if (!context.mounted) return;

      // Boucle volontaire : le chevron de retour du premier écran de
      // catégorisation renvoie `retourVersGalerie`, et on ROUVRE alors le
      // sélecteur au lieu de retomber sur l'accueil. La galerie n'est pas une
      // page de l'app — c'est une fonction qui s'ouvre et se referme — donc
      // « revenir à la galerie » ne peut pas être un simple `pop`.
      //
      // La sélection précédente est repassée au sélecteur : on retrouve ses
      // photos déjà cochées, exactement comme on les avait laissées.
      List<AssetEntity>? selectionPrecedente;

      while (true) {
        final List<AssetEntity>? result = await AssetPicker.pickAssets(
          context,
          pickerConfig: AssetPickerConfig(
            maxAssets: maxAssetsAutorises,
            selectedAssets: selectionPrecedente,
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
                  return Colors.white.withValues(alpha: 0.2); 
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

        // Sélecteur fermé sans rien choisir : l'utilisateur voulait sortir.
        if (result == null || result.isEmpty) return;
        if (!context.mounted) return;

        selectionPrecedente = result;

        final Object? retour = await Navigator.push<Object?>(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenCategorisationPhoto(photos: result),
          ),
        );

        // Tout sauf `retourVersGalerie` signifie que le parcours est terminé :
        // souvenirs enregistrés, ou abandon depuis un écran plus profond.
        if (retour != retourVersGalerie) return;
        if (!context.mounted) return;
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
                      style: styleTitreAction.copyWith(color: couleurTitre),
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
                  style: styleSecondaire.copyWith(color: couleurDescription),
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

  /// Modale « Limite atteinte ». Le message est unique : la limite gratuite
  /// porte sur le total de souvenirs, pas sur leur type.
  ///
  /// Elle passe par [afficherModalePremium], donc par un VRAI achat. Cette
  /// boîte avait sa propre mise en page et son propre bouton, lequel se
  /// contentait d'écrire `UserPrefs.isPremium = true` : le Premium se
  /// débloquait sans que rien ne soit facturé. Il y a désormais un seul
  /// chemin d'achat dans l'application, et il passe par la boutique.
  Future<void> _ouvrirAlerteAchat(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final bool debloque = await afficherModalePremium(
      context,
      titre: l10n.purchaseAlertTitle,
      message: l10n.purchaseAlertMessage(UserPrefs.limiteSouvenirsGratuits),
    );

    // `context.mounted` et non `mounted` : le contexte est ici un paramètre de
    // la méthode, et c'est bien LUI qu'on s'apprête à réutiliser après l'await.
    if (!debloque || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.notesPurchaseSuccessSnackBar),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {});
  }

  /// Affiche la pop-up "Ton bocal est plein !" UNIQUEMENT si Home est
  /// bien l'écran actif au premier plan — sinon réessaie au frame
  /// suivant. Sans ça, si le seuil est franchi pendant qu'un autre écran
  /// est encore ouvert (ex: la catégorisation d'un import en cours), la
  /// pop-up peut apparaître puis être aussitôt "avalée" par le retour à
  /// Home. Même principe que _tenterAfficherPalierEnAttente.
  void _tenterAfficherPopupBocalPlein(BuildContext context) {
    if (!_bocalPleinEnAttente) return;

    if (ModalRoute.of(context)?.isCurrent != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tenterAfficherPopupBocalPlein(context);
      });
      return;
    }

    _bocalPleinEnAttente = false;
    _afficherPopupBocalPlein(context);
  }

  /// Affiche la pop-up "Ton bocal est plein !" — déclenchée par
  /// BocalPastilles quand le bocal courant atteint sa capacité maximale
  /// alors qu'il reste des souvenirs en attente au-delà. Le clic sur
  /// "Nouveau bocal" fait avancer l'offset persisté (UserPrefs), ce qui
  /// force — via le changement de Key sur BocalPastilles — une
  /// réinitialisation propre : le bocal réapparaît vide, avec les
  /// souvenirs excédentaires déjà placés dedans.
  void _afficherPopupBocalPlein(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        final ThemeMode currentMode = MyApp.themeNotifier.value;
        final bool isDark = currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system && MediaQuery.of(dialogContext).platformBrightness == Brightness.dark);

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
                Text(
                  // Le bocal plein RACONTE quelque chose : Lora, comme les
                  // paliers et les badges. Les deux autres modales de cet
                  // écran (accès galerie, achat) DEMANDENT : elles restent en
                  // sans-serif.
                  l10n.jarFullTitle,
                  style: styleTitreRecit.copyWith(color: couleurTitre),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.jarFullMessage,
                  style: styleSecondaire.copyWith(color: couleurDescription),
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
                      Navigator.of(dialogContext).pop();
                      setState(() {
                        _prochainBocalDoitAnimerDemarrage = true;
                        UserPrefs.bocalResetOffset = UserPrefs.bocalResetOffset + _capaciteBocal;
                      });
                    },
                    child: Text(
                      l10n.btnNewJar,
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

  void _ouvrirHistoriqueDepuisBurger(BuildContext context) {
    debugPrint("--- DEBUG burger : isAttached=${_historyController.isAttached} ---");
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

  // Tailles proportionnelles à la largeur, mais BORNÉES. Sans borne, la
  // question d'accueil passait à 72 pt sur un iPad tenu en portrait, et à
  // 95 pt en paysage — un écran d'affichage de gare, pas une app intime.
  double responsiveWelcomeFontSize = (screenWidth * 0.05).clamp(18.0, 26.0);
  double responsiveQuestionFontSize = (screenWidth * 0.07).clamp(24.0, 36.0);

  // `MyApp.themeNotifier` pilote le `themeMode` du MaterialApp : tout
  // changement reconstruit cet écran, il n'y a donc rien à écouter ici.
  final ThemeMode modeCourant = MyApp.themeNotifier.value;
  final bool isDarkMode = modeCourant == ThemeMode.system
      ? (MediaQuery.platformBrightnessOf(context) == Brightness.dark)
      : (modeCourant == ThemeMode.dark);
  Home.isDarkMode = isDarkMode;

  return Container(
    // Fond clair : le contraste de l'ancien aplat orange écrasait le bocal.
    color: isDarkMode ? darkBg : lightOrange,
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
                          themeActuel.homeIconColor!.withValues(alpha: themeActuel.homeIconOpacity),
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

                  // Le bocal suit la hauteur de l'écran, MAIS il est borné.
                  //
                  // Sur un iPad 13 pouces, 35 % de la hauteur donnaient un
                  // bocal de près de cinq cents points de haut. Or le rayon
                  // d'une bille est plafonné à 26 points (voir
                  // BocalPastilles) : les quarante-cinq billes devenaient des
                  // grains de sable perdus au fond d'un aquarium. Borner le
                  // bocal rétablit le rapport entre le contenant et son
                  // contenu, et laisse simplement plus d'air autour sur les
                  // grands écrans.
                  double bocalHeight = (heightScreen * 0.35).clamp(180.0, 420.0);
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
                          // Sur tablette, 80 % de la largeur font une ligne de
                          // texte d'un mètre : l'œil perd le début de la ligne
                          // suivante. On borne la colonne et on la centre —
                          // sans effet sur téléphone, déjà plus étroit.
                          child: ContenuCentre(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // L'accueil et sa question ne se touchent pas :
                              // ils ne prennent donc jamais l'orange, qui
                              // signale une action dans cette application. Ils
                              // portent le marron de l'accueil, qui n'existe
                              // qu'ici — et seulement en mode clair, où il est
                              // lisible. Voir texteTitreAccueil.
                              //
                              // Les deux lignes forment un seul titre : elles
                              // changent de couleur ensemble, toujours.
                              Text(
                                l10n.welcomeMessage(prenomAffiche),
                                style: styleTitreLora.copyWith(
                                  color: texteTitreAccueil(isDarkMode),
                                  fontSize: tailleLora(responsiveWelcomeFontSize),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.mainQuestion(accordAffiche),
                                style: styleTitreLora.copyWith(
                                  color: texteTitreAccueil(isDarkMode),
                                  fontSize: tailleLora(responsiveQuestionFontSize),
                                  height: 1.2,
                                ),
                              ),
                            ],
                            ),
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
            // 1. Ombre AU SOL, en TROIS couches. L'ancienne ombre reprenait la
            //    silhouette entière du PNG et donnait l'impression que le
            //    bocal flottait dans le vide.
            //
            //    UNE SEULE SOURCE, POSÉE À GAUCHE. Les trois couches sont donc
            //    décalées vers la DROITE : leur bord gauche rentre sous le
            //    bocal, leur bord droit déborde franchement. Une ombre
            //    symétrique voudrait dire une lumière au zénith exact — c'est
            //    ce qui donnait l'impression d'un objet en lévitation.
            //
            //    ET ELLES SONT APLATIES. La hauteur de chaque ellipse et le
            //    flou VERTICAL sont bien plus faibles que leurs équivalents
            //    horizontaux : une ombre projetée sur une table s'étale au
            //    ras de la surface, elle ne monte pas.
            //
            //    Enfin, les trois couches racontent la même chose à trois
            //    distances : plus une couche est loin du bocal, plus elle est
            //    large, floue et pâle. C'est ce dégradé-là qui fait la
            //    profondeur — une ombre unique, si dense soit-elle, reste un
            //    autocollant.
            //
            //    1a. Le halo : la traîne la plus lointaine, celle qui part le
            //        plus loin sur la droite et se perd dans le fond.
            Positioned(
              left: bocalWidth * 0.10,
              right: -bocalWidth * 0.32,
              bottom: -bocalHeight * 0.010,
              height: bocalHeight * 0.105,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 44.0, sigmaY: 11.0, tileMode: TileMode.decal),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(bocalWidth, bocalHeight * 0.105),
                    ),
                  ),
                ),
              ),
            ),

            //    1b. La nappe : le corps de l'ombre, encore floue mais déjà
            //        lisible comme une forme.
            Positioned(
              left: bocalWidth * 0.14,
              right: -bocalWidth * 0.16,
              bottom: -bocalHeight * 0.012,
              height: bocalHeight * 0.068,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 8.0, tileMode: TileMode.decal),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: black.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(bocalWidth, bocalHeight * 0.068),
                    ),
                  ),
                ),
              ),
            ),

            //    1c. Le contact : resserré et plus dense, juste sous le verre.
            //        C'est cette dernière couche qui donne le sentiment que le
            //        bocal est POSÉ, et non simplement dessiné par-dessus.
            //        Elle est la moins décalée des trois : au point de contact,
            //        l'ombre touche encore l'objet.
            Positioned(
              left: bocalWidth * 0.23,
              right: bocalWidth * 0.07,
              bottom: bocalHeight * 0.012,
              height: bocalHeight * 0.026,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 3.0, tileMode: TileMode.decal),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: black.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(bocalWidth, bocalHeight * 0.026),
                    ),
                  ),
                ),
              ),
            ),

            // 2. LA STRUCTURE DU VERRE, derrière les billes.
            //
            //    `bocal_new.png` était un aplat quasi blanc OPAQUE : même à
            //    63 % d'opacité il restait une assiette grise posée sur le
            //    fond, et en mode sombre il crevait l'écran. `bocal_verre.png`
            //    est un MASQUE dont l'alpha suit l'inverse de la luminance du
            //    dessin : le remplissage blanc y est devenu transparent, seuls
            //    subsistent les traits et un voile de paroi. On le teinte donc
            //    en code — sombre sur fond clair, clair sur fond sombre.
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isDarkMode ? _verreSombre : _verreClair,
                  BlendMode.srcIn,
                ),
                child: const Image(
                  image: AssetImage('assets/bocal_verre.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 3. Pastilles (Les billes de souvenirs animées)
            Positioned.fill(
              child: BocalPastilles(
                key: ValueKey(UserPrefs.bocalResetOffset),
                capaciteBocal: _capaciteBocal,
                offsetBocal: UserPrefs.bocalResetOffset,
                animerDemarrage: _prochainBocalDoitAnimerDemarrage,
                onBocalPlein: () {
                  _bocalPleinEnAttente = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _tenterAfficherPopupBocalPlein(context);
                  });
                },
              ),
            ),

            // 4. LES REFLETS DU VERRE, PAR-DESSUS les billes.
            //
            //    Ce sont les stries quasi blanches des flancs du bocal,
            //    isolées du dessin d'origine par leur luminance. Posées
            //    devant, elles glissent sur les billes : c'est précisément ce
            //    qui donne l'impression de regarder à travers une paroi, et
            //    non un décor dessiné autour d'elles.
            Positioned.fill(
              child: IgnorePointer(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    isDarkMode ? _refletSombre : _refletClair,
                    BlendMode.srcIn,
                  ),
                  child: const Image(
                    image: AssetImage('assets/bocal_reflets_verre.png'),
                    fit: BoxFit.contain,
                  ),
                ),
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
                                    final int souvenirsActuels = await DatabaseService().getTotalNotesCount();

                                    // Une seule source de vérité pour le statut
                                    // premium : UserPrefs (persistant).
                                    if (!UserPrefs.isPremium &&
                                        souvenirsActuels >= UserPrefs.limiteSouvenirsGratuits) {
                                      if (!context.mounted) return;
                                      _ouvrirAlerteAchat(context);
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
    final int souvenirsActuels = await DatabaseService().getTotalNotesCount();

    // Même limite que pour les photos : 25 souvenirs tous types confondus.
    if (!UserPrefs.isPremium &&
        souvenirsActuels >= UserPrefs.limiteSouvenirsGratuits) {
      if (!context.mounted) return;
      _ouvrirAlerteAchat(context);
    } else {
      List<SourireTheme> couleursDisponibles = List.from(SourireTheme.tousLesThemes);

      if (couleursDisponibles.length > 1 && _derniereCouleurNote != null) {
        couleursDisponibles.removeWhere((theme) => theme.label == _derniereCouleurNote!.label);
      }

      couleursDisponibles.shuffle();
      final SourireTheme couleurChoisie = couleursDisponibles.first;
      _derniereCouleurNote = couleurChoisie;

      // Le thème des NOTES, pas celui du décor : depuis la baguette, les deux
      // vivent séparément. Voir ThemeService.
      final ThemeApp themeVisuelSelectionne = ThemeService.themeNoteNotifier.value;

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
            // La valeur de départ vient du cache du service : le flux, lui, ne
            // rejoue rien et ne déclenche plus de lecture. Voir DatabaseService.
            initialData: databaseService.notesEnCache,
            stream: databaseService.getNotesStream(),
            builder: (context, snapshot) {
              final notesFluides = snapshot.data ?? [];

              return Positioned.fill(
                child: WidgetHistorique(
                  notes: notesFluides,
                  controller: _historyController,
                  isDark: UserPrefs.isDark,
                  onNotesChanged: () {},
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
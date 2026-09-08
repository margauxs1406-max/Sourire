import 'package:flutter/material.dart';
import 'package:sourire/main.dart'; 
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/categorie_glissable.dart';
import 'package:sourire/widgets/pastille_nombre.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/widgets/btn_categorisation.dart'; 
import 'package:sourire/models/note_model.dart';
import 'package:sourire/screens/screen_apercu_lot.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/services/photo_service.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/widgets/btn_action_categorie.dart';
import 'package:sourire/services/notifications_service.dart';
import 'package:sourire/widgets/souvenir_historique.dart';

/// Valeur renvoyée par `Navigator.pop` quand l'utilisateur touche le chevron
/// de retour depuis le PREMIER écran de catégorisation.
///
/// La galerie n'est pas une page de l'application : `AssetPicker.pickAssets`
/// est une fonction qui s'ouvre, se referme et rend une liste. Elle n'existe
/// donc plus dans la pile de navigation au moment où l'on catégorise, et un
/// simple `pop` ramènerait à l'accueil. On remonte plutôt ce drapeau jusqu'à
/// la home, qui rouvre le sélecteur avec la sélection précédente déjà cochée.
const String retourVersGalerie = 'retour_galerie';

class ScreenCategorisationPhoto extends StatefulWidget {
  final List<AssetEntity> photos; 
  final int currentIndex;

  /// Catégoriser TOUTES les photos d'un coup plutôt qu'une par une.
  ///
  /// C'est le comportement par défaut d'une sélection multiple : quelqu'un qui
  /// vient de choisir dix photos de son fils veut les ranger d'un geste, pas
  /// répondre dix fois à la même question. L'écran offre une échappatoire vers
  /// le mode unitaire pour les lots hétérogènes.
  ///
  /// Sans effet sur une sélection d'une seule photo.
  final bool modeLot;

  /// `true` quand cet écran a été ouvert depuis l'écran de lot.
  ///
  /// Change ce que fait le chevron de retour : on remonte à l'écran de lot,
  /// posé juste en dessous dans la pile, au lieu de rouvrir la galerie.
  final bool venuDuLot;

  /// Catégories déjà cochées à l'ouverture.
  ///
  /// Sert au passage du mode lot au mode unitaire : ce que l'utilisateur avait
  /// coché pour l'ensemble devient le point de départ de chaque photo, qu'il
  /// n'a plus qu'à affiner.
  final List<String> categoriesInitiales;

  const ScreenCategorisationPhoto({
    required this.photos,
    this.currentIndex = 0,
    this.modeLot = true,
    this.venuDuLot = false,
    this.categoriesInitiales = const <String>[],
    super.key,
  });

  @override
  State<ScreenCategorisationPhoto> createState() => _ScreenCategorisationPhotoState();
}

class _ScreenCategorisationPhotoState extends State<ScreenCategorisationPhoto> {
  final DatabaseService _databaseService = DatabaseService();
  final List<String> _selectedCategories = [];

  /// `true` quand l'écran range plusieurs photos d'un seul geste.
  bool get enLot => widget.modeLot && widget.photos.length > 1;

  /// Nombre de photos qui SUIVENT celle montrée en vignette — le « +9 ».
  int get photosSuivantes => widget.photos.length - 1;
  final TextEditingController _newCategoryController = TextEditingController();
  bool _isAddingNew = false;

  // --- SÉCURITÉ ANTI DOUBLE-TAP ---------------------------------------------
  // 1) Verrou d'instance : passe à true de façon SYNCHRONE, avant tout await,
  //    donc avant même le premier rebuild. Sert aussi à l'affichage (spinner).
  bool _isSaving = false;

  // 2) Quelle action est en cours ('skip' ou 'validate') : permet de n'afficher
  //    l'indicateur de chargement que sur le bouton réellement pressé.
  String? _actionEnCours;

  // 3) Verrou global (static) : sur un écran 120 Hz, plusieurs instances de cet
  //    écran peuvent coexister dans la pile de navigation (route empilée
  //    pendant la transition). Le verrou d'instance ne les couvrirait pas.
  static bool _enregistrementGlobalEnCours = false;

  // 4) Index de photos déjà écrites en base pour la session de catégorisation
  //    en cours. Empêche tout ré-enregistrement (retour arrière puis nouvelle
  //    validation, route dupliquée, etc.).
  static final Set<int> _indexDejaEnregistres = <int>{};

  bool get isLast => widget.currentIndex == widget.photos.length - 1;
  bool get isMultiple => widget.photos.length > 1;

  @override
  void initState() {
    super.initState();
    // Nouvelle session de catégorisation : on repart d'une ardoise propre.
    if (widget.currentIndex == 0) {
      _indexDejaEnregistres.clear();
      _enregistrementGlobalEnCours = false;
    }
    _selectedCategories.addAll(widget.categoriesInitiales);
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayLabel(String key, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (key) {
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

  /// La photo n'est plus COPIÉE telle quelle : elle est redimensionnée à
  /// 1600 px de côté et réencodée en JPEG, ce qui divise son poids par dix
  /// sans perte visible.
  ///
  /// Le redimensionnement est délégué au système plutôt qu'au décodeur Dart —
  /// voir `PhotoService.enregistrerDepuisGalerie`, qui documente pourquoi la
  /// différence se compte en secondes.
  Future<String?> _sauvegarderFichierEnLocal(AssetEntity asset) =>
      PhotoService.enregistrerDepuisGalerie(asset);

  /// Prend le verrou de façon SYNCHRONE (aucun await avant l'affectation).
  /// Retourne false si un enregistrement est déjà en cours : le tap est ignoré.
  bool _prendreVerrou(String action) {
    if (_isSaving || _enregistrementGlobalEnCours) return false;
    _enregistrementGlobalEnCours = true;
    _isSaving = true;
    _actionEnCours = action;
    // setState uniquement pour rafraîchir l'UI : les verrous sont déjà posés
    // au-dessus, ils ne dépendent donc pas du cycle de rendu.
    setState(() {});
    return true;
  }

  void _relacherVerrou() {
    _enregistrementGlobalEnCours = false;
    if (!mounted) {
      _isSaving = false;
      _actionEnCours = null;
      return;
    }
    setState(() {
      _isSaving = false;
      _actionEnCours = null;
    });
  }

  /// Enregistre la photo [index] si elle ne l'a pas déjà été.
  Future<void> _enregistrerPhoto(int index, List<String> categories) async {
    if (_indexDejaEnregistres.contains(index)) return;
    // On réserve l'index AVANT l'await : deux appels concurrents ne peuvent
    // plus écrire la même photo deux fois.
    _indexDejaEnregistres.add(index);

    try {
      final String? localPath = await _sauvegarderFichierEnLocal(widget.photos[index]);
      if (localPath == null) {
        // Échec : on libère l'index pour permettre une nouvelle tentative.
        _indexDejaEnregistres.remove(index);
        return;
      }

      final nouvellePhoto = NoteSourire(
        text: null,
        photoPath: localPath,
        themeLabel: '',
        colorLabel: SourireTheme.getRandomPhoto().label,
        categories: categories.isEmpty ? ["unclassified"] : List<String>.from(categories),
        // `date` reste la date d'ENTRÉE dans le bocal : c'est elle qui ordonne
        // l'historique. La date de la galerie va dans `datePrise`, purement
        // informative — sans quoi une photo de 2019 importée aujourd'hui
        // replongerait tout au fond de l'historique.
        date: DateTime.now(),
        datePrise: widget.photos[index].createDateTime,
      );
      _databaseService.insertNote(nouvellePhoto);
      preloadHistoriqueImage(localPath); // volontairement SANS await
    } catch (e) {
      _indexDejaEnregistres.remove(index);
      rethrow;
    }
  }

  /// Range TOUTES les photos du lot dans les catégories cochées.
  ///
  /// Même boucle que [_passerTouteLaCategorisation], aux catégories près :
  /// c'est cette symétrie qui rend le mode lot presque gratuit.
  Future<void> _validerLeLot() async {
    if (!_prendreVerrou('validate')) return;

    try {
      for (int i = 0; i < widget.photos.length; i++) {
        await _enregistrerPhoto(i, _selectedCategories);
      }
      await NotificationService.planifierRappelSouvenirs();

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint("Échec de la validation du lot : $e");
      _relacherVerrou();
      return;
    } finally {
      _enregistrementGlobalEnCours = false;
    }
  }

  /// Ce que fait le chevron de retour, selon l'endroit où l'on se trouve.
  ///
  /// Trois situations, et une seule règle : on remonte d'un cran dans le
  /// parcours réel de l'utilisateur, pas dans la pile technique.
  /// - écran de lot, ou photo unique : la galerie, qu'il faut rouvrir ;
  /// - première photo d'une catégorisation une par une venue du lot : l'écran
  ///   de lot, qui est resté en dessous ;
  /// - photo suivante : la photo précédente.
  void _revenirEnArriere() {
    if (_isSaving) return;

    final bool premierEcran = widget.currentIndex == 0 && !widget.venuDuLot;
    Navigator.pop(context, premierEcran ? retourVersGalerie : null);
  }

  /// Ouvre le carrousel du lot, et écoute ce qu'il en revient.
  ///
  /// Le carrousel est désormais le seul endroit d'où l'on passe en mode une
  /// par une : c'est là qu'on découvre qu'un lot est hétérogène, donc là que
  /// la question se pose vraiment.
  Future<void> _ouvrirApercuDuLot() async {
    final bool? unParUn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenApercuLot(
          nombre: widget.photos.length,
          constructeurApercu: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AssetEntityImage(
              widget.photos[index],
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(1080),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );

    if (unParUn == true && mounted) _basculerEnUnParUn();
  }

  /// Bascule du mode lot vers le mode unitaire, sans rien perdre.
  ///
  /// Les catégories déjà cochées passent en pré-sélection : l'utilisateur qui
  /// a coché « Famille » pour l'ensemble n'a plus qu'à ajouter le prénom sur
  /// les deux photos qui le méritent.
  ///
  /// `push` et non `pushReplacement` : l'écran de lot reste en dessous, si
  /// bien que le chevron de retour depuis la première photo y ramène. On peut
  /// donc essayer le mode une par une et changer d'avis.
  void _basculerEnUnParUn() {
    if (_isSaving) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenCategorisationPhoto(
          photos: widget.photos,
          modeLot: false,
          venuDuLot: true,
          categoriesInitiales: List<String>.from(_selectedCategories),
        ),
      ),
    );
  }

  Future<void> _validerOuSuivant() async {
    if (enLot) return _validerLeLot();
    if (!_prendreVerrou('validate')) return;

    try {
      await _enregistrerPhoto(widget.currentIndex, _selectedCategories);
      await NotificationService.planifierRappelSouvenirs();

      if (!mounted) return;

      if (isLast) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenCategorisationPhoto(
              photos: widget.photos,
              currentIndex: widget.currentIndex + 1,
              modeLot: false,
              venuDuLot: widget.venuDuLot,
            ),
          ),
        ).then((_) {
          // Restaure l'état du bouton si l'utilisateur fait un retour arrière.
          if (mounted) {
            setState(() {
              _isSaving = false;
              _actionEnCours = null;
            });
          }
        });
      }
    } catch (e) {
      debugPrint("Échec de la validation : $e");
      _relacherVerrou();
      return;
    } finally {
      // Le verrou global est toujours relâché : l'écran suivant (ou l'écran
      // d'accueil) doit pouvoir travailler. Le verrou d'instance, lui, reste
      // actif tant qu'on n'est pas revenu sur cet écran.
      _enregistrementGlobalEnCours = false;
    }
  }

  Future<void> _passerTouteLaCategorisation() async {
    if (!_prendreVerrou('skip')) return;

    try {
      for (int i = widget.currentIndex; i < widget.photos.length; i++) {
        await _enregistrerPhoto(i, const <String>[]);
      }

      await NotificationService.planifierRappelSouvenirs();

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint("Échec du passage de la catégorisation : $e");
      _relacherVerrou();
      return;
    } finally {
      _enregistrementGlobalEnCours = false;
    }
  }

  void _soumettreNouvelleCategorie() {
    final text = _newCategoryController.text.trim();
    if (text.isNotEmpty) {
      final formattedText = text[0].toUpperCase() + text.substring(1);

      _databaseService.insertCategory(formattedText);
      setState(() {
        _selectedCategories.add(formattedText);
        _newCategoryController.clear();
        _isAddingNew = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final localizations = AppLocalizations.of(context)!;
    final String labelNouvelleCategorie = localizations.btnNewCategory;

    // Ces bandeaux sont posés en Positioned : leur hauteur ne peut pas être un
    // simple plancher. On l'indexe donc sur le facteur d'agrandissement du
    // texte du système, borné à 1,6 pour qu'un réglage extrême ne mange pas
    // toute la liste de catégories.
    final double echelleTexte =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6);
    const double topBarHeight = 60.0; 
    // Le bandeau est calé sur son contenu : 15 px au-dessus, l'aperçu de
    // 80 px, puis 8 px en dessous. Même hauteur que les écrans de note et de
    // recatégorisation — les trois écrans de catégorisation doivent se
    // superposer exactement quand on passe de l'un à l'autre.
    // Le facteur d'échelle du texte est conservé : il redonne de la marge
    // quand l'utilisateur grossit la police du système.
    final double titleHeight = 103.0 * echelleTexte;
    final double bottomBarHeight = 110.0 * echelleTexte;

    // Un bouton Valider est cliquable s'il y a des catégories ET qu'aucun enregistrement n'est en cours.
    final bool isValidateActive = _selectedCategories.isNotEmpty && !_isSaving;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_isAddingNew) {
          FocusScope.of(context).unfocus();
          setState(() {
            _newCategoryController.clear();
            _isAddingNew = false;
          });
        }
      },
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: MyApp.themeNotifier,
        builder: (context, currentThemeMode, child) {
          final bool isDarkMode = currentThemeMode == ThemeMode.system
    ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
    : (currentThemeMode == ThemeMode.dark);

          return Scaffold(
            backgroundColor: isDarkMode ? darkBg : white,
            resizeToAvoidBottomInset: false,
            // Pendant l'enregistrement, plus AUCUN pointeur n'est accepté sur
            // l'écran : ni les boutons, ni le chevron retour, ni les cases à
            // cocher. C'est la garantie ultime contre les taps en rafale.
            body: AbsorbPointer(
              absorbing: _isSaving,
              child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: topBarHeight,
                          child: Container(
                            color: isDarkMode ? darkBg : white,
                            padding: const EdgeInsets.only(top: 10),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  left: 0,
                                  child: BtnChevronGauche(
                                    onTap: _revenirEnArriere,
                                  ),
                                ),
                                const LogoSourire(color: orange),
                              ],
                            ),
                          ),
                        ),

                        Positioned(
                          top: topBarHeight,
                          left: 0,
                          right: 0,
                          height: titleHeight,
                          child: Container(
                            color: isDarkMode ? darkBg : white,
                            padding: const EdgeInsets.only(top: 15, bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    enLot
                                        ? localizations.batchCategoryQuestion
                                        : localizations.categoryQuestion,
                                    style: styleTitreLora.copyWith(
                                      // Un titre ne se touche pas : il reste en encre.
                                      color: texteTitre(isDarkMode),
                                      fontSize: tailleLora(screenWidth < 360 ? 18 : 22),
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                // La vignette montre la PREMIÈRE photo du lot,
                                // surmontée d'une pastille « +9 » : l'utilisateur
                                // doit voir d'un coup d'œil combien de souvenirs
                                // son choix va ranger.
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Structure reprise À L'IDENTIQUE de
                                    // WidgetSouvenirHistorique, qui sert
                                    // d'aperçu sur les deux autres écrans de
                                    // catégorisation : 80 px de côté, fond
                                    // sombre, rayon 6 à l'extérieur et 4 à
                                    // l'intérieur. C'est ce double rayon qui
                                    // manquait — un seul rayon de 10 donnait
                                    // des coins visiblement plus ronds.
                                    GestureDetector(
                                      // En lot, la vignette ouvre le
                                      // carrousel du lot entier : la
                                      // pastille « +9 » dit COMBIEN de
                                      // photos on s'apprête à ranger, elle
                                      // ne dit pas LESQUELLES.
                                      onTap: enLot ? _ouvrirApercuDuLot : null,
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1E1E),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: AssetEntityImage(
                                            widget.photos[widget.currentIndex],
                                            isOriginal: false, // ← miniature, pas l'original
                                            thumbnailSize: const ThumbnailSize.square(240),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (enLot)
                                      Positioned(
                                        right: -6,
                                        top: -6,
                                        child: PastilleNombre(nombre: photosSuivantes),
                                      ),
                                  ],
                                ),
                            ],
                            ),
                          ),
                        ),

                        Positioned(
                          top: topBarHeight + titleHeight,
                          left: 0,
                          right: 0,
                          bottom: keyboardHeight > 0 ? keyboardHeight : bottomBarHeight,
                          child: StreamBuilder<List<String>>(
                            initialData: _databaseService.categoriesEnCache,
                            stream: _databaseService.getCategoriesStream(),
                            builder: (context, snapshot) {
                              final categoriesList = snapshot.data ?? _databaseService.getAllCategories();

                              double screenWidth = MediaQuery.of(context).size.width;
                              double adaptiveFontSize = (screenWidth * 0.045).clamp(14.0, 22.0);

                              // Sur tablette, une liste de catégories large
                              // de mille points laisse la case à cocher à un
                              // bout de la dalle et le libellé à l'autre. On
                              // borne la colonne, et on la centre.
                              return ContenuCentre(
                                child: ListView.builder(
                                padding: const EdgeInsets.only(top: 5, bottom: 10),
                                // Les catégories, puis « Nouvelle catégorie ».
                                itemCount: categoriesList.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == categoriesList.length) {
                                    if (_isAddingNew) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: TextField(
                                          controller: _newCategoryController,
                                          autofocus: true,
                                          cursorColor: orange,
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.white : Colors.grey[600],
                                            fontSize: adaptiveFontSize,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: localizations.hintNewCategory,
                                            hintStyle: TextStyle(
                                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                              fontSize: adaptiveFontSize,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: const Icon(Icons.check, color: orange),
                                              onPressed: _soumettreNouvelleCategorie,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: const BorderSide(color: orange),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: const BorderSide(color: orange, width: 2),
                                            ),
                                          ),
                                          onSubmitted: (_) => _soumettreNouvelleCategorie(),
                                        ),
                                      );
                                    }
                                    return BoutonActionCategorie(
                                      label: labelNouvelleCategorie,
                                      icon: Icons.add,
                                      color: orange,
                                      hasCircle: true,
                                      // Filet sous la ligne et « + » à la
                                      // suite du texte : « Nouvelle catégorie »
                                      // se lit comme la dernière entrée de la
                                      // liste, son libellé aligné sur les noms
                                      // de catégories.
                                      separateur: true,
                                      iconeEnFin: true,
                                      isDarkMode: isDarkMode,
                                      useThemeStyleForText: false,
                                      onTap: () {
                                        setState(() {
                                          _isAddingNew = true;
                                        });
                                      },
                                    );
                                  }
                                  final categoryKey = categoriesList[index];
                                  return CategorieGlissable(
                                    cleCategorie: categoryKey,
                                    label: _getCategoryDisplayLabel(categoryKey, context),
                                    isSelected: _selectedCategories.contains(categoryKey),
                                    isDarkMode: isDarkMode,
                                    onSelectionChanged: (val) {
                                      setState(() {
                                        val ? _selectedCategories.add(categoryKey) : _selectedCategories.remove(categoryKey);
                                      });
                                    },
                                    onSuppression: () {
                                      setState(() {
                                        _selectedCategories.remove(categoryKey);
                                      });
                                    },
                                  );
                                },
                              ),
                              );
                            },
                          ),
                        ),

                        // ZONE 3. BANDEAU BAS AVEC SÉCURITÉ ANTI DOUBLE-TAP
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: bottomBarHeight,
                          child: Container(
                            color: isDarkMode ? darkBg : white,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // BOUTON PASSER
                                Expanded(
                                  child: BtnCategorisation(
                                    text: localizations.btnSkip,
                                    isSecondary: true,
                                    // Se grise et bloque les clics si un enregistrement est en cours
                                    isActive: !_isSaving,
                                    isLoading: _isSaving && _actionEnCours == 'skip',
                                    onTap: _passerTouteLaCategorisation,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // BOUTON VALIDER / SUIVANT
                                Expanded(
                                  child: BtnCategorisation(
                                    // En lot, un « Suivant » mentirait : il n'y
                                    // a pas d'écran suivant, tout est rangé
                                    // d'un coup.
                                    text: (enLot || isLast)
                                        ? localizations.btnValidate
                                        : (localizations.localeName == 'fr' ? "Suivant" : "Next"),
                                    isActive: isValidateActive,
                                    isLoading: _isSaving && _actionEnCours == 'validate',
                                    isSecondary: false,
                                    onTap: _validerOuSuivant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      ],
                    );
                  },
                ),
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}

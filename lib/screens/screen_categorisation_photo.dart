import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sourire/main.dart'; 
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/item_categorie.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/widgets/btn_categorisation.dart'; 
import 'package:sourire/models/note_model.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/services/photo_service.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/widgets/btn_action_categorie.dart';
import 'package:sourire/services/notifications_service.dart';
import 'package:sourire/widgets/souvenir_historique.dart';

class ScreenCategorisationPhoto extends StatefulWidget {
  final List<AssetEntity> photos; 
  final int currentIndex;

  const ScreenCategorisationPhoto({
    required this.photos,
    this.currentIndex = 0,
    super.key,
  });

  @override
  State<ScreenCategorisationPhoto> createState() => _ScreenCategorisationPhotoState();
}

class _ScreenCategorisationPhotoState extends State<ScreenCategorisationPhoto> {
  final DatabaseService _databaseService = DatabaseService();
  final List<String> _selectedCategories = [];
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
  /// sans perte visible. Voir PhotoService pour le détail du compromis.
  Future<String?> _sauvegarderFichierEnLocal(AssetEntity asset) async {
    final File? fileOrigin = await asset.file;
    if (fileOrigin == null) {
      debugPrint("Erreur : Impossible d'accéder au fichier d'origine de l'asset.");
      return null;
    }
    return PhotoService.enregistrer(fileOrigin);
  }

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

  Future<void> _validerOuSuivant() async {
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

  void _ouvrirModaleSuppression(BuildContext context, bool isDarkMode) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<List<String>>(
          stream: _databaseService.getCategoriesStream(),
          builder: (context, snapshot) {
            final categoriesList = snapshot.data ?? _databaseService.getAllCategories();
            const systemKeys = ["self_love", "friendship", "couple", "family", "leisure", "work"];
            final customList = categoriesList.where((cat) => !systemKeys.contains(cat)).toList();
            
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                localizations.titleDeleteModal,
                style: styleTitreAction.copyWith(color: texteFort(isDarkMode)),
              ),
              content: customList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        localizations.noCustomCategoryToDelete,
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      height: 250,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: customList.length,
                        itemBuilder: (context, index) {
                          final currentCat = customList[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              currentCat,
                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                _databaseService.deleteCategory(currentCat);
                                setState(() {
                                  _selectedCategories.remove(currentCat);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.btnClose, style: const TextStyle(color: orange, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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
    final double titleHeight = 90.0 * echelleTexte;
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
                                    onTap: () => Navigator.pop(context),
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
                            padding: const EdgeInsets.only(top: 15, bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    localizations.categoryQuestion,
                                    style: styleTitreLora.copyWith(
                                      color: isDarkMode ? Colors.white : orange,
                                      fontSize: tailleLora(screenWidth < 360 ? 18 : 22),
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: AssetEntityImage(
    widget.photos[widget.currentIndex],
    isOriginal: false, // ← demande une miniature, pas le fichier original
    thumbnailSize: const ThumbnailSize.square(150), // ← résolution du décodage, pas de l'affichage
    width: 65,
    height: 65,
    fit: BoxFit.cover,
  ),
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
                            stream: _databaseService.getCategoriesStream(),
                            builder: (context, snapshot) {
                              final categoriesList = snapshot.data ?? _databaseService.getAllCategories();

                              double screenWidth = MediaQuery.of(context).size.width;
                              double adaptiveFontSize = (screenWidth * 0.045).clamp(14.0, 22.0);

                              return ListView.builder(
                                padding: const EdgeInsets.only(top: 5, bottom: 10),
                                itemCount: categoriesList.length + 2,
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
                                      isDarkMode: isDarkMode,
                                      useThemeStyleForText: false,
                                      onTap: () {
                                        setState(() {
                                          _isAddingNew = true;
                                        });
                                      },
                                    );
                                  }
                                  if (index == categoriesList.length + 1) {
                                    return BoutonActionCategorie(
                                      label: localizations.btnDeleteCategories,
                                      icon: Icons.delete_outline,
                                      color: orange,
                                      hasCircle: false,
                                      isDarkMode: isDarkMode,
                                      useThemeStyleForText: true,
                                      onTap: () => _ouvrirModaleSuppression(context, isDarkMode),
                                    );
                                  }
                                  final categoryKey = categoriesList[index];
                                  return ItemCategorie(
                                    label: _getCategoryDisplayLabel(categoryKey, context),
                                    isSelected: _selectedCategories.contains(categoryKey),
                                    color: orange,
                                    isDarkMode: isDarkMode,
                                    onSelectionChanged: (val) {
                                      setState(() {
                                        val ? _selectedCategories.add(categoryKey) : _selectedCategories.remove(categoryKey);
                                      });
                                    },
                                  );
                                },
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
                                    text: isLast
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
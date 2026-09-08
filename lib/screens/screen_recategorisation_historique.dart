import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/main.dart'; 
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/btn_action.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/screens/screen_apercu_lot.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/widgets/categorie_glissable.dart';
import 'package:sourire/widgets/pastille_nombre.dart';
import 'package:sourire/widgets/souvenir_historique.dart';
import 'package:sourire/widgets/btn_action_categorie.dart';

class ScreenRecategorisationHistorique extends StatefulWidget {
  final List<NoteSourire> souvenirs;
  final int currentIndex;

  /// Recatégoriser TOUS les souvenirs sélectionnés d'un coup.
  ///
  /// Comportement par défaut d'une sélection multiple dans l'historique, avec
  /// une échappatoire vers le mode unitaire. Voir la documentation du même
  /// champ dans `ScreenCategorisationPhoto`.
  ///
  /// Sans effet sur un souvenir seul.
  final bool modeLot;

  /// Catégories déjà cochées à l'ouverture, pour le passage du lot à l'unité.
  final List<String>? categoriesInitiales;

  const ScreenRecategorisationHistorique({
    required this.souvenirs,
    this.currentIndex = 0,
    this.modeLot = true,
    this.categoriesInitiales,
    super.key,
  });

  @override
  State<ScreenRecategorisationHistorique> createState() => _ScreenRecategorisationHistoriqueState();
}

class _ScreenRecategorisationHistoriqueState extends State<ScreenRecategorisationHistorique> {
  final DatabaseService _databaseService = DatabaseService();
  final List<String> _selectedCategories = [];
  final TextEditingController _newCategoryController = TextEditingController();
  bool _isAddingNew = false;
  bool get isLast => widget.currentIndex == widget.souvenirs.length - 1;

  /// `true` quand l'écran range plusieurs souvenirs d'un seul geste.
  bool get enLot => widget.modeLot && widget.souvenirs.length > 1;

  /// Nombre de souvenirs qui SUIVENT celui montré en vignette — le « +9 ».
  int get souvenirsSuivants => widget.souvenirs.length - 1;

  @override
  void initState() {
    super.initState();

    // En arrivant du mode lot, on repart des catégories déjà cochées pour
    // l'ensemble. Sinon on part de celles du souvenir courant.
    //
    // En mode lot lui-même, on part d'une ardoise VIDE et non des catégories
    // du premier souvenir : valider écrasera celles de tous les autres, il
    // serait déloyal de pré-cocher au nom d'un seul.
    if (widget.categoriesInitiales != null) {
      _selectedCategories.addAll(widget.categoriesInitiales!);
    } else if (!enLot) {
      _selectedCategories.addAll(
        widget.souvenirs[widget.currentIndex].categories.where((cat) => 
          cat != "sans_categorie" && 
          cat != "Non classées" && 
          cat != "Non classé"
        )
      );
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
      case "self_love": return localizations.catSelfLove;
      case "friendship": return localizations.catFriendship;
      case "couple": return localizations.catCouple;
      case "family": return localizations.catFamily;
      case "leisure": return localizations.catLeisure;
      case "work": return localizations.catWork;
      default: return key;
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

  /// Applique les catégories cochées à TOUS les souvenirs du lot.
  void _validerLeLot() {
    final List<String> nouvelles = _selectedCategories.isEmpty
        ? ["sans_categorie"]
        : List<String>.from(_selectedCategories);

    for (int i = 0; i < widget.souvenirs.length; i++) {
      final NoteSourire misAJour =
          widget.souvenirs[i].copyWith(categories: nouvelles);
      _databaseService.updateNote(misAJour);
      widget.souvenirs[i] = misAJour;
    }

    if (mounted) Navigator.of(context).pop(widget.souvenirs);
  }

  /// Ouvre le carrousel du lot, et écoute ce qu'il en revient.
  Future<void> _ouvrirApercuDuLot() async {
    final bool? unParUn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenApercuLot(
          nombre: widget.souvenirs.length,
          // WidgetSouvenirHistorique met tout à l'échelle de la largeur qu'on
          // lui donne — texte comme icônes de thème. Le même widget sert donc
          // de vignette de 80 px et d'aperçu plein écran.
          constructeurApercu: (context, index) =>
              WidgetSouvenirHistorique(souvenir: widget.souvenirs[index]),
        ),
      ),
    );

    if (unParUn == true && mounted) _basculerEnUnParUn();
  }

  /// Bascule du mode lot vers le mode unitaire en gardant la pré-sélection.
  ///
  /// `push` et non `pushReplacement` : l'écran de lot reste en dessous, si
  /// bien que le chevron de retour depuis le premier souvenir y ramène. On
  /// peut donc essayer le mode une par une et changer d'avis.
  void _basculerEnUnParUn() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenRecategorisationHistorique(
          souvenirs: widget.souvenirs,
          modeLot: false,
          categoriesInitiales: List<String>.from(_selectedCategories),
        ),
      ),
    ).then((resultat) {
      // La liste mise à jour remonte de souvenir en souvenir jusqu'ici ; sans
      // ce relais, elle s'arrêterait sur l'écran de lot et l'historique ne se
      // rafraîchirait pas.
      if (mounted && resultat != null) {
        Navigator.of(context).pop(resultat);
      }
    });
  }

  void _validerOuSuivant() {
    if (enLot) return _validerLeLot();
    final souvenirActuel = widget.souvenirs[widget.currentIndex];
    final nouvellesCategories = _selectedCategories.isEmpty 
        ? ["sans_categorie"] 
        : List<String>.from(_selectedCategories);
    final souvenirMisAJour = souvenirActuel.copyWith(
      categories: nouvellesCategories,
    );

    _databaseService.updateNote(souvenirMisAJour); 
    widget.souvenirs[widget.currentIndex] = souvenirMisAJour;
    if (isLast) {
      if (mounted) {
        Navigator.of(context).pop(widget.souvenirs);
      }
    } else {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenRecategorisationHistorique(
              souvenirs: widget.souvenirs,
              currentIndex: widget.currentIndex + 1,
            ),
          ),
        ).then((resultatDuSuivant) {
          if (mounted && resultatDuSuivant != null) {
            Navigator.of(context).pop(resultatDuSuivant);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    double screenWidth = MediaQuery.of(context).size.width;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    final souvenir = widget.souvenirs[widget.currentIndex];
    final String labelNouvelleCategorie = localizations.btnNewCategory;
    // Ces bandeaux sont posés en Positioned : leur hauteur ne peut pas être un
    // simple plancher. On l'indexe donc sur le facteur d'agrandissement du
    // texte du système, borné à 1,6 pour qu'un réglage extrême ne mange pas
    // toute la liste de catégories.
    final double echelleTexte =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6);
    const double topBarHeight = 60.0; 
    // Le bandeau est calé sur son contenu : 15 px au-dessus, l'aperçu de
    // 80 px, puis 8 px en dessous. Il restait auparavant du vide sous le
    // titre. Le facteur d'échelle du texte est conservé : il redonne de la
    // marge quand l'utilisateur grossit la police du système.
    final double titleHeight = 103.0 * echelleTexte;
    final double bottomBarHeight = 110.0 * echelleTexte;

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
            body: SafeArea(
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
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: BtnChevronGauche(
                                    onTap: () => Navigator.pop(context),
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.center,
                                  child: LogoSourire(color: orange),
                                ),
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
                                // La vignette montre le PREMIER souvenir du
                                // lot, surmonté d'une pastille « +9 » : on
                                // doit voir d'un coup d'œil combien de
                                // souvenirs le choix va ranger.
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      // En lot, la vignette ouvre le
                                      // carrousel du lot entier : la
                                      // pastille « +9 » dit COMBIEN de
                                      // souvenirs on s'apprête à ranger,
                                      // elle ne dit pas LESQUELS.
                                      onTap: enLot ? _ouvrirApercuDuLot : null,
                                      child: SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: WidgetSouvenirHistorique(
                                          souvenir: souvenir,
                                        ),
                                      ),
                                    ),
                                    if (enLot)
                                      Positioned(
                                        right: -6,
                                        top: -6,
                                        child: PastilleNombre(
                                            nombre: souvenirsSuivants),
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
                                              borderSide: BorderSide(color: orange),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide(color: orange, width: 2),
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
                        
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0, 
                          height: bottomBarHeight,
                          child: Container(
                            color: isDarkMode ? darkBg : white, 
                            padding: const EdgeInsets.only(bottom: 30, top: 10), 
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: double.infinity, 
                              height: 56, 
                              child: BtnAction(
                                text: (enLot || isLast)
                                    ? localizations.btnValidate
                                    : (localizations.localeName == 'fr' ? "Suivant" : "Next"),
                                isActive: _selectedCategories.isNotEmpty,
                                color: orange,
                                onTap: _validerOuSuivant,
                              ),
                            ),
                          ),
                        ),

                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
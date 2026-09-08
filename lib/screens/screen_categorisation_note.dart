import 'package:flutter/material.dart';
import 'package:sourire/main.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/btn_categorisation.dart';
import 'package:sourire/widgets/categorie_glissable.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/souvenir_historique.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/widgets/btn_action_categorie.dart';
import 'package:sourire/services/notifications_service.dart';

class ScreenCategorisationNote extends StatefulWidget {
  final String note;
  final SourireTheme theme; 
  final ThemeApp themeVisuel; // <-- Étape A : Déclare la propriété reçue

  const ScreenCategorisationNote({
    required this.note,
    required this.theme, 
    required this.themeVisuel, // <-- Étape B : Demande-la dans le constructeur
    super.key,
  });

  @override
  State<ScreenCategorisationNote> createState() => _ScreenCategorisationNoteState();
}

class _ScreenCategorisationNoteState extends State<ScreenCategorisationNote> {
  final DatabaseService _databaseService = DatabaseService();
  final List<String> _selectedCategories = [];
  final TextEditingController _newCategoryController = TextEditingController();
  bool _isAddingNew = false;

  // --- SÉCURITÉ ANTI DOUBLE-TAP ---------------------------------------------
  // 1) Verrou d'instance, posé de façon SYNCHRONE avant tout await.
  bool _isSaving = false;

  // 2) Action en cours ('skip' ou 'validate') pour n'afficher l'indicateur de
  //    chargement que sur le bouton réellement pressé.
  String? _actionEnCours;

  // 3) Verrou global : screen_new_note peut empiler plusieurs instances de cet
  //    écran si son bouton Valider est tapé en rafale. Le verrou d'instance ne
  //    couvrirait pas ce cas.
  static bool _enregistrementGlobalEnCours = false;

  // 4) Cette note a-t-elle déjà été écrite en base par cette instance ?
  bool _noteDejaEnregistree = false;

  /// Copie éphémère du souvenir, uniquement pour l'aperçu affiché à droite du
  /// titre. Construite une seule fois : rien ici ne doit dépendre d'un
  /// `DateTime.now()` réévalué à chaque rebuild.
  late final NoteSourire _apercu = NoteSourire(
    text: widget.note,
    themeLabel: widget.themeVisuel.id,
    colorLabel: widget.theme.label,
    categories: const [],
    date: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    // Filet de sécurité : on ne veut jamais qu'un verrou global resté bloqué
    // (crash, cas limite) empêche définitivement l'enregistrement.
    _enregistrementGlobalEnCours = false;
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayLabel(String key, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (key) {
      case 'self_love': return localizations.catSelfLove;
      case 'friendship': return localizations.catFriendship;
      case 'couple': return localizations.catCouple;
      case 'family': return localizations.catFamily;
      case 'leisure': return localizations.catLeisure;
      case 'work': return localizations.catWork;
      default: return key; 
    }
  }

  /// Prend le verrou de façon SYNCHRONE (aucun await avant l'affectation).
  /// Retourne false si un enregistrement est déjà en cours : le tap est ignoré.
  bool _prendreVerrou(String action) {
    if (_isSaving || _noteDejaEnregistree || _enregistrementGlobalEnCours) {
      return false;
    }
    _enregistrementGlobalEnCours = true;
    _isSaving = true;
    _actionEnCours = action;
    // setState sert uniquement au rafraîchissement visuel : les verrous sont
    // déjà posés au-dessus, ils ne dépendent pas du cycle de rendu.
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

  Future<void> _enregistrerNote(List<String> categories, String action) async {
    if (!_prendreVerrou(action)) return;

    try {
      final nouvelleNote = NoteSourire(
        text: widget.note,
        themeLabel: widget.themeVisuel.id,
        colorLabel: widget.theme.label,
        categories: categories,
        date: DateTime.now(),
      );
      _databaseService.insertNote(nouvelleNote);
      _noteDejaEnregistree = true;

      // RECALCULE LA PROCHAINE NOTIFICATION AVEC LE NOUVEAU SOUVENIR DISPONIBLE
      await NotificationService.planifierRappelSouvenirs();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // En cas d'erreur BDD, on débloque l'UI pour permettre une 2e tentative.
      debugPrint("Échec de l'enregistrement de la note : $e");
      _noteDejaEnregistree = false;
      _relacherVerrou();
    } finally {
      _enregistrementGlobalEnCours = false;
    }
  }

  Future<void> _validerNote() =>
      _enregistrerNote(List<String>.from(_selectedCategories), 'validate');

  Future<void> _passerCategorisation() =>
      _enregistrerNote(<String>["unclassified"], 'skip');

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
    // 120 et non 90 : c'est la hauteur qu'il faut pour loger l'aperçu de
    // 80 px à droite du titre, comme dans l'écran de recatégorisation.
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
          // Le bouton Valider n'est cliquable que s'il y a au moins une
          // catégorie ET qu'aucun enregistrement n'est en cours.
          final bool isValidateActive = _selectedCategories.isNotEmpty && !_isSaving;

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
                        
                        // 1. BANDEAU HAUT (STRICTEMENT FIXE)
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

                        // 1b. TITRE FIXE
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
                                    localizations.categoryQuestion,
                                    style: styleTitreLora.copyWith(
                                      // Un titre ne se touche pas : il reste en encre.
                                          color: texteTitre(isDarkMode),
                                      fontSize: tailleLora(screenWidth < 360 ? 18 : 22),
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                // Aperçu du souvenir en cours d'écriture, comme
                                // dans l'écran de recatégorisation. Le souvenir
                                // n'existe pas encore en base : on en fabrique
                                // une copie éphémère, uniquement pour l'affichage.
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: WidgetSouvenirHistorique(
                                    souvenir: _apercu,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. ZONE SCROLLABLE
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
                                              icon: Icon(Icons.check, color: orange),
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
                                        val ? _selectedCategories.add(categoryKey)
                                            : _selectedCategories.remove(categoryKey);
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
                                                    
                        // 3. BANDEAU BAS (BOUTONS AVEC SÉCURITÉ ANTI-DOUBLE TAP)
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
                                    // Devient opaque/inactif si un enregistrement est en cours
                                    isActive: !_isSaving,
                                    isLoading: _isSaving && _actionEnCours == 'skip',
                                    onTap: _passerCategorisation,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // BOUTON VALIDER
                                // Un seul widget quel que soit l'état : plus de
                                // bascule Opacity/AbsorbPointer, qui recréait le
                                // bouton (et perdait son état d'appui) à chaque
                                // changement de sélection.
                                Expanded(
                                  child: BtnCategorisation(
                                    text: localizations.btnValidate,
                                    isSecondary: false,
                                    isActive: isValidateActive,
                                    isLoading: _isSaving && _actionEnCours == 'validate',
                                    onTap: _validerNote,
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
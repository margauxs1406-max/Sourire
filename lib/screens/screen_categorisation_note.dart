import 'package:flutter/material.dart';
import 'package:sourire/main.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/btn_categorisation_dynamique.dart';
import 'package:sourire/widgets/item_categorie.dart';
import 'package:sourire/widgets/logo_sourire.dart';
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
  
  // MODIFICATION : Sécurité anti-double clic
  bool _isSaving = false;

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

  void _validerNote() async {
    if (_isSaving) return; // Sécurité supplémentaire

    setState(() {
      _isSaving = true; // Bloque immédiatement l'accès
    });

    try {
      final nouvelleNote = NoteSourire(
        text: widget.note,
        themeLabel: widget.themeVisuel.id, 
        colorLabel: widget.theme.label,   
        categories: _selectedCategories,
        date: DateTime.now(),
      );
      _databaseService.insertNote(nouvelleNote);
      
      // RECALCULE LA PROCHAINE NOTIFICATION AVEC LE NOUVEAU SOUVENIR DISPONIBLE
      await NotificationService.planifierRappelSouvenirs();
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // En cas d'erreur BDD, on débloque l'UI
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _passerCategorisation() async {
    if (_isSaving) return; // Sécurité supplémentaire

    setState(() {
      _isSaving = true; // Bloque immédiatement l'accès
    });

    try {
      final nouvelleNote = NoteSourire(
        text: widget.note,
        themeLabel: widget.themeVisuel.id, 
        colorLabel: widget.theme.label,   
        categories: ["unclassified"],
        date: DateTime.now(),
      );
      _databaseService.insertNote(nouvelleNote);
      
      // RECALCULE LA PROCHAINE NOTIFICATION AVEC LE NOUVEAU SOUVENIR DISPONIBLE
      await NotificationService.planifierRappelSouvenirs();
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // En cas d'erreur BDD, on débloque l'UI
      setState(() {
        _isSaving = false;
      });
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
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
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
                  child: Text(localizations.btnClose, style: TextStyle(color: widget.theme.main, fontWeight: FontWeight.bold)),
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

    const double topBarHeight = 60.0; 
    const double titleHeight = 90.0; 
    const double bottomBarHeight = 110.0; 

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
          final bool isValidateActive = _selectedCategories.isNotEmpty;

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
                            padding: const EdgeInsets.only(top: 15, bottom: 10),
                            alignment: Alignment.topLeft,
                            child: Text(
                              localizations.categoryQuestion, 
                              style: styleNoteLarge.copyWith(
                                color: isDarkMode ? Colors.white : widget.theme.main,
                                fontSize: screenWidth < 360 ? 18 : 22,
                                height: 1.2,
                              ),
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
                                          cursorColor: widget.theme.main,
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
                                              icon: Icon(Icons.check, color: widget.theme.main),
                                              onPressed: _soumettreNouvelleCategorie,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide(color: widget.theme.main),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide(color: widget.theme.main, width: 2),
                                            ),
                                          ),
                                          onSubmitted: (_) => _soumettreNouvelleCategorie(),
                                        ),
                                      );
                                    }

                                    return BoutonActionCategorie(
                                      label: labelNouvelleCategorie,
                                      icon: Icons.add,
                                      color: widget.theme.main,
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
                                      color: widget.theme.main,
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
                                    color: widget.theme.main,
                                    isDarkMode: isDarkMode,
                                    onSelectionChanged: (val) {
                                      setState(() {
                                        val ? _selectedCategories.add(categoryKey)
                                            : _selectedCategories.remove(categoryKey);
                                      });
                                    },
                                  );
                                },
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
  child: BtnCategorisationDynamique(
    text: localizations.btnSkip,
    isSecondary: true,
    themeColor: widget.theme.main,
    isActive: !_isSaving, // Devient opaque/inactif si un enregistrement est en cours
    onTap: () {
      if (!_isSaving) _passerCategorisation();
    },
  ),
),
const SizedBox(width: 20),
// BOUTON VALIDER
Expanded(
  child: isValidateActive 
    ? BtnCategorisationDynamique(
        text: localizations.btnValidate,
        isSecondary: false,
        themeColor: widget.theme.main,
        isActive: !_isSaving, // Devient opaque/inactif si un enregistrement est en cours
        onTap: () {
          if (!_isSaving) _validerNote();
        },
      )
    : Opacity(
        opacity: 0.5,
        child: AbsorbPointer(
          child: BtnCategorisationDynamique(
            text: localizations.btnValidate,
            isSecondary: false,
            themeColor: widget.theme.main,
            onTap: () {},
          ),
        ),
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
          );
        },
      ),
    );
  }
}
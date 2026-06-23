import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; 
import 'package:path/path.dart' as p; 
import 'package:sourire/main.dart'; 
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/item_categorie.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/widgets/btn_categorisation.dart'; 
import 'package:sourire/models/note_model.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/widgets/btn_action_categorie.dart';
import 'package:sourire/services/notifications_service.dart';

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

  bool get isLast => widget.currentIndex == widget.photos.length - 1;
  bool get isMultiple => widget.photos.length > 1;

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

  Future<String?> _sauvegarderFichierEnLocal(AssetEntity asset) async {
    try {
      final File? fileOrigin = await asset.file;
      if (fileOrigin == null) {
        debugPrint("Erreur : Impossible d'accéder au fichier d'origine de l'asset.");
        return null;
      }

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String uniqueName = "sourire_${DateTime.now().microsecondsSinceEpoch}.jpg";
      final String permanentPath = p.join(appDocDir.path, uniqueName);

      final File permanentFile = await fileOrigin.copy(permanentPath);

      debugPrint("Photo sauvegardée avec succès ici : $permanentPath");
      return permanentFile.path;
    } catch (e) {
      debugPrint("Échec de la sauvegarde locale : $e");
      return null;
    }
  }

  void _validerOuSuivant() async {
    final String? localPath = await _sauvegarderFichierEnLocal(widget.photos[widget.currentIndex]);
    if (localPath != null) {
      final nouvellePhoto = NoteSourire(
        text: null,
        photoPath: localPath, 
        themeLabel: '', 
        colorLabel: '',
        categories: _selectedCategories.isEmpty ? ["sans_categorie"] : List<String>.from(_selectedCategories),
        date: DateTime.now(), 
      );
      _databaseService.insertNote(nouvellePhoto);
      
      await NotificationService.planifierRappelSouvenirs();
    }

    if (isLast) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenCategorisationPhoto(
              photos: widget.photos,
              currentIndex: widget.currentIndex + 1,
            ),
          ),
        );
      }
    }
  }

  void _passerTouteLaCategorisation() async {
    for (int i = widget.currentIndex; i < widget.photos.length; i++) {
      final String? localPath = await _sauvegarderFichierEnLocal(widget.photos[i]);
      
      if (localPath != null) {
        final photoSansCategorie = NoteSourire(
          text: null,
          photoPath: localPath, 
          themeLabel: '', 
          colorLabel: '',
          categories: ["sans_categorie"],
          date: DateTime.now(),
        );
        _databaseService.insertNote(photoSansCategorie);
      }
    }

    await NotificationService.planifierRappelSouvenirs();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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

    const double topBarHeight = 60.0; 
    const double titleHeight = 90.0;
    const double bottomBarHeight = 110.0; 

    final bool isValidateActive = _selectedCategories.isNotEmpty;
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
          final bool isDarkMode = currentThemeMode == ThemeMode.dark;

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
                                    style: styleNoteLarge.copyWith(
                                      color: isDarkMode ? Colors.white : orange,
                                      fontSize: screenWidth < 360 ? 18 : 22,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AssetEntityImage(
                                    widget.photos[widget.currentIndex],
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
                                Expanded(
                                  child: BtnCategorisation(
                                    text: localizations.btnSkip,
                                    isSecondary: true,
                                    onTap: _passerTouteLaCategorisation,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: BtnCategorisation(
                                    text: isLast 
                                        ? localizations.btnValidate 
                                        : (localizations.localeName == 'fr' ? "Suivant" : "Next"),
                                    isActive: isValidateActive,
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
          );
        },
      ),
    );
  }
}
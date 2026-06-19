import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart'; 
import 'package:sourire/main.dart'; 
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/btn_croix.dart';
import 'package:sourire/widgets/btn_categorisation.dart'; // Remplacement de btn_action par btn_categorisation
import 'package:sourire/widgets/item_categorie.dart';
import 'package:sourire/services/database_service.dart';

class EcranFiltrer extends StatefulWidget {
  final List<String> categoriesSelectionneesInitiales;
  final Function(List<String>) onFiltrerApplique;

  const EcranFiltrer({
    required this.categoriesSelectionneesInitiales,
    required this.onFiltrerApplique,
    super.key,
  });

  @override
  State<EcranFiltrer> createState() => _EcranFiltrerState();
}

class _EcranFiltrerState extends State<EcranFiltrer> {
  final DatabaseService _databaseService = DatabaseService(); 
  final List<String> _categoriesTemporaires = [];

  @override
  void initState() {
    super.initState();
    _categoriesTemporaires.addAll(widget.categoriesSelectionneesInitiales);
  }

  void _modifierSelection(String categorieKey, bool coche) {
    setState(() {
      if (coche) {
        if (!_categoriesTemporaires.contains(categorieKey)) {
          _categoriesTemporaires.add(categorieKey);
        }
      } else {
        _categoriesTemporaires.remove(categorieKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    // Définition de la hauteur de l'overlay (ici 75% de l'écran)
    double overlayHeight = MediaQuery.of(context).size.height * 0.75;

    String _getTranslatedCategoryLabel(String key) {
      switch (key) {
        case "self_love": return localizations.catSelfLove;
        case "friendship": return localizations.catFriendship;
        case "couple": return localizations.catCouple;
        case "family": return localizations.catFamily;
        case "leisure": return localizations.catLeisure;
        case "work": return localizations.catWork;
        case "others": return localizations.catOthers;
        case "unclassified": return localizations.catUnclassified;
        default: return key;
      }
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentThemeMode, child) {
        final bool isDarkMode = currentThemeMode == ThemeMode.dark;

        return Container(
          height: overlayHeight,
          decoration: BoxDecoration(
            color: isDarkMode ? darkBg : white, 
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- EN-TÊTE ---
                SizedBox(
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BtnCroix(
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      Text(
                        localizations.filterTitle, 
                        style: styleBouton.copyWith(
                          fontFamily: 'Lobster Two',
                          fontStyle: FontStyle.italic,
                          color: orange,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- SECTION TITRE ---
                Text(
                  localizations.categoriesTitle, 
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : black, 
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // --- LISTE DES FILTRES SCROLLABLE ---
                Expanded(
                  child: StreamBuilder<List<String>>(
                    stream: _databaseService.getCategoriesStream(),
                    builder: (context, snapshot) {
                      final baseCategories = snapshot.data ?? _databaseService.getAllCategories();
                      final List<String> filtresListe = List<String>.from(baseCategories);
                      
                      if (!filtresListe.contains("unclassified")) {
                        filtresListe.add("unclassified");
                      }

                      return ListView.builder(
                        itemCount: filtresListe.length,
                        itemBuilder: (context, index) {
                          final categoryKey = filtresListe[index];
                          final bool estCochee = _categoriesTemporaires.contains(categoryKey);

                          return ItemCategorie(
                            label: _getTranslatedCategoryLabel(categoryKey),
                            isSelected: estCochee,
                            isDarkMode: isDarkMode, 
                            onSelectionChanged: (bool value) {
                              _modifierSelection(categoryKey, value);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // --- ZONE DES BOUTONS (Mis à jour avec BtnCategorisation)
                Row(
                  children: [
                    // 1. BOUTON RÉTABLIR
                    Expanded(
                      child: BtnCategorisation(
                        text: localizations.btnReset,
                        isSecondary: true,
                        onTap: () {
                          setState(() {
                            _categoriesTemporaires.clear();
                          });
                          widget.onFiltrerApplique(_categoriesTemporaires); 
                          Navigator.pop(context); 
                        },
                      ),
                    ),

                    const SizedBox(width: 16), 

                    // 2. BOUTON FILTRER
                    Expanded(
                      child: BtnCategorisation(
                        text: localizations.btnFilter,
                        isSecondary: false,
                        isActive: _categoriesTemporaires.isNotEmpty,
                        onTap: () {
                          widget.onFiltrerApplique(_categoriesTemporaires);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/main.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/widgets/btn_filtrer.dart';
import 'package:sourire/widgets/btn_categorisation.dart';
import 'package:sourire/widgets/btn_chevron_bas.dart';
import 'package:sourire/widgets/ecran_filtrer.dart'; 
import 'package:sourire/services/database_service.dart';
import 'package:sourire/screens/screen_recategorisation_historique.dart';
import 'package:sourire/widgets/souvenir_historique.dart';
import 'package:sourire/widgets/souvenir_tirage.dart';

class WidgetHistorique extends StatefulWidget {
  final List<NoteSourire> notes; 
  final DraggableScrollableController? controller;
  final bool isDark;
  final VoidCallback? onNotesChanged;

  const WidgetHistorique({
    required this.notes, 
    this.controller, 
    this.isDark = false,
    this.onNotesChanged, 
    super.key
  });

  @override
  State<WidgetHistorique> createState() => _WidgetHistoriqueState();
}

class _WidgetHistoriqueState extends State<WidgetHistorique> {
  final DatabaseService databaseService = DatabaseService();
  List<String> _filtresActifs = [];
  bool _modeSelection = false;
  final List<NoteSourire> _souvenirsSelectionnes = [];
  
  bool _voletEstOuvert = false;

  void _ouvrirSouvenirGrandEcran(BuildContext context, NoteSourire souvenir) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25), 
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: WidgetSouvenirTirage(
                souvenir: souvenir,
              ),
            ),
          ),
        );
      },
    );
  }

  // 🌟 NOUVELLE MÉTHODE : Alerte de confirmation avant suppression permanente
  void _ouvrirAlerteSuppression(BuildContext context) {
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
                    Expanded(
                      child: Text(
                        l10n.deleteAlertTitle,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: couleurTitre),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: grey), 
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.deleteAlertMessage,
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
                    onPressed: () async {
                      Navigator.of(context).pop(); // Ferme la boîte de dialogue d'alerte
                      
                      if (_souvenirsSelectionnes.isEmpty) return;
                      
                      // Suppression effective dans la base de données
                      await Future.sync(() => databaseService.deleteMultipleNotes(_souvenirsSelectionnes));
                      
                      if (mounted) {
                        setState(() {
                          _souvenirsSelectionnes.clear();
                          _modeSelection = false;
                        });
                      }
                    },
                    child: Text(
                      l10n.btnDeleteSelection, // Réutilisation du texte du bouton supprimer
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

  @override
  void initState() {
    super.initState();
    _enregistrerControleur();
  }

  @override
  void didUpdateWidget(covariant WidgetHistorique oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_ecouterFermetureVolet);
      _enregistrerControleur();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_ecouterFermetureVolet);
    super.dispose();
  }

  void _enregistrerControleur() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller?.addListener(_ecouterFermetureVolet);
      }
    });
  }

  void _ecouterFermetureVolet() {
    if (widget.controller?.isAttached == true) {
      final double tailleActuelle = widget.controller!.size;
      final bool ouvert = tailleActuelle > 0.01; 

      if (ouvert != _voletEstOuvert) {
        setState(() {
          _voletEstOuvert = ouvert;
        });
      }

      if (tailleActuelle == 0.0 && _filtresActifs.isNotEmpty) {
        setState(() {
          _filtresActifs.clear();
        });
      }
    }
  }

  Map<String, List<NoteSourire>> _grouperParDate(List<NoteSourire> liste, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final Map<String, List<NoteSourire>> groupes = {};
    
    final maintenant = DateTime.now();
    final dateAujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final dateHier = dateAujourdhui.subtract(const Duration(days: 1));
    
    final localeCourante = Localizations.localeOf(context).toString();

    final listeFiltree = liste.where((note) {
      if (_filtresActifs.isEmpty) return true;
      final categoriesDeLaNote = note.categories;

      if (_filtresActifs.contains("unclassified") && categoriesDeLaNote.contains("unclassified")) {
        return true;
      }
      return categoriesDeLaNote.any((cat) => _filtresActifs.contains(cat));
    }).toList();

    listeFiltree.sort((a, b) => b.date.compareTo(a.date));

    for (var note in listeFiltree) {
      String cleDate;
      final dateNote = DateTime(note.date.year, note.date.month, note.date.day);

      if (dateNote.isAtSameMomentAs(dateAujourdhui)) {
        cleDate = localizations.today;
      } else if (dateNote.isAtSameMomentAs(dateHier)) {
        cleDate = localizations.yesterday;
      } else {
        cleDate = DateFormat('d MMMM', localeCourante).format(note.date);
      }
      
      if (!groupes.containsKey(cleDate)) {
        groupes[cleDate] = [];
      }
      groupes[cleDate]!.add(note);
    }
    return groupes;
  }

  SourireTheme _getThemeFromLabel(String label) {
    if (label == 'blanc') {
      return SourireTheme(main: black, light: white, label: 'blanc');
    }
    return SourireTheme.fromLabel(label);
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double margeSuperieureCible = statusBarHeight + 70 + 16;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentThemeMode, child) {
        final bool isDarkMode = currentThemeMode == ThemeMode.system
    ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
    : (currentThemeMode == ThemeMode.dark);
        final Color couleurFondVolet = isDarkMode ? black : white;

        return Stack(
          children: [
            DraggableScrollableSheet(
              controller: widget.controller,
              initialChildSize: 0.0, 
              minChildSize: 0.0,     
              maxChildSize: 1.0, 
              snap: true,
              builder: (context, scrollController) {
                return MediaQuery.removePadding(
                  context: context,
                  removeBottom: false,
                  child: Container(
                    margin: EdgeInsets.only(top: margeSuperieureCible),
                    decoration: BoxDecoration(
                      color: couleurFondVolet,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Container(
                      child: StreamBuilder<List<NoteSourire>>(
                        stream: databaseService.getNotesStream(),
                        builder: (context, snapshot) {
                          final toutesLesNotes = snapshot.data ?? widget.notes;

                          if (snapshot.hasData && widget.onNotesChanged != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onNotesChanged!();
                            });
                          }

                          final souvenirsGroupes = _grouperParDate(toutesLesNotes, context);
                          final localizations = AppLocalizations.of(context)!;

                          return Stack(
                            children: [
                              CustomScrollView(
                                controller: scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  const SliverToBoxAdapter(
                                    child: SizedBox(height: 60),
                                  ),

                                  if (toutesLesNotes.isEmpty)
                                    SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Center(
                                        child: Text(
                                          localizations.emptyHistory,
                                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                                        ),
                                      ),
                                    )
                                  else
                                    SliverPadding(
                                      padding: EdgeInsets.only(
                                        left: 20, 
                                        right: 20, 
                                        top: 10, 
                                        bottom: 20 + bottomPadding + (_modeSelection ? 100 : 0),
                                      ),
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            String dateCle = souvenirsGroupes.keys.elementAt(index);
                                            List<NoteSourire> items = souvenirsGroupes[dateCle]!;
                                            
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 15, bottom: 12),
                                                  child: Text(
                                                    dateCle,
                                                    style: TextStyle(
                                                      color: isDarkMode ? lightGrey : grey, 
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                GridView.builder(
                                                  padding: EdgeInsets.zero, 
                                                  shrinkWrap: true, 
                                                  physics: const NeverScrollableScrollPhysics(), 
                                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 4,
                                                    mainAxisSpacing: 12,
                                                    crossAxisSpacing: 12,
                                                    childAspectRatio: 1.0,
                                                  ),
                                                  itemCount: items.length,
                                                  itemBuilder: (context, itemIndex) {
                                                    final souvenir = items[itemIndex];
                                                    _getThemeFromLabel(souvenir.themeLabel);
                                                    final bool estSelectionne = _souvenirsSelectionnes.any((s) => s.id == souvenir.id);

                                                    return GestureDetector(
                                                      onLongPress: () {
                                                        setState(() {
                                                          _modeSelection = true;
                                                          if (!estSelectionne) {
                                                            _souvenirsSelectionnes.add(souvenir);
                                                          }
                                                        });
                                                      },
                                                      onTap: () {
                                                        if (_modeSelection) {
                                                          setState(() {
                                                            if (estSelectionne) {
                                                              _souvenirsSelectionnes.removeWhere((s) => s.id == souvenir.id);
                                                              if (_souvenirsSelectionnes.isEmpty) {
                                                                _modeSelection = false;
                                                              }
                                                            } else {
                                                              _souvenirsSelectionnes.add(souvenir);
                                                            }
                                                          });
                                                        } else {
                                                          _ouvrirSouvenirGrandEcran(context, souvenir);
                                                        }
                                                      },
                                                      child: Stack(
                                                        children: [
                                                          Positioned.fill(
                                                            child: WidgetSouvenirHistorique(
                                                              key: ValueKey(souvenir.photoPath ?? souvenir.id.toString()),
                                                              souvenir: souvenir,
                                                            ),
                                                          ),
                                                          if (_modeSelection && estSelectionne)
                                                            Positioned.fill(
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                  color: orange.withOpacity(0.4),
                                                                  borderRadius: BorderRadius.circular(6),
                                                                ),
                                                              ),
                                                            ),
                                                          if (_modeSelection)
                                                            Positioned(
                                                              top: 8,
                                                              right: 8,
                                                              child: Container(
                                                                width: 22,
                                                                height: 22,
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  color: estSelectionne ? orange : Colors.transparent,
                                                                  border: Border.all(
                                                                    color: estSelectionne ? orange : Colors.white,
                                                                    width: 1.5,
                                                                  ),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors.black.withOpacity(0.2),
                                                                      blurRadius: 2,
                                                                    )
                                                                  ],
                                                                ),
                                                                child: estSelectionne
                                                                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                                                                    : null,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 25),
                                                Divider(
                                                  height: 1, 
                                                  color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFEEEEEE)
                                                ),
                                              ],
                                            );
                                          },
                                          childCount: souvenirsGroupes.keys.length,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: couleurFondVolet,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Align(
                                              alignment: Alignment.center,
                                              child: BtnChevronBas(
                                                onTap: () {
                                                  widget.controller?.animateTo(
                                                    0.0,
                                                    duration: const Duration(milliseconds: 300),
                                                    curve: Curves.easeIn,
                                                  );
                                                },
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: BtnFiltrer(
                                                nombreDeFiltres: _filtresActifs.length,
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor: Colors.transparent,
                                                    builder: (context) => EcranFiltrer(
                                                      categoriesSelectionneesInitiales: _filtresActifs,
                                                      onFiltrerApplique: (nouvelleSelection) {
                                                        setState(() {
                                                          _filtresActifs = nouvelleSelection;
                                                        });
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(
                                        height: 1, 
                                        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE0E0E0)
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              if (_modeSelection)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.only(
                                      left: 20, 
                                      right: 20,
                                      top: 16,
                                      bottom: 16 + bottomPadding,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? darkSurface : Colors.white, 
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, -2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: BtnCategorisation(
                                            text: localizations.btnDeleteSelection,
                                            isSecondary: true,
                                            // 🌟 DEVENU SYNCHRONE : Redirige vers la boîte de dialogue d'alerte
                                            onTap: () {
                                              if (_souvenirsSelectionnes.isEmpty) return;
                                              _ouvrirAlerteSuppression(context);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: BtnCategorisation(
                                            text: localizations.btnCategorizeSelection,
                                            onTap: () {
                                              if (_souvenirsSelectionnes.isNotEmpty) {
                                                Navigator.push<List<NoteSourire>>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ScreenRecategorisationHistorique(
                                                      souvenirs: List<NoteSourire>.from(_souvenirsSelectionnes),
                                                    ),
                                                  ),
                                                ).then((souvenirsModifies) {
                                                  setState(() {
                                                    _souvenirsSelectionnes.clear();
                                                    _modeSelection = false;
                                                  });
                                                });
                                              }
                                            },
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
          ],
        );
      },
    );
  }
}
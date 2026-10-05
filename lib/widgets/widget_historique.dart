import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/main.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/widgets/btn_filtrer.dart';
import 'package:sourire/widgets/btn_categorisation.dart';
import 'package:sourire/widgets/btn_chevron_bas.dart';
import 'package:sourire/models/periode_filtre.dart';
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

class _WidgetHistoriqueState extends State<WidgetHistorique>
    with SingleTickerProviderStateMixin {
  final DatabaseService databaseService = DatabaseService();
  List<String> _filtresActifs = [];

  /// Tranche de temps active, ou `null` si l'historique n'est pas borné.
  PeriodeFiltre? _periodeActive;

  /// Déploiement du tiroir de filtres : 0 replié, 1 entièrement descendu.
  ///
  /// Un contrôleur explicite plutôt qu'un `AnimatedSize` : le panneau doit
  /// pouvoir être replié depuis l'extérieur — quand le volet d'historique
  /// redescend — sans reconstruire l'arbre.
  late final AnimationController _controleurTiroir = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  );

  /// Hauteur de l'en-tête du volet : la barre « Filtrer » + chevron, et la
  /// barre de sélection quand elle est là.
  ///
  /// Sert à deux endroits qui doivent rester d'accord — le vide réservé en
  /// tête de liste, pour que le premier souvenir ne passe pas sous l'en-tête,
  /// et l'ancrage du panneau de filtres, qui se pose juste dessous.
  double get _hauteurEnTete => _modeSelection ? 96 : 60;

  void _basculerTiroir() {
    if (_controleurTiroir.status == AnimationStatus.forward ||
        _controleurTiroir.status == AnimationStatus.completed) {
      _controleurTiroir.reverse();
    } else {
      _controleurTiroir.forward();
    }
  }

  /// Course du panneau, adoucie. Construite une seule fois : une
  /// `CurvedAnimation` créée à chaque `build` s'abonnerait au contrôleur sans
  /// jamais s'en détacher.
  late final CurvedAnimation _courbeTiroir = CurvedAnimation(
    parent: _controleurTiroir,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  /// Années pour lesquelles le bocal contient au moins un souvenir.
  ///
  /// Sur la date AFFICHÉE, comme le filtre lui-même : une photo de 2019
  /// importée hier appartient à 2019 pour qui la cherche.
  List<int> _anneesDisponibles(List<NoteSourire> notes) =>
      notes.map((NoteSourire note) => note.dateAffichee.year).toSet().toList();
  bool _modeSelection = false;
  final List<NoteSourire> _souvenirsSelectionnes = [];
  
  bool _voletEstOuvert = false;

  void _ouvrirSouvenirGrandEcran(BuildContext context, NoteSourire souvenir) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25), 
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: GestureDetector(
            // `opaque`, et c'est tout l'objet du correctif.
            //
            // Par défaut, un GestureDetector qui a un enfant ne reçoit les
            // touchers QUE là où cet enfant peint réellement. Son enfant est
            // ici un `ContenuCentre`, donc un `Center` : il occupe toute la
            // boîte mais ne « dessine » que le carré du souvenir. Taper à
            // côté ne touchait donc pas le détecteur — et ne touchait pas non
            // plus le voile du fond, puisque la boîte de dialogue, large de
            // presque tout l'écran, absorbait le toucher au passage. Le
            // souvenir ne se refermait qu'en tapant dessus.
            //
            // En opaque, le détecteur revendique toute sa surface : taper
            // n'importe où referme. Les boutons du souvenir continuent de
            // fonctionner, Flutter donnant la main au plus intérieur des
            // détecteurs.
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            // Bornée : sans cette limite, le souvenir agrandi occupait un
            // carré de neuf cents points sur un iPad 13 pouces. Une note
            // qu'on relit n'a pas besoin d'être une affiche.
            child: ContenuCentre(
              largeurMax: 520,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: WidgetSouvenirTirage(
                  souvenir: souvenir,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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
                        style: styleTitreAction.copyWith(color: couleurTitre),
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
                    onPressed: () async {
                      Navigator.of(context).pop();
                      
                      if (_souvenirsSelectionnes.isEmpty) return;
                      
                      await Future.sync(() => databaseService.deleteMultipleNotes(_souvenirsSelectionnes));
                      
                      if (mounted) {
                        setState(() {
                          _souvenirsSelectionnes.clear();
                          _modeSelection = false;
                        });
                      }
                    },
                    child: Text(
                      l10n.btnDeleteSelection,
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
    _courbeTiroir.dispose();
    _controleurTiroir.dispose();
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
 
      if (tailleActuelle == 0.0 &&
          (_filtresActifs.isNotEmpty || _periodeActive != null)) {
        setState(() {
          _filtresActifs.clear();
          _periodeActive = null;
        });
      }

      // Le panneau se replie avec le volet : sans cela il resterait ouvert
      // sous le bocal et réapparaîtrait tel quel à la prochaine remontée,
      // alors que ses filtres, eux, viennent d'être levés.
      if (tailleActuelle == 0.0) {
        _controleurTiroir.value = 0;
      }
 
      // Réinitialise le mode sélection multiple quand le volet se ferme
      // complètement, pour repartir sur un affichage propre à la prochaine
      // ouverture.
      if (tailleActuelle == 0.0 && _modeSelection) {
        setState(() {
          _modeSelection = false;
          _souvenirsSelectionnes.clear();
        });
      }
    }
  }

  /// Applique les filtres de catégorie actifs à une liste de souvenirs.
  /// Extrait dans une méthode partagée pour être réutilisable à la fois
  /// par le regroupement par date ET par le "Tout sélectionner" (qui doit
  /// sélectionner exactement ce que l'utilisateur voit à l'écran).
  List<NoteSourire> _filtrerListe(List<NoteSourire> liste) {
    if (_filtresActifs.isEmpty && _periodeActive == null) return liste;

    return liste.where((note) {
      // La période se lit sur la date AFFICHÉE — celle que porte le souvenir
      // à l'écran. Filtrer sur la date d'entrée en base donnerait des
      // résultats incompréhensibles pour une photo ancienne importée hier.
      if (_periodeActive != null && !_periodeActive!.contient(note.dateAffichee)) {
        return false;
      }
      if (_filtresActifs.isEmpty) return true;

      final categoriesDeLaNote = note.categories;
      if (_filtresActifs.contains("unclassified") && categoriesDeLaNote.contains("unclassified")) {
        return true;
      }
      return categoriesDeLaNote.any((cat) => _filtresActifs.contains(cat));
    }).toList();
  }

  Map<String, List<NoteSourire>> _grouperParDate(List<NoteSourire> liste, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final Map<String, List<NoteSourire>> groupes = {};
    
    final maintenant = DateTime.now();
    final dateAujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final dateHier = dateAujourdhui.subtract(const Duration(days: 1));
    
    final localeCourante = Localizations.localeOf(context).toString();

    final listeFiltree = _filtrerListe(liste);

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

  /// Met les groupes à plat : un en-tête de date, puis des rangées de quatre
  /// souvenirs, puis l'en-tête suivant.
  ///
  /// C'est ce qui permet au `SliverList` de ne construire que les rangées
  /// visibles. Voir le commentaire à l'endroit du `SliverList`.
  /// Quatre vignettes par ligne sur téléphone, davantage sur tablette.
  ///
  /// À quatre colonnes sur un iPad 13 pouces, chaque vignette faisait deux
  /// cent quarante points de côté : des timbres devenus des affiches, et
  /// trois fois moins de souvenirs à l'écran que sur un téléphone. On garde
  /// donc une vignette de taille comparable en ajoutant des colonnes.
  int _vignettesParLigne(BuildContext context) {
    final double largeur = MediaQuery.sizeOf(context).width;
    if (largeur >= 900) return 8;
    if (largeur >= 700) return 6;
    if (largeur >= 550) return 5;
    return 4;
  }

  List<_LigneHistorique> _aplatir(
    Map<String, List<NoteSourire>> groupes,
    int parLigne,
  ) {
    final List<_LigneHistorique> lignes = <_LigneHistorique>[];

    groupes.forEach((String date, List<NoteSourire> souvenirs) {
      lignes.add(_LigneHistorique.entete(date));
      for (int i = 0; i < souvenirs.length; i += parLigne) {
        final int fin = (i + parLigne) > souvenirs.length
            ? souvenirs.length
            : i + parLigne;
        lignes.add(_LigneHistorique.rangee(
          souvenirs.sublist(i, fin),
          derniereDuGroupe: fin >= souvenirs.length,
        ));
      }
    });

    return lignes;
  }

  Widget _construireLigne(_LigneHistorique ligne, bool isDarkMode, int parLigne) {
    if (ligne.estUnEntete) {
      return Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 12),
        child: Text(
          ligne.titre!,
          style: TextStyle(
            color: isDarkMode ? lightGrey : grey,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Une rangée de quatre carrés. `AspectRatio` dans un `Expanded` donne à
    // chaque vignette une hauteur égale à sa largeur, quelle que soit la
    // largeur de l'écran : c'est ce qui rend la grille juste aussi bien sur
    // un petit téléphone que sur un iPad.
    final List<Widget> cellules = <Widget>[];
    for (int i = 0; i < parLigne; i++) {
      if (i > 0) cellules.add(const SizedBox(width: 12));
      if (i < ligne.souvenirs.length) {
        cellules.add(Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: _vignette(ligne.souvenirs[i]),
          ),
        ));
      } else {
        // Case vide de fin de rangée : elle réserve la place pour que les
        // vignettes restent alignées sur la colonne.
        cellules.add(const Expanded(child: SizedBox.shrink()));
      }
    }

    return Column(
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: cellules),
        SizedBox(height: ligne.derniereDuGroupe ? 25 : 12),
        if (ligne.derniereDuGroupe)
          Divider(
            height: 1,
            color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFEEEEEE),
          ),
      ],
    );
  }

  Widget _vignette(NoteSourire souvenir) {
    final bool estSelectionne =
        _souvenirsSelectionnes.any((s) => s.id == souvenir.id);

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
                  color: orange.withValues(alpha: 0.4),
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
                      color: Colors.black.withValues(alpha: 0.2),
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
  }

  /// Bascule entre "tout sélectionner" et "tout désélectionner", sur la
  /// base de ce qui est réellement affiché à l'écran (donc en tenant
  /// compte des filtres de catégorie actifs).
  void _toggleSelectionnerTout(List<NoteSourire> listeVisible) {
    setState(() {
      final bool toutEstDejaSelectionne = listeVisible.isNotEmpty &&
          _souvenirsSelectionnes.length == listeVisible.length &&
          listeVisible.every((n) => _souvenirsSelectionnes.any((s) => s.id == n.id));

      if (toutEstDejaSelectionne) {
        _souvenirsSelectionnes.clear();
        _modeSelection = false;
      } else {
        _souvenirsSelectionnes
          ..clear()
          ..addAll(listeVisible);
        _modeSelection = true;
      }
    });
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
                    child: StreamBuilder<List<NoteSourire>>(
                        initialData: databaseService.notesEnCache,
                        stream: databaseService.getNotesStream(),
                        builder: (context, snapshot) {
                          final toutesLesNotes = snapshot.data ?? widget.notes;

                          if (snapshot.hasData && widget.onNotesChanged != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onNotesChanged!();
                            });
                          }

                          // Le regroupement (coûteux si beaucoup de souvenirs) ne se fait
                          // que si le volet est réellement ouvert.
                          final souvenirsGroupes = _voletEstOuvert
                              ? _grouperParDate(toutesLesNotes, context)
                              : <String, List<NoteSourire>>{};
                          // Mise à plat en en-têtes et rangées de quatre, faite ici
                          // une seule fois plutôt que dans le constructeur de chaque
                          // élément.
                          final int vignettesParLigne =
                              _vignettesParLigne(context);
                          final List<_LigneHistorique> lignes =
                              _aplatir(souvenirsGroupes, vignettesParLigne);
                          final listeVisibleActuelle = _voletEstOuvert
                              ? _filtrerListe(toutesLesNotes)
                              : <NoteSourire>[];
                          // Calculées ici, une fois par arrivée de souvenirs,
                          // et non dans le `builder` de l'animation, qui
                          // s'exécute à chaque image du tiroir.
                          final List<int> anneesDisponibles =
                              _anneesDisponibles(toutesLesNotes);
                          final localizations = AppLocalizations.of(context)!;

                          return Stack(
                            children: [
                              // ⚠️ Le CustomScrollView (et son controller) DOIT toujours
                              // être construit, même volet fermé : c'est ce qui permet au
                              // DraggableScrollableController de s'attacher. Seul le
                              // contenu des slivers (la grille de photos) est conditionné
                              // à l'ouverture réelle du volet.
                              CustomScrollView(
                                controller: scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: !_voletEstOuvert
                                    ? const [SliverToBoxAdapter(child: SizedBox.shrink())]
                                    : [
                                  SliverToBoxAdapter(
                                    child: SizedBox(height: _hauteurEnTete),
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
                                      // Une liste PLATE : un en-tête de date, puis des
                                      // rangées de quatre vignettes, puis l'en-tête
                                      // suivant.
                                      //
                                      // Il y avait auparavant une `GridView` en
                                      // `shrinkWrap` par journée. Une grille en
                                      // shrinkWrap doit mesurer tous ses enfants pour
                                      // connaître sa hauteur : elle les construisait donc
                                      // TOUS d'un coup, et chaque vignette lance une
                                      // lecture disque. Le jour où quelqu'un importait
                                      // deux cents photos, ouvrir l'historique
                                      // construisait deux cents vignettes et lançait deux
                                      // cents lectures simultanées. À plat, le
                                      // `SliverList` ne construit que ce qui est visible.
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) => _construireLigne(
                                            lignes[index],
                                            isDarkMode,
                                            vignettesParLigne,
                                          ),
                                          childCount: lignes.length,
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
                                              // À GAUCHE, et non plus à droite :
                                              // le panneau se déplie juste sous
                                              // ce mot, et le regard descend
                                              // alors dans le sens de la
                                              // lecture.
                                              alignment: Alignment.centerLeft,
                                              child: BtnFiltrer(
                                                // La période compte pour un
                                                // filtre : sans cela, le
                                                // décompte resterait à zéro
                                                // alors que l'historique est
                                                // bel et bien restreint.
                                                nombreDeFiltres: _filtresActifs.length +
                                                    (_periodeActive == null ? 0 : 1),
                                                onTap: _basculerTiroir,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // --- BARRE "SÉLECTION" : n'apparaît que quand au
                                      // moins un souvenir est sélectionné. Affiche le
                                      // nombre d'éléments sélectionnés à gauche, et un
                                      // bouton "Tout sélectionner"/"Tout désélectionner"
                                      // à droite (basé sur ce qui est visible à l'écran,
                                      // donc respecte les filtres actifs).
                                      if (_modeSelection)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              GestureDetector(
                                                onTap: () => _toggleSelectionnerTout(listeVisibleActuelle),
                                                child: Text(
                                                  _souvenirsSelectionnes.length == listeVisibleActuelle.length &&
                                                          listeVisibleActuelle.isNotEmpty
                                                      ? localizations.btnDeselectAll
                                                      : localizations.btnSelectAll,
                                                  style: const TextStyle(
                                                    color: orange,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                localizations.selectedCountLabel(_souvenirsSelectionnes.length),
                                                style: TextStyle(
                                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
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

                              // LE PANNEAU DE FILTRES.
                              //
                              // Empilé APRÈS l'en-tête, donc au-dessus de lui
                              // comme de la liste, et posé à l'aplomb du mot
                              // « Filtrer ». Il ne touche à rien de ce qui est
                              // dessous : ni voile, ni décalage, ni fond
                              // repeint — seule son ombre portée le détache.
                              Positioned(
                                top: _hauteurEnTete,
                                left: 20,
                                child: AnimatedBuilder(
                                  animation: _controleurTiroir,
                                  builder: (context, _) {
                                    // Replié, il quitte l'arbre : son écoute
                                    // des catégories s'arrête, et la liste
                                    // reste intégralement touchable.
                                    if (_controleurTiroir.isDismissed) {
                                      return const SizedBox.shrink();
                                    }
                                    return SizeTransition(
                                      sizeFactor: _courbeTiroir,
                                      // -1 : le panneau se déroule par le haut,
                                      // comme un store. Par défaut il
                                      // s'ouvrirait depuis son centre.
                                      axisAlignment: -1,
                                      child: EcranFiltrer(
                                        categories: _filtresActifs,
                                        periode: _periodeActive,
                                        anneesDisponibles: anneesDisponibles,
                                        sombre: isDarkMode,
                                        // Les filtres s'appliquent à chaque
                                        // touche : on voit l'historique se
                                        // resserrer derrière le panneau, donc
                                        // il n'y a rien à valider.
                                        onChange: (categories, periode) {
                                          setState(() {
                                            _filtresActifs = categories;
                                            _periodeActive = periode;
                                          });
                                        },
                                      ),
                                    );
                                  },
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
                                          color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
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
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Un élément de la liste d'historique : soit un en-tête de date, soit une
/// rangée de quatre vignettes au plus.
class _LigneHistorique {
  final String? titre;
  final List<NoteSourire> souvenirs;

  /// Vrai pour la dernière rangée d'une journée : c'est elle qui porte le
  /// trait de séparation.
  final bool derniereDuGroupe;

  const _LigneHistorique.entete(String this.titre)
      : souvenirs = const <NoteSourire>[],
        derniereDuGroupe = false;

  const _LigneHistorique.rangee(this.souvenirs, {required this.derniereDuGroupe})
      : titre = null;

  bool get estUnEntete => titre != null;
}

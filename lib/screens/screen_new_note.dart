import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/main.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/screens/screen_choix_theme_note.dart';
import 'package:sourire/theme/theme_service.dart';
import 'package:sourire/widgets/btn_rond_souvenir.dart';
import 'package:sourire/widgets/modale_premium.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/theme/user_prefs.dart'; 
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/widgets/btn_action.dart';
import 'package:sourire/screens/screen_categorisation_note.dart';
import 'package:sourire/l10n/app_localizations.dart';

class ScreenNewNote extends StatefulWidget {
  final SourireTheme couleur; 
  final ThemeApp themeVisuel; 

  /// Souvenir à RÉÉCRIRE, ou `null` pour en écrire un nouveau.
  ///
  /// Le même écran sert aux deux, et c'est délibéré : il porte déjà le clavier,
  /// le recentrage du texte, la typographie Lora et le fond thématique. Rendre
  /// le souvenir modifiable sur place, dans la fenêtre de tirage, aurait voulu
  /// dire réécrire tout cela dans un widget aujourd'hui en lecture seule.
  ///
  /// En modification, seul le TEXTE change : la date d'entrée dans le bocal,
  /// la couleur et les catégories sont conservées. On ne repasse donc pas par
  /// l'écran de catégorisation, on enregistre et on referme.
  final NoteSourire? souvenirAModifier;

  const ScreenNewNote({
    required this.couleur,
    required this.themeVisuel,
    this.souvenirAModifier,
    super.key,
  });

  bool get enModification => souvenirAModifier != null;

  @override
  State<ScreenNewNote> createState() => _ScreenNewNoteState();
}

class _ScreenNewNoteState extends State<ScreenNewNote> {
  final TextEditingController _controller = TextEditingController();

  /// Focus du champ de saisie, tenu explicitement.
  ///
  /// Le champ montait auparavant le clavier par `autofocus: true`, et c'est ce
  /// qui faisait sauter le clavier sous la modale Premium. `autofocus` n'est
  /// pas un geste ponctuel : il INSCRIT une demande de focus auprès du
  /// `FocusScope` de la route, et ce scope la rejoue chaque fois qu'il
  /// redevient actif sans que rien d'autre ne tienne le focus. Or c'est
  /// exactement l'état où se trouve cet écran au retour de l'écran des thèmes,
  /// puisqu'on y a justement relâché le focus avant de partir : la demande en
  /// attente se déclenchait alors au pire moment, pendant que la boîte
  /// s'ouvrait par-dessus.
  ///
  /// Avec un nœud explicite, le focus est demandé UNE FOIS, à l'ouverture de
  /// l'écran, et plus jamais de lui-même.
  final FocusNode _focusNote = FocusNode();

  /// Décor du post-it. Part de celui reçu, puis suit la baguette.
  late ThemeApp _themeVisuel;
  
  // Utilisation d'un ValueNotifier pour éviter le setState global sur tout l'écran
  final ValueNotifier<bool> _canValidateNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _themeVisuel = widget.themeVisuel;
    _controller.text = widget.souvenirAModifier?.text ?? '';
    // Curseur en fin de texte : en modification, on vient presque toujours
    // ajouter ou corriger la fin d'une phrase, pas repartir du début.
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    _controller.addListener(_updateValidationState);
    _updateValidationState();

    // Le clavier s'ouvre dès l'arrivée sur l'écran — on vient y écrire — mais
    // par une demande UNIQUE, après la première image. Rien ne la rejouera.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNote.requestFocus();
    });
  }

  void _updateValidationState() {
    final bool isNotEmpty = _controller.text.trim().isNotEmpty;
    if (_canValidateNotifier.value != isNotEmpty) {
      _canValidateNotifier.value = isNotEmpty;
    }
  }

  /// Enregistre, puis part là où il faut.
  ///
  /// Écriture d'un nouveau souvenir : on enchaîne sur la catégorisation, le
  /// souvenir n'existe pas encore en base.
  ///
  /// Modification : on écrit le nouveau texte et on referme. Le souvenir a
  /// déjà ses catégories, sa couleur et sa date — reposer la question des
  /// catégories pour une correction de faute de frappe serait absurde. On
  /// remonte le souvenir mis à jour à l'écran appelant, qui repeint aussitôt.
  void _valider() {
    final String texte = _controller.text;

    if (widget.enModification) {
      final NoteSourire misAJour =
          widget.souvenirAModifier!.copyWith(text: texte);
      DatabaseService().updateNote(misAJour);
      Navigator.pop(context, misAJour);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenCategorisationNote(
          note: texte,
          theme: widget.couleur,
          themeVisuel: _themeVisuel,
        ),
      ),
    );
  }

  /// Ouvre le choix du décor, et applique ce qui en revient.
  ///
  /// L'aperçu envoyé est un souvenir ÉPHÉMÈRE : la note n'existe pas encore en
  /// base, on n'en fabrique une copie que pour la donner à peindre.
  Future<void> _ouvrirChoixTheme() async {
    // LE CLAVIER PART AVANT D'EMPILER L'ÉCRAN DES THÈMES.
    //
    // Sans cela, la route de saisie retient que le champ avait le focus et le
    // lui rend dès qu'elle réapparaît — c'est-à-dire à l'instant précis où la
    // modale Premium s'ouvre par-dessus. On voyait le clavier remonter sous la
    // boîte, dans un écran où plus rien ne s'écrit : c'est ce qui donnait
    // l'impression que les deux se disputaient l'écran.
    //
    // L'écran des thèmes ne contient aucun champ de saisie : la note n'y est
    // qu'un aperçu peint, et le clavier n'y a rien à faire.
    //
    // Conséquence assumée : au retour, le clavier ne remonte pas tout seul. Il
    // faut toucher la note pour reprendre l'écriture — ce qui vaut mieux qu'un
    // clavier qui jaillit sans qu'on ait rien demandé.
    //
    // On relâche le NŒUD du champ, et non le scope : relâcher le scope laissait
    // la demande d'`autofocus` reprendre la main au retour. Voir _focusNote.
    _focusNote.unfocus();

    final NoteSourire apercu = NoteSourire(
      text: _controller.text,
      themeLabel: _themeVisuel.id,
      colorLabel: widget.couleur.label,
      categories: const <String>[],
      date: DateTime.now(),
    );

    final Object? resultat = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenChoixThemeNote(
          apercu: apercu,
          couleur: widget.couleur,
          themeInitial: _themeVisuel,
        ),
      ),
    );

    if (!mounted || resultat == null) return;

    // Thème verrouillé : on propose le Premium ICI, avec un argumentaire qui
    // parle des notes.
    //
    // L'ancienne version renvoyait vers l'écran des thèmes de la home : le
    // parcours se terminait sur une page qui vend autre chose que ce qu'on
    // venait de demander. Quatrième point d'achat, donc, et pas un détour.
    if (estAppelPremium(resultat)) {
      final bool achete = await afficherModalePremium(
        context,
        titre: AppLocalizations.of(context)!.personalization,
        message: AppLocalizations.of(context)!.notesThemesPurchaseMessage,
      );
      if (!achete || !mounted) return;
      // Premium tout juste acquis : on rouvre le choix, où tout est désormais
      // déverrouillé. Refaire chercher la baguette serait une punition.
      return _ouvrirChoixTheme();
    }

    if (resultat is! ThemeApp) return;
    setState(() => _themeVisuel = resultat);
    // Mémorisé comme défaut des prochaines notes — sans toucher au thème
    // de la home, qui vit maintenant de son côté.
    ThemeService.changerThemeNote(resultat);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateValidationState);
    _controller.dispose();
    _focusNote.dispose();
    _canValidateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    // Bornées : sur un iPad, 40 % de la largeur donnaient un bouton de 410 pt
    // de large, et 6,5 % de la hauteur un bouton de 89 pt de haut.
    double responsiveFontSize = (screenWidth * 0.05).clamp(16.0, 24.0);
    double largeurBouton = (screenWidth * 0.4).clamp(140.0, 260.0);
    double hauteurBouton = (screenHeight * 0.065).clamp(46.0, 64.0);

    final String accordAffiche = UserPrefs.accordHeureux;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentThemeMode, child) {
        // LOGIQUE CORRIGÉE : Gère le mode dynamique en suivant le système ou le choix forcé
        final bool isDarkMode = currentThemeMode == ThemeMode.system
            ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
            : (currentThemeMode == ThemeMode.dark);
        
        final Color iconColor = isDarkMode 
            ? Colors.white.withValues(alpha: 0.25) 
            : widget.couleur.main.withValues(alpha: _themeVisuel.noteIconOpacity);

        return Scaffold(
          backgroundColor: isDarkMode ? darkBg : white,
          // Empêche le resize violent du clavier qui force la reconfiguration de l'aspectRatio
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              // Le post-it est carré et prend toute la largeur : sur iPad il
              // devenait un panneau d'affichage. On borne la colonne, il
              // retrouve la taille d'une note qu'on écrit.
              child: ContenuCentre(
                child: Column(
                children: [
                  const SizedBox(height: 10),

                  // --- HEADER ---
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 0,
                          child: BtnChevronGauche(onTap: () => Navigator.pop(context)),
                        ),
                        const Center(
                          child: LogoSourire(color: orange),
                        ),
                      ],
                    ),
                  ),

                  // --- ZONE DE LA NOTE COMPRESSIBLE ---
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double postItSize = constraints.maxWidth;

                              return Container(
                                decoration: BoxDecoration(
                                  // `fond` et non `darkSurface` : le gris
                                  // uniforme faisait perdre à la note sa
                                  // couleur au moment même où on la choisit,
                                  // et ne correspondait pas au fond des
                                  // pastilles de l'écran de thèmes.
                                  color: widget.couleur.fond(isDarkMode),
                                  borderRadius: BorderRadius.circular(radiusDefault),
                                  boxShadow: isDarkMode ? null : shadowDrop,
                                  border: Border.all(
                                    color: isDarkMode
                                        ? darkSeparateur
                                        : widget.couleur.main.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(radiusDefault),
                                  // RepaintBoundary isole le rendu du Post-it des couches système
                                  child: RepaintBoundary(
                                    child: Stack(
                                      children: [
                                        
                                        // --- 1. LES ICÔNES DE FOND (Ne bougent plus, dessinées une seule fois) ---
                                        ..._themeVisuel.noteIcons.map((config) {
                                          final double width = config.getWidth(postItSize);
                                          final double height = config.getHeight(postItSize);
                                          final double left = config.getX(postItSize);
                                          final double top = config.getY(postItSize);

                                          Widget iconWidget = SvgPicture.asset(
                                            config.assetPath,
                                            width: width,
                                            height: height,
                                            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                                          );

                                          if (config.rotation != 0.0) {
                                            iconWidget = Transform.rotate(
                                              angle: config.rotation * (math.pi / 180),
                                              child: iconWidget,
                                            );
                                          }

                                          return Positioned(
                                            left: left,
                                            top: top,
                                            child: iconWidget,
                                          );
                                        }),

                                        // --- 2. LA ZONE DE TEXTE ---
                                        Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.all(paddingDefault), 
                                            child: Center(
                                              child: SingleChildScrollView(
                                                physics: const BouncingScrollPhysics(),
                                                child: TextField(
                                                  controller: _controller,
                                                  // Pas d'`autofocus` : voir
                                                  // _focusNote, c'est lui qui
                                                  // ouvre le clavier, une fois.
                                                  focusNode: _focusNote,
                                                  maxLines: null,
                                                  keyboardType: TextInputType.multiline,
                                                  textAlign: TextAlign.center,
                                                  cursorColor: isDarkMode ? Colors.white : widget.couleur.main,
                                                  style: styleNoteLarge.copyWith(
                                                    color: isDarkMode ? Colors.white : widget.couleur.main,
                                                    fontSize: tailleLora(responsiveFontSize),
                                                    height: 1.2,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: AppLocalizations.of(context)!.writeHappyThought(accordAffiche),
                                                    hintStyle: styleNoteLarge.copyWith(
                                                      color: isDarkMode ? Colors.white38 : widget.couleur.main.withValues(alpha: 0.3),
                                                      fontSize: tailleLora(responsiveFontSize),
                                                      height: 1.2,
                                                    ),
                                                    border: InputBorder.none,
                                                    counterText: "",
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // --- 3. LA BAGUETTE ---
                                        //
                                        // Même pastille que le partage et la
                                        // réécriture d'un souvenir : ce sont
                                        // toutes des actions posées SUR une
                                        // note, elles se ressemblent donc.
                                        //
                                        // Visible pour tout le monde, y compris
                                        // sans premium : c'est ici, au moment
                                        // où l'on écrit, que l'envie d'un beau
                                        // décor se manifeste — donc ici que
                                        // l'offre a le plus de sens.
                                        Positioned(
                                          right: 12,
                                          bottom: 12,
                                          child: Opacity(
                                            opacity: 0.8,
                                            child: BtnRondSouvenir(
                                              icone: Icons.auto_fix_high,
                                              onTap: _ouvrirChoixTheme,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- BOUTON VALIDER ---
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + screenHeight * 0.02),
                    child: SizedBox(
                      width: largeurBouton,
                      height: hauteurBouton,
                      child: OverflowBox(
                        minWidth: largeurBouton,
                        maxWidth: largeurBouton,
                        minHeight: hauteurBouton,
                        maxHeight: hauteurBouton,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _canValidateNotifier,
                          builder: (context, canValidate, child) {
                            return BtnAction(
                              text: AppLocalizations.of(context)!.btnValidate,
                              isActive: canValidate,
                              // Le orange de la marque, pas la couleur tirée au
                              // sort : seule la note elle-même se colore.
                              color: orange,
                              onTap: _valider, 
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
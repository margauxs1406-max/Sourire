import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui; // Importation essentielle pour le décodeur brut
import 'package:flutter/material.dart';
// Fournit l'haptique ET réexporte dart:typed_data (Uint8List).
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/services/partage_service.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/screens/screen_new_note.dart';
import 'package:sourire/screens/screen_profil.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/theme/theme_service.dart';
import 'package:sourire/widgets/btn_rond_souvenir.dart';
import 'package:sourire/widgets/souvenir_historique.dart'; // Cache partagé

// La résolution d'un label de couleur vit dans SourireTheme.fromLabel
// (tokens.dart). Une copie locale traînait ici et ne connaissait que quatre
// couleurs sur huit : un souvenir jaune, violet, rouge ou turquoise
// retombait silencieusement sur l'orange dès qu'il passait par le tirage,
// l'affichage en grand ou le partage.

/// Opacité des deux pastilles posées PAR-DESSUS un souvenir : la date à
/// gauche, le partage à droite. Légèrement translucides, elles s'effacent
/// devant la photo sans jamais devenir difficiles à lire ou à viser.
const double _opaciteSurcouche = 0.8;

class WidgetSouvenirTirage extends StatefulWidget {
  final NoteSourire souvenir;

  /// Bouton de partage posé en bas à droite, par-dessus le souvenir.
  ///
  /// Il vit ici et non dans la fenêtre de tirage : le même widget sert à
  /// l'affichage en grand depuis l'historique, qui hérite donc du bouton
  /// sans duplication.
  final bool afficherPartage;

  const WidgetSouvenirTirage({
    required this.souvenir,
    this.afficherPartage = true,
    super.key,
  });

  @override
  State<WidgetSouvenirTirage> createState() => _WidgetSouvenirTirageState();
}

class _WidgetSouvenirTirageState extends State<WidgetSouvenirTirage> {
  // Remplace l'ancien ScrollController : gère à la fois le centrage
  // initial (comme avant) ET le zoom/pan (nouveau), via InteractiveViewer.
  final TransformationController _transformationController = TransformationController();
  Size? _lastCalculatedSize;
  Uint8List? _imageBytes;
  bool _isLoaded = false;

  /// Date corrigée à la main par l'utilisateur pendant cette session.
  ///
  /// `null` tant qu'il n'a rien touché — on affiche alors la date du souvenir
  /// tel qu'il vient de la base. On ne recharge pas le souvenir depuis SQLite
  /// après l'écriture : le flux de la base rafraîchira l'historique de son
  /// côté, ici il suffit de peindre tout de suite la bonne date.
  DateTime? _dateCorrigee;

  /// Texte réécrit par l'utilisateur pendant cette session. Voir [_dateCorrigee].
  String? _texteCorrige;

  /// Le souvenir tel qu'il doit s'afficher MAINTENANT, corrections comprises.
  NoteSourire get _souvenir {
    NoteSourire courant = widget.souvenir;
    if (_dateCorrigee != null) {
      courant = courant.copyWith(datePrise: _dateCorrigee);
    }
    if (_texteCorrige != null) {
      courant = courant.copyWith(text: _texteCorrige);
    }
    return courant;
  }

  @override
  void initState() {
    super.initState();
    _verifierEtChargerImage();
  }

  /// Vérifie d'abord le cache PARTAGÉ (le même que l'historique) de façon
  /// SYNCHRONE. Comme chaque photo est préchargée dès son insertion en
  /// base, ce cache est quasiment toujours déjà "chaud" au moment d'un
  /// tirage — donc l'image est prête dès la toute première frame, sans
  /// délai visible entre l'apparition du cadre/ombre et la photo.
  void _verifierEtChargerImage() {
    final bool isPhoto = widget.souvenir.photoPath != null && widget.souvenir.photoPath!.trim().isNotEmpty;
    if (!isPhoto) {
      _isLoaded = true; // Pas d'image à charger pour une note texte
      return;
    }

    final String pathKey = widget.souvenir.photoPath!.trim();
    final Uint8List? cached = getCachedHistoriqueImageBytes(pathKey);

    if (cached != null) {
      _imageBytes = cached;
      _isLoaded = true;
    } else {
      // Cas rare (photo jamais encore préchargée) : on charge, ce qui
      // alimentera au passage le cache partagé pour la prochaine fois.
      _chargerImageAsynchrone(pathKey);
    }
  }

  Future<void> _chargerImageAsynchrone(String pathKey) async {
    await preloadHistoriqueImage(pathKey);
    _imageBytes = getCachedHistoriqueImageBytes(pathKey);
    if (mounted) {
      setState(() { _isLoaded = true; });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Reproduit EXACTEMENT l'ancien calcul de centrage (image plus grande
  /// que la fenêtre sur son axe dominant), mais l'applique désormais via
  /// la matrice de transformation de l'InteractiveViewer plutôt que via
  /// un ScrollController.jumpTo — même résultat visuel de départ, avec
  /// en plus la possibilité de zoomer/dézoomer par-dessus.
  void _centrerLaVue(Size imageSize, double bocalSize) {
    if (_lastCalculatedSize == imageSize) return;
    _lastCalculatedSize = imageSize;

    final bool isPaysage = imageSize.width > imageSize.height;
    double targetOffsetX = 0.0;
    double targetOffsetY = 0.0;

    if (isPaysage) {
      final double renduWidth = (imageSize.width * bocalSize) / imageSize.height;
      targetOffsetX = (renduWidth - bocalSize) / 2;
    } else {
      final double renduHeight = (imageSize.height * bocalSize) / imageSize.width;
      targetOffsetY = (renduHeight - bocalSize) / 2;
    }

    if (targetOffsetX > 0 || targetOffsetY > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _transformationController.value = Matrix4.identity()
          ..translateByDouble(-targetOffsetX, -targetOffsetY, 0, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCouleur = SourireTheme.fromLabel(widget.souvenir.colorLabel);
    final bool isPhoto = widget.souvenir.photoPath != null && widget.souvenir.photoPath!.trim().isNotEmpty;

    // Le souvenir en grand est ouvert par-dessus la home ou l'historique, tous
    // deux déjà sombres la nuit : un pastel presque blanc plein écran y était
    // un flash. `Theme.of` suffit — c'est `MaterialApp` qui applique le
    // réglage, et le contexte en hérite jusque dans les dialogues.
    final bool sombre = Theme.of(context).brightness == Brightness.dark;

    final ThemeApp themeGraphique =
        ThemeService.parId(widget.souvenir.themeLabel);

    if (!_isLoaded && _imageBytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: orange),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = constraints.maxWidth;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isPhoto ? Colors.transparent : themeCouleur.fond(sombre),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                if (!isPhoto && themeGraphique.noteIcons.isNotEmpty)
                  ...themeGraphique.noteIcons.map((iconConfig) {
                    return Positioned(
                      left: iconConfig.getX(size),
                      top: iconConfig.getY(size),
                      width: iconConfig.getWidth(size),
                      height: iconConfig.getHeight(size),
                      child: Transform.rotate(
                        angle: iconConfig.rotation * math.pi / 180,
                        child: Opacity(
                          opacity: themeGraphique.noteIconOpacity,
                          child: SvgPicture.asset(
                            iconConfig.assetPath,
                            colorFilter: ColorFilter.mode(
                              themeCouleur.encre(sombre),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                Positioned.fill(
                  child: isPhoto
                      ? (_imageBytes != null && _imageBytes!.isNotEmpty
                          ? FutureBuilder<Size>(
                              future: _getImageSize(_imageBytes!),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();

                                final imageSize = snapshot.data!;
                                final bool isPaysage = imageSize.width > imageSize.height;

                                _centrerLaVue(imageSize, size);

                                final double? imageWidth = isPaysage ? null : size;
                                final double? imageHeight = isPaysage ? size : null;

                                // InteractiveViewer remplace le SingleChildScrollView :
                                // même centrage initial (via _centrerLaVue), même
                                // possibilité de parcourir une image plus grande que
                                // la fenêtre, avec en plus le pinch-to-zoom natif.
                                return InteractiveViewer(
                                  transformationController: _transformationController,
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  boundaryMargin: EdgeInsets.zero,
                                  constrained: false,
                                  child: SizedBox(
                                    width: isPaysage ? (imageSize.width * size) / imageSize.height : size,
                                    height: isPaysage ? size : (imageSize.height * size) / imageSize.width,
                                    child: Image.memory(
                                      _imageBytes!,
                                      width: imageWidth,
                                      height: imageHeight,
                                      fit: isPaysage ? BoxFit.fitHeight : BoxFit.fitWidth,
                                      gaplessPlayback: true,
                                      cacheWidth: null,
                                      cacheHeight: null,
                                    ),
                                  ),
                                );
                              },
                            )
                          : SizedBox(
                              height: size,
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                              ),
                            ))
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Container(
                            constraints: BoxConstraints(minHeight: size),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(25),
                            child: Text(
                              _souvenir.text ?? "",
                              textAlign: TextAlign.center,
                              style: styleNoteLarge.copyWith(
                                color: themeCouleur.encre(sombre),
                                fontSize: tailleLora(24),
                              ),
                            ),
                          ),
                        ),
                ),

                // DATE DU SOUVENIR, par-dessus, en bas à gauche.
                // Elle fait pendant au bouton de partage, à l'autre bout.
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Opacity(
                    opacity: _opaciteSurcouche,
                    child: _PastilleDate(
                      date: _souvenir.dateAffichee,
                      onTap: _modifierDate,
                    ),
                  ),
                ),

                // ACTIONS, en bas à droite : réécrire, puis partager.
                //
                // Le crayon n'apparaît QUE sur les notes. Une photo ne se
                // réécrit pas — et proposer une action inopérante coûte plus
                // cher en confusion qu'elle ne rapporte en symétrie.
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Opacity(
                    opacity: _opaciteSurcouche,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isPhoto) ...[
                          BtnRondSouvenir(
                            icone: Icons.edit_outlined,
                            onTap: () => _modifierTexte(themeCouleur, themeGraphique),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (widget.afficherPartage)
                          _BoutonPartage(souvenir: _souvenir),
                      ],
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

  // --- RÉÉCRITURE DU TEXTE ---------------------------------------------------

  /// Rouvre l'écran d'écriture, cette fois en mode modification.
  ///
  /// On ne modifie pas le texte SUR PLACE, dans cette fenêtre : il y faudrait
  /// un champ de saisie, la gestion du clavier et le recentrage du texte quand
  /// il remonte — trois choses que `ScreenNewNote` sait déjà faire, et qu'il
  /// aurait fallu réécrire ici, dans un widget que l'historique partage.
  Future<void> _modifierTexte(
    SourireTheme couleur,
    ThemeApp themeVisuel,
  ) async {
    HapticFeedback.selectionClick();

    final NoteSourire? misAJour = await Navigator.push<NoteSourire>(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenNewNote(
          couleur: couleur,
          themeVisuel: themeVisuel,
          souvenirAModifier: _souvenir,
        ),
      ),
    );

    if (misAJour == null || !mounted) return;
    // L'écriture en base est déjà faite par ScreenNewNote ; ici on ne fait que
    // repeindre tout de suite, sans attendre le tour du flux.
    setState(() => _texteCorrige = misAJour.text);
  }

  // --- CORRECTION DE LA DATE -------------------------------------------------

  /// Ouvre le sélecteur de date de la plateforme et enregistre le choix.
  ///
  /// On n'écrit QUE `datePrise`, jamais `date`. La première est la date
  /// RACONTÉE : celle qu'on lit sur le souvenir, celle qui figure sur le
  /// polaroid partagé. La seconde est la date d'ENTRÉE dans le bocal, et
  /// c'est elle qui ordonne l'historique et la pile de billes. Les séparer
  /// permet de corriger une photo mal datée par la galerie sans que le
  /// souvenir replonge d'un coup au fond de l'historique.
  Future<void> _modifierDate() async {
    HapticFeedback.selectionClick();

    final DateTime affichee = _souvenir.dateAffichee;
    final DateTime actuelle = DateTime(affichee.year, affichee.month, affichee.day);
    final DateTime aujourdhui = DateUtils.dateOnly(DateTime.now());
    final DateTime premiere = DateTime(1900);

    // Un souvenir ne peut pas venir du futur. Si la galerie a menti sur la
    // date — horloge déréglée, métadonnées corrompues — on ramène le curseur
    // à aujourd'hui plutôt que de laisser le sélecteur refuser de s'ouvrir.
    final DateTime initiale = actuelle.isAfter(aujourdhui) ? aujourdhui : actuelle;

    // En `if/else` et non en ternaire : dans une ternaire, les deux branches
    // appartiennent à la MÊME expression, et l'analyseur voit le `await` de la
    // branche iOS comme une coupure asynchrone précédant la lecture de
    // `context` dans l'autre branche. C'est un faux positif — les deux
    // branches s'excluent — mais l'écrire en if/else est plus lisible de toute
    // façon, et laisse `flutter analyze` silencieux.
    final DateTime? choisie;
    if (Platform.isIOS) {
      choisie = await _selecteurCupertino(initiale, premiere, aujourdhui);
    } else {
      choisie = await showDatePicker(
        context: context,
        initialDate: initiale,
        firstDate: premiere,
        lastDate: aujourdhui,
      );
    }

    if (choisie == null || !mounted) return;

    final DateTime retenue = DateUtils.dateOnly(choisie);
    if (retenue == actuelle) return;

    setState(() => _dateCorrigee = retenue);
    DatabaseService().updateNote(widget.souvenir.copyWith(datePrise: retenue));
  }

  /// Roue de date iOS, présentée dans une feuille qui remonte du bas.
  ///
  /// `showDatePicker` afficherait un calendrier Material jusque sur iPhone :
  /// juste, mais étranger. La roue est le geste que l'utilisateur iOS connaît.
  /// Elle ne valide rien d'elle-même — d'où les deux boutons au-dessus.
  Future<DateTime?> _selecteurCupertino(
    DateTime initiale,
    DateTime premiere,
    DateTime derniere,
  ) {
    DateTime provisoire = initiale;
    final bool sombre = Theme.of(context).brightness == Brightness.dark;

    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (contexteModale) {
        final MaterialLocalizations mots = MaterialLocalizations.of(contexteModale);
        return Container(
          height: 300,
          color: sombre ? darkSurface : white,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(contexteModale).pop(),
                      child: Text(
                        mots.cancelButtonLabel,
                        style: styleCorps.copyWith(color: texteDoux(sombre)),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(contexteModale).pop(provisoire),
                      child: Text(
                        mots.okButtonLabel,
                        style: styleCorps.copyWith(
                          color: orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initiale,
                    minimumDate: premiere,
                    maximumDate: derniere,
                    onDateTimeChanged: (valeur) => provisoire = valeur,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Size> _getImageSize(Uint8List bytes) async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(buffer);
    return Size(descriptor.width.toDouble(), descriptor.height.toDouble());
  }
}

/// Pastille de partage posée sur le souvenir.
///
/// Date du souvenir, posée en bas à gauche.
///
/// Même matière que le bouton de partage — pastille blanche, encre orange,
/// ombre portée décalée de 2 px — pour que les deux éléments se lisent comme
/// une même couche posée sur le souvenir.
class _PastilleDate extends StatelessWidget {
  final DateTime date;

  /// Appelé au toucher : ouvre le sélecteur de date.
  final VoidCallback onTap;

  const _PastilleDate({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const BorderRadius arrondi = BorderRadius.all(Radius.circular(999));

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: arrondi,
        boxShadow: shadowPastille,
      ),
      child: Material(
        color: white,
        borderRadius: arrondi,
        child: InkWell(
          borderRadius: arrondi,
          // Comme pour le bouton de partage : en consommant le geste ici, on
          // empêche le GestureDetector de l'historique de refermer la fenêtre
          // au moment où l'on touche la date.
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              formaterDateSouvenir(date),
              style: styleMention.copyWith(color: orange),
            ),
          ),
        ),
      ),
    );
  }
}

/// Partage : l'icône suit la convention de la plateforme — le carré à flèche
/// montante sur iOS, les trois nœuds reliés sur Android.
class _BoutonPartage extends StatelessWidget {
  final NoteSourire souvenir;

  const _BoutonPartage({required this.souvenir});

  @override
  Widget build(BuildContext context) {
    return BtnRondSouvenir(
      icone: Platform.isIOS ? Icons.ios_share : Icons.share_outlined,
      onTap: () {
        HapticFeedback.selectionClick();
        _ouvrirPartage(context, souvenir);
      },
    );
  }
}

/// Partage du souvenir : un seul format, un polaroid.
///
/// Pas de feuille de choix intermédiaire — un tap, une image, la feuille de
/// partage du système. C'est l'utilisateur qui déclenche l'envoi, souvenir par
/// souvenir : rien ne sort du téléphone tout seul.
Future<void> _ouvrirPartage(BuildContext context, NoteSourire souvenir) async {
  final l10n = AppLocalizations.of(context)!;
  final themeCouleur = SourireTheme.fromLabel(souvenir.colorLabel);

  // Sert à borner la hauteur de l'image d'une note : elle ne doit pas
  // s'afficher sur plus de la moitié d'un écran de téléphone.
  final Size tailleEcran = MediaQuery.sizeOf(context);

  // Position de la fenêtre à l'écran : iPad ancre la feuille de partage
  // système sur ce rectangle, faute de quoi elle refuse de s'ouvrir.
  final RenderBox? boite = context.findRenderObject() as RenderBox?;
  final Rect? origineIpad = boite != null && boite.hasSize
      ? boite.localToGlobal(Offset.zero) & boite.size
      : null;

  // Le rendu, le décodage de la photo et l'ouverture de la feuille système
  // prennent un instant : sans indicateur, l'utilisateur croirait que son tap
  // n'a rien déclenché.
  final NavigatorState navigateur = Navigator.of(context, rootNavigator: true);
  bool attenteAffichee = true;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: black.withValues(alpha: 0.35),
    builder: (_) => Center(
      child: const CircularProgressIndicator(color: orange),
    ),
  );

  bool succes = false;
  try {
    succes = await PartageService.partager(
      souvenir: souvenir,
      couleurPrincipale: themeCouleur.main,
      couleurClaire: themeCouleur.light,
      tailleEcran: tailleEcran,
      origineIpad: origineIpad,
    );
  } finally {
    if (attenteAffichee) {
      attenteAffichee = false;
      navigateur.pop();
    }
  }

  if (!succes && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shareError)),
    );
  }
}

/// Éclosion du souvenir, comme une fleur qui s'ouvre depuis son centre.
///
/// Le souvenir naît d'un point au milieu de l'écran, se déploie en pivotant
/// légèrement, dépasse d'un cheveu sa taille finale puis se pose. Les deux
/// axes ne s'ouvrent pas exactement en même temps — la hauteur devance la
/// largeur — ce qui donne une éclosion plutôt qu'un simple agrandissement.
class _EclosionFleur extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;

  const _EclosionFleur({
    required this.animation,
    required this.child,
  });

  @override
  State<_EclosionFleur> createState() => _EclosionFleurState();
}

class _EclosionFleurState extends State<_EclosionFleur> {
  /// Taille du bouton au départ : assez petit pour qu'on ne lise pas encore
  /// le souvenir, assez grand pour qu'il ne surgisse pas de nulle part.
  static const double _echelleDepart = 0.16;

  /// Vrille initiale, qui se dévisse au fur et à mesure de l'ouverture.
  static const double _rotationDepart = -0.45; // ≈ -26°

  bool _hapticDepart = false;
  bool _hapticEclosion = false;
  bool _hapticPose = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_declencherHaptique);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_declencherHaptique);
    super.dispose();
  }

  /// Une vibration par temps fort, jamais rejouée : les drapeaux ne sont
  /// remis à zéro nulle part, donc la fermeture du souvenir (animation à
  /// l'envers) reste silencieuse.
  void _declencherHaptique() {
    final double t = widget.animation.value;

    if (!_hapticDepart && t > 0.02) {
      _hapticDepart = true;
      HapticFeedback.lightImpact();
    }
    if (!_hapticEclosion && t >= 0.45) {
      _hapticEclosion = true;
      HapticFeedback.mediumImpact();
    }
    if (!_hapticPose && t >= 0.95) {
      _hapticPose = true;
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final double t = widget.animation.value.clamp(0.0, 1.0);

        // easeOutBack dépasse légèrement 1 : c'est le petit rebond de la
        // corolle qui s'ouvre un peu trop grand avant de se stabiliser.
        final double ouvertureY = Curves.easeOutBack.transform(t);
        // La largeur suit avec un léger retard.
        final double ouvertureX =
            Curves.easeOutBack.transform((t * 0.88).clamp(0.0, 1.0));

        final double echelleY = _echelleDepart + (1 - _echelleDepart) * ouvertureY;
        final double echelleX = _echelleDepart + (1 - _echelleDepart) * ouvertureX;

        final double rotation =
            _rotationDepart * (1 - Curves.easeOutCubic.transform(t));

        return Opacity(
          opacity: (t / 0.15).clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: rotation,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scaleByDouble(echelleX, echelleY, 1, 1),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Affiche l'overlay dialog contenant le widget du souvenir pioché
void afficherSouvenirBocal(BuildContext context, NoteSourire souvenir) {
  // L'éclosion est plus courte que le dépliage : c'est un seul geste continu,
  // au-delà de ~700 ms elle traîne.
  final int dureeAnimation = ScreenProfil.animationsDoucesActive ? 400 : 700;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Fermer",
    barrierColor: black.withValues(alpha: 0.25),
    transitionDuration: Duration(milliseconds: dureeAnimation),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Le bouton de partage est désormais posé DANS la carte, il ne
              // réclame donc plus de place sous elle.
              final double tailleCarree = constraints.maxHeight.isFinite
                  ? math.min(constraints.maxWidth, constraints.maxHeight)
                  : constraints.maxWidth;

              final Widget carte = Container(
                width: tailleCarree,
                height: tailleCarree,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: WidgetSouvenirTirage(souvenir: souvenir),
                ),
              );

              // En mode « animations douces », le fondu du transitionBuilder
              // suffit : ni éclosion, ni vibration.
              if (ScreenProfil.animationsDoucesActive) return carte;

              return _EclosionFleur(animation: anim1, child: carte);
            },
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      if (ScreenProfil.animationsDoucesActive) {
        return Opacity(
          opacity: anim1.value,
          child: child,
        );
      }
      // L'éclosion est appliquée dans le pageBuilder, au plus près de la carte.
      return child;
    },
  );
}
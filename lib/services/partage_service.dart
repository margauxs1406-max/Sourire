import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/souvenir_historique.dart';

/// Fabrique une image « brandée Sourire » à partir d'un souvenir et l'envoie
/// à la feuille de partage du système.
///
/// Rien ne transite par un serveur : l'image est dessinée à la volée, écrite
/// dans le dossier temporaire de l'app, puis remise au système. C'est
/// l'utilisateur qui choisit la destination, souvenir par souvenir — le bocal
/// lui-même ne quitte jamais le téléphone.
///
/// Le rendu se fait directement sur un `Canvas` plutôt qu'en capturant un
/// widget : on maîtrise exactement les dimensions de sortie, et surtout on
/// garantit que la photo est décodée avant d'être peinte (une capture de
/// widget peut produire une image vide si le chargement n'est pas terminé).
///
/// Un seul format, une seule image fixe : photo comme note partent en
/// polaroid. La note, elle, s'allonge verticalement quand le texte est long,
/// jusqu'à une hauteur plafond au-delà de laquelle c'est la police qui se
/// réduit.
class PartageService {
  PartageService._();

  // --- GABARIT ----------------------------------------------------------------

  /// Largeur de la carte polaroid. Tout le reste en découle.
  static const double _largeurCarte = 1080;

  /// Marge blanche du polaroid, sur les trois côtés fins.
  static const double _marge = 60;

  /// Largeur de la vignette (photo ou note).
  static const double _cote = _largeurCarte - _marge * 2; // 960

  /// Bande basse du polaroid, celle où l'on signe.
  static const double _bandeSignature = 270;

  /// Couronne autour de la carte : c'est dans cette marge que l'ombre portée a
  /// la place de s'étaler. Sans elle, l'ombre serait rognée par le bord de
  /// l'image.
  static const double _ombreMarge = 54;

  /// Fond de cette couronne. Volontairement blanc OPAQUE et non transparent :
  /// plusieurs messageries ré-encodent les images en JPEG, qui n'a pas de
  /// canal alpha — le pourtour transparent y virerait au noir et encadrerait
  /// le polaroid d'un liseré sombre. Sur le fond blanc d'une conversation, ce
  /// blanc est invisible et seule l'ombre se voit, ce qui est le but.
  /// Mettre `Color(0x00000000)` ici pour retrouver un vrai fond transparent.
  static const Color _fondPourtour = Color(0xFFFFFFFF);

  static const Radius _rayonVignette = Radius.circular(20);

  /// Coins de la carte à peine adoucis : une ombre portée sur un rectangle
  /// parfaitement vif fait sticker découpé.
  static const Radius _rayonCarte = Radius.circular(12);

  /// Blanc franc et non cassé : le blanc chaud d'origine tirait sur
  /// l'orange et jurait contre le fond coloré des notes.
  static const Color _blancPolaroid = white;

  // --- TEXTE ------------------------------------------------------------------

  static const double _paddingTexte = 70;
  static const double _tailleTexteMax = 66;
  static const double _tailleTexteMin = 26;

  // --- HAUTEUR PLAFOND --------------------------------------------------------

  // La consigne — « l'image ne doit pas dépasser la moitié de l'écran » — ne
  // se traduit pas directement en pixels : on ignore l'écran de celui qui
  // reçoit. On raisonne donc en PROPORTION, calculée sur l'écran de
  // l'expéditeur : dans une messagerie, une image occupe environ la largeur
  // d'une bulle ; pour qu'elle s'affiche sur au plus la moitié de la hauteur
  // de l'écran, son rapport hauteur/largeur ne doit pas dépasser
  // (0,5 × hauteur écran) / (largeur d'une bulle).

  /// Part de la largeur de l'écran qu'occupe une bulle de conversation.
  /// WhatsApp, Messenger et iMessage tournent tous autour de cette valeur.
  static const double _partBulle = 0.72;

  /// Part de la hauteur d'écran que l'image ne doit pas dépasser.
  static const double _partHauteurEcran = 0.5;

  /// Garde-fous : en dessous, la note ne pourrait plus s'allonger du tout ;
  /// au-dessus, elle deviendrait une bande difficile à lire.
  static const double _ratioMin = 1.20;
  static const double _ratioMax = 2.00;

  /// Dessine le souvenir puis ouvre la feuille de partage native.
  ///
  /// [tailleEcran] sert uniquement à calculer la hauteur plafond d'une note
  /// (voir plus haut) ; le rendu d'une photo n'en dépend pas.
  ///
  /// Retourne `false` si le rendu ou l'écriture du fichier a échoué. Un partage
  /// simplement abandonné par l'utilisateur n'est PAS un échec.
  static Future<bool> partager({
    required NoteSourire souvenir,
    required Color couleurPrincipale,
    required Color couleurClaire,
    required Size tailleEcran,
    Rect? origineIpad,
  }) async {
    try {
      final Uint8List octets = await _rendre(
        souvenir: souvenir,
        couleurPrincipale: couleurPrincipale,
        couleurClaire: couleurClaire,
        tailleEcran: tailleEcran,
      );

      final Directory dossier = await getTemporaryDirectory();
      final File fichier = File(
        '${dossier.path}/sourire_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await fichier.writeAsBytes(octets, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(fichier.path, mimeType: 'image/png')],
          // Requis sur iPad, où la feuille de partage est un popover ancré.
          sharePositionOrigin: origineIpad,
        ),
      );
      return true;
    } catch (e) {
      debugPrint("Partage impossible : $e");
      return false;
    }
  }

  // --- RENDU ------------------------------------------------------------------

  static Future<Uint8List> _rendre({
    required NoteSourire souvenir,
    required Color couleurPrincipale,
    required Color couleurClaire,
    required Size tailleEcran,
  }) async {
    final bool estPhoto =
        souvenir.photoPath != null && souvenir.photoPath!.trim().isNotEmpty;

    // La photo est décodée AVANT d'ouvrir le canvas : on ne peint jamais un
    // trou en attendant un chargement. Idem pour les icônes de thème.
    final ui.Image? photo =
        estPhoto ? await _chargerPhoto(souvenir.photoPath!.trim()) : null;

    // Une photo garde la vignette carrée d'origine ; une note s'allonge.
    double hauteurVignette = _cote;
    TextPainter? texte;
    List<_IconeVignette> icones = const <_IconeVignette>[];

    if (photo == null) {
      final _MesureTexte mesure = _mesurerTexte(
        souvenir.text?.trim() ?? '',
        _hauteurVignetteMax(tailleEcran),
        couleurPrincipale,
      );
      texte = mesure.peintre;
      hauteurVignette = mesure.hauteurVignette;
      icones = await _chargerIcones(souvenir.themeLabel, hauteurVignette);
    }

    final double hauteurCarte = _marge + hauteurVignette + _bandeSignature;
    final double largeurTotale = _largeurCarte + _ombreMarge * 2;
    final double hauteurTotale = hauteurCarte + _ombreMarge * 2;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, largeurTotale, hauteurTotale),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, largeurTotale, hauteurTotale),
      Paint()..color = _fondPourtour,
    );

    final Rect carte = Rect.fromLTWH(
      _ombreMarge,
      _ombreMarge,
      _largeurCarte,
      hauteurCarte,
    );
    final RRect carteArrondie = RRect.fromRectAndRadius(carte, _rayonCarte);

    // Ombre portée : le polaroid est presque blanc, il se noierait sur le fond
    // blanc d'une messagerie. Volontairement basse et diffuse — on cherche à
    // décoller la carte, pas à la faire léviter.
    canvas.drawRRect(
      carteArrondie.shift(const Offset(0, 10)),
      Paint()
        ..color = black.withValues(alpha: 0.16)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18),
    );

    canvas.drawRRect(carteArrondie, Paint()..color = _blancPolaroid);

    final Rect zoneVignette = Rect.fromLTWH(
      carte.left + _marge,
      carte.top + _marge,
      _cote,
      hauteurVignette,
    );
    final RRect vignetteArrondie =
        RRect.fromRectAndRadius(zoneVignette, _rayonVignette);

    if (photo != null) {
      canvas.save();
      canvas.clipRRect(vignetteArrondie);
      _dessinerEnCover(canvas, photo, zoneVignette);
      canvas.restore();
    } else {
      canvas.drawRRect(vignetteArrondie, Paint()..color = couleurClaire);

      // Les icônes de thème débordent volontairement de la vignette : on les
      // découpe à ses bords, exactement comme dans l'historique.
      canvas.save();
      canvas.clipRRect(vignetteArrondie);
      for (final _IconeVignette icone in icones) {
        icone.dessiner(canvas, zoneVignette.topLeft, couleurPrincipale);
      }
      canvas.restore();

      if (texte != null) {
        texte.paint(
          canvas,
          Offset(
            zoneVignette.left + _paddingTexte,
            zoneVignette.top + (hauteurVignette - texte.height) / 2,
          ),
        );
      }
    }

    // Liseré discret autour de la vignette, pour la détacher du cadre quand
    // la photo est claire ou la note presque blanche.
    canvas.drawRRect(
      vignetteArrondie,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = black.withValues(alpha: 0.06),
    );

    // Bande basse du polaroid : la date à gauche, la marque à droite.
    // La date n'est PAS reprise de la pastille posée sur le souvenir à
    // l'écran — sur une image que l'on donne, elle appartient au cadre, pas
    // à la photo.
    _dessinerBandeau(
      canvas,
      carte: carte,
      basVignette: zoneVignette.bottom,
      date: souvenir.dateAffichee,
    );

    final ui.Picture picture = recorder.endRecording();
    final ui.Image rendu =
        await picture.toImage(largeurTotale.toInt(), hauteurTotale.toInt());
    final ByteData? octets =
        await rendu.toByteData(format: ui.ImageByteFormat.png);

    // On ne libère qu'une fois les octets extraits : le Picture référence
    // encore la photo et les icônes jusqu'au toImage().
    picture.dispose();
    rendu.dispose();
    photo?.dispose();
    for (final _IconeVignette icone in icones) {
      icone.liberer();
    }

    if (octets == null) {
      throw StateError("Encodage PNG impossible");
    }
    return octets.buffer.asUint8List();
  }

  // --- GÉOMÉTRIE DE LA NOTE ---------------------------------------------------

  /// Hauteur au-delà de laquelle la note cesse de s'allonger et se met à
  /// réduire sa police.
  static double _hauteurVignetteMax(Size ecran) {
    double ratio = _ratioMin;
    if (ecran.width > 0 && ecran.height > 0) {
      ratio = (ecran.height * _partHauteurEcran) / (ecran.width * _partBulle);
    }
    ratio = math.min(math.max(ratio, _ratioMin), _ratioMax);

    final double hauteurCarteMax = _largeurCarte * ratio;
    return math.max(_cote, hauteurCarteMax - _marge - _bandeSignature);
  }

  /// Compose le texte de la note et en déduit la hauteur de la vignette.
  ///
  /// Tant que le texte tient dans la hauteur plafond, c'est la vignette qui
  /// s'adapte au texte. Une fois le plafond atteint, la vignette se fige et
  /// c'est la police qui descend — un souvenir long ne doit jamais être
  /// tronqué dans une image qu'on partage.
  static _MesureTexte _mesurerTexte(
    String texte,
    double hauteurMax,
    Color couleur,
  ) {
    final double largeurUtile = _cote - _paddingTexte * 2;
    final double hauteurUtileMax = hauteurMax - _paddingTexte * 2;

    double taille = _tailleTexteMax;
    late TextPainter peintre;

    while (true) {
      peintre = TextPainter(
        text: TextSpan(
          text: texte,
          style: styleNoteLarge.copyWith(
            color: couleur,
            fontSize: tailleLora(taille),
            height: 1.25,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: largeurUtile, maxWidth: largeurUtile);

      if (peintre.height <= hauteurUtileMax || taille <= _tailleTexteMin) break;
      taille -= 3;
    }

    final double hauteurVignette = math.min(
      math.max(peintre.height + _paddingTexte * 2, _cote),
      hauteurMax,
    );

    return _MesureTexte(peintre, hauteurVignette);
  }

  /// Prépare les icônes du thème, positionnées pour une vignette de
  /// [hauteurVignette].
  ///
  /// Les positions du thème sont pensées pour une note carrée. Quand la
  /// vignette s'allonge, on ne les étire pas : celles du haut restent collées
  /// en haut, celles du bas restent collées en bas, et c'est le vide central
  /// qui grandit.
  static Future<List<_IconeVignette>> _chargerIcones(
    String themeLabel,
    double hauteurVignette,
  ) async {
    final ThemeApp theme = ThemeRepository.tousLesThemes.firstWhere(
      (t) => t.id.toLowerCase() == themeLabel.toLowerCase(),
      orElse: () => ThemeRepository.themeClassique,
    );
    if (theme.noteIcons.isEmpty) return const <_IconeVignette>[];

    final List<_IconeVignette> icones = <_IconeVignette>[];

    for (final BackgroundIconConfig config in theme.noteIcons) {
      try {
        final PictureInfo info =
            await vg.loadPicture(SvgAssetLoader(config.assetPath), null);

        // Les ratios sont exprimés pour une note carrée : on les projette
        // donc sur le côté de la vignette, pas sur sa hauteur réelle.
        final double largeur = config.getWidth(_cote);
        final double hauteur = config.getHeight(_cote);
        final double x = config.getX(_cote);
        final double yCarre = config.getY(_cote);

        final bool ancreEnHaut = yCarre + hauteur / 2 < _cote / 2;
        final double y = ancreEnHaut
            ? yCarre
            // Distance au bas de la note carrée, reportée telle quelle sur le
            // bas de la vignette allongée.
            : hauteurVignette - (_cote - yCarre - hauteur) - hauteur;

        icones.add(
          _IconeVignette(
            picture: info.picture,
            tailleSource: info.size,
            boite: Rect.fromLTWH(x, y, largeur, hauteur),
            rotation: config.rotation * math.pi / 180,
            opacite: theme.noteIconOpacity,
          ),
        );
      } catch (e) {
        debugPrint("Partage : icône ${config.assetPath} illisible ($e)");
      }
    }

    return icones;
  }

  // --- PRIMITIVES DE DESSIN ---------------------------------------------------

  /// Remplit [dest] avec [image] sans la déformer (équivalent de BoxFit.cover).
  static void _dessinerEnCover(Canvas canvas, ui.Image image, Rect dest) {
    final double iw = image.width.toDouble();
    final double ih = image.height.toDouble();
    if (iw <= 0 || ih <= 0) return;

    final double echelle = math.max(dest.width / iw, dest.height / ih);
    final double largeurSource = dest.width / echelle;
    final double hauteurSource = dest.height / echelle;

    final Rect source = Rect.fromLTWH(
      (iw - largeurSource) / 2,
      (ih - hauteurSource) / 2,
      largeurSource,
      hauteurSource,
    );

    canvas.drawImageRect(
      image,
      source,
      dest,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  /// Bande basse du polaroid : la date à gauche, le logo « Sourire » à
  /// droite, tous deux dans l'orange de la marque et centrés sur la même
  /// ligne de base optique.
  static void _dessinerBandeau(
    Canvas canvas, {
    required Rect carte,
    required double basVignette,
    required DateTime date,
  }) {
    final TextPainter logo = TextPainter(
      text: TextSpan(
        text: 'Sourire',
        style: styleLogo.copyWith(color: orange, fontSize: 60),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // La date est en police d'interface, pas en Spicy Rice : le logo doit
    // rester le seul élément « écrit à la main » du polaroid.
    final TextPainter dateur = TextPainter(
      text: TextSpan(
        text: formaterDateSouvenir(date),
        style: const TextStyle(
          color: orange,
          fontSize: 40,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double milieu = basVignette + (carte.bottom - basVignette) / 2;
    dateur.paint(
      canvas,
      Offset(carte.left + _marge, milieu - dateur.height / 2),
    );

    final double y = basVignette + (carte.bottom - basVignette - logo.height) / 2;
    logo.paint(canvas, Offset(carte.right - _marge - logo.width, y));
  }

  static Future<ui.Image?> _chargerPhoto(String chemin) async {
    try {
      Uint8List? octets = getCachedHistoriqueImageBytes(chemin);

      if (octets == null) {
        final File fichier = File(chemin);
        if (!await fichier.exists()) return null;
        octets = await fichier.readAsBytes();
      }

      final ui.Codec codec = await ui.instantiateImageCodec(octets);
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint("Partage : photo illisible ($e)");
      return null;
    }
  }
}

/// Texte composé + hauteur de vignette qui en découle.
class _MesureTexte {
  final TextPainter peintre;
  final double hauteurVignette;

  const _MesureTexte(this.peintre, this.hauteurVignette);
}

/// Une icône de thème prête à être peinte sur le canvas.
///
/// [boite] est exprimée relativement au coin haut-gauche de la vignette.
class _IconeVignette {
  final ui.Picture picture;
  final Size tailleSource;
  final Rect boite;
  final double rotation;
  final double opacite;

  const _IconeVignette({
    required this.picture,
    required this.tailleSource,
    required this.boite,
    required this.rotation,
    required this.opacite,
  });

  void dessiner(Canvas canvas, Offset origineVignette, Color couleur) {
    if (tailleSource.width <= 0 || tailleSource.height <= 0) return;

    final Rect cible = boite.shift(origineVignette);

    // Le SVG est monochrome à l'arrivée : on le recolore via un calque filtré,
    // comme le fait le `ColorFilter` de SvgPicture dans l'historique.
    // L'opacité passe par l'alpha de la couleur du filtre.
    canvas.saveLayer(
      // La rotation fait sortir l'icône de sa boîte : on élargit les bornes du
      // calque de la demi-diagonale, sans quoi elle serait rognée.
      cible.inflate(cible.longestSide / 2),
      Paint()
        ..colorFilter = ColorFilter.mode(
          couleur.withValues(alpha: opacite),
          BlendMode.srcIn,
        ),
    );

    canvas.translate(cible.center.dx, cible.center.dy);
    if (rotation != 0) canvas.rotate(rotation);
    canvas.translate(-cible.width / 2, -cible.height / 2);

    // BoxFit.contain, le comportement par défaut de SvgPicture.
    final double echelle = math.min(
      cible.width / tailleSource.width,
      cible.height / tailleSource.height,
    );
    canvas.translate(
      (cible.width - tailleSource.width * echelle) / 2,
      (cible.height - tailleSource.height * echelle) / 2,
    );
    canvas.scale(echelle);

    canvas.drawPicture(picture);
    canvas.restore();
  }

  void liberer() => picture.dispose();
}

import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Requis pour le rendu automatique des SVG sécurisés
import 'package:sourire/theme/tokens.dart'; // Couleurs de marque (orange…)
import 'dart:math' as math;

/// Représente les données de positionnement responsive d'une icône de fond
class BackgroundIconConfig {
  final String assetPath;
  final double widthRatio;
  final double heightRatio;
  final double xRatio;
  final double yRatio;
  final double rotation; // En degrés

  const BackgroundIconConfig({
    required this.assetPath,
    required this.widthRatio,
    required this.heightRatio,
    required this.xRatio,
    required this.yRatio,
    this.rotation = 0.0,
  });

  /// Calcule la taille finale en fonction de la dimension de l'écran ou du conteneur
  double getWidth(double currentWidth) => currentWidth * widthRatio;
  double getHeight(double currentHeight) => currentHeight * heightRatio;

  /// Calcule la position finale relative
  double getX(double currentWidth) => currentWidth * xRatio;
  double getY(double currentHeight) => currentHeight * yRatio;

  /// GARANTIE TECHNIQUE : Génère le widget d'affichage de l'icône en encapsulant 
  /// obligatoirement sa rotation convertie en radians, peu importe le layout parent.
  Widget buildIconWidget({
    required double baseWidth,
    required double baseHeight,
    Color? color,
    double opacity = 1.0,
  }) {
    final double targetWidth = getWidth(baseWidth);
    final double targetHeight = getHeight(baseHeight);
    final bool isSvg = assetPath.toLowerCase().endsWith('.svg');

    // 1. Construction du chargeur d'image brut (SVG ou Bitmap)
    Widget imageWidget;
    if (isSvg) {
      imageWidget = SvgPicture.asset(
        assetPath,
        width: targetWidth,
        height: targetHeight,
        fit: BoxFit.contain,
        colorFilter: color != null 
            ? ColorFilter.mode(color.withValues(alpha: opacity), BlendMode.srcIn) 
            : null,
      );
    } else {
      imageWidget = Image.asset(
        assetPath,
        width: targetWidth,
        height: targetHeight,
        fit: BoxFit.contain,
        color: color?.withValues(alpha: opacity),
      );
    }

    // 2. Application de l'opacité globale si l'image n'est pas colorisée dynamiquement
    if (color == null && opacity < 1.0) {
      imageWidget = Opacity(opacity: opacity, child: imageWidget);
    }

    // 4. CAPSULE DE ROTATION CRITIQUE : Convertit les degrés en radians et force le pivot
    if (rotation != 0.0) {
      imageWidget = Transform.rotate(
        angle: rotation * (math.pi / 180),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Classe principale définissant les thèmes de l'application
class ThemeApp {
  final String id;
  final String Function(BuildContext context) label;
  final bool isPremium;

  // Configuration Home
  final List<BackgroundIconConfig> homeIcons;
  final Color? homeIconColor;
  final double homeIconOpacity;

  // Configuration Note
  final List<BackgroundIconConfig> noteIcons;
  final double noteIconOpacity;

  /// Icône emblématique du thème : la PLUS GRANDE de ses icônes de home.
  ///
  /// Elle se déduit plutôt que de se déclarer, et la règle tombe juste sur
  /// tous les thèmes existants — la tortue pour les animaux marins, le
  /// cerisier pour la nature, le disque pour la musique. C'est logique : la
  /// plus grande icône du décor est celle qui porte le thème.
  ///
  /// `null` pour le thème classique, qui n'a pas de décor. Le carrousel de la
  /// baguette montre alors un cercle vide, ce qui dit exactement ce qu'il est.
  String? get iconePhare {
    if (homeIcons.isEmpty) return null;
    BackgroundIconConfig plusGrande = homeIcons.first;
    for (final BackgroundIconConfig icone in homeIcons) {
      if (icone.widthRatio > plusGrande.widthRatio) plusGrande = icone;
    }
    return plusGrande.assetPath;
  }

  const ThemeApp({
    required this.id,
    required this.label,
    this.isPremium = true,
    this.homeIcons = const [],
    this.homeIconColor,
    this.homeIconOpacity = 1.0,
    this.noteIcons = const [],
    this.noteIconOpacity = 1.0,
  });
}

/// Bibliothèque contenant les thèmes disponibles
class ThemeRepository {
  // Références d'écrans d'origine pour les calculs de ratios
  static const double _homeBaseWidth = 393.0;
  static const double _homeBaseHeight = 852.0;
  
  // Basé sur une boîte de note carrée générique (ex: 300x300) pour préserver les proportions exactes du visuel
  static const double _noteBaseSize = 300.0; 

  // ==========================================
  // 1/ THÈME PAR DÉFAUT
  // ==========================================
  static final ThemeApp themeClassique = ThemeApp(
    id: 'classique', 
    label: (context) => AppLocalizations.of(context)!.themeClassique,
    isPremium: false,
    homeIcons: const [],
    noteIcons: const [],
  );

  // ==========================================
  // 2/ THÈME MONTAGNE
  // ==========================================
  static final ThemeApp themeMontagne = ThemeApp(
    id: 'montagne', 
    label: (context) => AppLocalizations.of(context)!.themeMontagne,
    isPremium: true,
    
    homeIconColor: orange,
    homeIconOpacity: 0.30,
     

    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/montagne/flocon3.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/montagne/flocon2.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 334 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/montagne/montagnes_fin.svg',
         widthRatio: 250 / _homeBaseWidth,
        heightRatio: 250 / _homeBaseHeight,
        xRatio: -56 / _homeBaseWidth,
         yRatio: 265 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/montagne/bonnet_fin.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 313 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
      ),
    ],

    noteIconOpacity: 0.25,

    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/montagne/bonnet.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 40 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/montagne/flocon3_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: -4 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/montagne/chocolat.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 255 / _noteBaseSize, 
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/montagne/flocon2.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/montagne/ski.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/montagne/montagnes.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 165 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  // ==========================================
  // 3/ THÈME MER
  // ==========================================
  static final ThemeApp themeMer = ThemeApp(
    id: 'mer',
    label: (context) => AppLocalizations.of(context)!.themeMer,
    isPremium: true,
    homeIconColor: orange,
    homeIconOpacity: 0.30,
     
    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/mer/coquillage.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/mer/soleil.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 334 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/mer/vague_fin.svg',
         widthRatio: 250 / _homeBaseWidth,
        heightRatio: 250 / _homeBaseHeight,
        xRatio: -56 / _homeBaseWidth,
         yRatio: 265 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/mer/claquettes_fin.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 300 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
        rotation: 12,
      ),
    ],
    noteIconOpacity: 0.25,
    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/mer/claquettes.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 40 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/mer/coquillage_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: -4 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/mer/surf.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 245 / _noteBaseSize, 
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/mer/soleil_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/mer/cocotier.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 0,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/mer/vague.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 165 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  // ==========================================
  // 4/ THÈME ABSTRAIT
  // ==========================================
  // ==========================================
  // 5/ THÈME SPORT
  // ==========================================
  static final ThemeApp themeSport = ThemeApp(
    id: 'sport',
    label: (context) => AppLocalizations.of(context)!.themeSport,
    isPremium: true,
    homeIconColor: orange,
    homeIconOpacity: 0.30,
     
    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/sport/foot.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/sport/course.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 334 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/sport/rugby_fin.svg',
        widthRatio: 240 / _homeBaseWidth,
        heightRatio: 240 / _homeBaseHeight,
        xRatio: -66 / _homeBaseWidth,
        yRatio: 265 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/sport/drapeau_fin.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 313 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
      ),
    ],
    noteIconOpacity: 0.25,
    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/sport/drapeau.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 40 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/sport/foot_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: -4 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/sport/parapente.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 255 / _noteBaseSize, 
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/sport/course.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/sport/muscu.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/sport/rugby.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 165 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  // ==========================================
  // 6/ THÈME MUSIQUE
  // ==========================================
  static final ThemeApp themeMusique = ThemeApp(
    id: 'musique',
    label: (context) => AppLocalizations.of(context)!.themeMusique,
    isPremium: true,
    homeIconColor: orange,
    homeIconOpacity: 0.30,
     
    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/musique/notes_vides.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/musique/notes_pleines.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 334 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/musique/disque_fin.svg',
        widthRatio: 240 / _homeBaseWidth,
        heightRatio: 240 / _homeBaseHeight,
        xRatio: -56 / _homeBaseWidth,
        yRatio: 265 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/musique/micro_fin.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 313 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
      ),
    ],
    noteIconOpacity: 0.25,
    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/musique/micro.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 40 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/musique/notes_vides_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: -4 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/musique/casque.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 255 / _noteBaseSize, 
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/musique/notes_pleines.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/musique/guitare.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/musique/disque.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 165 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  // ==========================================
  // 7/ THÈME CINÉMA
  // ==========================================
  static final ThemeApp themeCinema = ThemeApp(
    id: 'cinema',
    label: (context) => AppLocalizations.of(context)!.themeCinema,
    isPremium: true,
    homeIconColor: orange,
    homeIconOpacity: 0.30,
     
    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/cinema/billet.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/cinema/burger.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 334 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/cinema/clap_fin.svg',
         widthRatio: 250 / _homeBaseWidth,
        heightRatio: 250 / _homeBaseHeight,
        xRatio: -56 / _homeBaseWidth,
         yRatio: 265 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/cinema/pop-corn_fin.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 313 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
      ),
    ],
    noteIconOpacity: 0.25,
    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/cinema/pop-corn.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 40 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/cinema/billet_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: -4 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/cinema/bande.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 255 / _noteBaseSize, 
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/cinema/burger_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/cinema/camera.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/cinema/clap.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 165 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  // ==========================================
  // 8/ THÈME ANIMAUX MARINS
  // ==========================================
  static final ThemeApp themeAnimauxMarins = ThemeApp(
    id: 'animaux_marins',
    label: (context) => AppLocalizations.of(context)!.themeAnimauxMarins,
    isPremium: true,
    homeIconColor: orange,
    homeIconOpacity: 0.30,
     
    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/animaux_marins/dauphin.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/animaux_marins/baleine.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 344 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/animaux_marins/tortue_fin.svg',
         widthRatio: 250 / _homeBaseWidth,
        heightRatio: 250 / _homeBaseHeight,
        xRatio: -75 / _homeBaseWidth,
         yRatio: 265 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/animaux_marins/poulpe_fin.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 313 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
      ),
    ],
    noteIconOpacity: 0.25,
    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/animaux_marins/poulpe.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 50 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/animaux_marins/dauphin_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: -4 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/animaux_marins/raie.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 255 / _noteBaseSize, 
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/animaux_marins/baleine_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/animaux_marins/requin.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/animaux_marins/tortue.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 155 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  // ==========================================
  // 9/ THÈME NATURE
  // ==========================================
  //
  // Anciennement « floral ». L'identifiant a changé avec le nom : les
  // souvenirs et les préférences enregistrés sous 'floral' sont rattrapés
  // par `ThemeService.parId`.
  static final ThemeApp themeNature = ThemeApp(
    id: 'nature',
    label: (context) => AppLocalizations.of(context)!.themeNature,
    isPremium: true,
    homeIconColor: orange,
    homeIconOpacity: 0.30,
     
    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/nature/lotus.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/nature/marguerite.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 334 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/nature/cerisier_fin.svg',
         widthRatio: 250 / _homeBaseWidth,
        heightRatio: 250 / _homeBaseHeight,
        xRatio: -56 / _homeBaseWidth,
        yRatio: 275 / _homeBaseHeight,
        rotation: 11,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/nature/monstera_fin.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 313 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
        rotation: 12,
      ),
    ],
    noteIconOpacity: 0.25,
    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/nature/monstera.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 40 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/nature/lotus.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: -4 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/nature/fougere.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 255 / _noteBaseSize, 
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/nature/marguerite_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/nature/trefle.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/nature/cerisier.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 165 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  // ==========================================
  // 10/ THÈME KAWAII
  // ==========================================
  static final ThemeApp themeKawaii = ThemeApp(
    id: 'kawaii',
    label: (context) => AppLocalizations.of(context)!.themeKawaii,
    isPremium: true,
    homeIconColor: orange,
    homeIconOpacity: 0.30,
     
    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/kawaii/sushi.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/kawaii/donut.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 334 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/kawaii/soleil_fin.svg',
         widthRatio: 250 / _homeBaseWidth,
        heightRatio: 250 / _homeBaseHeight,
        xRatio: -56 / _homeBaseWidth,
         yRatio: 275 / _homeBaseHeight,
        rotation: 13,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/kawaii/sundae_fin.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 313 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
      ),
    ],
    noteIconOpacity: 0.25,
    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/kawaii/sundae.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 40 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/kawaii/sushi_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: 12 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/kawaii/arc-en-ciel.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 255 / _noteBaseSize, 
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/kawaii/donut_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/kawaii/frappe.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/kawaii/soleil.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 165 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  // ==========================================
  // 11/ THÈME AMOUR
  // ==========================================
  //
  // Décor et fond de note calqués sur les animaux marins : mêmes tailles,
  // mêmes positions, mêmes rotations. Seules les icônes changent. Les
  // épaisseurs de trait ont été ajustées créneau par créneau pour retrouver
  // exactement celles du thème modèle — 1,50 px apparents dans la note, plus
  // fin pour les deux petites icônes du décor, qui doivent rester discrètes.
  static final ThemeApp themeAmour = ThemeApp(
    id: 'amour',
    label: (context) => AppLocalizations.of(context)!.themeAmour,
    isPremium: true,
    homeIconColor: orange,
    homeIconOpacity: 0.30,

    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/amour/etoiles.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/amour/coeur.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 344 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/amour/cupidon.svg',
        widthRatio: 250 / _homeBaseWidth,
        heightRatio: 250 / _homeBaseHeight,
        xRatio: -75 / _homeBaseWidth,
        yRatio: 265 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/amour/bouquet.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 313 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
        rotation: -12,
      ),
    ],
    noteIconOpacity: 0.25,
    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/amour/bouquet_note.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 50 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/amour/etoiles_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: -4 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/amour/alliances.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 255 / _noteBaseSize,
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/amour/coeur_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/amour/lettre.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/amour/cupidon_note.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 155 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  // ==========================================
  // 12/ THÈME CÉLÉBRATIONS
  // ==========================================
  static final ThemeApp themeCelebration = ThemeApp(
    id: 'celebration',
    label: (context) => AppLocalizations.of(context)!.themeCelebration,
    isPremium: true,
    homeIconColor: orange,
    homeIconOpacity: 0.30,

    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/celebration/rire.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/celebration/confettis.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 344 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/celebration/feux-dartifice.svg',
        widthRatio: 250 / _homeBaseWidth,
        heightRatio: 250 / _homeBaseHeight,
        xRatio: -75 / _homeBaseWidth,
        yRatio: 265 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/celebration/champagne.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 313 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
      ),
    ],
    noteIconOpacity: 0.25,
    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/celebration/champagne_note.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 50 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/celebration/rire_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: -4 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/celebration/gateau.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 255 / _noteBaseSize,
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/celebration/confettis_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/celebration/ballons.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/celebration/feux-dartifice_note.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 155 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  // ==========================================
  // 13/ THÈME VOYAGE
  // ==========================================
  static final ThemeApp themeVoyage = ThemeApp(
    id: 'voyage',
    label: (context) => AppLocalizations.of(context)!.themeVoyage,
    isPremium: true,
    homeIconColor: orange,
    homeIconOpacity: 0.30,

    homeIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/voyage/rose-des-vents.svg',
        widthRatio: 32 / _homeBaseWidth,
        heightRatio: 32 / _homeBaseHeight,
        xRatio: 316 / _homeBaseWidth,
        yRatio: 158 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/voyage/appareil-photo.svg',
        widthRatio: 40 / _homeBaseWidth,
        heightRatio: 40 / _homeBaseHeight,
        xRatio: 344 / _homeBaseWidth,
        yRatio: 206 / _homeBaseHeight,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/voyage/planete.svg',
        widthRatio: 250 / _homeBaseWidth,
        heightRatio: 250 / _homeBaseHeight,
        xRatio: -75 / _homeBaseWidth,
        yRatio: 265 / _homeBaseHeight,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/voyage/passeport.svg',
        widthRatio: 124 / _homeBaseWidth,
        heightRatio: 124 / _homeBaseHeight,
        xRatio: 313 / _homeBaseWidth,
        yRatio: 630 / _homeBaseHeight,
      ),
    ],
    noteIconOpacity: 0.25,
    noteIcons: [
      BackgroundIconConfig(
        assetPath: 'assets/themes/voyage/passeport_note.svg',
        widthRatio: 68 / _noteBaseSize,
        heightRatio: 68 / _noteBaseSize,
        xRatio: 50 / _noteBaseSize,
        yRatio: -8 / _noteBaseSize,
        rotation: -12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/voyage/rose-des-vents_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: 252 / _noteBaseSize,
        yRatio: -4 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/voyage/valise.svg',
        widthRatio: 62 / _noteBaseSize,
        heightRatio: 62 / _noteBaseSize,
        xRatio: 255 / _noteBaseSize,
        yRatio: 165 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/voyage/appareil-photo_note.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -12 / _noteBaseSize,
        yRatio: 245 / _noteBaseSize,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/voyage/avion.svg',
        widthRatio: 48 / _noteBaseSize,
        heightRatio: 48 / _noteBaseSize,
        xRatio: -16 / _noteBaseSize,
        yRatio: 105 / _noteBaseSize,
        rotation: 12,
      ),
      BackgroundIconConfig(
        assetPath: 'assets/themes/voyage/planete_note.svg',
        widthRatio: 80 / _noteBaseSize,
        heightRatio: 80 / _noteBaseSize,
        xRatio: 155 / _noteBaseSize,
        yRatio: 235 / _noteBaseSize,
      ),
    ],
  );

  /// Liste globale pour l'affichage de la boutique / sélection
  static final List<ThemeApp> tousLesThemes = [
    themeClassique,
    // Le thème « abstrait » a été retiré, définition comprise : ses fichiers
    // SVG n'existent plus sur le disque. Les souvenirs enregistrés avec
    // 'abstrait' s'affichent avec le thème classique, la résolution d'un
    // thème passant par cette liste.
    themeAmour,
    themeAnimauxMarins,
    themeCelebration,
    themeCinema,
    themeKawaii,
    themeMer,
    themeMontagne,
    themeMusique,
    themeNature,
    themeSport,
    themeVoyage,
  ];
}
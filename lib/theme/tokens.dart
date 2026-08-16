import 'package:flutter/material.dart';
import 'dart:math';

// --- COLORS (Gardez vos couleurs intactes) ---
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color grey = Color(0xFF616161);
const Color lightGrey = Color(0xFFA6A6A6);
const Color orange = Color(0xFFFF8000);
const Color lightOrange = Color(0xFFFFFBF5);
const Color green = Color(0xFF60B993);
const Color lightGreen = Color(0xFFFDFFFB);
const Color blue = Color(0xFF5CCDFE);
const Color lightBlue = Color(0xFFFBFEFF);
const Color pink = Color(0xFFFE5CC2);
const Color lightPink = Color(0xFFFFFDFB);
const Color darkBg = Color(0xFF1E1E1E);        
const Color darkSurface = Color(0xFF2A2A2A);   
const Color darkSeparateur = Color(0xFF2D2D2D); 

// --- NOUVELLES COULEURS : dédiées aux photos, pour l'effet arc-en-ciel du bocal ---
// Ajuste les hex si tu veux d'autres teintes.
const Color yellow = Color.fromARGB(255, 255, 204, 1);
const Color lightYellow = Color(0xFFFFFEF5);
const Color purple = Color(0xFFA503F6);
const Color lightPurple = Color(0xFFFCFAFF);
const Color red = Color.fromARGB(255, 250, 58, 58);
const Color lightRed = Color(0xFFFFFAFA);
const Color teal = Color(0xFF03C4A4);
const Color lightTeal = Color(0xFFF5FFFE);

// NOTE : la structure BackgroundIconConfig vivait aussi ici, en double de
// celle de models/theme_app.dart. Cette copie n'était utilisée nulle part —
// seule celle de theme_app.dart porte les positions des thèmes, et c'est elle
// qui expose les helpers getX/getY/getWidth/getHeight. Elle a été supprimée.

class SourireTheme {
  final Color main;    
  final Color light;   
  final String label;  

  SourireTheme({required this.main, required this.light, required this.label});

  // --- La liste de référence de vos thèmes pour les NOTES TEXTE ---
  static final List<SourireTheme> tousLesThemes = [
    SourireTheme(main: orange, light: lightOrange, label: "orange"),
    SourireTheme(main: green, light: lightGreen, label: "vert"),
    SourireTheme(main: blue, light: lightBlue, label: "bleu"),
    SourireTheme(main: pink, light: lightPink, label: "rose"),
    SourireTheme(main: purple, light: lightPurple, label: "violet"),
  ];

  // --- Liste dédiée aux PHOTOS ---
  //
  // Les photos piochent désormais dans TOUTES les couleurs de l'app : les
  // quatre qui leur étaient réservées, plus celles des notes. Le bocal y
  // gagne en variété, et une bille ne trahit plus le type de souvenir
  // qu'elle représente.
  static final List<SourireTheme> tousLesThemesPhotos = [
    SourireTheme(main: yellow, light: lightYellow, label: "jaune"),
    SourireTheme(main: red, light: lightRed, label: "rouge"),
    SourireTheme(main: teal, light: lightTeal, label: "turquoise"),
    SourireTheme(main: orange, light: lightOrange, label: "orange"),
    SourireTheme(main: green, light: lightGreen, label: "vert"),
    SourireTheme(main: blue, light: lightBlue, label: "bleu"),
    SourireTheme(main: pink, light: lightPink, label: "rose"),
    SourireTheme(main: purple, light: lightPurple, label: "violet"),
  ];

  // Une seule instance de Random réutilisée, pour éviter tout risque
  // de graines identiques lors d'appels très rapprochés (ex: import
  // de plusieurs photos d'affilée dans une boucle).
  static final Random _rng = Random();

  static SourireTheme getRandom() {
    return tousLesThemes[_rng.nextInt(tousLesThemes.length)];
  }

  // --- NOUVEAU : tirage aléatoire dédié aux photos ---
  static SourireTheme getRandomPhoto() {
    return tousLesThemesPhotos[_rng.nextInt(tousLesThemesPhotos.length)];
  }

  /// Récupère le thème exact à partir du texte enregistré en base de données.
  /// Gère maintenant aussi bien les labels des notes texte que ceux des photos.
  static SourireTheme fromLabel(String? colorLabel) {
    switch (colorLabel) {
      case 'vert':
        return SourireTheme(main: green, light: lightGreen, label: 'vert');
      case 'bleu':
        return SourireTheme(main: blue, light: lightBlue, label: 'bleu');
      case 'rose':
        return SourireTheme(main: pink, light: lightPink, label: 'rose');
      case 'jaune':
        return SourireTheme(main: yellow, light: lightYellow, label: 'jaune');
      case 'violet':
        return SourireTheme(main: purple, light: lightPurple, label: 'violet');
      case 'rouge':
        return SourireTheme(main: red, light: lightRed, label: 'rouge');
      case 'turquoise':
        return SourireTheme(main: teal, light: lightTeal, label: 'turquoise');
      case 'orange':
      default:
        return SourireTheme(main: orange, light: lightOrange, label: 'orange');
    }
  }
}

// --- TYPOGRAPHY & EFFECTS (Laissez votre reste du fichier inchangé) ---
const TextStyle styleLogo = TextStyle(fontFamily: 'Spicy Rice', fontSize: 36, color : white);
/// Lora a un œil bien plus large que Lobster Two : à taille de police égale,
/// elle paraît nettement plus grosse. Toutes les tailles qui s'appliquent à
/// Lora passent donc par [tailleLora], qui applique ce facteur de correction —
/// le rendu reste visuellement identique à l'ancienne police.
const double facteurLora = 0.85;

/// Convertit une taille pensée pour Lobster Two en taille Lora équivalente.
double tailleLora(double taille) => taille * facteurLora;

/// Titres en Lora, en demi-gras.
///
/// Lora est livrée en police VARIABLE : un seul fichier porte toutes les
/// graisses, le long de l'axe « wght ». Sur ce type de fichier `fontWeight`
/// seul ne change rien — Flutter ne connaît qu'un unique asset déclaré et se
/// contenterait d'un gras synthétique. C'est `fontVariations` qui pilote
/// réellement la graisse. On renseigne les deux : la variation pour le rendu,
/// le poids pour que les mesures et le reste du framework restent cohérents.
///
/// Réservé aux TITRES : le texte des souvenirs reste en graisse normale
/// (cf. [styleNoteLarge]).
const TextStyle styleTitreLora = TextStyle(
  fontFamily: 'Lora',
  fontWeight: FontWeight.w600,
  fontVariations: [FontVariation('wght', 600)],
);

/// Texte des souvenirs : Lora en graisse normale, volontairement.
const TextStyle styleNoteLarge = TextStyle(fontFamily: 'Lora', fontSize: 31);
const TextStyle styleNoteSmall = TextStyle(fontFamily: 'Lora', fontSize: 7);

// --- ÉCHELLE TYPOGRAPHIQUE ---------------------------------------------------
//
// Sept rôles couvrent toute l'application (le titre de modale se dédouble
// selon ce qu'elle dit — voir plus bas). Aucun de ces styles ne fixe de
// famille sans-serif : ils héritent de celle du ThemeData — Inclusive Sans
// sur Android, San Francisco sur iOS. Voir main.dart.

/// 1. Titre d'écran, en Lora demi-gras. La taille vient de l'appelant — elle
/// est presque toujours responsive — et passe par [tailleLora].
const TextStyle styleTitreEcran = styleTitreLora;

/// 2a. Titre d'une modale qui RACONTE quelque chose : palier atteint, badge
/// débloqué, bocal plein, bienvenue. En Lora, comme les titres d'écran.
///
/// 22 pt et non 18 : `tailleLora` ramène 22 à 18,7 pt, et une serif a besoin
/// de plus de corps qu'une sans-serif pour rester lisible.
final TextStyle styleTitreRecit = styleTitreLora.copyWith(fontSize: tailleLora(22));

/// 2b. Titre d'une modale qui DEMANDE quelque chose : confirmation,
/// suppression, erreur, réglage. Sans-serif — la serif y ferait décorative au
/// moment précis où l'on attend de la clarté.
const TextStyle styleTitreAction =
    TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

/// 3. Titre de section à l'intérieur d'un écran.
const TextStyle styleSection =
    TextStyle(fontSize: 20, fontWeight: FontWeight.w600);

/// 4. Corps courant : libellé de champ, ligne de réglage, valeur affichée,
/// texte d'un bouton plein.
const TextStyle styleCorps =
    TextStyle(fontSize: 16, fontWeight: FontWeight.w500);

/// 5. Texte secondaire : description sous un titre, sous-titre d'un réglage.
const TextStyle styleSecondaire = TextStyle(fontSize: 14, height: 1.4);

/// 6. Mention discrète : badge, compteur, libellé de filtre actif.
const TextStyle styleMention =
    TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

// Le septième rôle, le texte des souvenirs, est [styleNoteLarge] ci-dessus.

/// Couleur du texte principal. Remplace les huit variables locales
/// (`couleurTitre`, `couleurTextePrincipal`, `textColor`…) qui disaient toutes
/// la même chose.
Color texteFort(bool sombre) => sombre ? white : black;

/// Couleur du texte secondaire.
Color texteDoux(bool sombre) => sombre ? lightGrey : grey;

// Ces deux styles demandaient « Inclusive Sans » alors que la famille
// n'était pas déclarée : Flutter retombait sans prévenir sur la police
// système. La famille est désormais posée une seule fois, dans le
// ThemeData de main.dart, et seulement sur Android.
const TextStyle styleBouton = TextStyle(fontWeight: FontWeight.w500, fontSize: 16);
const TextStyle styleCategorie = TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color : grey);
const List<BoxShadow> shadowDrop = [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(4, 4))];

/// Format de date des souvenirs : JJ.MM.AAAA, le même partout — pastille
/// posée sur le souvenir comme bandeau du polaroid partagé.
String formaterDateSouvenir(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.'
    '${d.year}';

/// Ombre de la pastille de date et du bouton de partage : même décalage, pour
/// que les deux éléments posés sur un souvenir se ressemblent.
const List<BoxShadow> shadowPastille = [
  BoxShadow(color: Color(0x2E000000), blurRadius: 5, offset: Offset(2, 2)),
];

/// Ombre très légère, pour détacher un élément blanc du fond `lightOrange`
/// sans donner l'impression qu'il flotte. Utilisée sur les champs et les
/// cartes de l'onboarding.
const List<BoxShadow> shadowSoft = [
  BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
];
const double radiusDefault = 15.0;
const double paddingDefault = 20.0;
const double gapDefault = 16.0;

/// Passe à `false` une fois la phase de test terminée, pour masquer
/// automatiquement la mention "Gratuit pour les tests" sur les boutons
/// Premium (home.dart et screen_choix_themes.dart).
const bool phaseDeTestActive = true;

/// Interrupteur de test : force l'affichage de TOUS les badges comme
/// débloqués dans screen_mes_badges.dart, sans avoir besoin de créer
/// réellement des milliers de souvenirs. Purement en mémoire (non
/// persisté) — se réinitialise à chaque redémarrage de l'app. Visible
/// uniquement quand `phaseDeTestActive` est actif.
final ValueNotifier<bool> debloquerTousBadgesTestNotifier = ValueNotifier<bool>(false);
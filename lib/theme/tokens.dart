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
const Color purple = Color.fromARGB(255, 111, 6, 240);
const Color lightPurple = Color(0xFFFCFAFF);
const Color red = Color.fromARGB(255, 250, 58, 58);
const Color lightRed = Color(0xFFFFFAFA);
const Color teal = Color.fromARGB(255, 10, 219, 191);
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

  // --- NOUVEAU : liste de référence dédiée aux PHOTOS ---
  static final List<SourireTheme> tousLesThemesPhotos = [
    SourireTheme(main: yellow, light: lightYellow, label: "jaune"),
    SourireTheme(main: purple, light: lightPurple, label: "violet"),
    SourireTheme(main: red, light: lightRed, label: "rouge"),
    SourireTheme(main: teal, light: lightTeal, label: "turquoise"),
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
        return SourireTheme(main: const Color.fromARGB(255, 88, 5, 189), light: lightPurple, label: 'violet');
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

const TextStyle styleNoteLarge = TextStyle(fontFamily: 'Lora', fontSize: 31);
const TextStyle styleNoteSmall = TextStyle(fontFamily: 'Lora', fontSize: 7);
const TextStyle styleBouton = TextStyle(fontFamily: 'Inclusive Sans', fontWeight: FontWeight.w500, fontSize: 16);
const TextStyle styleCategorie = TextStyle(fontFamily: 'Inclusive Sans', fontWeight: FontWeight.w500, fontSize: 20, color : grey);
const List<BoxShadow> shadowDrop = [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(4, 4))];
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
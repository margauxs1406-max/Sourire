import 'package:flutter/widgets.dart';

/// Une langue proposée par l'application.
class LangueApp {
  /// Code stocké en préférences — c'est lui, et non le libellé traduit, qui
  /// est persisté : un libellé changerait de valeur en changeant de langue.
  final String code;

  /// Locale complète, région comprise, telle que la réclament
  /// `supportedLocales` et les formateurs de dates d'intl.
  final Locale locale;

  /// Nom de la langue ÉCRIT DANS CETTE LANGUE — « Español », jamais
  /// « Espagnol ». C'est le seul moyen pour quelqu'un qui ne comprend pas la
  /// langue affichée à l'instant de retrouver la sienne dans la liste. Ce nom
  /// n'a donc rien à faire dans les fichiers .arb : il ne se traduit pas.
  final String nom;

  const LangueApp({
    required this.code,
    required this.locale,
    required this.nom,
  });
}

/// Catalogue des langues de l'application.
///
/// Source unique : l'onboarding, l'écran Langues du profil, `supportedLocales`
/// et le choix de la langue d'amorçage lisent tous cette liste. Ajouter une
/// langue se fait donc ici et dans `lib/l10n/`, nulle part ailleurs.
class Langues {
  const Langues._();

  static const LangueApp francais = LangueApp(
    code: 'fr',
    locale: Locale('fr', 'FR'),
    nom: 'Français',
  );

  static const LangueApp anglais = LangueApp(
    code: 'en',
    locale: Locale('en', 'US'),
    nom: 'English',
  );

  static const LangueApp espagnol = LangueApp(
    code: 'es',
    locale: Locale('es', 'ES'),
    nom: 'Español',
  );

  /// Dans l'ordre d'affichage. Le français en tête : c'est la langue du
  /// fichier modèle et celle de repli.
  static const List<LangueApp> toutes = <LangueApp>[
    francais,
    anglais,
    espagnol,
  ];

  static List<Locale> get locales =>
      <Locale>[for (final LangueApp langue in toutes) langue.locale];

  /// Langue correspondant à un code stocké. Repli sur le français pour un
  /// code inconnu — celui d'une version future, ou une préférence corrompue.
  static LangueApp parCode(String code) {
    for (final LangueApp langue in toutes) {
      if (langue.code == code) return langue;
    }
    return francais;
  }
}

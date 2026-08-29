import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Une tranche de temps sur laquelle borner l'historique.
///
/// Volontairement réduite à une année, éventuellement resserrée sur un mois.
/// C'est la façon dont on cherche réellement dans un journal — « l'été
/// dernier », « en mars » — alors que les anciennes puces « ce mois-ci » et
/// « cette année » ne savaient parler que du présent, et que le sélecteur de
/// plage sur mesure demandait deux dates exactes pour répondre à la même
/// question.
///
/// Immuable et sans référence à « maintenant » : une période désigne toujours
/// les mêmes bornes, qu'on la relise une seconde ou six mois plus tard.
@immutable
class PeriodeFiltre {
  /// Année retenue, sur quatre chiffres.
  final int annee;

  /// Mois retenu (1 à 12), ou `null` pour l'année entière.
  final int? mois;

  /// Sans [mois], la période couvre l'année entière.
  const PeriodeFiltre({required this.annee, this.mois});

  /// Premier instant retenu.
  DateTime get debut => DateTime(annee, mois ?? 1);

  /// Dernier instant retenu, borne INCLUSE — d'où la fin de journée à
  /// 23:59:59. Sans cela, tous les souvenirs du dernier jour seraient exclus.
  ///
  /// Le jour 0 du mois suivant, c'est le dernier jour de celui-ci : Dart
  /// normalise le débordement, y compris en décembre et les années
  /// bissextiles, et il n'y a aucun calendrier à tenir à la main.
  DateTime get fin => mois == null
      ? DateTime(annee, 12, 31, 23, 59, 59)
      : DateTime(annee, mois! + 1, 0, 23, 59, 59);

  /// `true` si [date] tombe dans la tranche.
  bool contient(DateTime date) => !date.isBefore(debut) && !date.isAfter(fin);

  /// La même période resserrée sur un mois, ou élargie à l'année si [mois]
  /// est `null`.
  PeriodeFiltre avecMois(int? mois) =>
      PeriodeFiltre(annee: annee, mois: mois);

  /// Libellé lisible : « 2025 », ou « mars 2025 ».
  String libelle(BuildContext context) {
    if (mois == null) return '$annee';
    return '${nomDuMois(context, mois!)} $annee';
  }

  /// Nom complet d'un mois dans la langue affichée.
  ///
  /// Passe par intl plutôt que par les fichiers .arb : douze noms de mois par
  /// langue, c'est trente-six chaînes à traduire et à tenir à jour pour une
  /// information qu'intl possède déjà pour toutes les locales.
  static String nomDuMois(BuildContext context, int mois) {
    final String locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMM(locale).format(DateTime(2000, mois));
  }

  /// Nom abrégé d'un mois — « janv. », « ene. » — pour les puces, où le nom
  /// complet ferait déborder la grille.
  static String nomCourtDuMois(BuildContext context, int mois) {
    final String locale = Localizations.localeOf(context).toString();
    return DateFormat.MMM(locale).format(DateTime(2000, mois));
  }

  @override
  bool operator ==(Object other) =>
      other is PeriodeFiltre && other.annee == annee && other.mois == mois;

  @override
  int get hashCode => Object.hash(annee, mois);
}

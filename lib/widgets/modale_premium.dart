import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/main.dart';
import 'package:sourire/theme/theme_service.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/theme/user_prefs.dart';

/// Propose le passage au Premium, avec un argumentaire propre à l'endroit d'où
/// l'on vient.
///
/// L'offre n'est pas la même chose selon le moment : quelqu'un qui bute sur la
/// limite de souvenirs n'achète pas pour les mêmes raisons que quelqu'un qui
/// vient de voir sa note en thème floral. D'où le [message], donné par
/// l'appelant, plutôt qu'un texte unique qui parlerait à moitié dans les deux
/// cas.
///
/// Retourne `true` si l'achat a été validé.
///
/// ⚠️ L'« achat » est encore un raccourci : il débloque sans rien facturer, en
/// attendant l'immatriculation de MxS Studio et le branchement de
/// `in_app_purchase`. C'est ici qu'il faudra poser le vrai parcours StoreKit /
/// Play Billing — voir la note de préparation du projet.
Future<bool> afficherModalePremium(
  BuildContext context, {
  required String titre,
  required String message,
}) async {
  final ThemeMode mode = MyApp.themeNotifier.value;
  final bool sombre = mode == ThemeMode.system
      ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
      : mode == ThemeMode.dark;

  final bool? achete = await showDialog<bool>(
    context: context,
    builder: (contexteModale) {
      final AppLocalizations mots = AppLocalizations.of(contexteModale)!;

      return AlertDialog(
        backgroundColor: sombre ? darkSurface : white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // Titre nu. L'étincelle qui l'accompagnait était une décoration de
        // plus dans une boîte qui demande déjà de l'argent : elle promettait
        // de la magie là où l'offre se suffit à elle-même.
        title: Text(
          titre,
          style: styleTitreRecit.copyWith(color: texteTitre(sombre)),
        ),
        content: Text(
          message,
          style: styleSecondaire.copyWith(color: texteDoux(sombre)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexteModale).pop(false),
            child: Text(
              MaterialLocalizations.of(contexteModale).cancelButtonLabel,
              style: styleCorps.copyWith(color: texteDoux(sombre)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(contexteModale).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Text(
              mots.btnGoPremium,
              style: styleCorps.copyWith(
                color: white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (achete != true) return false;

  UserPrefs.isPremium = true;
  ThemeService.deverrouillerPremium();
  return true;
}

import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/theme/tokens.dart';

/// Entonnoir + « Filtrer », en haut à gauche de l'historique.
///
/// Remplace la pilule orange pleine qui occupait le coin droit : un bouton
/// plein annonce l'action principale d'un écran, or filtrer n'est pas ce qu'on
/// vient faire dans l'historique. Le texte orange souligné dit la même chose —
/// c'est cliquable — sans prendre la place d'un bouton.
///
/// À gauche, parce que c'est là que commence la lecture, et parce que le
/// panneau se déplie juste dessous : il tombe alors dans le sens du regard.
class BtnFiltrer extends StatelessWidget {
  /// Nombre de filtres actifs, période comprise. Au-delà de zéro, il s'affiche
  /// entre parenthèses : sans lui, un historique tronqué passerait pour
  /// l'historique complet.
  final int nombreDeFiltres;

  final VoidCallback onTap;

  const BtnFiltrer({
    required this.nombreDeFiltres,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations mots = AppLocalizations.of(context)!;
    final String libelle = nombreDeFiltres > 0
        // Un nombre entre parenthèses se lit dans toutes les langues : rien à
        // traduire, contrairement au « Filtré (2) » codé en dur d'avant.
        ? '${mots.btnFilter} ($nombreDeFiltres)'
        : mots.btnFilter;

    return GestureDetector(
      onTap: onTap,
      // Sans cela, seuls les pixels dessinés répondraient au doigt.
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.filter_alt_outlined, size: 22, color: orange),
            const SizedBox(width: 6),
            Text(
              libelle,
              style: styleCorps.copyWith(
                color: orange,
                // Demi-gras : le mot est seul en haut du volet, sans fond ni
                // contour pour le porter. C'est la graisse qui lui donne le
                // poids d'un bouton.
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

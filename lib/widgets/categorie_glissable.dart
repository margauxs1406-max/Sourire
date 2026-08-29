import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/item_categorie.dart';

/// Fraction de la ligne à parcourir pour ARMER la suppression.
///
/// Une seule valeur pour deux choses, et c'est le point important : c'est le
/// seuil au-delà duquel le fond passe au rouge, ET celui au-delà duquel lâcher
/// le doigt déclenche la suppression. Si les deux différaient, l'utilisateur
/// verrait un fond rouge menaçant puis ne verrait rien se produire — ou pire,
/// l'inverse.
const double _seuilArmement = 0.25;

/// Une ligne de catégorie qu'on supprime en la faisant glisser vers la gauche.
///
/// Remplace l'ancien bouton « Supprimer des catégories », qui ouvrait une
/// modale listant à nouveau toutes les catégories : deux écrans et trois gestes
/// pour effacer une ligne qu'on avait déjà sous les yeux. Le glissement est le
/// geste que tout le monde connaît depuis Mail sur iOS.
///
/// Partagée par les trois écrans de catégorisation — notes, photos, historique.
class CategorieGlissable extends StatefulWidget {
  /// Clé telle qu'elle est stockée en base (`family`, ou le texte libre saisi
  /// par l'utilisateur). C'est elle qu'on supprime.
  final String cleCategorie;

  /// Libellé affiché, traduit si c'est une catégorie par défaut.
  final String label;

  final bool isSelected;
  final bool isDarkMode;
  final ValueChanged<bool> onSelectionChanged;

  /// Appelé après une suppression effective, pour que l'écran retire la clé
  /// de sa propre sélection en cours.
  final VoidCallback onSuppression;

  const CategorieGlissable({
    required this.cleCategorie,
    required this.label,
    required this.isSelected,
    required this.isDarkMode,
    required this.onSelectionChanged,
    required this.onSuppression,
    super.key,
  });

  @override
  State<CategorieGlissable> createState() => _CategorieGlissableState();
}

class _CategorieGlissableState extends State<CategorieGlissable> {
  /// `true` dès que le glissement a dépassé [_seuilArmement].
  ///
  /// On ne mémorise pas la progression continue, seulement ce booléen : il ne
  /// change que deux fois par geste, ce qui évite de reconstruire la ligne à
  /// chaque frame du glissement.
  bool _armee = false;

  void _suivreGlissement(DismissUpdateDetails details) {
    final bool armee = details.progress >= _seuilArmement;
    if (armee == _armee) return;

    // Petit choc au passage du seuil : le doigt sait que l'action est armée
    // sans que l'œil ait à quitter la liste.
    HapticFeedback.selectionClick();
    setState(() => _armee = armee);
  }

  /// Demande confirmation, supprime, et retourne TOUJOURS `false`.
  ///
  /// Ce `false` est délibéré. Un `Dismissible` qui retourne `true` retire
  /// lui-même la ligne, et Flutter lève une assertion si le widget est encore
  /// dans l'arbre à la frame suivante. Or ici la liste ne nous appartient pas :
  /// elle vient d'un `StreamBuilder` branché sur la base, qui se rafraîchira
  /// quelques millisecondes plus tard. On laisse donc la ligne revenir en
  /// place, et c'est le flux qui la fait disparaître — pas d'assertion, pas de
  /// désynchronisation possible entre l'affichage et la base.
  Future<bool> _confirmerEtSupprimer(BuildContext context) async {
    final AppLocalizations mots = AppLocalizations.of(context)!;
    final DatabaseService service = DatabaseService();
    final bool sombre = widget.isDarkMode;

    final int usages =
        await service.compterSouvenirsAvecCategorie(widget.cleCategorie);
    if (!context.mounted) return false;

    // Une catégorie que personne n'utilise part sans poser de question :
    // demander confirmation pour une action sans conséquence n'apprend rien à
    // l'utilisateur et lui coûte un geste.
    bool confirme = usages == 0;

    if (!confirme) {
      confirme = await showDialog<bool>(
            context: context,
            builder: (contexteModale) => AlertDialog(
              backgroundColor: sombre ? darkSurface : white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                mots.deleteCategoryConfirmTitle(widget.label),
                style: styleTitreAction.copyWith(color: texteFort(sombre)),
              ),
              content: Text(
                mots.deleteCategoryConfirmBody(usages),
                style: styleSecondaire.copyWith(color: texteDoux(sombre)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(contexteModale).pop(false),
                  child: Text(
                    MaterialLocalizations.of(contexteModale).cancelButtonLabel,
                    style: styleCorps.copyWith(color: texteDoux(sombre)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(contexteModale).pop(true),
                  child: Text(
                    mots.btnDeleteConfirm,
                    style: styleCorps.copyWith(
                      color: red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (confirme) {
      HapticFeedback.mediumImpact();
      service.deleteCategory(widget.cleCategorie);
      widget.onSuppression();
    }
    if (mounted) setState(() => _armee = false);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Deux états, deux couleurs. Sous le seuil, le gris dit « il se passe
    // quelque chose » sans annoncer de dégât ; au-delà, le rouge dit « si tu
    // lâches maintenant, ça part ». C'est cette bascule qui rend le geste
    // réversible en connaissance de cause : tant qu'on est dans le gris, on
    // peut remettre la ligne en place sans conséquence.
    final Color couleurIcone = _armee ? red : grey;
    final Color couleurFond =
        (_armee ? red : grey).withValues(alpha: _armee ? 0.14 : 0.12);

    return Dismissible(
      key: ValueKey<String>(widget.cleCategorie),
      // Uniquement de la droite vers la gauche : le glissement inverse est
      // réservé au retour arrière par le système sur iOS.
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: _seuilArmement},
      onUpdate: _suivreGlissement,
      confirmDismiss: (_) => _confirmerEtSupprimer(context),
      background: const SizedBox.shrink(),
      // Ce qui se découvre sous la ligne pendant le glissement.
      secondaryBackground: DecoratedBox(
        decoration: BoxDecoration(color: couleurFond),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_outline, color: couleurIcone),
          ),
        ),
      ),
      child: ItemCategorie(
        label: widget.label,
        isSelected: widget.isSelected,
        color: orange,
        isDarkMode: widget.isDarkMode,
        onSelectionChanged: widget.onSelectionChanged,
      ),
    );
  }
}

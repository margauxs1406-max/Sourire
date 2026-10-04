import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/checkbox_sourire.dart';

/// Une ligne de catégorie cochable, pour les trois écrans de catégorisation.
///
/// ⚠️ AUCUNE LARGEUR DE CETTE LIGNE NE DOIT ÊTRE CALCULÉE SUR
/// `MediaQuery.size.width`.
///
/// La ligne vit dans une colonne bornée à [largeurContenuMax] et centrée (voir
/// `ContenuCentre`), bien plus étroite que la dalle d'une tablette. Le libellé
/// réservait auparavant 69 % de la largeur de l'ÉCRAN : sur un iPad de 834
/// points, cela faisait 575 points réclamés dans une colonne qui n'en fait que
/// 560. La `Row` débordait, et la case à cocher se retrouvait posée APRÈS le
/// bord du cadre — donc découpée à l'affichage, et surtout hors d'atteinte du
/// doigt, puisque Flutter ne teste pas les touchers en dehors d'une zone
/// découpée. Aucune catégorie n'était plus sélectionnable sur iPad, ce qui a
/// valu à Sourire un refus App Store au titre de la directive 2.1(a).
///
/// La bonne forme est celle-ci : le libellé prend la place qui reste
/// (`Expanded`), la case garde la sienne. C'est juste à toutes les largeurs,
/// de la fenêtre Slide Over de 320 points à l'iPad en paysage, et il n'y a
/// plus de proportion à tenir à jour.
class ItemCategorie extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final Color color;
  final bool isDarkMode;

  const ItemCategorie({
    required this.label,
    required this.isSelected,
    required this.onSelectionChanged,
    this.color = orange,
    this.isDarkMode = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // La TAILLE DU TEXTE, elle, reste indexée sur l'écran et bornée : c'est
    // une question de lisibilité à bout de bras, pas de place disponible, et
    // le plafond de 22 points l'empêche de grossir sans fin sur tablette.
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double adaptiveFontSize = (screenWidth * 0.045).clamp(14.0, 22.0);

    return GestureDetector(
      // Toute la ligne coche la catégorie, et non la seule case.
      //
      // D'abord parce qu'une cible de 42 points au bout d'une ligne de 500 est
      // une cible manquée pour qui a de gros doigts ou la main qui tremble —
      // et Sourire s'adresse aussi à ces mains-là. Ensuite parce que c'est un
      // filet : le jour où la case se retrouverait mal placée, la catégorie
      // resterait sélectionnable depuis son libellé.
      //
      // `opaque` pour que les touchers passent aussi dans les blancs de la
      // ligne. La case garde son propre détecteur : c'est lui qui gagne quand
      // le doigt tombe dessus, Flutter donnant la main au plus intérieur des
      // deux. Un seul appel part donc dans tous les cas.
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelectionChanged(!isSelected),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? darkBg : white,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? darkSeparateur : lightGrey,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: styleCategorie.copyWith(
                  fontSize: adaptiveFontSize,
                  // Même graisse que « Nouvelle catégorie » au repos ; la
                  // sélection se marque par le demi-gras ET la couleur.
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? color
                      : (isDarkMode ? Colors.white70 : grey),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Un blanc minimum entre le libellé le plus long et la case :
            // l'ellipse ne doit jamais venir toucher le carré.
            const SizedBox(width: 16),

            CheckboxSourire(
              initialValue: isSelected,
              onChanged: onSelectionChanged,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

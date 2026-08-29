import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

class BoutonActionCategorie extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool hasCircle;
  final bool isDarkMode;
  final bool useThemeStyleForText;

  /// Trace un filet sous la ligne, identique à celui des catégories.
  ///
  /// Sert à faire lire « Nouvelle catégorie » comme la DERNIÈRE ligne de la
  /// liste plutôt que comme un bouton posé en dessous.
  final bool separateur;

  /// Place l'icône APRÈS le texte plutôt qu'avant.
  ///
  /// Une icône en tête annonce ce qu'on va faire (« + Nouvelle catégorie ») ;
  /// une icône en fin annonce où l'on va (« Catégoriser 1 par 1 › »). Les deux
  /// cohabitent dans la même liste, d'où ce réglage plutôt qu'un second widget.
  final bool iconeEnFin;

  final VoidCallback onTap;

  const BoutonActionCategorie({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.hasCircle,
    required this.isDarkMode,
    required this.useThemeStyleForText,
    this.separateur = false,
    this.iconeEnFin = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final double adaptiveFontSize = (screenWidth * 0.045).clamp(14.0, 22.0);

    // Récupération sécurisée du style textuel par défaut ou global
    final TextStyle baseStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, 
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              // Même filet que celui d'ItemCategorie, à la couleur près du
              // mode sombre : la ligne doit appartenir à la liste, pas s'en
              // détacher.
              color: separateur
                  ? (isDarkMode ? darkSeparateur : lightGrey)
                  : Colors.transparent,
              width: separateur ? 1.0 : 0.0,
            ),
          ),
        ),
        child: Builder(
          builder: (context) {
            final Widget pastilleIcone = Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasCircle ? color : Colors.transparent,
                border: hasCircle 
                    ? null 
                    : Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: hasCircle ? Colors.white : color,
                  size: 16,
                ),
              ),
            );

            final Widget texte = Text(
              label,
              style: useThemeStyleForText
                  ? TextStyle(
                      fontFamily: baseStyle.fontFamily,
                      // Même taille que les noms de catégories : cette ligne
                      // est une entrée de la liste, pas une note de bas de page.
                      fontSize: adaptiveFontSize,
                      fontWeight: FontWeight.normal, 
                      color: color, 
                    )
                  : baseStyle.copyWith(
                      fontSize: adaptiveFontSize, // Nouvelle catégorie : taille adaptative
                      color: isDarkMode ? Colors.white70 : Colors.grey[700], 
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );

            // Icône en fin : elle se colle au TEXTE et non au bord droit de
            // l'écran. Le texte garde le même bord gauche que les noms de
            // catégories — c'est lui qui porte l'alignement de la liste — mais
            // le « + » et le « › » restent lus comme faisant partie du
            // libellé, pas comme une colonne de contrôles à part.
            //
            // D'où `MainAxisSize.min` : la rangée se rétracte sur son contenu.
            // Le `Flexible` sert de garde-fou aux libellés très longs ou aux
            // très grandes polices système — le texte se tronque alors plutôt
            // que de pousser l'icône hors de l'écran.
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: iconeEnFin ? MainAxisSize.min : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: iconeEnFin
                  ? [
                      Flexible(child: texte),
                      const SizedBox(width: 10),
                      pastilleIcone,
                    ]
                  : [
                      pastilleIcone,
                      const SizedBox(width: 15),
                      Expanded(child: texte),
                    ],
            );
          },
        ),
      ),
    );
  }
}
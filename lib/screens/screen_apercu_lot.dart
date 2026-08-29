import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/main.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/widgets/logo_sourire.dart';

/// Carrousel des souvenirs d'un lot en cours de catégorisation.
///
/// Le bandeau de l'écran de catégorisation ne montre que la PREMIÈRE vignette,
/// avec une pastille « +9 ». Cela suffit à dire combien de souvenirs le choix
/// va ranger, mais pas à vérifier QUE ce sont bien les bons — or c'est
/// exactement la question qu'on se pose avant d'appliquer une catégorie à dix
/// photos d'un coup. Cet écran répond à cette question, et à elle seule.
///
/// Volontairement inerte : ni zoom, ni défilement à l'intérieur d'un souvenir.
/// On feuillette, on vérifie, on ressort. Toute autre interaction serait une
/// promesse que cet écran ne tient pas.
///
/// Retourne `true` si l'utilisateur a choisi de catégoriser un par un.
class ScreenApercuLot extends StatefulWidget {
  /// Nombre de souvenirs du lot.
  final int nombre;

  /// Construit l'aperçu en grand du souvenir d'indice donné. Il reçoit une
  /// zone carrée, aussi large que l'écran moins ses marges.
  final IndexedWidgetBuilder constructeurApercu;

  const ScreenApercuLot({
    required this.nombre,
    required this.constructeurApercu,
    super.key,
  });

  @override
  State<ScreenApercuLot> createState() => _ScreenApercuLotState();
}

class _ScreenApercuLotState extends State<ScreenApercuLot> {
  final PageController _controleur = PageController();
  int _indexCourant = 0;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations mots = AppLocalizations.of(context)!;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, mode, _) {
        final bool sombre = mode == ThemeMode.system
            ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
            : mode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: sombre ? darkBg : white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // BANDEAU DU HAUT, identique aux écrans de catégorisation.
                  SizedBox(
                    height: 60,
                    // LARGEUR EXPLICITE, et c'est tout le problème.
                    //
                    // Sans elle, la Column ne donne qu'une contrainte de
                    // largeur LÂCHE, et un Stack se dimensionne alors sur son
                    // plus grand enfant NON positionné — ici le seul logo. Le
                    // bandeau se réduisait donc à la largeur du logo, et le
                    // `Positioned(left: 0)` collait le chevron contre lui au
                    // lieu de le poser au bord de l'écran : invisible, caché
                    // derrière le logo.
                    //
                    // Les écrans de catégorisation n'avaient pas ce défaut :
                    // leur bandeau est un `Positioned(left: 0, right: 0)`, donc
                    // déjà contraint en largeur.
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 0,
                            child: BtnChevronGauche(
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                          const LogoSourire(color: orange),
                        ],
                      ),
                    ),
                  ),

                  // LE CARROUSEL, et son compteur juste dessous.
                  //
                  // Les deux forment un bloc : le compteur légende le
                  // carrousel, il ne flotte pas au milieu de l'écran. Ils sont
                  // donc groupés et centrés ensemble dans l'espace libre.
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: PageView.builder(
                                controller: _controleur,
                                itemCount: widget.nombre,
                                onPageChanged: (index) =>
                                    setState(() => _indexCourant = index),
                                // 4 px de chaque côté : deux voisines se
                                // retrouvent donc séparées de 8 px pendant le
                                // glissement, au lieu de se toucher.
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: widget.constructeurApercu(context, index),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Un compteur plutôt que des points : au-delà de cinq
                          // ou six souvenirs, une rangée de points ne se compte
                          // plus, alors qu'un « 3 / 10 » reste lisible quel que
                          // soit le lot.
                          Text(
                            '${_indexCourant + 1} / ${widget.nombre}',
                            style: styleMention.copyWith(color: texteDoux(sombre)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SORTIE VERS LA CATÉGORISATION UNE PAR UNE.
                  //
                  // Bouton secondaire — fond blanc, encre et contour orange :
                  // c'est un chemin de traverse, pas l'action principale de
                  // l'écran, qui reste de vérifier le lot puis de ressortir.
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: sombre ? darkSurface : white,
                        side: const BorderSide(color: orange, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radiusDefault),
                        ),
                      ),
                      child: Text(
                        mots.batchCategorizeOneByOne,
                        style: styleCorps.copyWith(
                          color: orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

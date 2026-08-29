import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/main.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/widgets/btn_action.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/souvenir_historique.dart';

/// Choix du décor d'une note, à l'instant où on l'écrit.
///
/// L'ancien chemin passait par Profil > Personnalisation : trois écrans à
/// remonter pour changer d'ambiance, et la note en cours perdue en route. Ici
/// on voit le texte réel, sur le vrai fond, et on change d'avis autant qu'on
/// veut avant d'appliquer.
///
/// Retourne le thème retenu, ou `null` si l'utilisateur ressort sans rien
/// changer.
class ScreenChoixThemeNote extends StatefulWidget {
  /// Le souvenir tel qu'il est en train d'être écrit — texte et couleur
  /// compris. Il n'existe pas encore en base : on ne s'en sert que pour
  /// peindre l'aperçu.
  final NoteSourire apercu;

  /// Couleur tirée au sort pour cette note. Elle habille aussi les pastilles
  /// du carrousel, pour qu'on voie chaque thème DANS sa couleur.
  final SourireTheme couleur;

  /// Thème appliqué en arrivant.
  final ThemeApp themeInitial;

  const ScreenChoixThemeNote({
    required this.apercu,
    required this.couleur,
    required this.themeInitial,
    super.key,
  });

  @override
  State<ScreenChoixThemeNote> createState() => _ScreenChoixThemeNoteState();
}

/// Hauteur du carrousel de pastilles : le cercle, son libellé, et la marge
/// que le cadenas déborde en bas.
const double _hauteurCarrousel = 96;

/// Écart entre l'aperçu et le carrousel.
const double _ecartApercuCarrousel = 16;

class _ScreenChoixThemeNoteState extends State<ScreenChoixThemeNote> {
  late ThemeApp _themeCourant;

  @override
  void initState() {
    super.initState();
    _themeCourant = widget.themeInitial;
  }

  bool get _estPremium => UserPrefs.isPremium;

  /// Un thème verrouillé ne s'applique pas : il ouvre l'offre premium.
  ///
  /// C'est le moment le plus favorable pour la présenter — la personne est en
  /// train d'écrire, elle vient de voir ce que le thème donnerait, et l'offre
  /// répond à une envie qu'elle a formulée d'elle-même une seconde plus tôt.
  void _choisir(ThemeApp theme) {
    if (theme.isPremium && !_estPremium) {
      Navigator.pop(context, _AppelPremium.instance);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _themeCourant = theme);
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

                  // L'APERÇU, ET LE CARROUSEL ACCROCHÉ DESSOUS.
                  //
                  // Les deux forment un bloc, centré verticalement dans
                  // l'espace libre : les pastilles se lisent comme la suite de
                  // l'aperçu — voilà les décors, en voici un appliqué — alors
                  // qu'en bas de l'écran elles ressemblaient à une barre
                  // d'outils sans rapport avec ce qu'on regarde.
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Flexible SANS Center : `Center` s'étire jusqu'à la
                        // hauteur qu'on lui autorise, et le carrousel se
                        // retrouverait repoussé en bas. Nu, l'AspectRatio
                        // prend sa taille naturelle — un carré de la largeur
                        // disponible, ou moins si l'écran est court.
                        Flexible(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: WidgetSouvenirHistorique(
                              // La clé force la reconstruction à chaque
                              // changement : sans elle, Flutter réutiliserait
                              // l'état du widget précédent et les icônes ne
                              // bougeraient pas.
                              key: ValueKey<String>(_themeCourant.id),
                              souvenir: widget.apercu.copyWith(
                                themeLabel: _themeCourant.id,
                              ),
                              // Plein écran : la note suit le mode d'affichage,
                              // et prend donc en sombre le fond exact des
                              // pastilles du carrousel juste dessous.
                              suitLeModeSombre: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: _ecartApercuCarrousel),

                        // LE CARROUSEL DES THÈMES.
                        SizedBox(
                          height: _hauteurCarrousel,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: ThemeRepository.tousLesThemes.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final ThemeApp theme =
                                  ThemeRepository.tousLesThemes[index];
                              return _PastilleTheme(
                                theme: theme,
                                couleur: widget.couleur,
                                actif: theme.id == _themeCourant.id,
                                verrouille: theme.isPremium && !_estPremium,
                                sombre: sombre,
                                onTap: () => _choisir(theme),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      // RÉTABLIR : revient au thème d'arrivée sans quitter
                      // l'écran. On peut donc explorer sans rien risquer.
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () => setState(
                                () => _themeCourant = widget.themeInitial),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: sombre ? darkSurface : white,
                              side: const BorderSide(color: orange, width: 1.5),
                              // 30, comme BtnAction : les deux boutons sont
                              // côte à côte, un rayon différent se verrait.
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              mots.btnReset,
                              style: styleCorps.copyWith(
                                color: orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: BtnAction(
                            text: mots.btnApply,
                            isActive: true,
                            color: orange,
                            onTap: () => Navigator.pop(context, _themeCourant),
                          ),
                        ),
                      ),
                    ],
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

/// Sentinelle renvoyée quand l'utilisateur touche un thème verrouillé.
///
/// Une classe plutôt qu'une chaîne : l'écran appelant sait ainsi distinguer
/// « applique ce thème » (un `ThemeApp`) de « montre-moi l'offre » sans
/// convention fragile sur une valeur de texte.
class _AppelPremium {
  const _AppelPremium._();
  static const _AppelPremium instance = _AppelPremium._();
}

/// `true` si le résultat du choix de thème est une demande d'offre premium.
bool estAppelPremium(Object? resultat) => resultat is _AppelPremium;

/// Pastille ronde représentant un thème dans le carrousel.
///
/// Fond, icône et contour reprennent les couleurs de la note en cours : on ne
/// voit pas « le thème floral » dans l'absolu, on voit ce qu'il donnera SUR
/// cette note-là.
class _PastilleTheme extends StatelessWidget {
  final ThemeApp theme;
  final SourireTheme couleur;
  final bool actif;
  final bool verrouille;
  final bool sombre;
  final VoidCallback onTap;

  const _PastilleTheme({
    required this.theme,
    required this.couleur,
    required this.actif,
    required this.verrouille,
    required this.sombre,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String? icone = theme.iconePhare;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Le pastel du souvenir en clair, sa version sombre la nuit :
                  // douze pastilles presque blanches alignées sous un écran
                  // noir formaient une guirlande éblouissante.
                  color: couleur.fond(sombre),
                  border: Border.all(
                    color: couleur.encre(sombre),
                    // Le thème actif se marque par un contour plus épais, pas
                    // par une couleur différente : la couleur, ici, appartient
                    // à la note et ne doit rien signifier d'autre.
                    width: actif ? 3 : 1,
                  ),
                ),
                child: icone == null
                    // Le thème classique n'a pas d'icône : un cercle vide dit
                    // exactement ce qu'il est — une note sans décor.
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.all(13),
                        child: Opacity(
                          opacity: verrouille ? 0.35 : 1,
                          child: SvgPicture.asset(
                            icone,
                            colorFilter: ColorFilter.mode(
                                couleur.encre(sombre), BlendMode.srcIn),
                          ),
                        ),
                      ),
              ),
              if (verrouille)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: orange,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.lock_outline, color: white, size: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 68,
            child: Text(
              theme.label(context),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: styleMention.copyWith(
                color: actif ? couleur.encre(sombre) : texteDoux(sombre),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

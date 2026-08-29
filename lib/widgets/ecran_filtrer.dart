import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/models/periode_filtre.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/theme/tokens.dart';

/// Panneau de filtrage de l'historique — période et catégories.
///
/// Un menu déroulant, pas un écran : il se déplie sous le mot « Filtrer », ne
/// prend que la largeur qu'il lui faut, et ne touche à rien de ce qui est
/// dessous. Pas de voile, pas de feuille modale — on continue de voir la
/// liste, et c'est le but : les filtres s'appliquent AU FUR ET À MESURE, donc
/// on voit l'historique se resserrer pendant qu'on coche.
///
/// D'où l'absence de bouton « Filtrer » à valider : il n'y a plus rien à
/// valider. Seul « Rétablir » subsiste, et seulement quand il y a quelque
/// chose à lever.
///
/// Sans état propre : la vérité est chez l'historique, le panneau se contente
/// de la peindre et de renvoyer ce qu'on touche.
class EcranFiltrer extends StatelessWidget {
  /// Catégories actuellement cochées.
  final List<String> categories;

  /// Période active, ou `null` si l'historique n'est pas borné.
  final PeriodeFiltre? periode;

  /// Années pour lesquelles il existe au moins un souvenir, sans ordre imposé.
  ///
  /// Proposer 2020-2030 en dur afficherait des années vides qui ne filtrent
  /// rien : la liste vient donc du bocal lui-même.
  final List<int> anneesDisponibles;

  /// Remonte les deux filtres à chaque changement.
  final void Function(List<String> categories, PeriodeFiltre? periode) onChange;

  final bool sombre;

  const EcranFiltrer({
    required this.categories,
    required this.anneesDisponibles,
    required this.onChange,
    required this.sombre,
    this.periode,
    super.key,
  });

  /// Largeur du panneau. Assez pour le nom de catégorie le plus long et trois
  /// puces de mois par ligne, pas plus : un menu qui barre tout l'écran n'est
  /// plus un menu.
  static const double largeur = 250;

  /// Années proposées, de la plus récente à la plus ancienne.
  ///
  /// L'année filtrée y figure même si plus aucun souvenir ne s'y trouve —
  /// sinon un filtre actif disparaîtrait de la liste après la suppression du
  /// dernier souvenir de l'année, sans moyen de le décocher.
  List<int> get _annees {
    final Set<int> annees = <int>{...anneesDisponibles};
    if (periode != null) annees.add(periode!.annee);
    if (annees.isEmpty) annees.add(DateTime.now().year);
    return (annees.toList()..sort()).reversed.toList();
  }

  /// Coche ou décoche une année. Retoucher l'année active la retire, et le
  /// mois part avec elle : un mois sans année ne désigne rien.
  void _choisirAnnee(int annee) => onChange(
        categories,
        periode?.annee == annee ? null : PeriodeFiltre(annee: annee),
      );

  /// Resserre la période sur un mois, ou la rouvre à l'année entière si on
  /// retouche le mois déjà coché.
  void _choisirMois(int mois) {
    final PeriodeFiltre? active = periode;
    if (active == null) return;
    onChange(categories, active.avecMois(active.mois == mois ? null : mois));
  }

  void _basculerCategorie(String cle) {
    final List<String> suite = List<String>.from(categories);
    if (!suite.remove(cle)) suite.add(cle);
    onChange(suite, periode);
  }

  static final DatabaseService _bdd = DatabaseService();

  /// Ombre portée du panneau, plus décalée vers la droite que [shadowDrop].
  ///
  /// Le panneau est collé au bord gauche de l'écran : une ombre symétrique n'a
  /// rien à porter de ce côté-là et ne se voit que d'un seul. En la poussant
  /// vers la droite, elle tombe entièrement sur la liste, et le relief se lit.
  static const List<BoxShadow> _ombre = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(8, 4)),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations mots = AppLocalizations.of(context)!;
    final bool quelqueChoseDeFiltre = categories.isNotEmpty || periode != null;

    return Container(
      width: largeur,
      // Moitié de l'écran au plus, et le panneau défile au-delà : avec vingt
      // catégories il descendrait sinon jusqu'au bas de l'historique.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height / 2,
      ),
      decoration: BoxDecoration(
        color: sombre ? darkSurface : white,
        // Angles supérieurs DROITS : le panneau sort de la barre « Filtrer »,
        // il lui est solidaire par le haut. Des coins arrondis là-haut le
        // détacheraient en carte flottante, alors qu'il se déroule.
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(radiusDefault),
          bottomRight: Radius.circular(radiusDefault),
        ),
        // La SEULE chose qui détache le panneau de la page. Pas de voile, pas
        // de bordure : une ombre portée, comme un carton posé sur la liste.
        boxShadow: _ombre,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: _Section(mots.filterByPeriod, sombre: sombre)),
                if (quelqueChoseDeFiltre)
                  GestureDetector(
                    onTap: () => onChange(const <String>[], null),
                    child: Text(
                      mots.btnReset,
                      style: styleSecondaire.copyWith(
                        color: orange,
                        decoration: TextDecoration.underline,
                        decorationColor: orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final int annee in _annees)
                  _Puce(
                    libelle: '$annee',
                    active: annee == periode?.annee,
                    sombre: sombre,
                    onTap: () => _choisirAnnee(annee),
                  ),
              ],
            ),

            // La grille des mois n'apparaît qu'une fois l'année choisie : un
            // mois seul ne désigne aucune période, et douze puces inertes en
            // tête de panneau ne feraient qu'encombrer.
            if (periode != null) ...<Widget>[
              const SizedBox(height: 6),
              _GrilleMois(
                moisActif: periode!.mois,
                sombre: sombre,
                onChoisir: _choisirMois,
              ),
            ],

            const SizedBox(height: 18),
            _Section(mots.filterByCategory, sombre: sombre),
            const SizedBox(height: 4),

            // Le flux des catégories plutôt qu'une liste figée : elles se
            // créent et se suppriment depuis les écrans de catégorisation,
            // pendant que ce panneau peut être ouvert.
            StreamBuilder<List<String>>(
              // `DatabaseService` est un singleton et son contrôleur est
              // diffusé : le flux rendu est le même objet à chaque
              // reconstruction, donc `StreamBuilder` ne se réabonne pas.
              stream: _bdd.getCategoriesStream(),
              builder: (context, instantane) {
                final List<String> cles = List<String>.from(
                  instantane.data ?? _bdd.getAllCategories(),
                );
                if (!cles.contains('unclassified')) cles.add('unclassified');

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final String cle in cles)
                      _LigneCategorie(
                        libelle: _libelleCategorie(mots, cle),
                        cochee: categories.contains(cle),
                        sombre: sombre,
                        onTap: () => _basculerCategorie(cle),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Les catégories par défaut sont stockées sous une clé stable et traduites
  /// à l'affichage ; celles créées par l'utilisateur sont déjà du texte.
  static String _libelleCategorie(AppLocalizations mots, String cle) {
    switch (cle) {
      case 'self_love':
        return mots.catSelfLove;
      case 'friendship':
        return mots.catFriendship;
      case 'couple':
        return mots.catCouple;
      case 'family':
        return mots.catFamily;
      case 'leisure':
        return mots.catLeisure;
      case 'work':
        return mots.catWork;
      case 'others':
        return mots.catOthers;
      case 'unclassified':
        return mots.catUnclassified;
      default:
        return cle;
    }
  }
}

/// Titre de section — 14 demi-gras, exactement le style des noms de thèmes
/// dans l'écran de choix des thèmes.
///
/// Plus petit que les lignes qu'il coiffe, et c'est voulu : « Par période » et
/// « Par catégorie » ne sont pas des titres qu'on lit, ce sont des étiquettes
/// qui disent à quoi sert le bloc en dessous. Les faire plus gros que les
/// choix eux-mêmes inverserait la hiérarchie.
class _Section extends StatelessWidget {
  final String texte;
  final bool sombre;

  const _Section(this.texte, {required this.sombre});

  @override
  Widget build(BuildContext context) => Text(
        texte,
        style: styleCorps.copyWith(
          fontSize: tailleAdaptee(context, 14),
          fontWeight: FontWeight.w600,
          color: texteTitre(sombre),
        ),
      );
}

/// Une catégorie cochable.
///
/// Remplace `ItemCategorie`, dessiné pour les écrans de catégorisation en
/// pleine page : cases de 24 px, interlignes larges, séparateurs. Dans un menu
/// de 250 px de large, c'est une ligne de liste, rien de plus.
class _LigneCategorie extends StatelessWidget {
  final String libelle;
  final bool cochee;
  final bool sombre;
  final VoidCallback onTap;

  const _LigneCategorie({
    required this.libelle,
    required this.cochee,
    required this.sombre,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            // Même case que `CheckboxSourire`, en plus petit : contour orange
            // en permanence, fond blanc au repos, fond orange et coche blanche
            // une fois cochée. On la reconstruit ici plutôt que de réutiliser
            // le composant, dont la taille est calculée sur la largeur de
            // l'écran — 26 à 42 px, hors d'échelle dans un menu de 250.
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: cochee ? orange : (sombre ? darkSurface : white),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: orange, width: 2),
              ),
              child: cochee
                  ? const Icon(Icons.check_rounded, color: white, size: 14)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                libelle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // 16 / w500 : la ligne de réglage du profil.
                //
                // En encre douce et non en orange : c'est la CASE qui porte
                // l'action et qui s'allume, le nom de la catégorie n'est que
                // ce sur quoi elle porte. Douze libellés orange alignés
                // faisaient une liste de liens là où il n'y a qu'une liste.
                // Le demi-gras marque la sélection, comme dans les écrans de
                // catégorisation.
                style: styleCorps.copyWith(
                  color: texteDoux(sombre),
                  fontWeight: cochee ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les douze mois, en trois colonnes de quatre.
///
/// Trois et non quatre : le panneau ne fait que 250 px, et les abréviations
/// changent de longueur d'une langue à l'autre — « janv. » en français,
/// « ene. » en espagnol.
class _GrilleMois extends StatelessWidget {
  final int? moisActif;
  final bool sombre;
  final void Function(int mois) onChoisir;

  const _GrilleMois({
    required this.moisActif,
    required this.sombre,
    required this.onChoisir,
  });

  @override
  Widget build(BuildContext context) {
    const int colonnes = 3;
    const double ecart = 6;

    return LayoutBuilder(
      builder: (context, contraintes) {
        final double largeurPuce =
            (contraintes.maxWidth - ecart * (colonnes - 1)) / colonnes;

        return Wrap(
          spacing: ecart,
          runSpacing: ecart,
          children: <Widget>[
            for (int mois = 1; mois <= 12; mois++)
              SizedBox(
                width: largeurPuce,
                child: _Puce(
                  libelle: PeriodeFiltre.nomCourtDuMois(context, mois),
                  active: mois == moisActif,
                  sombre: sombre,
                  centre: true,
                  onTap: () => onChoisir(mois),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Pilule qui se remplit quand elle est active.
///
/// Au repos : contour et texte orange sur fond blanc — c'est cliquable, et
/// dans cette application l'orange ne dit rien d'autre. Un contour gris la
/// faisait passer pour une étiquette à lire.
///
/// Active : orange plein, texte blanc. Même bascule que la case à cocher juste
/// en dessous, donc la même chose se lit de la même façon.
class _Puce extends StatelessWidget {
  final String libelle;
  final bool active;
  final bool sombre;

  /// Centre le libellé, pour les puces de largeur imposée.
  final bool centre;

  final VoidCallback onTap;

  const _Puce({
    required this.libelle,
    required this.active,
    required this.sombre,
    required this.onTap,
    this.centre = false,
  });

  @override
  Widget build(BuildContext context) {
    const BorderRadius arrondi = BorderRadius.all(Radius.circular(999));

    return Material(
      color: active ? orange : (sombre ? darkSurface : white),
      borderRadius: arrondi,
      child: InkWell(
        borderRadius: arrondi,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          alignment: centre ? Alignment.center : null,
          decoration: BoxDecoration(
            borderRadius: arrondi,
            border: Border.all(color: orange),
          ),
          child: Text(
            libelle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: centre ? TextAlign.center : TextAlign.start,
            // 13 / w600 : la mention discrète du profil.
            style: styleMention.copyWith(color: active ? white : orange),
          ),
        ),
      ),
    );
  }
}

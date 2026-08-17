# Sourire — inventaire typographique

Relevé exhaustif au 14 août 2026, version 1.0.0+12. **161 déclarations de style**
de texte réparties dans 32 fichiers.

---

## 1. Le constat qui commande tout le reste

### Trois polices sont déclarées dans `pubspec.yaml`… en réalité deux

```yaml
fonts:
  - family: Lora        → assets/fonts/Lora-VariableFont_wght.ttf
  - family: Spicy Rice  → assets/fonts/SpicyRice-Regular.ttf
```

`assets/fonts/` contient pourtant **InclusiveSans-VariableFont_wght.ttf** et
**InclusiveSans-Italic-VariableFont_wght.ttf**, jamais déclarés. Or
`styleBouton` et `styleCategorie` demandent `fontFamily: 'Inclusive Sans'` :
Flutter ne trouve pas la famille et retombe **silencieusement** sur la police
système. Aucun avertissement, aucune erreur — d'où l'impression que ça marche.

Conséquence : ces deux styles s'affichent aujourd'hui en **Roboto sur Android
et SF Pro sur iOS**. Deux rendus différents selon le téléphone.

Les quatre fichiers `LobsterTwo-*.ttf` sont eux devenus des fichiers morts
depuis le passage à Lora.

### `ThemeData` ne fixe aucune `fontFamily`

Ni le thème clair ni le thème sombre (`main.dart`, l. 278 et 284) ne
définissent de police par défaut. **Environ 130 des 161 styles n'indiquent
aucune famille** : ils héritent donc du défaut Flutter, c'est-à-dire de la
police du système.

### Donc, en pratique, l'app tourne aujourd'hui sur

| Police | Où | Nombre de styles |
|---|---|---|
| **Police système** (Roboto / SF Pro) | partout ailleurs : réglages, popups, boutons, catégories, champs | ~130 |
| **Lora** | titres d'écran, texte des souvenirs | 15 |
| **Spicy Rice** | logo « Sourire » uniquement | 2 |
| ~~Inclusive Sans~~ | *demandée, jamais chargée* | 2 |

---

## 2. Les styles nommés (`tokens.dart`)

| Style | Famille | Taille | Graisse | Couleur | Usage réel |
|---|---|---|---|---|---|
| `styleLogo` | Spicy Rice | 36 | regular | `white` | logo Sourire (`logo_sourire.dart`), signature du polaroid partagé (forcée à 60 pt / orange) |
| `styleTitreLora` | Lora | héritée | **w600** + `wght` 600 | héritée | titres d'écran : home, catégorisation ×3, onboarding ×5, reset mot de passe, filtre |
| `styleNoteLarge` | Lora | 31 | regular | héritée | texte des souvenirs : saisie, historique, tirage, image partagée |
| `styleNoteSmall` | Lora | 7 | regular | héritée | **inutilisé** — aucune occurrence dans `lib/` |
| `styleBouton` | ~~Inclusive Sans~~ | 16 | w500 | héritée | un seul appel : `btn_filtrer.dart` |
| `styleCategorie` | ~~Inclusive Sans~~ | 20 | w500 | `grey` | un seul appel : `item_categorie.dart` |

`tailleLora(x) = x × 0,85` compense l'œil plus large de Lora par rapport à
l'ancienne Lobster Two. Appliqué à **tous** les appels Lora.

---

## 3. Toutes les tailles en circulation

### Tailles fixes (valeur en dur)

| Taille | Graisse | Occurrences | Rôle observé |
|---|---|---|---|
| 20 | bold | 2 | titre de section (« Catégories » dans le filtre) |
| 18 | bold | 9 | **titre de modale / de section** — le style le plus répandu |
| 16 | bold | 4 | libellé de CTA |
| 16 | w600 | 3 | titre de ligne de réglage |
| 16 | w500 | 8 | libellé de champ, de ligne de réglage |
| 16 | regular | 4 | valeur d'un champ |
| 15 | bold | 4 | texte du bouton d'une popup |
| 15 | regular | 4 | valeur en lecture seule |
| 14 | bold | 4 | message d'erreur (rouge), puce cochée |
| 14 | w600 | 3 | libellé de filtre actif |
| 14 | regular | 13 | **texte secondaire / description** — le plus répandu des textes courants |
| 13 | w600 | 3 | badge, mention discrète |
| 13 | regular | 3 | sous-titre d'une ligne de réglage |
| 12 | w600 | 1 | mention de test |

### Tailles calculées

| Formule | Bornes | Où |
|---|---|---|
| `largeur × 0,075` | 24 – 40 | message de bienvenue de l'onboarding |
| `largeur × 0,064` | 18 – 30 | titres de l'onboarding et du reset mot de passe |
| `largeur < 360 ? 18 : 22` | — | titre « Quelle catégorie ? » ×3 |
| `largeur × 0,05` / `× 0,07` | — | « Bonjour » / « Qu'est-ce qui te rend heureux » |
| `largeur × 0,045` | 14 – 22 | items de catégorie |
| `largeur × 0,04` | 14 – 18 | texte des boutons de catégorisation |
| `hauteur/largeur × 0,075` puis `× 0,05` | 18+ / 14+ | titre et corps des popups paliers et badges |
| `× scale` | 10 à 20 | écran testeurs (7 tailles distinctes) |

### Graisses

`regular`, `w500`, `w600`, `bold` (= w700). Quatre niveaux, souvent utilisés
de façon interchangeable pour le même rôle : un titre de modale est tantôt
`18/bold`, tantôt `18/w600`.

### Couleurs de texte

`white`, `black`, `grey`, `lightGrey`, `orange`, `Colors.red`,
`Colors.grey[400/500/600/800]`, `Colors.white70`, `Colors.black54/45`,
`Color(0xFF2E7D32)` (vert de validation), `Color(0xFFD32F2F)` (rouge d'erreur),
plus les variables locales `couleurTitre`, `couleurTexte`,
`couleurTextePrincipal`, `couleurDescription`, `textColor`,
`texteSecondaire`, `couleurContenu`, `couleurTextePopup`.

**Huit noms différents pour ce qui est, presque partout, la même paire
« texte principal / texte secondaire ».** C'est ici que se trouve le plus gros
gisement de simplification.

---

## 4. Le même rôle, écrit de plusieurs façons

| Rôle | Variantes trouvées |
|---|---|
| Titre de modale | `18/bold/couleurTitre` · `18/bold/couleurTextePopup` · `18/bold/Colors.black` · `18/bold/couleurTextePrincipal` · `(w×0,075).clamp(18,·)/bold` |
| Texte secondaire | `14/regular/couleurDescription` · `14/regular/isDark ? lightGrey : grey` · `14/regular/texteSecondaire` · `13/regular/isDark ? lightGrey : grey` |
| Bouton d'une popup | `15/bold/white` (3 fichiers, redéclaré à chaque fois) |
| Ligne de réglage | `16/w500/grey` · `16/w600/isDark ? white : black` · `16/w500/couleurTextePrincipal` |

---

## 5. Réduction possible

Une palette de **7 styles** couvrirait les 161 déclarations actuelles :

| Nom proposé | Famille | Taille | Graisse | Remplace |
|---|---|---|---|---|
| `styleTitreEcran` | Lora | responsive | w600 | `styleTitreLora` (inchangé) |
| `styleTitreModale` | à décider (voir §6) | 18 | w600 | les 9 variantes de titre de modale |
| `styleSection` | sans | 20 | w600 | titres de section |
| `styleCorps` | sans | 16 | w500 | libellés, lignes de réglage, valeurs |
| `styleSecondaire` | sans | 14 | regular | descriptions, sous-titres |
| `styleMention` | sans | 13 | w600 | badges, mentions |
| `styleNote` | Lora | responsive | regular | `styleNoteLarge` (inchangé) |

Plus deux couleurs sémantiques — `texteFort` et `texteDoux`, chacune déclinée
clair/sombre — pour absorber les huit variables de couleur actuelles.

**À trancher avant tout le reste :** activer Inclusive Sans (l'ajouter au
`pubspec.yaml` et la poser en `fontFamily` du `ThemeData`), ou assumer la
police système. Aujourd'hui c'est un entre-deux non voulu.

---

## 6. Faut-il écrire tous les titres de modale en Lora ?

**Oui, mais seulement les titres, et pas toutes les modales.**

Ce qui plaide pour :

- Lora est aujourd'hui la seule chose qui distingue visuellement Sourire d'une
  app Material générique. Elle n'apparaît que sur 15 des 161 styles — la
  marque est diluée.
- Une serif à empattements sur un titre court et une sans-serif sur le corps
  de texte, c'est l'appariement le plus classique et le plus sûr en typographie.
  Le contraste des deux familles fait la hiérarchie mieux que le gras seul.
- Tes titres d'écran sont déjà en Lora : une modale titrée en sans-serif crée
  une rupture au moment précis où l'utilisateur change de contexte.

Les réserves, qui sont réelles :

- **Lora est une police de lecture, pas d'interface.** Elle est superbe sur
  « Ton bocal est plein ! », beaucoup moins sur « Supprimer ce souvenir ? »
  posé au-dessus de deux boutons — les empattements y font décoratif au moment
  où l'on attend de la clarté.
- À 18 pt, `tailleLora` ramène à 15,3 pt : c'est petit pour une serif, qui a
  besoin de plus de corps qu'une sans pour rester lisible. Il faudrait titrer
  les modales à 20–22 pt.
- Les popups de confirmation et les messages d'erreur gagnent à rester neutres.
  La serif porte une intention chaleureuse ; sur un avertissement, elle sonne faux.

**La règle que je te propose :** Lora sur les modales qui *racontent quelque
chose* — palier atteint, badge débloqué, bocal plein, message de bienvenue. Et
la sans-serif sur les modales qui *demandent quelque chose* — confirmation,
suppression, erreur, réglage. Un seul critère, facile à trancher au cas par
cas, et qui garde à Lora sa valeur : si tout est en Lora, plus rien ne l'est.

Dans les deux cas, une seule taille et une seule graisse pour toute la
catégorie, sinon on remplace un désordre par un autre.

---

## 7. Ce qui a été appliqué (V15)

Les huit styles vivent dans `tokens.dart` : `styleTitreEcran`,
`styleTitreRecit`, `styleTitreAction`, `styleSection`, `styleCorps`,
`styleSecondaire`, `styleMention`, `styleNoteLarge`. Plus les deux couleurs
sémantiques `texteFort(bool)` et `texteDoux(bool)`.

Migrés : les six modales (accès galerie, achat premium, bocal plein,
suppression de souvenirs, suppression de catégories ×3, popup de profil),
les popups palier et badge, les titres de section (filtre, thèmes, badges) et
les lignes de réglage du profil.

Pas encore migrés, volontairement : `screen_testeurs.dart` (écran interne, 14
styles avec un facteur `scale` qui lui est propre), `screen_lock.dart` et les
widgets de bouton, dont les tailles sont calculées à partir de la géométrie de
l'écran plutôt que d'une échelle typographique.

Le partage de la règle Lora/sans-serif est en place : `styleTitreRecit` sur
bocal plein, palier atteint et badge débloqué ; `styleTitreAction` sur toutes
les modales de confirmation, de suppression et de réglage.

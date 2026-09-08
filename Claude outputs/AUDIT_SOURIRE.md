# Audit de Sourire avant publication

Revue du code et des fonctionnalités, de l'onboarding à l'export des données.
Périmètre lu : les 60 fichiers de `lib/`, le manifeste Android, l'`Info.plist`
iOS, le `build.gradle.kts` et le `pubspec.yaml`.

Trois questions posées, trois réponses courtes avant le détail.

**« Est-ce que l'app va ramer au bout d'un certain nombre de souvenirs ? »**
Oui, et j'ai trouvé pourquoi. Ce n'est pas une lente dégradation : c'est une
requête SQL complète exécutée soixante fois par seconde, en permanence, sur
l'écran d'accueil. Le coût de cette requête est proportionnel au nombre de
souvenirs. À vingt souvenirs cela ne se voit pas. À trois cents, l'app tire la
langue. À mille, elle devient inutilisable. C'est le point B.1, et c'est de loin
le plus important de ce document.

**« Est-ce qu'on n'a rien oublié comme fonctionnalité ? »**
Le parcours est complet et cohérent. Il manque surtout un bouton « tout
effacer », et la sauvegarde exportée ne tient pas la charge au-delà de deux ou
trois cents photos.

**« Est-ce que la version poussée en prod est impeccable ? »**
Pas encore. Cinq points bloquants, dont deux qui exposent à un refus des stores
et deux qui touchent à la promesse de confidentialité affichée sur ta fiche et
sur ton site.

---

## A. Bloquants avant publication

### A.1 L'achat Premium débloque sans facturer

`lib/widgets/modale_premium.dart:84-88`

```dart
if (achete != true) return false;
UserPrefs.isPremium = true;
ThemeService.deverrouillerPremium();
```

Un simple appui sur le bouton lève la limite des 25 souvenirs et déverrouille
tous les décors. Aucun passage par StoreKit ni par Play Billing. Publier en
l'état, c'est afficher une offre payante que personne ne paie, et surtout
présenter à Apple un parcours d'achat qui ne passe pas par leur système, ce qui
est un motif de rejet direct.

Deux issues possibles. Soit brancher `in_app_purchase` maintenant, avec la
restauration d'achat obligatoire côté Apple. Soit publier la 1.0 entièrement
gratuite en retirant la modale et la limite, et sortir le Premium en 1.1 une
fois l'immatriculation faite. La seconde option est plus rapide et sans risque.

### A.2 Le verrou de l'application ne protège rien

`lib/screens/screen_reset_password.dart:32-61`

Depuis l'écran de verrouillage, le lien « Mot de passe oublié ? » ouvre un écran
qui demande simplement un nouveau mot de passe et l'enregistre. Il n'y a aucune
vérification : ni code envoyé par mail, ni biométrie exigée, rien. N'importe qui
tenant le téléphone déverrouillé peut ouvrir Sourire, taper « mot de passe
oublié », choisir « 0000 » et lire tous les souvenirs.

Le mot de passe est donc décoratif. Deux façons de le rendre réel :

- exiger la biométrie pour accéder à l'écran de réinitialisation, quand elle est
  disponible sur l'appareil ;
- sinon, prévenir clairement que réinitialiser le mot de passe efface le bocal,
  et l'effacer réellement. C'est la seule garantie possible sans serveur.

À défaut de l'un ou l'autre, mieux vaut retirer le lien et n'offrir que la
biométrie.

### A.3 Le mot de passe est stocké en clair

`lib/theme/user_prefs.dart:45-46`, `lib/screens/screen_lock.dart:91`

```dart
static String get password => _prefs?.getString('password') ?? "";
...
if (_passwordController.text == UserPrefs.password) { ... }
```

Il est écrit tel quel dans les préférences partagées, et comparé en clair. Sur
Android ce fichier XML est lisible sur un appareil rooté, sur iOS il part dans
les sauvegardes iCloud et iTunes en clair.

Correctif propre et court : stocker `sha256(sel + motDePasse)` et le sel, et
comparer les empreintes. Une dizaine de lignes, plus une migration silencieuse
au premier lancement pour convertir le mot de passe déjà enregistré.

### A.4 La sauvegarde automatique Android est active

`android/app/src/main/AndroidManifest.xml`

L'attribut `android:allowBackup` n'est pas déclaré, il vaut donc `true` par
défaut. Concrètement, Android copie automatiquement les préférences, la base
SQLite et les photos du dossier de l'app vers le Google Drive de l'utilisateur.

Ta fiche store et ton site disent « tout est enregistré sur votre téléphone et
nulle part ailleurs » et « rien ne part jamais tout seul ». En l'état, c'est
faux sur Android. Le mot de passe en clair part avec.

Correctif d'une ligne dans la balise `<application>` :

```xml
android:allowBackup="false"
android:fullBackupContent="false"
android:dataExtractionRules="@xml/data_extraction_rules"
```

Le premier attribut suffit. Le troisième permet, si tu préfères garder une
sauvegarde, d'en exclure explicitement les préférences et la base.

### A.5 Deux déclarations qui exposent à un refus

**iOS.** `ios/Runner/Info.plist:58-62` déclare :

```xml
<key>UIBackgroundModes</key>
<array><string>fetch</string><string>remote-notification</string></array>
```

L'app n'a ni serveur, ni notification distante, ni rafraîchissement en arrière
plan. Apple vérifie ce point et refuse les modes déclarés mais inutilisés
(directive 2.5.4). À supprimer entièrement.

**Android.** Le manifeste demande `SCHEDULE_EXACT_ALARM`. Google Play réserve
cette permission aux réveils, agendas et alarmes, et demande une justification
pour tout le reste. Un rappel de gratitude hebdomadaire n'en a pas besoin :
`AndroidScheduleMode.inexactAllowWhileIdle` déclenche le rappel à quelques
minutes près, ce qui est parfaitement suffisant ici, et fait tomber la
permission. C'est aussi meilleur pour la batterie.

---

## B. Performance : pourquoi l'app ralentit, et de combien

### B.1 Une requête SQL complète à chaque image de l'écran d'accueil

**C'est la cause principale, et elle explique à elle seule le symptôme.**

Trois fichiers concourent au problème.

`lib/services/database_service.dart:122-126` :

```dart
Stream<List<NoteSourire>> getNotesStream() {
  _notifierChangement();          // ← déclenche un SELECT * FROM notes
  return _notesStreamController.stream;
}
```

Appeler `getNotesStream()` ne se contente pas de rendre le flux : la méthode
relit **toute** la table et pousse le résultat à tous les abonnés.

`lib/widgets/bocal_pastilles.dart:170-185 et 440-441` :

```dart
void _onTick(Duration elapsed) {
  ...
  if (mounted) setState(() {});   // ← 60 fois par seconde, pour la physique
}

Widget build(BuildContext context) {
  return StreamBuilder<List<NoteSourire>>(
    stream: DatabaseService().getNotesStream(),   // ← donc 60 fois par seconde
```

Le `Ticker` de la physique des billes reconstruit le widget à chaque image, et
chaque reconstruction rappelle `getNotesStream()`, donc relance un
`SELECT * FROM notes` complet suivi de la construction d'un objet `NoteSourire`
par ligne.

Et ce n'est pas tout : chaque résultat est diffusé aux **trois**
`StreamBuilder` abonnés au même flux, qui sont tous les trois montés en même
temps sur l'accueil.

| Fichier | Ligne |
|---|---|
| `widgets/bocal_pastilles.dart` | 441 |
| `screens/home.dart` | 1177 |
| `widgets/widget_historique.dart` | 386 |

Chacun d'eux, en se reconstruisant, rappelle `getNotesStream()` et relance une
requête. La boucle s'auto-entretient et s'amplifie.

**Ce que cela donne concrètement :**

| Souvenirs dans le bocal | Lignes lues et converties par seconde |
|---|---|
| 25 | ~4 500 |
| 100 | ~18 000 |
| 500 | ~90 000 |
| 2 000 | ~360 000 |

C'est exactement la courbe que tu redoutes. En dessous d'une centaine de
souvenirs, le téléphone encaisse et rien ne se voit. Au-delà, le fil d'exécution
de la base ne suit plus, la file d'attente des requêtes s'allonge, l'animation
saccade, et l'app chauffe et vide la batterie même à l'arrêt sur l'écran
d'accueil.

**Le correctif.** Séparer la lecture de l'abonnement. Le flux ne doit rien
déclencher, et il doit conserver sa dernière valeur pour les nouveaux abonnés :

```dart
// Dernière liste connue, rendue immédiatement à tout nouvel abonné.
List<NoteSourire> _dernieresNotes = const [];
List<NoteSourire> get notesEnCache => _dernieresNotes;

/// Le flux, et RIEN d'autre. Aucun effet de bord : cette méthode est appelée
/// à chaque reconstruction d'un widget, donc potentiellement soixante fois
/// par seconde. C'est aux écritures de déclencher une relecture.
Stream<List<NoteSourire>> getNotesStream() => _notesStreamController.stream;

/// À appeler une fois, au démarrage.
Future<void> chargerNotes() async {
  _dernieresNotes = await _fetchNotesFromDb();
  _notesStreamController.add(_dernieresNotes);
}

Future<void> _notifierChangement() async {
  _dernieresNotes = await _fetchNotesFromDb();
  _notesStreamController.add(_dernieresNotes);
}
```

Côté widgets, il suffit alors d'ajouter `initialData: DatabaseService().notesEnCache`
aux trois `StreamBuilder`, et d'appeler `chargerNotes()` une fois dans `main()`.
Les écritures continuent d'appeler `_notifierChangement()` comme aujourd'hui, et
l'interface reste à jour, mais on passe de soixante requêtes par seconde à une
seule par modification réelle.

Le même défaut existe à l'identique sur `getCategoriesStream()`
(`database_service.dart:128-131`), appelé dans quatre écrans.

C'est le correctif à faire en premier. Il est court, localisé, et il retire à
lui seul l'essentiel du problème.

### B.2 L'historique retrie et regroupe tout à chaque reconstruction

`lib/widgets/widget_historique.dart:288-320`

`_grouperParDate()` filtre la liste entière, la trie, et formate une date par
souvenir avec `DateFormat`. Tant que le volet est fermé le calcul est évité, ce
qui est bien vu, mais dès qu'il est ouvert il est refait à chaque reconstruction,
donc aujourd'hui soixante fois par seconde à cause de B.1. Une fois B.1 corrigé,
il ne se rejouera plus qu'aux vrais changements, ce qui est acceptable. Si tu
veux aller plus loin, mémoriser le résultat tant que la liste et les filtres
n'ont pas changé coûte cinq lignes.

Détail dans la même méthode, ligne 449 :

```dart
String dateCle = souvenirsGroupes.keys.elementAt(index);
```

`elementAt` reparcourt la collection depuis le début à chaque appel. Le coût de
construction de la liste est donc quadratique en nombre de journées. À trois ans
d'usage quotidien cela commence à peser. Corriger en calculant une fois
`final cles = souvenirsGroupes.keys.toList();` avant le `SliverList`.

### B.3 La grille d'une journée est construite en entier, d'un coup

`lib/widgets/widget_historique.dart:466-476`

```dart
GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
```

Un `GridView` en `shrinkWrap` doit mesurer tous ses enfants pour connaître sa
hauteur : il les construit donc tous, sans paresse. Chaque vignette lance une
lecture disque de sa photo. Tant qu'une journée compte dix ou vingt souvenirs,
aucun souci. Le jour où quelqu'un importe deux cents photos d'un coup, ouvrir
l'historique construit deux cents vignettes et lance deux cents lectures
simultanées, et le volet se fige.

Deux façons de traiter, au choix : remplacer la structure par un unique
`SliverList` de lignes de quatre, avec les en-têtes de date insérés comme
éléments de la même liste, ce qui restaure la construction paresseuse ; ou
plafonner l'affichage d'une journée à un nombre raisonnable avec un
« voir les 180 autres ». La première est la bonne solution, la seconde tient en
vingt lignes.

À noter, le cache d'images est déjà propre : cache LRU de trente entrées dans
`souvenir_historique.dart:26-36`, et `cacheWidth` passé à `Image.memory`. Rien à
reprendre de ce côté.

### B.4 La base n'a aucun index

`lib/services/database_service.dart:77-104`

La table `notes` n'a d'index que sur sa clé primaire. Or toutes les lectures
font `ORDER BY date DESC`, ce qui oblige SQLite à trier l'intégralité de la
table à chaque appel. Un index règle la question :

```dart
// dans _onCreate, et dans _onUpgrade sous `if (ancienne < 5)`
await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_date ON notes(date DESC)');
await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_amorce ON notes(estAmorce)');
```

Pense à passer `version: 5` dans `_initDatabase` en ajoutant la marche de
migration, sinon les bases déjà installées ne la joueront jamais.

### B.5 Supprimer une catégorie écrit ligne à ligne, hors transaction

`lib/services/database_service.dart:384-403`

```dart
final notes = await _fetchNotesFromDb();
for (var souvenir in notes) {
  if (souvenir.categories.contains(categoryKey)) {
    ...
    await db.update('notes', ..., where: 'id = ?', whereArgs: [souvenir.id]);
  }
}
```

Chaque `update` isolé est une transaction implicite, donc une écriture physique
sur le disque. Supprimer une catégorie portée par cinq cents souvenirs, c'est
cinq cents écritures disque à la suite, interface figée pendant tout ce temps.
Le remède est le même `Batch` que tu utilises déjà ailleurs :

```dart
final batch = db.batch();
for (final souvenir in notes) { ... batch.update(...); }
await batch.commit(noResult: true);
```

Une seule transaction, quelques millisecondes.

### B.6 Le tirage au sort charge tout le bocal

`lib/services/database_service.dart:433-452`

`getRandomNote()` lit la table entière, construit un objet par ligne, puis en
garde un seul. Sans filtre de catégorie, SQLite sait le faire tout seul :

```dart
final maps = await db.rawQuery('SELECT * FROM notes ORDER BY RANDOM() LIMIT 1');
```

Avec filtre de catégorie, comme les catégories sont stockées en une seule
colonne texte, on peut au minimum réduire avec un `WHERE categories LIKE ?`
avant de finir le tri en mémoire.

Ce n'est pas critique, le tirage est ponctuel. Mais il est aussi déclenché
depuis le clic sur une notification (`main.dart:187`), au réveil de l'app, au
moment précis où on veut qu'elle s'ouvre vite.

### B.7 L'export du bocal peut faire tomber l'app

`lib/services/sauvegarde_service.dart:53-121`

L'export lit **toutes** les photos en mémoire, les empile dans un objet
`Archive`, puis produit le ZIP complet en mémoire, le tout sur le fil
d'exécution de l'interface.

Pic mémoire approximatif, avec des photos réduites à 300 Ko :

| Photos | Mémoire nécessaire |
|---|---|
| 100 | ~60 Mo |
| 300 | ~180 Mo |
| 800 | ~480 Mo |

Sur un Android d'entrée de gamme, le système tue l'application bien avant le
dernier palier, et l'utilisateur perd sa sauvegarde sans comprendre pourquoi.
L'interface est par ailleurs entièrement figée pendant la fabrication, sans
indicateur de progression.

Trois correctifs, par ordre d'importance :

1. écrire l'archive en flux vers le fichier plutôt que de la construire en
   mémoire (`ZipFileEncoder`, qui prend un chemin de fichier et accepte
   `addFile` un par un) ;
2. régler la compression sur « aucune » pour les photos, puisqu'un JPEG ne se
   compresse pas : on gagne beaucoup de temps processeur pour zéro octet ;
3. afficher une progression, et purger les anciens ZIP du dossier temporaire,
   qui s'y accumulent aujourd'hui à chaque export.

L'import (`sauvegarde_service.dart:148-236`) a exactement le même défaut au
décodage, avec le même correctif.

### B.8 Ce qui va bien, et qu'il ne faut pas toucher

- La réduction des photos à l'import (`photo_service.dart`) est bien pensée :
  passage par la vignette native du système, repli propre sur un décodage en
  `isolate`, seuil de non-recompression. C'est le bon design.
- La physique des billes est plafonnée à 45 billes par bocal, donc son coût en
  n² reste borné quel que soit le nombre de souvenirs. Rien à craindre de ce
  côté.
- Le cache LRU des vignettes d'historique est correct.
- Les insertions groupées passent déjà par des `Batch`.

---

## C. Fonctionnalités manquantes ou incomplètes

### C.1 Aucun moyen de tout effacer

Rien dans l'app ne permet de vider le bocal ou de repartir de zéro. C'est la
demande la plus courante sur ce type d'application, et la seule réponse
aujourd'hui est de désinstaller. Un bouton « Effacer tous mes souvenirs » dans
le profil, avec confirmation en deux temps, comble le manque et rend crédible
la promesse de maîtrise des données.

### C.2 Le rattrapage des anciennes photos ne fonctionne pas sur iOS

`lib/services/photo_service.dart:167` fait `File(chemin)` directement à partir de
`photoPath`. Or sur iOS, `database_service.dart:467` n'enregistre que le nom du
fichier :

```dart
final String pathEnregistrer = Platform.isIOS ? basename(cleanPath) : cleanPath;
```

Le chemin est donc relatif, le fichier n'est jamais trouvé, et la passe de
réduction ne réduit rien sur iPhone. Les autres écrans, eux, reconstruisent bien
le chemin absolu (`souvenir_historique.dart:153-158`). Il manque le même
traitement dans `reduireLesAnciennes()`.

Le plus propre serait de centraliser cette résolution dans une seule fonction
`Future<File> fichierPhoto(String chemin)` utilisée partout, plutôt que de
répéter le test de plateforme dans quatre fichiers.

### C.3 L'import multiple de photos perd la date de prise de vue

`lib/services/database_service.dart:455-485`

`insertMultiplePhotos` n'écrit ni `datePrise` ni `estAmorce`. Toutes les photos
importées ensemble prennent donc la date du jour comme date affichée, alors
qu'une photo importée seule conserve la sienne. Comme le filtre par année se
base sur `dateAffichee`, une importation groupée de photos de 2019 se rangera en
2026. Le sélecteur connaît pourtant la date : `AssetEntity.createDateTime`.

### C.4 Android 14 et l'accès partiel aux photos

Le manifeste déclare `READ_MEDIA_IMAGES` mais pas
`READ_MEDIA_VISUAL_USER_SELECTED`. Sur Android 14 et au delà, l'utilisateur peut
n'autoriser que quelques photos : sans cette déclaration le comportement devient
incohérent selon les appareils. À ajouter, et à tester sur un Android 14.

Rappel par ailleurs : Google Play demande de remplir la déclaration
« Autorisations relatives aux photos et vidéos » pour toute app demandant
`READ_MEDIA_IMAGES`. Prévois-la dans la console.

### C.5 Petits manques de confort

- Ni le numéro de version, ni un lien vers la politique de confidentialité ne
  figurent dans l'app. Les deux se posent en trois lignes dans le profil, et
  c'est ce que cherchent les utilisateurs avant d'écrire à l'assistance.
- L'`Info.plist` autorise le paysage sur iPhone alors que `main.dart:45-48`
  force le portrait. Sans conséquence, mais autant aligner les deux.

---

## D. Propreté du code

Rien de bloquant ici, mais tu tiens à un code propre, donc voici la liste.

### D.1 Des écritures en base qu'on ne peut pas attendre

`insertNote`, `updateNote`, `insertCategory`, `deleteCategory` et
`insertMultiplePhotos` sont déclarées `void ... async`. Conséquences : l'appelant
ne peut pas savoir quand l'écriture est finie, et surtout, si elle échoue,
l'exception part dans le vide et fait planter l'app sans message exploitable.
Un `Future<void>` à la place, et un `await` chez les appelants, suffit. C'est la
correction la plus rentable de cette section.

On voit d'ailleurs le contournement à `widget_historique.dart:172` :

```dart
await Future.sync(() => databaseService.deleteMultipleNotes(...));
```

### D.2 Effets de bord pendant la construction de l'interface

`home.dart:1181-1188` appelle `_verifierPalier()` à l'intérieur du `builder` du
`StreamBuilder`, et cette méthode écrit dans les préférences
(`UserPrefs.dernierPalierCelebre = ...`). Écrire sur le disque pendant la
construction d'un widget est fragile, et aujourd'hui cela se produit à chaque
image. À déplacer dans un `addPostFrameCallback`, ou mieux, dans l'écoute du
flux plutôt que dans son affichage.

### D.3 Reliquats à supprimer

- Deux dépendances déclarées et jamais utilisées : `drop_shadow` et
  `simple_shadow`.
- 48 clés de traduction orphaines dans `app_fr.arb`, `app_en.arb` et
  `app_es.arb`, soit 144 entrées mortes. Liste jointe plus bas.
- `pubspec.yaml` porte toujours la description « A new Flutter project. ».

### D.4 Fichiers devenus trop gros

`screen_profil.dart` fait 77 Ko, `home.dart` 49 Ko, `widget_historique.dart`
40 Ko. Ce ne sont plus des écrans, ce sont des dossiers. Rien n'oblige à les
découper aujourd'hui, mais chaque correction dans ces fichiers coûte de plus en
plus cher, et c'est là que se logent les régressions. Le découpage naturel de
`screen_profil` est une section par fichier.

### D.5 La compilation de release n'est pas minifiée

`android/app/build.gradle.kts:50-55` déclare `proguardFiles` mais jamais
`isMinifyEnabled = true`. Les règles ProGuard ne sont donc pas appliquées : le
bundle est plus lourd que nécessaire et le code Kotlin n'est pas obfusqué.
À activer et à tester en release avant publication, car la minification peut
révéler des problèmes de réflexion dans certains greffons.

Par ailleurs, `signingConfigs` fait un `as String` non protégé sur les valeurs de
`key.properties`. Si le fichier manque, même une compilation debug échoue avec
une erreur peu parlante. Un `as String?` avec repli rendrait le projet
reconstructible par n'importe qui sans le fichier de signature.

---

## Ordre de traitement suggéré

**Lot 1, la performance.** B.1, puis B.4 et B.5. C'est le lot qui répond à ta
question, il est court et sans risque fonctionnel.

**Lot 2, les bloquants stores.** A.5 et A.4, qui tiennent en quelques lignes de
configuration. Puis A.1, la décision Premium.

**Lot 3, la sécurité.** A.2 et A.3, qui vont ensemble.

**Lot 4, les données.** B.7 pour l'export, C.1 pour l'effacement, C.2 et C.3
pour les photos.

**Lot 5, la propreté.** D.1 à D.5, à faire tranquillement.

---

## Annexe : clés de traduction orphaines

À retirer de `app_fr.arb`, `app_en.arb` et `app_es.arb`, avec leurs
métadonnées `@` associées, puis relancer `flutter gen-l10n`.

```
btnClose, btnDeleteCategories, btnOk, btnSave, categoriesIncluded,
dailyGratitudeReminder, dailyReminderSubtitle, deleteConfirmMessage,
drawnMemoriesFrequency, drawnMemoriesSubtitle, everyDay, everyTwoDays,
everyWeek, frequencySettings, galleryPreview, galleryRecent, logout,
noCustomCategoryToDelete, popupPalierMessage, popupPalierTitle,
profilAlertTitle, profilBtnEmpty, profilHelpAnswer1, profilHelpAnswer2,
profilHelpQuestion1, profilHelpQuestion2, profilLabelBiometrics,
profilLabelEmail, profilLabelFirstName, profilLabelGalleryAccess,
profilLabelImportedPhotos, profilLabelPassword, profilLabelTextMemories,
profilMenuDarkMode, profilMenuLanguage, profilMenuNotifications,
profilMenuSoftAnimations, profilSnackbarEmptied, profilTitleAccountSettings,
profilTitleHelp, profilTitlePersonalData, profilTitleStorage,
recategorizeTitle, reminderTime, themeAbstrait, themesDescription,
titleDeleteModal, titleSourire
```

J'ai vérifié le cas le moins évident : `popupPalierTitle` et
`popupPalierMessage` ne sont pas non plus construits dynamiquement,
`popup_palier.dart` passe par `texteBadgePourPalier()` et n'utilise que
`btnContinuerPalier`. Les 48 clés peuvent donc partir sans risque.

Bonne nouvelle par ailleurs : `screen_testeurs.dart` a bien disparu du projet et
n'est plus importé nulle part.

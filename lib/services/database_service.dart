import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';
import 'package:sourire/theme/tokens.dart';

class DatabaseService {
  static Database? _database;

  // Liste des catégories système protégées
  final List<String> _systemCategories = [
    "self_love",
    "friendship",
    "couple",
    "family",
    "leisure",
    "work",
  ];

  // Les contrôleurs de flux (Streams) d'origine pour ne pas casser tes StreamBuilders
  final StreamController<List<NoteSourire>> _notesStreamController = StreamController<List<NoteSourire>>.broadcast();
  final StreamController<List<String>> _categoriesStreamController = StreamController<List<String>>.broadcast();

  // --- MÉMOIRE DE LA DERNIÈRE LECTURE ---------------------------------------
  //
  // Un `StreamController.broadcast` ne rejoue rien : un widget qui s'abonne
  // n'obtient sa première valeur qu'à la prochaine émission. C'est ce qui
  // obligeait `getNotesStream()` à relancer une lecture à chaque appel, donc
  // à chaque reconstruction de widget, donc soixante fois par seconde sur la
  // home à cause du Ticker du bocal.
  //
  // On garde donc ici la dernière liste connue, et les écrans la passent en
  // `initialData` à leur StreamBuilder. Le flux, lui, ne sert plus qu'à
  // annoncer les CHANGEMENTS.
  List<NoteSourire> _dernieresNotes = const <NoteSourire>[];
  List<String> _dernieresCategories = const <String>[];

  /// Dernière liste de souvenirs lue en base, disponible immédiatement.
  /// À passer en `initialData` des `StreamBuilder`.
  List<NoteSourire> get notesEnCache => _dernieresNotes;

  /// Dernière liste de catégories lue en base, disponible immédiatement.
  List<String> get categoriesEnCache => _dernieresCategories;

  // Instance unique (Singleton) inchangée
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // --- INITIALISATION DE SQFLITE ---

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'sourire_bocal.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Migrations de schéma. Les bases déjà installées chez les testeurs sont
  /// en version 1 : on ne peut pas les recréer, seulement les compléter.
  Future<void> _onUpgrade(Database db, int ancienne, int nouvelle) async {
    if (ancienne < 2) {
      await db.execute(
        "ALTER TABLE notes ADD COLUMN estAmorce INTEGER NOT NULL DEFAULT 0",
      );
    }
    if (ancienne < 3) {
      // Date d'origine d'une photo. Nullable : les souvenirs déjà en base
      // n'en ont pas, et retomberont sur leur date d'entrée.
      await db.execute("ALTER TABLE notes ADD COLUMN datePrise TEXT");
    }
    if (ancienne < 4) {
      // Les six catégories par défaut deviennent supprimables. On ne peut pas
      // les effacer d'une table — elles n'y ont jamais été, elles vivent en
      // dur dans [_systemCategories]. On mémorise donc les MASQUAGES.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories_masquees(
          name TEXT PRIMARY KEY
        )
      ''');
    }
    if (ancienne < 5) {
      // Index. Toutes les lectures trient par date décroissante : sans index,
      // SQLite retrie la table entière à chaque appel.
      await _creerIndex(db);
    }
  }

  /// Index de lecture. Voir [_onUpgrade] pour la raison.
  ///
  /// `date` est stockée en ISO 8601, dont l'ordre alphabétique est aussi
  /// l'ordre chronologique : un index B-tree ordinaire suffit donc à servir
  /// le `ORDER BY date DESC` sans tri.
  Future<void> _creerIndex(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_date ON notes(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_amorce ON notes(estAmorce)',
    );
  }

  // Création des deux tables nécessaires : notes et catégories personnalisées
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT,
        photoPath TEXT,
        themeLabel TEXT,
        colorLabel TEXT,
        categories TEXT,
        date TEXT,
        datePrise TEXT,
        estAmorce INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_categories(
        name TEXT PRIMARY KEY
      )
    ''');

    // Catégories par défaut que l'utilisateur a supprimées. Voir _onUpgrade.
    await db.execute('''
      CREATE TABLE categories_masquees(
        name TEXT PRIMARY KEY
      )
    ''');

    await _creerIndex(db);
  }

  // --- FLUX -----------------------------------------------------------------

  /// Le flux des souvenirs, ET RIEN D'AUTRE.
  ///
  /// ⚠️ Cette méthode ne doit JAMAIS déclencher de lecture. Elle est appelée
  /// dans le `build` de plusieurs widgets, dont le bocal, que son Ticker de
  /// physique reconstruit à chaque image. Une lecture ici, c'est un
  /// `SELECT * FROM notes` soixante fois par seconde, dont le coût grandit
  /// avec le nombre de souvenirs. C'était la cause des ralentissements sur
  /// les gros bocaux.
  ///
  /// Les abonnés obtiennent leur première valeur par [notesEnCache], passé en
  /// `initialData`. Ensuite, seules les écritures émettent.
  Stream<List<NoteSourire>> getNotesStream() => _notesStreamController.stream;

  /// Le flux des catégories. Même règle que [getNotesStream] : aucun effet de
  /// bord, la valeur de départ vient de [categoriesEnCache].
  Stream<List<String>> getCategoriesStream() => _categoriesStreamController.stream;

  /// Première lecture, à appeler une seule fois au démarrage, avant `runApp`.
  ///
  /// Sans elle, les écrans afficheraient un bocal vide jusqu'à la première
  /// écriture.
  Future<void> chargerDonneesInitiales() async {
    await _rechargerNotes();
    await _rechargerCategories();
  }

  // --- RECHARGEMENTS --------------------------------------------------------

  /// Empêche vingt écritures rapprochées de provoquer vingt relectures.
  bool _rechargementNotesPlanifie = false;

  /// Relit les souvenirs et prévient les abonnés.
  ///
  /// Les appels rapprochés sont fondus en un seul : valider un lot de vingt
  /// photos écrit vingt lignes, mais ne doit relire la base qu'une fois.
  Future<void> _notifierChangement() async {
    if (_rechargementNotesPlanifie) return;
    _rechargementNotesPlanifie = true;
    // Deux images d'écran : assez pour absorber une rafale d'écritures,
    // trop peu pour se voir.
    await Future<void>.delayed(const Duration(milliseconds: 32));
    _rechargementNotesPlanifie = false;
    await _rechargerNotes();
  }

  Future<void> _rechargerNotes() async {
    _dernieresNotes = await _fetchNotesFromDb();
    if (!_notesStreamController.isClosed) {
      _notesStreamController.add(_dernieresNotes);
    }
  }

  Future<void> _notifierChangementCategories() => _rechargerCategories();

  Future<void> _rechargerCategories() async {
    _dernieresCategories = await _fetchCategoriesFromDb();
    if (!_categoriesStreamController.isClosed) {
      _categoriesStreamController.add(_dernieresCategories);
    }
  }

  // --- LOGIQUE INTERNE DE LECTURE SQL ---

  Future<List<NoteSourire>> _fetchNotesFromDb() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => NoteSourire.fromMap(maps[i]));
  }

  /// Toutes les catégories disponibles, TRIÉES PAR FRÉQUENCE D'USAGE.
  ///
  /// Trois règles, dans cet ordre :
  /// 1. les catégories par défaut supprimées par l'utilisateur disparaissent ;
  /// 2. les plus utilisées remontent — c'est ce qui fait qu'après quelques
  ///    semaines, les deux ou trois catégories qui comptent vraiment pour
  ///    quelqu'un sont sous son pouce sans qu'il ait à chercher ;
  /// 3. à égalité, l'ordre historique est conservé (les six par défaut dans
  ///    leur ordre d'origine, puis les personnalisées par ordre de création).
  ///    Sans cette troisième règle, les catégories jamais utilisées
  ///    danseraient d'un affichage à l'autre.
  Future<List<String>> _fetchCategoriesFromDb() async {
    final db = await database;

    final List<Map<String, dynamic>> perso = await db.query('custom_categories');
    final List<Map<String, dynamic>> masquees = await db.query('categories_masquees');

    final Set<String> aMasquer =
        masquees.map((m) => m['name'] as String).toSet();

    final List<String> disponibles = [
      ..._systemCategories.where((c) => !aMasquer.contains(c)),
      ...perso.map((m) => m['name'] as String),
    ];

    final Map<String, int> usages = await _compterUsagesCategories();

    // Position d'origine mémorisée une fois : `indexOf` dans le comparateur
    // rendait le tri quadratique.
    final Map<String, int> rangDorigine = <String, int>{
      for (int i = 0; i < disponibles.length; i++) disponibles[i]: i,
    };

    // Tri STABLE : `List.sort` ne l'est pas en Dart, on départage donc
    // explicitement par la position d'origine.
    final List<String> tri = List<String>.from(disponibles);
    tri.sort((a, b) {
      final int ecart = (usages[b] ?? 0).compareTo(usages[a] ?? 0);
      if (ecart != 0) return ecart;
      return (rangDorigine[a] ?? 0).compareTo(rangDorigine[b] ?? 0);
    });
    return tri;
  }

  /// Nombre de souvenirs portant chaque catégorie.
  ///
  /// Les catégories sont stockées en une seule colonne texte, "Cat1,Cat2" :
  /// pas de table de liaison, donc pas de `GROUP BY` possible. On compte donc
  /// en mémoire, sur la seule colonne utile.
  Future<Map<String, int>> _compterUsagesCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> lignes =
        await db.query('notes', columns: ['categories']);

    final Map<String, int> usages = <String, int>{};
    for (final ligne in lignes) {
      final String brut = (ligne['categories'] as String?) ?? '';
      if (brut.isEmpty) continue;
      for (final String categorie in brut.split(',')) {
        final String nom = categorie.trim();
        if (nom.isEmpty || nom == 'sans_categorie') continue;
        usages[nom] = (usages[nom] ?? 0) + 1;
      }
    }
    return usages;
  }

  /// Nombre de souvenirs portant [categorie].
  ///
  /// Sert à décider s'il faut confirmer une suppression : effacer une
  /// catégorie que personne n'utilise ne mérite pas de question.
  Future<int> compterSouvenirsAvecCategorie(String categorie) async {
    final Map<String, int> usages = await _compterUsagesCategories();
    return usages[categorie] ?? 0;
  }

  /// Rétablit les six catégories par défaut supprimées.
  ///
  /// Elles reviennent en tant que CLÉS (`family`, `work`…), donc traduites.
  /// Recréer « Famille » à la main donnerait une catégorie en texte brut, qui
  /// resterait française même en anglais — d'où ce bouton.
  Future<void> restaurerCategoriesParDefaut() async {
    final db = await database;
    await db.delete('categories_masquees');
    debugPrint("--- BDD SQL : catégories par défaut restaurées ---");
    await _notifierChangementCategories();
  }

  /// `true` si au moins une catégorie par défaut a été supprimée — sert à
  /// n'afficher le bouton de restauration que quand il a un sens.
  Future<bool> aDesCategoriesParDefautMasquees() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories_masquees');
    return maps.isNotEmpty;
  }

  // --- EN EXCLUSIVITÉ : SANS CHANGEMENT DE SIGNATURE POUR TES ÉCRANS ---

  /// Repli synchrone pour les écrans qui doivent afficher quelque chose avant
  /// la première émission du flux. Rend les catégories déjà connues si on en
  /// a, sinon les six par défaut.
  List<String> getAllCategories() {
    if (_dernieresCategories.isNotEmpty) {
      return List<String>.from(_dernieresCategories);
    }
    return [..._systemCategories];
  }

  // Remplace l'ancienne méthode par celle-ci
  Future<List<NoteSourire>> getAllNotesAsync() async {
    return await _fetchNotesFromDb();
  }

  // Compte uniquement les souvenirs textuels (où photoPath est nul ou vide)
  Future<int> getTextNotesCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM notes WHERE photoPath IS NULL OR photoPath = ''")
    );
    return count ?? 0;
  }

  // Compte uniquement les souvenirs de type Photo (où photoPath contient un chemin)
  Future<int> getPhotoNotesCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM notes WHERE photoPath IS NOT NULL AND photoPath != ''")
    );
    return count ?? 0;
  }

  // Compte TOUS les souvenirs, notes et photos confondues.
  // C'est ce total qui est comparé à UserPrefs.limiteSouvenirsGratuits.
  Future<int> getTotalNotesCount() async {
    final db = await database;
    // Les souvenirs d'amorçage sont exclus : ils n'ont pas été écrits par
    // l'utilisateur, ils ne doivent pas entamer son quota gratuit.
    final count = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM notes WHERE estAmorce = 0"),
    );
    return count ?? 0;
  }

  /// Dépose les souvenirs d'amorçage dans un bocal vide.
  ///
  /// Sans effet si le bocal contient déjà quoi que ce soit : les testeurs
  /// déjà installés ne verront rien apparaître. Ces souvenirs sont marqués
  /// `estAmorce`, donc hors quota et hors paliers, mais restent de vrais
  /// souvenirs — tirables, affichables, supprimables.
  Future<void> amorcerBocal(List<String> textes, String themeId) async {
    if (textes.isEmpty) return;
    final db = await database;

    final int dejaPresents =
        Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM notes")) ?? 0;
    if (dejaPresents > 0) return;

    final List<SourireTheme> couleurs =
        List<SourireTheme>.from(SourireTheme.tousLesThemes)..shuffle();
    final DateTime maintenant = DateTime.now();

    final Batch batch = db.batch();
    for (int i = 0; i < textes.length; i++) {
      batch.insert('notes', {
        'text': textes[i],
        'photoPath': null,
        'themeLabel': themeId,
        'colorLabel': couleurs[i % couleurs.length].label,
        'categories': 'unclassified',
        // Dates légèrement décalées : sans ça l'historique les empile toutes
        // sur la même minute.
        'date': maintenant
            .subtract(Duration(minutes: textes.length - i))
            .toIso8601String(),
        'estAmorce': 1,
      });
    }

    await batch.commit(noResult: true);
    debugPrint("--- BDD SQL : ${textes.length} souvenirs d'amorçage déposés ---");
    await _notifierChangement();
  }

  /// Catégories créées par l'utilisateur, sans les catégories système.
  /// Utilisé par l'export : les catégories système existent déjà partout.
  Future<List<String>> getCategoriesPersonnalisees() async {
    final toutes = await _fetchCategoriesFromDb();
    return toutes.where((c) => !_systemCategories.contains(c)).toList();
  }

  /// Réinsère des souvenirs venant d'une archive de sauvegarde.
  ///
  /// Les doublons ont déjà été écartés par SauvegardeService : ici on écrit,
  /// on ne juge pas. Une seule transaction pour ne pas rafraîchir l'interface
  /// des centaines de fois.
  Future<void> insererSouvenirsImportes(List<NoteSourire> souvenirs) async {
    if (souvenirs.isEmpty) return;
    final db = await database;

    final Batch batch = db.batch();
    for (final NoteSourire souvenir in souvenirs) {
      final Map<String, dynamic> ligne = souvenir.toMap();
      // L'id est réattribué par SQLite : celui de l'archive n'a aucun sens ici.
      ligne.remove('id');
      batch.insert('notes', ligne);
    }
    await batch.commit(noResult: true);

    debugPrint("--- BDD SQL : ${souvenirs.length} souvenir(s) réimporté(s) ---");
    await _notifierChangement();
  }

  /// Vide entièrement le bocal : souvenirs, catégories personnalisées et
  /// masquages. Les fichiers photo sont effacés à part, par l'appelant, qui
  /// seul connaît le dossier de l'app.
  ///
  /// Retourne les chemins des photos qui étaient référencées, pour que
  /// l'appelant puisse les supprimer du disque.
  Future<List<String>> viderLeBocal() async {
    final db = await database;

    final List<String> photos = _dernieresNotes
        .map((NoteSourire n) => n.photoPath?.trim() ?? '')
        .where((String c) => c.isNotEmpty)
        .toList();

    final Batch batch = db.batch();
    batch.delete('notes');
    batch.delete('custom_categories');
    batch.delete('categories_masquees');
    await batch.commit(noResult: true);

    debugPrint("--- BDD SQL : bocal entièrement vidé ---");
    await _rechargerNotes();
    await _rechargerCategories();
    return photos;
  }

  // --- LES MÉTHODES CRUD MODIFIÉES POUR ACCÉDER À LA BDD ---
  //
  // Toutes rendent un Future, et non plus `void`. Sans cela, l'appelant ne
  // pouvait ni attendre la fin de l'écriture, ni intercepter une erreur : une
  // exception dans un `void async` remonte au gestionnaire global et fait
  // planter l'app sans message exploitable.

  // 1. Ajouter une catégorie
  Future<void> insertCategory(String name) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) return;

    final formattedName = cleanedName[0].toUpperCase() + cleanedName.substring(1);
    final currentCategories = await _fetchCategoriesFromDb();

    if (!currentCategories.contains(formattedName)) {
      final db = await database;
      await db.insert(
        'custom_categories',
        {'name': formattedName},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      debugPrint("--- BDD SQL : Nouvelle catégorie ajoutée : $formattedName ---");
      await _notifierChangementCategories();
    }
  }

  // 2. Supprimer une catégorie et mettre à jour les notes
  Future<void> deleteCategory(String categoryKey) async {
    final db = await database;

    if (_systemCategories.contains(categoryKey)) {
      // Une catégorie par défaut n'existe dans aucune table : elle est écrite
      // en dur dans [_systemCategories]. On ne peut donc pas la supprimer, on
      // la MASQUE — et le masquage, lui, est persistant.
      await db.insert(
        'categories_masquees',
        {'name': categoryKey},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } else {
      await db.delete('custom_categories', where: 'name = ?', whereArgs: [categoryKey]);
    }

    // Retrait de la catégorie sur les souvenirs qui la portent.
    //
    // EN UNE SEULE TRANSACTION. Chaque `update` isolé est une transaction
    // implicite, donc une écriture physique sur le disque : supprimer une
    // catégorie portée par cinq cents souvenirs figeait l'interface le temps
    // de cinq cents écritures.
    final notes = await _fetchNotesFromDb();
    final Batch batch = db.batch();
    int touchees = 0;

    for (final souvenir in notes) {
      if (!souvenir.categories.contains(categoryKey)) continue;

      final List<String> updatedCategories = List<String>.from(souvenir.categories)
        ..remove(categoryKey);
      if (updatedCategories.isEmpty) {
        updatedCategories.add("sans_categorie");
      }

      batch.update(
        'notes',
        souvenir.copyWith(categories: updatedCategories).toMap(),
        where: 'id = ?',
        whereArgs: [souvenir.id],
      );
      touchees++;
    }

    if (touchees > 0) await batch.commit(noResult: true);

    debugPrint("--- BDD SQL : Catégorie supprimée : $categoryKey, $touchees souvenir(s) mis à jour ---");
    await _notifierChangementCategories();
    await _notifierChangement();
  }

  // 3. Insérer un souvenir
  Future<void> insertNote(NoteSourire note) async {
    final List<String> categoriesFinales = note.categories.isEmpty ? ["sans_categorie"] : note.categories;
    final db = await database;

    final rawNote = {
      'text': note.text,
      'photoPath': note.photoPath,
      'themeLabel': note.themeLabel,
      'colorLabel': note.colorLabel,
      'categories': categoriesFinales.join(','),
      'date': note.date.toIso8601String(),
      'datePrise': note.datePrise?.toIso8601String(),
      'estAmorce': note.estAmorce ? 1 : 0,
    };

    await db.insert('notes', rawNote);
    debugPrint("--- BDD SQL : Note sauvegardée ---");
    await _notifierChangement();
  }

  // 4. Tirer un souvenir au sort
  //
  // Sans filtre de catégorie, c'est SQLite qui tire, et il ne rend qu'une
  // ligne : inutile de charger tout le bocal en mémoire pour n'en garder
  // qu'un. Avec filtre, on présélectionne en SQL sur la colonne texte avant
  // de vérifier finement en mémoire — `categories` stocke "cat1,cat2", donc
  // le `LIKE` peut rendre des faux positifs, jamais des faux négatifs.
  Future<NoteSourire?> getRandomNote({List<String>? categoriesCibles}) async {
    final db = await database;

    final bool filtre = categoriesCibles != null &&
        categoriesCibles.isNotEmpty &&
        !categoriesCibles.contains("all_categories");

    if (!filtre) {
      final List<Map<String, dynamic>> tirage =
          await db.rawQuery('SELECT * FROM notes ORDER BY RANDOM() LIMIT 1');
      if (tirage.isEmpty) return null;
      return NoteSourire.fromMap(tirage.first);
    }

    final String conditions =
        List<String>.filled(categoriesCibles.length, 'categories LIKE ?').join(' OR ');
    final List<String> motifs =
        categoriesCibles.map((String c) => '%$c%').toList();

    final List<Map<String, dynamic>> candidats = await db.rawQuery(
      'SELECT * FROM notes WHERE $conditions ORDER BY RANDOM() LIMIT 50',
      motifs,
    );

    // Vérification exacte : « couple » ne doit pas être tiré parce qu'une
    // catégorie personnalisée s'appelle « Couple de chats ».
    for (final Map<String, dynamic> ligne in candidats) {
      final NoteSourire souvenir = NoteSourire.fromMap(ligne);
      if (souvenir.categories.any((String c) => categoriesCibles.contains(c))) {
        return souvenir;
      }
    }
    return null;
  }

  // 5. Supprimer plusieurs notes
  Future<void> deleteMultipleNotes(List<NoteSourire> notesASupprimer) async {
    if (notesASupprimer.isEmpty) return;
    final db = await database;
    final batch = db.batch();

    for (var note in notesASupprimer) {
      batch.delete('notes', where: 'id = ?', whereArgs: [note.id]);
    }

    await batch.commit(noResult: true);
    debugPrint("--- BDD SQL : ${notesASupprimer.length} élément(s) supprimé(s) ---");
    await _notifierChangement();
  }

  // 6. Mettre à jour une note
  Future<void> updateNote(NoteSourire noteModifiee) async {
    final db = await database;
    final rowsAffected = await db.update(
      'notes',
      noteModifiee.toMap(),
      where: 'id = ?',
      whereArgs: [noteModifiee.id],
    );

    if (rowsAffected != 0) {
      debugPrint("--- BDD SQL : Souvenir ${noteModifiee.id} mis à jour ---");
      await _notifierChangement();
    } else {
      debugPrint("--- BDD ERREUR : Souvenir introuvable pour la mise à jour ---");
    }
  }
}

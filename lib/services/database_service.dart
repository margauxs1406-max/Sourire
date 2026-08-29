import 'dart:async';
import 'dart:io';
import 'dart:math';
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
      version: 4,
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
  }

  // --- NOTIFICATEURS INCHANGÉS (Mais ils lisent maintenant la base SQL) ---

  void _notifierChangement() async {
    // On s'assure que la BDD est bien initialisée avant de faire la requête
    await database; 
    final notes = await _fetchNotesFromDb();
    _notesStreamController.add(notes);
  }

  void _notifierChangementCategories() async {
    // On s'assure que la BDD est bien initialisée avant de faire la requête
    await database; 
    final categories = await _fetchCategoriesFromDb();
    _categoriesStreamController.add(categories);
  }

  Stream<List<NoteSourire>> getNotesStream() {
    // On déclenche la lecture en tâche de fond de manière sécurisée
    _notifierChangement();
    return _notesStreamController.stream;
  }

  Stream<List<String>> getCategoriesStream() {
    _notifierChangementCategories();
    return _categoriesStreamController.stream;
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

    // Tri STABLE : `List.sort` ne l'est pas en Dart, on départage donc
    // explicitement par la position d'origine.
    final List<String> tri = List<String>.from(disponibles);
    tri.sort((a, b) {
      final int ecart = (usages[b] ?? 0).compareTo(usages[a] ?? 0);
      if (ecart != 0) return ecart;
      return disponibles.indexOf(a).compareTo(disponibles.indexOf(b));
    });
    return tri;
  }

  /// Nombre de souvenirs portant chaque catégorie.
  ///
  /// Les catégories sont stockées en une seule colonne texte, "Cat1,Cat2" :
  /// pas de table de liaison, donc pas de `GROUP BY` possible. On compte donc
  /// en mémoire — sur quelques milliers de souvenirs c'est instantané, et
  /// cette lecture est déjà faite à chaque rafraîchissement du flux.
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
    _notifierChangementCategories();
  }

  /// `true` si au moins une catégorie par défaut a été supprimée — sert à
  /// n'afficher le bouton de restauration que quand il a un sens.
  Future<bool> aDesCategoriesParDefautMasquees() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories_masquees');
    return maps.isNotEmpty;
  }

  // --- EN EXCLUSIVITÉ : SANS CHANGEMENT DE SIGNATURE POUR TES ÉCRANS ---

  // Pour conserver la compatibilité synchrone sur certains de tes écrans existants
  List<String> getAllCategories() {
    // Note : Cette méthode risque de renvoyer uniquement le système au premier millième de seconde,
    // l'idéal est de migrer vers le stream. Mais on la laisse pour éviter le crash au boot.
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
    _notifierChangement();
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
    _notifierChangement();
  }

  // --- LES MÉTHODES CRUD MODIFIÉES POUR ACCÉDER À LA BDD ---

  // 1. Ajouter une catégorie
  void insertCategory(String name) async {
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
      _notifierChangementCategories();
    }
  }

  // 2. Supprimer une catégorie et mettre à jour les notes
  void deleteCategory(String categoryKey) async {
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

    // Parcourir et mettre à jour les notes qui contenailettent cette catégorie
    final notes = await _fetchNotesFromDb();
    for (var souvenir in notes) {
      if (souvenir.categories.contains(categoryKey)) {
        final List<String> updatedCategories = List<String>.from(souvenir.categories);
        updatedCategories.remove(categoryKey);
        
        if (updatedCategories.isEmpty) {
          updatedCategories.add("sans_categorie");
        }

        final updatedNote = souvenir.copyWith(categories: updatedCategories);
        await db.update(
          'notes',
          updatedNote.toMap(),
          where: 'id = ?',
          whereArgs: [souvenir.id],
        );
      }
    }
    debugPrint("--- BDD SQL : Catégorie supprimée : $categoryKey et souvenirs mis à jour ---");
    _notifierChangementCategories();
    _notifierChangement();
  }

  // 3. Insérer un souvenir
  void insertNote(NoteSourire note) async {
    final List<String> categoriesFinales = note.categories.isEmpty ? ["sans_categorie"] : note.categories;
    final db = await database;

    debugPrint("--- DEBUG insertNote : photoPath=${note.photoPath} | colorLabel='${note.colorLabel}' ---");

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
    _notifierChangement();
  }

  // 4. Tirer une note au sort (Asynchrone par nature avec la BDD, mais renvoie un Future maintenant)
  Future<NoteSourire?> getRandomNote({List<String>? categoriesCibles}) async {
    List<NoteSourire> notesFiltrees = await _fetchNotesFromDb();

    if (notesFiltrees.isEmpty) return null;

    if (categoriesCibles != null && 
        categoriesCibles.isNotEmpty && 
        !categoriesCibles.contains("all_categories")) {
      
      notesFiltrees = notesFiltrees.where((note) {
        return note.categories.any((cat) => categoriesCibles.contains(cat));
      }).toList();
    }

    if (notesFiltrees.isEmpty) return null;

    final random = Random();
    int randomIndex = random.nextInt(notesFiltrees.length);
    return notesFiltrees[randomIndex];
  }

  // 5. Insérer plusieurs photos (Sécurisé pour le changement d'UUID iOS)
  void insertMultiplePhotos({
    required List<String> photoPaths,
    required List<String> categories,
    required String themeLabel,
  }) async {
    final List<String> categoriesFinales = categories.isEmpty ? ["sans_categorie"] : categories;
    final db = await database;

    final batch = db.batch();

    for (String path in photoPaths) {
      final String cleanPath = path.replaceAll('file://', '').trim();
      final String pathEnregistrer = Platform.isIOS ? basename(cleanPath) : cleanPath;

      final randomLabel = SourireTheme.getRandomPhoto().label;
debugPrint("--- DEBUG couleur photo choisie : $randomLabel ---");

batch.insert('notes', {
  'text': null,
  'photoPath': pathEnregistrer,
  'themeLabel': themeLabel,
  'colorLabel': randomLabel,
  'categories': categoriesFinales.join(','),
  'date': DateTime.now().toIso8601String(),
});
    }

    await batch.commit(noResult: true);
    debugPrint("--- BDD SQL : ${photoPaths.length} photo(s) sauvegardée(s) de manière résiliente ---");
    _notifierChangement();
  }

  // 6. Supprimer plusieurs notes
  Future<void> deleteMultipleNotes(List<NoteSourire> notesASupprimer) async {
  final db = await database;
  final batch = db.batch();

  for (var note in notesASupprimer) {
    batch.delete('notes', where: 'id = ?', whereArgs: [note.id]);
  }

  await batch.commit(noResult: true);
  debugPrint("--- BDD SQL : ${notesASupprimer.length} élément(s) supprimé(s) ---");
  _notifierChangement();
}

  // 7. Mettre à jour une note
  void updateNote(NoteSourire noteModifiee) async {
    final db = await database;
    final rowsAffected = await db.update(
      'notes',
      noteModifiee.toMap(),
      where: 'id = ?',
      whereArgs: [noteModifiee.id],
    );

    if (rowsAffected != 0) {
      debugPrint("--- BDD SQL : Souvenir ${noteModifiee.id} mis à jour ---");
      _notifierChangement();
    } else {
      debugPrint("--- BDD ERREUR : Souvenir introuvable pour la mise à jour ---");
    }
  }
}
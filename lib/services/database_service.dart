import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';

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
      version: 1,
      onCreate: _onCreate,
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
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_categories(
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

  Future<List<String>> _fetchCategoriesFromDb() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('custom_categories');
    
    // Fusionner les catégories système et les catégories custom stockées en base
    final List<String> customList = maps.map((m) => m['name'] as String).toList();
    return [..._systemCategories, ...customList];
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
      print("--- BDD SQL : Nouvelle catégorie ajoutée : $formattedName ---");
      _notifierChangementCategories();
    }
  }

  // 2. Supprimer une catégorie et mettre à jour les notes
  void deleteCategory(String categoryKey) async {
    if (_systemCategories.contains(categoryKey)) return;

    final db = await database;
    // Supprimer de la table catégorie
    await db.delete('custom_categories', where: 'name = ?', whereArgs: [categoryKey]);

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
    print("--- BDD SQL : Catégorie supprimée : $categoryKey et souvenirs mis à jour ---");
    _notifierChangementCategories();
    _notifierChangement();
  }

  // 3. Insérer un souvenir
  void insertNote(NoteSourire note) async {
    final List<String> categoriesFinales = note.categories.isEmpty ? ["sans_categorie"] : note.categories;
    final db = await database;

    final rawNote = {
      'text': note.text,
      'photoPath': note.photoPath,
      'themeLabel': note.themeLabel,
      'colorLabel': note.colorLabel,
      'categories': categoriesFinales.join(','),
      'date': note.date.toIso8601String(),
    };

    await db.insert('notes', rawNote);
    print("--- BDD SQL : Note sauvegardée ---");
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
      // CORRECTION CONTRE LES IMAGES NOIRES : 
      // On extrait uniquement le nom du fichier ("image.jpg") pour éviter de stocker l'arborescence instable d'iOS.
      // On applique p.basename(path) uniquement si on est sur iOS, ou globalement si on veut uniformiser.
      final String cleanPath = path.replaceAll('file://', '').trim();
      final String pathEnregistrer = Platform.isIOS ? basename(cleanPath) : cleanPath;

      batch.insert('notes', {
        'text': null,
        'photoPath': pathEnregistrer,
        'themeLabel': themeLabel,
        'colorLabel': 'orange',
        'categories': categoriesFinales.join(','),
        'date': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
    print("--- BDD SQL : ${photoPaths.length} photo(s) sauvegardée(s) de manière résiliente ---");
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
  print("--- BDD SQL : ${notesASupprimer.length} élément(s) supprimé(s) ---");
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
      print("--- BDD SQL : Souvenir ${noteModifiee.id} mis à jour ---");
      _notifierChangement();
    } else {
      print("--- BDD ERREUR : Souvenir introuvable pour la mise à jour ---");
    }
  }
}
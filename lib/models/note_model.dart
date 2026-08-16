class NoteSourire {
  final int? id;
  final String? text;         
  final String? photoPath;    
  final String themeLabel;   
  final String colorLabel;   
  final List<String> categories;
  final DateTime date;

  /// Souvenir d'amorçage proposé à l'installation.
  ///
  /// Ce sont de vrais souvenirs — tirables, visibles dans l'historique,
  /// supprimables — mais ils ne comptent ni dans la limite gratuite ni dans
  /// les paliers de gamification : l'utilisateur ne les a pas écrits.
  final bool estAmorce;

  NoteSourire({
    this.id,
    this.text,
    this.photoPath,          
    required this.themeLabel,
    required this.colorLabel, 
    required this.categories,
    required this.date,
    this.estAmorce = false,
  });

  // --- COPIE / CONVERSION POUR SQLITE ---

  // 1. Convertit une ligne SQL (Map) en objet NoteSourire (Lecture)
  factory NoteSourire.fromMap(Map<String, dynamic> map) {
    return NoteSourire(
      id: map['id'] as int?,
      text: map['text'] as String?,
      photoPath: map['photoPath'] as String?,
      themeLabel: map['themeLabel'] as String? ?? 'orange',
      colorLabel: map['colorLabel'] as String? ?? 'orange',
      // On transforme la chaîne "Cat1,Cat2" en vraie List<String>
      categories: map['categories'] != null && (map['categories'] as String).isNotEmpty
          ? (map['categories'] as String).split(',')
          : [],
      // SQLite stocke les dates en chaînes de caractères (ISO8601), on la re-transforme en DateTime
      date: map['date'] != null 
          ? DateTime.parse(map['date'] as String) 
          : DateTime.now(),
      estAmorce: (map['estAmorce'] as int? ?? 0) == 1,
    );
  }

  // 2. Convertit un objet NoteSourire en Map pour SQLITE (Écriture)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'photoPath': photoPath,
      'themeLabel': themeLabel,
      'colorLabel': colorLabel,
      // On fusionne la liste ['Famille', 'Amis'] en une chaîne "Famille,Amis"
      'categories': categories.join(','),
      // On stocke la date au format texte standardisé ISO8601
      'date': date.toIso8601String(),
      'estAmorce': estAmorce ? 1 : 0,
    };
  }

  // Garde ton ancienne méthode copyWith ici...
  NoteSourire copyWith({
    int? id,
    String? text,
    String? photoPath,
    String? themeLabel,
    String? colorLabel,      
    List<String>? categories,
    DateTime? date,
    bool? estAmorce,
  }) {
    return NoteSourire(
      id: id ?? this.id,
      text: text ?? this.text,
      photoPath: photoPath ?? this.photoPath,
      themeLabel: themeLabel ?? this.themeLabel,
      colorLabel: colorLabel ?? this.colorLabel,
      categories: categories ?? this.categories,
      date: date ?? this.date,
      estAmorce: estAmorce ?? this.estAmorce,
    );
  }
}
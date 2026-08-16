class NoteSourire {
  final int? id;
  final String? text;         
  final String? photoPath;    
  final String themeLabel;   
  final String colorLabel;   
  final List<String> categories;

  /// Date d'ENTRÉE du souvenir dans le bocal. C'est elle, et elle seule, qui
  /// ordonne l'historique et le bocal : elle ne doit jamais être remplacée
  /// par la date d'origine d'une photo, sous peine de voir un souvenir
  /// importé aujourd'hui replonger au fond de l'historique.
  final DateTime date;

  /// Date à laquelle la photo a été PRISE, telle que la galerie du téléphone
  /// la connaît. `null` pour une note écrite : sa date d'écriture est déjà
  /// [date]. Purement informative — c'est elle qu'on affiche sur le souvenir.
  final DateTime? datePrise;

  /// Date à montrer à l'utilisateur : celle de la photo si on la connaît,
  /// sinon celle de l'entrée dans le bocal.
  DateTime get dateAffichee => datePrise ?? date;

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
    this.datePrise,
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
      datePrise: map['datePrise'] != null
          ? DateTime.tryParse(map['datePrise'] as String)
          : null,
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
      'datePrise': datePrise?.toIso8601String(),
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
    DateTime? datePrise,
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
      datePrise: datePrise ?? this.datePrise,
      estAmorce: estAmorce ?? this.estAmorce,
    );
  }
}
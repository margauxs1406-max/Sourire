import '../services/database_service.dart';

class StockageService {
  static Future<Map<String, String>> calculerEspaceOccupe() async {
    try {
      // CORRECTION SQLITE : On ajoute "await" et on appelle la méthode Async
      final toutesLesNotes = await DatabaseService().getAllNotesAsync();
      
      int octetsPhotos = 0;
      int octetsNotes = 0;

      // 2. Parcourir les notes pour simuler un poids réaliste
      for (var souvenir in toutesLesNotes) {
        if (souvenir.photoPath != null && souvenir.photoPath!.isNotEmpty) {
          // C'est une photo : on simule ~1.4 Mo par image
          octetsPhotos += 1468006; 
        }
        
        if (souvenir.text != null && souvenir.text!.isNotEmpty) {
          // C'est du texte : on simule ~1.2 Ko par note écrite
          octetsNotes += 1228;
        }
      }

      // 3. Retourner les tailles formatées
      return {
        'photos': _formaterTaille(octetsPhotos),
        'notes': _formaterTaille(octetsNotes),
      };
    } catch (e) {
      print("Erreur lors du calcul de l'espace simulé : $e");
      return {'photos': '0 Ko', 'notes': '0 Ko'};
    }
  }

  static String _formaterTaille(int octets) {
    if (octets <= 0) return "0 Ko";
    if (octets < 1024 * 1024) {
      return "${(octets / 1024).toStringAsFixed(1)} Ko";
    }
    return "${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo";
  }
}
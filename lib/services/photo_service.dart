import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/theme/user_prefs.dart';

/// Réduction et enregistrement des photos importées.
///
/// Jusqu'ici, importer une photo consistait à COPIER le fichier d'origine tel
/// quel dans le dossier de l'app. Une photo de téléphone récent pèse 3 à 6 Mo
/// pour 4000 px de côté : sur cinquante souvenirs, cela fait plus de 200 Mo à
/// lire et à décoder, d'où les lenteurs d'affichage qui s'aggravent à mesure
/// que le bocal se remplit.
///
/// On redimensionne donc à l'import. [coteMax] est très au-dessus de ce que
/// l'écran peut montrer — la plus grande vue d'un souvenir fait environ 400 px
/// logiques, soit 1200 px physiques sur un écran à 3× — ce qui laisse de la
/// marge pour le zoom de l'InteractiveViewer sans conserver d'inutile.
class PhotoService {
  PhotoService._();

  /// Côté le plus long après réduction, en pixels.
  static const int coteMax = 1600;

  /// Qualité JPEG. 82 est le point où l'œil ne distingue plus l'original sur
  /// une photo de vacances, alors que le fichier a déjà fondu d'un ordre de
  /// grandeur.
  static const int qualiteJpeg = 82;

  /// En dessous de ce poids, une photo est déjà légère : on ne la retouche pas.
  /// Recompresser un JPEG ne fait que dégrader l'image sans rien gagner.
  static const int seuilRecompression = 400 * 1024;

  // --- IMPORT -----------------------------------------------------------------

  /// Réduit [origine] et l'écrit dans le dossier de l'app.
  ///
  /// Retourne le chemin du fichier créé, ou `null` si l'opération a échoué.
  /// En cas d'échec du décodage — format exotique, fichier tronqué — on
  /// retombe sur une copie brute : mieux vaut une photo lourde que pas de
  /// photo du tout.
  static Future<String?> enregistrer(File origine) async {
    try {
      final Directory dossier = await getApplicationDocumentsDirectory();
      final String nom = "sourire_${DateTime.now().microsecondsSinceEpoch}.jpg";
      final String destination = p.join(dossier.path, nom);

      final Uint8List source = await origine.readAsBytes();
      final Uint8List? reduite = await _reduire(source);

      if (reduite == null) {
        debugPrint("Photo illisible par le décodeur : copie brute.");
        final File copie = await origine.copy(destination);
        return copie.path;
      }

      await File(destination).writeAsBytes(reduite, flush: true);
      debugPrint("Photo réduite : ${source.length ~/ 1024} Ko -> "
          "${reduite.length ~/ 1024} Ko");
      return destination;
    } catch (e) {
      debugPrint("Échec de l'enregistrement de la photo : $e");
      return null;
    }
  }

  // --- RATTRAPAGE -------------------------------------------------------------

  /// Réduit les photos déjà en base qui dépassent [seuilRecompression].
  ///
  /// Passe unique, jouée en tâche de fond au démarrage : les testeurs qui ont
  /// déjà importé des centaines de photos pleine résolution en profitent sans
  /// avoir à réimporter quoi que ce soit. Chaque fichier est réécrit SOUS LE
  /// MÊME NOM — la base n'a donc pas à être touchée, et une sauvegarde
  /// exportée avant la migration reste réimportable.
  ///
  /// Retourne le nombre de photos effectivement réduites.
  static Future<int> reduireLesAnciennes() async {
    if (UserPrefs.photosDejaReduites) return 0;

    int reduites = 0;
    try {
      final List<NoteSourire> souvenirs =
          await DatabaseService().getAllNotesAsync();

      for (final NoteSourire souvenir in souvenirs) {
        final String? chemin = souvenir.photoPath?.trim();
        if (chemin == null || chemin.isEmpty) continue;

        final File fichier = File(chemin);
        if (!await fichier.exists()) continue;
        if (await fichier.length() <= seuilRecompression) continue;

        final Uint8List? reduite = await _reduire(await fichier.readAsBytes());
        if (reduite == null) continue;

        // Écriture dans un fichier temporaire puis renommage : une coupure
        // au mauvais moment ne peut pas laisser un souvenir à moitié écrit.
        final File tampon = File('$chemin.tmp');
        await tampon.writeAsBytes(reduite, flush: true);
        await tampon.rename(chemin);
        reduites++;
      }

      UserPrefs.photosDejaReduites = true;
      debugPrint("Rattrapage terminé : $reduites photo(s) réduite(s).");
    } catch (e) {
      // Volontairement non marqué comme fait : on retentera au prochain
      // démarrage plutôt que d'abandonner les photos restantes.
      debugPrint("Rattrapage des photos interrompu : $e");
    }
    return reduites;
  }

  // --- MOTEUR -----------------------------------------------------------------

  /// Décode, redresse et réduit [source]. `null` si le décodage échoue.
  ///
  /// Le travail part dans un isolate : décoder un JPEG de 12 Mpx bloquerait
  /// l'interface une bonne demi-seconde par photo.
  static Future<Uint8List?> _reduire(Uint8List source) =>
      compute(_reduireDansIsolate, source);
}

/// Corps du redimensionnement, exécuté hors du thread d'interface.
///
/// Fonction de premier niveau et non méthode : c'est ce qu'exige `compute`.
Uint8List? _reduireDansIsolate(Uint8List source) {
  final img.Image? decodee = img.decodeImage(source);
  if (decodee == null) return null;

  // L'orientation d'une photo de téléphone vit dans ses métadonnées EXIF.
  // Le redimensionnement les perd : sans ce redressement préalable, les
  // photos prises à la verticale ressortiraient couchées.
  final img.Image droite = img.bakeOrientation(decodee);

  final int cote =
      droite.width > droite.height ? droite.width : droite.height;

  final img.Image finale = cote <= PhotoService.coteMax
      ? droite
      : img.copyResize(
          droite,
          width: droite.width >= droite.height ? PhotoService.coteMax : null,
          height: droite.width >= droite.height ? null : PhotoService.coteMax,
          interpolation: img.Interpolation.average,
        );

  return img.encodeJpg(finale, quality: PhotoService.qualiteJpeg);
}

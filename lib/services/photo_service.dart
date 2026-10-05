import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// Plus aucune couche d'accès à la photothèque ici : les photos arrivent sous
// forme de fichiers, remis un par un par le sélecteur du système. Ce service
// ne sait plus ce qu'est une galerie, et c'est très bien ainsi.
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

  // --- OÙ VIT UNE PHOTO -------------------------------------------------------

  /// Le fichier correspondant à un `photoPath` de la base.
  ///
  /// Sur iOS, le dossier de l'application change d'identifiant à chaque
  /// réinstallation et à chaque restauration : un chemin absolu enregistré
  /// hier peut ne plus exister demain. Seul le NOM du fichier est donc
  /// fiable, et le dossier se redemande au système à chaque fois.
  ///
  /// Cette résolution était recopiée dans trois fichiers, et OUBLIÉE dans
  /// [reduireLesAnciennes], qui ouvrait `File(chemin)` tel quel : sur iPhone,
  /// le fichier n'était jamais trouvé et la passe de réduction ne réduisait
  /// rien. Une seule fonction, utilisée partout, ferme la question.
  static Future<File?> fichierPhoto(String? chemin) async {
    final String propre = (chemin ?? '').replaceAll('file://', '').trim();
    if (propre.isEmpty) return null;

    final Directory dossier = await getApplicationDocumentsDirectory();
    final File candidat = File(p.join(dossier.path, p.basename(propre)));
    if (await candidat.exists()) return candidat;

    // Repli : chemin absolu d'origine, encore valable sur Android.
    final File direct = File(propre);
    if (await direct.exists()) return direct;

    return null;
  }

  /// Efface toutes les photos du dossier de l'application.
  /// Utilisé par « effacer tous mes souvenirs ». Retourne le nombre de
  /// fichiers supprimés.
  static Future<int> supprimerToutesLesPhotos() async {
    int supprimees = 0;
    try {
      final Directory dossier = await getApplicationDocumentsDirectory();
      await for (final FileSystemEntity entite in dossier.list()) {
        if (entite is! File) continue;
        final String nom = p.basename(entite.path);
        // On ne touche qu'aux fichiers écrits par Sourire : le dossier de
        // l'app contient aussi ce que posent les greffons.
        if (!nom.startsWith('sourire_')) continue;
        await entite.delete();
        supprimees++;
      }
    } catch (e) {
      debugPrint("Suppression des photos interrompue : $e");
    }
    return supprimees;
  }

  // --- IMPORT -----------------------------------------------------------------

  /// Enregistre une photo remise par le sélecteur du système.
  ///
  /// Le sélecteur fait déjà le gros du travail. On lui demande une image bornée
  /// à [coteMax] et compressée à [qualiteJpeg] : ce redimensionnement est
  /// exécuté par la plateforme, en natif, et rend un fichier déjà léger en
  /// quelques dizaines de millisecondes. C'est ce qui remplace l'ancienne voie
  /// rapide, qui demandait une vignette à `photo_manager` — et c'est la même
  /// idée : ne jamais décoder douze mégapixels avec le décodeur JPEG en Dart
  /// pur, qui met une à trois secondes par photo.
  ///
  /// Il reste donc seulement à ranger le fichier dans le dossier de
  /// l'application. S'il arrivait malgré tout au-dessus de
  /// [seuilRecompression] — sélecteur ancien, plateforme qui ignore les bornes
  /// — on repasse par [enregistrer], qui réduit en Dart. Mieux vaut trois
  /// secondes d'attente qu'une photo de six mégaoctets gardée à vie.
  static Future<String?> enregistrerDepuisSelecteur(File origine) async {
    try {
      final int poids = await origine.length();
      if (poids > seuilRecompression) {
        debugPrint("Photo encore lourde (${poids ~/ 1024} Ko) : réduction en Dart.");
        return enregistrer(origine);
      }

      final Directory dossier = await getApplicationDocumentsDirectory();
      final String destination = p.join(
        dossier.path,
        "sourire_${DateTime.now().microsecondsSinceEpoch}.jpg",
      );
      final File copie = await origine.copy(destination);
      debugPrint("Photo rangée telle quelle : ${poids ~/ 1024} Ko");
      return copie.path;
    } catch (e) {
      debugPrint("Rangement direct impossible ($e) : on réduit en Dart.");
      return enregistrer(origine);
    }
  }

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
        // Résolution centralisée : sur iOS la base ne stocke que le nom du
        // fichier, pas son chemin. Ouvrir `File(souvenir.photoPath)` ne
        // trouvait donc jamais rien sur iPhone.
        final File? fichier = await fichierPhoto(souvenir.photoPath);
        if (fichier == null) continue;
        if (await fichier.length() <= seuilRecompression) continue;

        final Uint8List? reduite = await _reduire(await fichier.readAsBytes());
        if (reduite == null) continue;

        // Écriture dans un fichier temporaire puis renommage : une coupure
        // au mauvais moment ne peut pas laisser un souvenir à moitié écrit.
        final File tampon = File('${fichier.path}.tmp');
        await tampon.writeAsBytes(reduite, flush: true);
        await tampon.rename(fichier.path);
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

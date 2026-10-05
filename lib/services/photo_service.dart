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

  /// Au-dessus de ce poids, un fichier sorti du sélecteur n'a visiblement PAS
  /// été redimensionné par la plateforme, et il faut le réduire nous-mêmes.
  ///
  /// Trois mégaoctets et non [seuilRecompression] : ce seuil-là vaut 400 Ko, ce
  /// qui est la bonne borne pour décider si une photo DÉJÀ en base mérite d'être
  /// recompressée, mais une très mauvaise pour un fichier qui sort du sélecteur.
  /// Une image de 1600 px en qualité 82 pèse couramment 300 à 600 Ko : avec
  /// l'ancien seuil, la plupart des photos repassaient par le décodeur Dart
  /// alors qu'elles étaient déjà à la bonne taille — une à trois secondes
  /// perdues PAR PHOTO, soit une demi-minute sur un lot de dix. C'était la
  /// latence ressentie sur « Passer » et « Valider ».
  static const int seuilSelecteurNonBorne = 3 * 1024 * 1024;

  /// Enregistre une photo remise par le sélecteur du système.
  ///
  /// Le sélecteur fait déjà le gros du travail. On lui demande une image bornée
  /// à [coteMax] et compressée à [qualiteJpeg] : ce redimensionnement est
  /// exécuté par la plateforme, en natif, et rend un fichier déjà léger en
  /// quelques dizaines de millisecondes. C'est ce qui remplace l'ancienne voie
  /// rapide, qui demandait une vignette à `photo_manager` — et c'est la même
  /// idée : ne jamais décoder douze mégapixels avec le décodeur JPEG en Dart
  /// pur.
  ///
  /// Il reste donc seulement à ranger le fichier. On ne retouche à rien tant
  /// qu'il reste sous [seuilSelecteurNonBorne] : recompresser un JPEG déjà
  /// compressé ne fait que le dégrader, lentement.
  static Future<String?> enregistrerDepuisSelecteur(File origine) async {
    try {
      final int poids = await origine.length();
      if (poids > seuilSelecteurNonBorne) {
        debugPrint("Photo non bornée (${poids ~/ 1024} Ko) : réduction en Dart.");
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

  /// La date de prise de vue lue dans les métadonnées EXIF, ou `null`.
  ///
  /// C'est le seul moyen de retrouver la vraie date d'une photo depuis le
  /// sélecteur du système : celui-ci remet un fichier et rien d'autre, jamais
  /// l'identifiant de l'image dans la photothèque. L'ancien sélecteur, lui,
  /// lisait la date dans l'index de la galerie — ce même index dont l'accès
  /// nous est désormais refusé.
  ///
  /// Les deux plateformes recopient l'EXIF dans le fichier redimensionné :
  /// Android par son `ExifDataCopier`, iOS en réinjectant le dictionnaire de
  /// métadonnées de l'image d'origine. La date survit donc au
  /// redimensionnement — mais au conditionnel, et c'est important :
  ///
  /// - la recopie échoue en silence des deux côtés, sans rien remonter ;
  /// - **beaucoup de photos n'ont aucune date EXIF** : captures d'écran,
  ///   images reçues par messagerie, visuels retouchés, exports de réseaux
  ///   sociaux.
  ///
  /// `null` n'est donc PAS une anomalie, c'est un cas de figure ordinaire que
  /// l'appelant doit traiter comme tel. Et la date obtenue reste une
  /// proposition : l'utilisateur peut toujours la corriger depuis le souvenir
  /// ouvert en grand.
  ///
  /// Aucun pixel n'est décodé ici. `decodeJpgExif` parcourt les marqueurs du
  /// fichier et s'arrête au premier segment EXIF rencontré.
  static Future<DateTime?> dateDePriseDeVue(File fichier) async {
    try {
      final Uint8List octets = await fichier.readAsBytes();
      final img.ExifData? exif = img.decodeJpgExif(octets);
      if (exif == null) return null;

      // DateTimeOriginal vit dans la sous-IFD Exif, et non dans l'IFD
      // principale. `DateTime` y est le repli : certains appareils ne
      // renseignent que celle-là.
      final String? brut = exif.exifIfd['DateTimeOriginal']?.toString() ??
          exif.imageIfd['DateTime']?.toString();
      if (brut == null) return null;

      // Format EXIF : « AAAA:MM:JJ HH:MM:SS ». Ce ne sont pas des tirets, et
      // DateTime.parse n'en veut pas.
      final RegExp forme = RegExp(
        r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
      );
      final Match? m = forme.firstMatch(brut.trim());
      if (m == null) return null;

      final DateTime lue = DateTime(
        int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!),
        int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6]!),
      );

      // Un appareil mal réglé peut dater une photo de 1970 ou de l'an
      // prochain. On refuse l'invraisemblable plutôt que de l'afficher sur un
      // souvenir partagé.
      if (lue.year < 1990 || lue.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        return null;
      }
      return lue;
    } catch (e) {
      debugPrint("Date EXIF illisible : $e");
      return null;
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

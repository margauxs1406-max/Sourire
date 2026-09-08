import 'dart:convert';
import 'dart:io';

// archive_io.dart et non archive.dart : `ZipFileEncoder` n'est exporté que
// par la partie du paquet qui s'appuie sur dart:io, et celle-ci réexporte
// tout le reste — `ZipDecoder` et `ArchiveFile` compris.
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/services/photo_service.dart';

/// Résultat d'un import, pour pouvoir dire à l'utilisateur ce qui s'est passé.
class ResultatImport {
  final bool succes;
  final int ajoutes;
  final int dejaPresents;

  const ResultatImport({
    required this.succes,
    this.ajoutes = 0,
    this.dejaPresents = 0,
  });

  static const ResultatImport echec = ResultatImport(succes: false);
}

/// Export et réimport du bocal, sous forme d'une archive que l'utilisateur
/// range où il veut.
///
/// C'est la réponse au besoin de sauvegarde sans toucher à la promesse de
/// l'app : aucun serveur, aucun compte. L'archive est fabriquée à la demande,
/// remise à la feuille de partage du système, et c'est l'utilisateur qui
/// décide de sa destination — Drive, Fichiers, un mail à lui-même.
class SauvegardeService {
  SauvegardeService._();

  /// Version du format d'archive. À incrémenter si la structure change, pour
  /// pouvoir refuser proprement une archive qu'on ne saurait pas relire.
  static const int versionFormat = 1;

  static const String _nomManifeste = 'souvenirs.json';
  static const String _dossierPhotos = 'photos';

  static final DatabaseService _bdd = DatabaseService();

  // --- EXPORT -----------------------------------------------------------------

  /// Fabrique l'archive et ouvre la feuille de partage.
  ///
  /// Retourne `false` uniquement si la fabrication a échoué : un partage
  /// abandonné par l'utilisateur reste un succès.
  static Future<bool> exporter({Rect? origineIpad}) async {
    File? archiveFichier;
    File? manifesteFichier;

    try {
      final List<NoteSourire> souvenirs = await _bdd.getAllNotesAsync();
      final List<String> categories = await _bdd.getCategoriesPersonnalisees();

      final Directory dossier = await getTemporaryDirectory();
      await _nettoyerAnciennesArchives(dossier);

      final String horodatage =
          DateTime.now().toIso8601String().substring(0, 10);
      archiveFichier = File(p.join(dossier.path, 'sourire-$horodatage.zip'));
      if (await archiveFichier.exists()) await archiveFichier.delete();

      // ÉCRITURE EN FLUX, et non plus en mémoire.
      //
      // L'export construisait auparavant un objet `Archive` contenant les
      // octets de TOUTES les photos, puis en produisait le ZIP complet, lui
      // aussi entièrement en mémoire. Sur trois cents photos cela demandait
      // près de deux cents mégaoctets d'un coup, et le système tuait
      // l'application avant la fin. `ZipFileEncoder` lit et compresse un
      // fichier à la fois, directement vers le disque : le pic mémoire ne
      // dépend plus du nombre de souvenirs.
      final ZipFileEncoder encodeur = ZipFileEncoder();
      encodeur.create(archiveFichier.path);

      final List<Map<String, dynamic>> manifesteSouvenirs = [];
      final Set<String> nomsDejaAjoutes = <String>{};

      for (final NoteSourire souvenir in souvenirs) {
        String? nomPhoto;

        final File? photo = await PhotoService.fichierPhoto(souvenir.photoPath);
        if (photo != null) {
          // On ne garde que le nom du fichier : le chemin absolu de l'app
          // change à chaque réinstallation, il ne veut rien dire ailleurs.
          nomPhoto = p.basename(photo.path);
          // Deux souvenirs peuvent pointer le même fichier : on ne l'écrit
          // qu'une fois dans l'archive.
          if (nomsDejaAjoutes.add(nomPhoto)) {
            // Niveau 0, sans compression : un JPEG est déjà compressé, le
            // deflater s'épuiserait pour un gain nul. Sur trois cents photos,
            // c'est plusieurs dizaines de secondes gagnées.
            await encodeur.addFile(photo, '$_dossierPhotos/$nomPhoto', 0);
          }
        }

        manifesteSouvenirs.add({
          'text': souvenir.text,
          'photo': nomPhoto,
          'themeLabel': souvenir.themeLabel,
          'colorLabel': souvenir.colorLabel,
          'categories': souvenir.categories,
          'date': souvenir.date.toIso8601String(),
          'datePrise': souvenir.datePrise?.toIso8601String(),
          'estAmorce': souvenir.estAmorce,
        });
      }

      final Map<String, dynamic> manifeste = {
        'format': versionFormat,
        'exporteLe': DateTime.now().toIso8601String(),
        'categoriesPersonnalisees': categories,
        'souvenirs': manifesteSouvenirs,
      };

      // Le manifeste passe par un fichier temporaire : `ZipFileEncoder`
      // travaille à partir de fichiers, pas d'octets en mémoire.
      manifesteFichier = File(p.join(dossier.path, _nomManifeste));
      await manifesteFichier.writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifeste),
        flush: true,
      );
      await encodeur.addFile(manifesteFichier, _nomManifeste);

      await encodeur.close();
      await manifesteFichier.delete();
      manifesteFichier = null;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(archiveFichier.path, mimeType: 'application/zip')],
          sharePositionOrigin: origineIpad,
        ),
      );
      return true;
    } catch (e) {
      debugPrint("Export impossible : $e");
      return false;
    } finally {
      // Le manifeste ne doit jamais rester derrière, même en cas d'échec.
      // L'archive, elle, est laissée en place : la feuille de partage peut
      // encore être en train de la lire. Elle sera balayée au prochain export
      // par [_nettoyerAnciennesArchives].
      try {
        if (manifesteFichier != null && await manifesteFichier.exists()) {
          await manifesteFichier.delete();
        }
      } catch (_) {
        // Un fichier temporaire non effacé n'est pas une raison de faire
        // échouer un export réussi.
      }
    }
  }

  /// Efface les archives des exports précédents.
  ///
  /// Elles s'accumulaient dans le dossier temporaire, un fichier de plusieurs
  /// dizaines de mégaoctets à chaque sauvegarde.
  static Future<void> _nettoyerAnciennesArchives(Directory dossier) async {
    try {
      await for (final FileSystemEntity entite in dossier.list()) {
        if (entite is! File) continue;
        final String nom = p.basename(entite.path);
        if (!nom.startsWith('sourire-') || !nom.endsWith('.zip')) continue;
        await entite.delete();
      }
    } catch (e) {
      debugPrint("Nettoyage des anciennes archives interrompu : $e");
    }
  }

  // --- IMPORT -----------------------------------------------------------------

  /// Laisse l'utilisateur choisir une archive et y ajoute les souvenirs
  /// manquants.
  ///
  /// L'import est volontairement ADDITIF : il ne supprime jamais rien et
  /// ignore les souvenirs déjà présents. Restaurer une vieille sauvegarde ne
  /// peut donc pas effacer ce qui a été écrit depuis.
  ///
  /// Retourne `null` si l'utilisateur a simplement refermé le sélecteur.
  static Future<ResultatImport?> importer() async {
    FilePickerResult? choix;
    try {
      choix = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
    } catch (e) {
      debugPrint("Sélecteur de fichier indisponible : $e");
      return ResultatImport.echec;
    }

    final String? chemin = choix?.files.single.path;
    if (chemin == null) return null; // annulé par l'utilisateur

    try {
      final List<int> octets = await File(chemin).readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(octets);

      final ArchiveFile? manifesteFichier = archive.files
          .cast<ArchiveFile?>()
          .firstWhere((f) => f?.name == _nomManifeste, orElse: () => null);
      if (manifesteFichier == null) return ResultatImport.echec;

      final Map<String, dynamic> manifeste = jsonDecode(
        utf8.decode(manifesteFichier.readBytes() ?? <int>[]),
      ) as Map<String, dynamic>;

      final int format = manifeste['format'] as int? ?? 0;
      if (format > versionFormat) {
        // Archive produite par une version plus récente de l'app.
        debugPrint("Format d'archive $format non pris en charge");
        return ResultatImport.echec;
      }

      // Photos : réécrites dans le dossier de l'app, sous leur nom d'origine.
      final Directory dossierApp = await getApplicationDocumentsDirectory();
      final Map<String, String> cheminsPhotos = {};

      for (final ArchiveFile fichier in archive.files) {
        if (!fichier.isFile || !fichier.name.startsWith('$_dossierPhotos/')) {
          continue;
        }
        final String nom = p.basename(fichier.name);
        final File destination = File(p.join(dossierApp.path, nom));
        final List<int>? octetsPhoto = fichier.readBytes();
        if (octetsPhoto != null && !await destination.exists()) {
          await destination.writeAsBytes(octetsPhoto);
        }
        cheminsPhotos[nom] = destination.path;
      }

      // Catégories personnalisées : ajoutées si absentes.
      for (final dynamic categorie
          in (manifeste['categoriesPersonnalisees'] as List<dynamic>? ?? [])) {
        _bdd.insertCategory(categorie as String);
      }

      // Souvenirs : on compare sur une signature stable plutôt que sur l'id,
      // qui est réattribué par SQLite à chaque insertion.
      final List<NoteSourire> existants = await _bdd.getAllNotesAsync();
      final Set<String> signatures = existants.map(_signature).toSet();

      final List<NoteSourire> aAjouter = [];
      int deja = 0;

      for (final dynamic brut
          in (manifeste['souvenirs'] as List<dynamic>? ?? [])) {
        final Map<String, dynamic> m = brut as Map<String, dynamic>;
        final String? nomPhoto = m['photo'] as String?;

        final NoteSourire souvenir = NoteSourire(
          text: m['text'] as String?,
          photoPath: nomPhoto == null ? null : cheminsPhotos[nomPhoto],
          themeLabel: m['themeLabel'] as String? ?? 'classique',
          colorLabel: m['colorLabel'] as String? ?? 'orange',
          categories: (m['categories'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
          date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
          datePrise: DateTime.tryParse(m['datePrise'] as String? ?? ''),
          estAmorce: m['estAmorce'] as bool? ?? false,
        );

        if (signatures.contains(_signature(souvenir))) {
          deja++;
        } else {
          signatures.add(_signature(souvenir));
          aAjouter.add(souvenir);
        }
      }

      await _bdd.insererSouvenirsImportes(aAjouter);

      return ResultatImport(
        succes: true,
        ajoutes: aAjouter.length,
        dejaPresents: deja,
      );
    } catch (e) {
      debugPrint("Import impossible : $e");
      return ResultatImport.echec;
    }
  }

  /// Identité d'un souvenir indépendante de son id : date à la seconde,
  /// texte, et nom du fichier photo.
  static String _signature(NoteSourire souvenir) {
    final String photo = souvenir.photoPath == null || souvenir.photoPath!.isEmpty
        ? ''
        : p.basename(souvenir.photoPath!);
    return '${souvenir.date.toIso8601String()}|${souvenir.text ?? ''}|$photo';
  }
}

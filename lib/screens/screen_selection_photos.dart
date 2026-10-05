import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sourire/main.dart';
import 'package:sourire/screens/screen_categorisation_photo.dart';
import 'package:sourire/services/photo_service.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/widgets/logo_sourire.dart';

/// L'antichambre du sélecteur de photos.
///
/// ## Pourquoi cet écran existe
///
/// Le sélecteur du système n'est pas une page de Sourire : c'est une activité
/// à part, qui recouvre l'application puis se retire. Quand elle se retire,
/// l'écran qui réapparaît est celui qui était là avant — et c'était l'accueil,
/// avec son bocal, son titre et ses deux boutons. L'utilisateur voyait donc
/// l'accueil réapparaître une fraction de seconde, puis glisser vers l'écran
/// de catégorisation. Deux changements d'écran là où il n'avait rien demandé :
/// ça se lit comme une application qui rame, et c'était le cas.
///
/// Cet écran est simplement posé À LA PLACE de l'accueil avant d'ouvrir le
/// sélecteur. Au retour, le décor n'a donc pas bougé — mêmes fond, même
/// bandeau, même logo que l'écran de catégorisation qui va le remplacer. Le
/// contenu se remplit, c'est tout. Il n'y a plus de retour à l'accueil, et
/// plus de transition entre le sélecteur et la catégorisation.
///
/// ## Il porte aussi la boucle
///
/// Le chevron de retour du premier écran de catégorisation renvoie
/// [retourVersGalerie] : il faut alors ROUVRIR le sélecteur, et non retomber
/// sur l'accueil. Cette boucle vivait dans la home, qui redevenait donc
/// visible à chaque aller-retour. Elle vit maintenant ici, sous l'écran de
/// catégorisation, là où elle ne se voit pas.
class ScreenSelectionPhotos extends StatefulWidget {
  /// Nombre maximal de photos sélectionnables, déjà borné par la place qui
  /// reste avant la limite gratuite.
  final int maxPhotos;

  const ScreenSelectionPhotos({required this.maxPhotos, super.key});

  @override
  State<ScreenSelectionPhotos> createState() => _ScreenSelectionPhotosState();
}

class _ScreenSelectionPhotosState extends State<ScreenSelectionPhotos> {
  final ImagePicker _selecteur = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Après la première image : le sélecteur s'ouvre une fois que cet écran
    // est réellement peint, sinon c'est l'accueil qui reste visible derrière
    // lui et on n'aurait rien gagné.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ouvrirSelecteur();
    });
  }

  Future<void> _ouvrirSelecteur() async {
    while (true) {
      final List<XFile> choisies;

      try {
        if (widget.maxPhotos <= 1) {
          // Une seule place avant la limite gratuite : la sélection multiple
          // n'a plus de sens, et `limit: 1` n'est pas accepté par toutes les
          // versions du greffon.
          final XFile? une = await _selecteur.pickImage(
            source: ImageSource.gallery,
            maxWidth: PhotoService.coteMax.toDouble(),
            maxHeight: PhotoService.coteMax.toDouble(),
            imageQuality: PhotoService.qualiteJpeg,
          );
          choisies = une == null ? const <XFile>[] : <XFile>[une];
        } else {
          choisies = await _selecteur.pickMultiImage(
            limit: widget.maxPhotos,
            maxWidth: PhotoService.coteMax.toDouble(),
            maxHeight: PhotoService.coteMax.toDouble(),
            imageQuality: PhotoService.qualiteJpeg,
          );
        }
      } catch (e) {
        debugPrint("Sélecteur de photos indisponible : $e");
        _refermer();
        return;
      }

      if (!mounted) return;

      // Sélecteur fermé sans rien choisir : l'utilisateur voulait sortir. On
      // s'efface, et il retrouve l'accueil.
      if (choisies.isEmpty) {
        _refermer();
        return;
      }

      // Le reste de l'application ne manipule que des fichiers : elle n'a
      // aucune notion de photothèque, et ne doit pas en acquérir une.
      final List<File> fichiers =
          choisies.map((XFile x) => File(x.path)).toList();

      final Object? retour = await Navigator.push<Object?>(
        context,
        // SANS ANIMATION, et c'est le cœur du correctif.
        //
        // Cet écran et celui de catégorisation partagent exactement le même
        // fond et le même bandeau : les faire glisser l'un sur l'autre
        // montrerait un mouvement sans rien à voir bouger. Sans transition, le
        // contenu apparaît simplement, comme si l'écran s'était rempli.
        PageRouteBuilder<Object?>(
          // Trois `_` et non `_`, `__`, `___` : depuis Dart 3.7, plusieurs
          // paramètres peuvent porter le même nom joker sans se gêner.
          pageBuilder: (_, _, _) => ScreenCategorisationPhoto(photos: fichiers),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );

      // L'enregistrement d'un souvenir remonte jusqu'à l'accueil par un
      // `popUntil` : cet écran n'existe alors plus, et il n'y a rien à faire.
      if (!mounted) return;

      // Tout sauf `retourVersGalerie` termine le parcours.
      if (retour != retourVersGalerie) {
        _refermer();
        return;
      }
      // Sinon la boucle repart, et le sélecteur se rouvre par-dessus cet
      // écran — jamais par-dessus l'accueil.
    }
  }

  void _refermer() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = MyApp.themeNotifier.value;
    final bool sombre = mode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : mode == ThemeMode.dark;

    // Le décor de l'écran de catégorisation, et rien d'autre. Pas de toupie :
    // cet écran n'est visible qu'un instant, et une toupie qui clignote
    // raconte une attente là où il n'y en a pas.
    return Scaffold(
      backgroundColor: sombre ? darkBg : white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SizedBox(
            height: 60,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    child: BtnChevronGauche(onTap: _refermer),
                  ),
                  const LogoSourire(color: orange),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

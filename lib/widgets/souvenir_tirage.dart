import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/screens/screen_profil.dart';
import 'package:sourire/models/theme_app.dart'; 

SourireTheme _getThemeFromColorLabel(String? colorLabel) {
  switch (colorLabel) {
    case 'vert':
      return SourireTheme(main: green, light: lightGreen, label: 'vert');
    case 'bleu':
      return SourireTheme(main: blue, light: lightBlue, label: 'bleu');
    case 'rose':
      return SourireTheme(main: pink, light: lightPink, label: 'rose');
    case 'orange':
    default:
      return SourireTheme(main: orange, light: lightOrange, label: 'orange');
  }
}

class WidgetSouvenirTirage extends StatefulWidget {
  final NoteSourire souvenir;

  const WidgetSouvenirTirage({required this.souvenir, super.key});

  @override
  State<WidgetSouvenirTirage> createState() => _WidgetSouvenirTirageState();
}

class _WidgetSouvenirTirageState extends State<WidgetSouvenirTirage> {
  ScrollController? _scrollController;
  Size? _lastCalculatedSize;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  // Force le positionnement au centre exact après le calcul du layout
  void _centrerLeScroll(Size imageSize, double bocalSize) {
    if (_lastCalculatedSize == imageSize) return;
    _lastCalculatedSize = imageSize;

    final bool isPaysage = imageSize.width > imageSize.height;
    double targetOffset = 0.0;

    if (isPaysage) {
      final double renduWidth = (imageSize.width * bocalSize) / imageSize.height;
      targetOffset = (renduWidth - bocalSize) / 2;
    } else {
      final double renduHeight = (imageSize.height * bocalSize) / imageSize.width;
      targetOffset = (renduHeight - bocalSize) / 2;
    }

    if (targetOffset > 0 && _scrollController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController!.hasClients) {
          _scrollController!.jumpTo(targetOffset);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCouleur = _getThemeFromColorLabel(widget.souvenir.colorLabel);
    final bool isPhoto = widget.souvenir.photoPath != null && widget.souvenir.photoPath!.trim().isNotEmpty;

    final ThemeApp themeGraphique = ThemeRepository.tousLesThemes.firstWhere(
      (t) => t.id.toLowerCase() == widget.souvenir.themeLabel.toLowerCase(),
      orElse: () => ThemeRepository.themeClassique,
    );

    debugPrint("ID recherché: '${widget.souvenir.themeLabel}' -> Trouvé dans le Repo: '${themeGraphique.id}'");

    Uint8List? imageBytes;
    if (isPhoto) {
      try {
        final cleanPath = widget.souvenir.photoPath!.replaceAll('file://', '').trim();
        final file = File(cleanPath);
        if (file.existsSync()) {
          imageBytes = file.readAsBytesSync();
        }
      } catch (e) {
        debugPrint("Erreur lecture photo : $e");
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = constraints.maxWidth;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isPhoto ? Colors.transparent : themeCouleur.light,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ==========================================
                // COUCHE 1 : LES ICÔNES EN ARRIÈRE-PLAN
                // ==========================================
                if (!isPhoto && themeGraphique.noteIcons.isNotEmpty)
                  ...themeGraphique.noteIcons.map((iconConfig) {
                    return Positioned(
                      left: iconConfig.getX(size),
                      top: iconConfig.getY(size),
                      width: iconConfig.getWidth(size),
                      height: iconConfig.getHeight(size),
                      child: Transform.rotate(
                        angle: iconConfig.rotation * math.pi / 180,
                        child: Opacity(
                          opacity: themeGraphique.noteIconOpacity,
                          child: SvgPicture.asset(
                            iconConfig.assetPath,
                            colorFilter: ColorFilter.mode(
                              themeCouleur.main,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                // ==========================================
                // COUCHE 2 : LE CONTENU (TEXTE OU PHOTO INTEGRALE SCROLLABLE ET CENTREE)
                // ==========================================
                Positioned.fill(
                  child: isPhoto
                      ? (imageBytes != null && imageBytes.isNotEmpty
                          ? FutureBuilder<Size>(
                              future: _getImageSize(imageBytes),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();
                                
                                final imageSize = snapshot.data!;
                                final bool isPaysage = imageSize.width > imageSize.height;

                                // Déclenche le repositionnement au centre exact
                                _centrerLeScroll(imageSize, size);

                                // Calcul précis des dimensions réelles de l'image
                                final double? imageWidth = isPaysage ? null : size;
                                final double? imageHeight = isPaysage ? size : null;

                                return SingleChildScrollView(
                                  controller: _scrollController,
                                  scrollDirection: isPaysage ? Axis.horizontal : Axis.vertical,
                                  physics: const BouncingScrollPhysics(),
                                  child: SizedBox(
                                    width: isPaysage ? (imageSize.width * size) / imageSize.height : size,
                                    height: isPaysage ? size : (imageSize.height * size) / imageSize.width,
                                    child: Image.memory(
                                      imageBytes!,
                                      width: imageWidth,
                                      height: imageHeight,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            )
                          : SizedBox(
                              height: size,
                              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                            ))
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Container(
                            constraints: BoxConstraints(minHeight: size),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(25),
                            child: Text(
                              widget.souvenir.text ?? "",
                              textAlign: TextAlign.center,
                              style: styleNoteLarge.copyWith(
                                color: themeCouleur.main,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Size> _getImageSize(Uint8List bytes) async {
    final image = await decodeImageFromList(bytes);
    return Size(image.width.toDouble(), image.height.toDouble());
  }
}

void afficherSouvenirBocal(BuildContext context, NoteSourire souvenir) {
  final int dureeAnimation = ScreenProfil.animationsDoucesActive ? 400 : 800;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Fermer",
    barrierColor: black.withOpacity(0.25),
    transitionDuration: Duration(milliseconds: dureeAnimation),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double tailleCarree = constraints.maxWidth;

              return Container(
                width: tailleCarree,
                height: tailleCarree,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: WidgetSouvenirTirage(souvenir: souvenir),
                ),
              );
            },
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      if (ScreenProfil.animationsDoucesActive) {
        return Opacity(
          opacity: anim1.value,
          child: child,
        );
      } else {
        return Transform.rotate(
          angle: (1 - anim1.value) * 12.5,
          child: Transform.scale(
            scale: anim1.value,
            child: Opacity(
              opacity: anim1.value,
              child: child,
            ),
          ),
        );
      }
    },
  );
}
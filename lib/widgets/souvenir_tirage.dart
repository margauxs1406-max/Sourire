import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui; // Importation essentielle pour le décodeur brut
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/screens/screen_profil.dart';
import 'package:sourire/models/theme_app.dart'; 
import 'package:sourire/widgets/souvenir_historique.dart'; // Cache partagé

/// Résolution des thèmes de couleur de l'application
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
  Uint8List? _imageBytes;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _verifierEtChargerImage();
  }

  /// Vérifie d'abord le cache PARTAGÉ (le même que l'historique) de façon
  /// SYNCHRONE. Comme chaque photo est préchargée dès son insertion en
  /// base, ce cache est quasiment toujours déjà "chaud" au moment d'un
  /// tirage — donc l'image est prête dès la toute première frame, sans
  /// délai visible entre l'apparition du cadre/ombre et la photo.
  void _verifierEtChargerImage() {
    final bool isPhoto = widget.souvenir.photoPath != null && widget.souvenir.photoPath!.trim().isNotEmpty;
    if (!isPhoto) {
      _isLoaded = true; // Pas d'image à charger pour une note texte
      return;
    }

    final String pathKey = widget.souvenir.photoPath!.trim();
    final Uint8List? cached = getCachedHistoriqueImageBytes(pathKey);

    if (cached != null) {
      _imageBytes = cached;
      _isLoaded = true;
    } else {
      // Cas rare (photo jamais encore préchargée) : on charge, ce qui
      // alimentera au passage le cache partagé pour la prochaine fois.
      _chargerImageAsynchrone(pathKey);
    }
  }

  Future<void> _chargerImageAsynchrone(String pathKey) async {
    await preloadHistoriqueImage(pathKey);
    _imageBytes = getCachedHistoriqueImageBytes(pathKey);
    if (mounted) {
      setState(() { _isLoaded = true; });
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

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

    if (!_isLoaded && _imageBytes == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
                Positioned.fill(
                  child: isPhoto
                      ? (_imageBytes != null && _imageBytes!.isNotEmpty
                          ? FutureBuilder<Size>(
                              future: _getImageSize(_imageBytes!),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();
                                
                                final imageSize = snapshot.data!;
                                final bool isPaysage = imageSize.width > imageSize.height;

                                _centrerLeScroll(imageSize, size);

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
                                      _imageBytes!,
                                      width: imageWidth,
                                      height: imageHeight,
                                      fit: isPaysage ? BoxFit.fitHeight : BoxFit.fitWidth,
                                      gaplessPlayback: true,
                                      cacheWidth: null,
                                      cacheHeight: null,
                                    ),
                                  ),
                                );
                              },
                            )
                          : SizedBox(
                              height: size,
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                              ),
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
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(buffer);
    return Size(descriptor.width.toDouble(), descriptor.height.toDouble());
  }
}

/// Affiche l'overlay dialog contenant le widget du souvenir pioché
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
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/screens/screen_profil.dart';
import 'package:sourire/models/theme_app.dart'; 

final Map<String, Uint8List> _globalImageCache = {};

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
    _chargerImageBytes();
  }

  Future<void> _chargerImageBytes() async {
    final bool isPhoto = widget.souvenir.photoPath != null && widget.souvenir.photoPath!.trim().isNotEmpty;
    if (!isPhoto) {
      if (mounted) setState(() { _isLoaded = true; });
      return;
    }

    final String pathKey = widget.souvenir.photoPath!.trim();

    if (_globalImageCache.containsKey(pathKey)) {
      _imageBytes = _globalImageCache[pathKey];
      if (mounted) setState(() { _isLoaded = true; });
      return;
    }

    try {
      final cleanPath = pathKey.replaceAll('file://', '');
      File file;

      if (Platform.isIOS) {
        final String fileName = p.basename(cleanPath);
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        file = File(p.join(appDocDir.path, fileName));
      } else {
        file = File(cleanPath);
      }

      if (file.existsSync()) {
        _imageBytes = file.readAsBytesSync();
        _globalImageCache[pathKey] = _imageBytes!;
      }
    } catch (e) {
      debugPrint("Erreur lecture photo tirage : $e");
    }

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

                                // On calcule proprement les dimensions cibles globales
                                final double scrollAreaWidth = isPaysage ? (imageSize.width * size) / imageSize.height : size;
                                final double scrollAreaHeight = isPaysage ? size : (imageSize.height * size) / imageSize.width;

                                return SingleChildScrollView(
                                  controller: _scrollController,
                                  scrollDirection: isPaysage ? Axis.horizontal : Axis.vertical,
                                  physics: const BouncingScrollPhysics(),
                                  child: SizedBox(
                                    width: scrollAreaWidth,
                                    height: scrollAreaHeight,
                                    child: Image.memory(
                                      _imageBytes!,
                                      // CORRECTION : On force l'image à occuper TOUTE la dimension calculée du SizedBox.
                                      // Cela oblige Flutter à afficher les zones "hors standard" (en haut et en bas)
                                      // qui étaient coupées par le 'null' précédent.
                                      width: scrollAreaWidth,
                                      height: scrollAreaHeight,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
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
    final image = await decodeImageFromList(bytes);
    return Size(image.width.toDouble(), image.height.toDouble());
  }
}
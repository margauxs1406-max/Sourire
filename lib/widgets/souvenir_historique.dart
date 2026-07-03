import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/models/theme_app.dart';

// Déclaration du cache partagé pour éliminer les accès asynchrones répétitifs au stockage
final Map<String, Uint8List> _historiqueImageCache = {};

/// Précharge une photo dans le cache mémoire partagé de l'historique, en
/// tâche de fond, SANS bloquer l'appelant (ne pas attendre son résultat).
/// À appeler juste après l'enregistrement d'une nouvelle photo (ex: dans
/// screen_categorisation_photo.dart), pour que l'image soit déjà prête en
/// mémoire quand l'utilisateur ouvre l'historique — évite le flash noir
/// de chargement à l'ouverture du volet.
Future<void> preloadHistoriqueImage(String? photoPath) async {
  if (photoPath == null || photoPath.trim().isEmpty) return;

  final String pathKey = photoPath.trim();

  // Déjà en cache : rien à faire.
  if (_historiqueImageCache.containsKey(pathKey) && _historiqueImageCache[pathKey]!.isNotEmpty) {
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
      final bytes = await file.readAsBytes();
      _historiqueImageCache[pathKey] = bytes;
      
    } else {
      
    }
  } catch (e) {
  }
}

class WidgetSouvenirHistorique extends StatefulWidget {
  final NoteSourire souvenir;

  const WidgetSouvenirHistorique({required this.souvenir, super.key});

  @override
  State<WidgetSouvenirHistorique> createState() => _WidgetSouvenirHistoriqueState();
}

class _WidgetSouvenirHistoriqueState extends State<WidgetSouvenirHistorique> {
  Uint8List? _cachedBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verifierEtChargerImage();
  }

  void _verifierEtChargerImage() {
  if (widget.souvenir.photoPath == null || widget.souvenir.photoPath!.trim().isEmpty) return;
  
  final String pathKey = widget.souvenir.photoPath!.trim();
  final bool dejaEnCache = _historiqueImageCache.containsKey(pathKey) && _historiqueImageCache[pathKey]!.isNotEmpty;
  
  
  if (dejaEnCache) {
    _cachedBytes = _historiqueImageCache[pathKey];
  } else {
    _chargerImageAsynchrone(pathKey);
  }
}

  Future<void> _chargerImageAsynchrone(String pathKey) async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

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
        final bytes = await file.readAsBytes();
        _historiqueImageCache[pathKey] = bytes;
        if (mounted) {
          setState(() {
            _cachedBytes = bytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _isLoading = false; });
      }
    } catch (e) {
      
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCouleur = SourireTheme.fromLabel(widget.souvenir.colorLabel);
    final bool isPhoto = widget.souvenir.photoPath != null && widget.souvenir.photoPath!.trim().isNotEmpty;

    final ThemeApp themeGraphique = ThemeRepository.tousLesThemes.firstWhere(
      (t) => t.id.toLowerCase() == widget.souvenir.themeLabel.toLowerCase(),
      orElse: () => ThemeRepository.themeClassique,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = constraints.maxWidth;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isPhoto ? const Color(0xFF1E1E1E) : themeCouleur.light,
            borderRadius: BorderRadius.circular(6), 
            border: isPhoto 
                ? null 
                : Border.all(
                    color: themeCouleur.main,
                    width: 1, 
                  ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
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
                        angle: (iconConfig.rotation) * math.pi / 180,
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
                      ? (_cachedBytes != null
                          ? Image.memory(
                              _cachedBytes!,
                              width: size,
                              height: size,
                              fit: BoxFit.cover,
                              cacheWidth: (size * MediaQuery.of(context).devicePixelRatio).round(),
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image, color: Colors.white, size: 24),
                                );
                              },
                            )
                          : Container(
                              color: const Color(0xFF1E1E1E),
                              child: Center(
                                child: _isLoading 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                      )
                                    : const Icon(Icons.broken_image, color: Colors.white54, size: 24),
                               ),
                            ))
                      : Container(
                          padding: EdgeInsets.all(size * 0.1),
                          alignment: Alignment.center,
                          child: Text(
                            widget.souvenir.text ?? "",
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: styleNoteLarge.copyWith(
                              color: themeCouleur.main,
                              fontSize: size * 0.09,
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
}
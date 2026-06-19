import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/models/note_model.dart';
import 'package:sourire/models/theme_app.dart';

class WidgetSouvenirHistorique extends StatelessWidget {
  final NoteSourire souvenir;

  const WidgetSouvenirHistorique({required this.souvenir, super.key});

  @override
  Widget build(BuildContext context) {
    final themeCouleur = SourireTheme.fromLabel(souvenir.colorLabel);
    final bool isPhoto = souvenir.photoPath != null && souvenir.photoPath!.trim().isNotEmpty;

    final ThemeApp themeGraphique = ThemeRepository.tousLesThemes.firstWhere(
      (t) => t.id.toLowerCase() == souvenir.themeLabel.toLowerCase(),
      orElse: () => ThemeRepository.themeClassique,
    );

    File? imageFile;
    if (isPhoto) {
      try {
        final cleanPath = souvenir.photoPath!.replaceAll('file://', '').trim();
        final file = File(cleanPath);
        if (file.existsSync()) {
          imageFile = file;
        }
      } catch (e) {
        debugPrint("Erreur accès photo historique : $e");
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = constraints.maxWidth;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isPhoto ? const Color(0xFF1E1E1E) : themeCouleur.light,
            borderRadius: BorderRadius.circular(6), 
            // Le contour s'applique uniquement si ce n'est PAS une photo
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
                // ——————————————
                // COUCHE 1 : LES ICÔNES DE THÈME (Uniquement si pas de photo)
                // ——————————————
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

                // ——————————————
                // COUCHE 2 : LE CONTENU
                // ——————————————
                Positioned.fill(
                  child: isPhoto
                      ? (imageFile != null
                          ? Image.file(
                              imageFile,
                              width: size,
                              height: size,
                              fit: BoxFit.cover,
                              cacheWidth: 150, 
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image, color: Colors.white, size: 24),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(Icons.broken_image, color: Colors.white, size: 24),
                            ))
                      : Container(
                          padding: EdgeInsets.all(size * 0.1),
                          alignment: Alignment.center,
                          child: Text(
                            souvenir.text ?? "",
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
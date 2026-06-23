import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/main.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/theme/theme_service.dart';
import 'package:sourire/theme/tokens.dart'; 
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';

class ScreenChoixThemes extends StatefulWidget {
  final bool isDarkMode;
  
  const ScreenChoixThemes({super.key, required this.isDarkMode});

  @override
  State<ScreenChoixThemes> createState() => _ScreenChoixThemesState();
}

class _ScreenChoixThemesState extends State<ScreenChoixThemes> {
  String _currentThemeId = (UserPrefs.themeId.isEmpty) 
      ? 'classique' 
      : UserPrefs.themeId;

  void _appliquerTheme(ThemeApp theme) {
    setState(() {
      _currentThemeId = theme.id;
      UserPrefs.themeId = theme.id;
    });

    // 1. MISE À JOUR DU THEME GLOBAL
    ThemeService.changerThemeVisuel(theme);

    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    MyApp.themeNotifier.notifyListeners(); 
  }

  void _ouvrirApercuTheme(BuildContext context, ThemeApp theme, Color textColor, Color dialogBgColor) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final double screenWidth = MediaQuery.of(dialogContext).size.width;
        final double screenHeight = MediaQuery.of(dialogContext).size.height;

        // Facteurs responsives pour la modale d'aperçu
        final double textScaleFactor = screenWidth / 390;
        final double sizeTitle = (screenWidth * 18) / 390;
        final double sizeButtonText = (screenWidth * 15) / 390;

        // CORRECTION : On se base maintenant sur UserPrefs.isPremium pour masquer le bouton définitivement
        final bool afficherBoutonPremium = theme.isPremium && !UserPrefs.isPremium;

        return Dialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(20.0 * textScaleFactor.clamp(0.8, 1.2)),
            child: SingleChildScrollView( 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    theme.label(context),
                    style: TextStyle(
                      fontSize: sizeTitle,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16 * textScaleFactor.clamp(0.8, 1.2)),
                  
                  // Image adaptative dans l'aperçu
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.45, 
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 0.78,
                          child: Image.asset(
                            theme.vignettePath,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: orange,
                                child: Icon(Icons.image_not_supported, color: Colors.white, size: 40 * textScaleFactor),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bouton d'action
                  SizedBox(height: 24 * textScaleFactor.clamp(0.8, 1.2)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        padding: EdgeInsets.symmetric(vertical: 14 * textScaleFactor.clamp(0.8, 1.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        
                        if (afficherBoutonPremium) {
                          ThemeService.deverrouillerPremium();
                          
                          // CORRECTION : Sauvegarde locale persistante pour que ça survive au redémarrage
                          UserPrefs.isPremium = true; 
                          
                          _appliquerTheme(theme);
                          setState(() {});
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.premiumSuccessSnackBar(theme.label(context))),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          _appliquerTheme(theme);
                        }
                      },
                      child: Text(
                        afficherBoutonPremium 
                            ? AppLocalizations.of(context)!.btnPasserPremium 
                            : AppLocalizations.of(context)!.btnAppliquer,
                        style: TextStyle(
                          color: white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: sizeButtonText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isDarkMode ? darkBg : white;
    final Color textColor = widget.isDarkMode ? white : black;
    final Color headerBgColor = widget.isDarkMode ? darkSurface : white;
    final Color dialogBgColor = widget.isDarkMode ? darkSurface : white;

    // Calculs de tailles responsives pour la grille principale
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = (screenWidth * 18) / 390;
    final double itemFontSize = (screenWidth * 14) / 390;
    final double iconScaleFactor = (screenWidth * 14) / 390;

    List<ThemeApp> themesTries = List.from(ThemeRepository.tousLesThemes);

    themesTries.sort((a, b) {
      if (a.id == 'classique') return -1;
      if (b.id == 'classique') return 1;
      return a.label(context).toLowerCase().compareTo(b.label(context).toLowerCase());
    });

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER FIXE UNIQUE
            Container(
              color: headerBgColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    child: BtnChevronGauche(
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const LogoSourire(color: orange),
                ],
              ),
            ),
            
            // CONTENU SCROLLABLE
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 30, right: 30, top: 20, bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.themesTitle,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 25),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: themesTries.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.70, 
                      ),
                      itemBuilder: (context, index) {
                        final theme = themesTries[index];
                        final bool isSelected = theme.id == _currentThemeId;

                        return GestureDetector(
                          onTap: () => _ouvrirApercuTheme(context, theme, textColor, dialogBgColor),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                theme.label(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: itemFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Stack(
                                  children: [
                                    // Affichage de l'image PNG (Contrainte par le layout parent étendu)
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          theme.vignettePath,
                                          fit: BoxFit.fill,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: orange,
                                              child: const Icon(Icons.image_not_supported, color: Colors.white),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    
                                    // Overlay de sélection (Coche blanche)
                                    if (isSelected)
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.check, color: orange, size: iconScaleFactor),
                                        ),
                                      ),

                                    // CORRECTION : Cadenas masqué définitivement si UserPrefs.isPremium est vrai
                                    if (theme.isPremium && !isSelected && !UserPrefs.isPremium)
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.lock_outline, color: Colors.white, size: iconScaleFactor),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
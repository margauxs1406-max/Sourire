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

  // Applique le thème définitivement
  // Applique le thème définitivement
  void _appliquerTheme(ThemeApp theme) {
    setState(() {
      _currentThemeId = theme.id;
      UserPrefs.themeId = theme.id;
    });

    // 1. MISE À JOUR DU THEME GLOBAL (Informe la Home et toute l'application)
    ThemeService.changerThemeVisuel(theme);

    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    MyApp.themeNotifier.notifyListeners(); 
  }

  void _ouvrirApercuTheme(BuildContext context, ThemeApp theme, Color textColor, Color dialogBgColor) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final double screenHeight = MediaQuery.of(dialogContext).size.height;

        // Détermination dynamique du texte du bouton de l'aperçu
        final bool afficherBoutonPremium = theme.isPremium && !ThemeService.estUtilisateurPremium;

        return Dialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView( 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    theme.label(context),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Image adaptative
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
                            fit: BoxFit.fill, // Optimisation anti-rognage
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: orange,
                                child: const Icon(Icons.image_not_supported, color: Colors.white, size: 40),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bouton d'action
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Ferme la modale
                        
                        if (afficherBoutonPremium) {
                          // 1. SIMULATION DU PAIEMENT REUSSI GLOBAL
                          ThemeService.deverrouillerPremium();
                          
                          // 2. Application immédiate du thème cliqué
                          _appliquerTheme(theme);
                          
                          // 3. Force le rafraîchissement complet pour faire sauter TOUS les verrous de la grille
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
                        style: const TextStyle(
                          color: white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 15,
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
                        fontSize: 18,
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
                        childAspectRatio: 0.78,
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
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Stack(
                                  children: [
                                    // Affichage de l'image PNG
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          theme.vignettePath,
                                          fit: BoxFit.fill, // Optimisation anti-rognage
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
                                          child: const Icon(Icons.check, color: orange, size: 14),
                                        ),
                                      ),

                                    // Overlay Premium (Cadenas masqué dynamiquement si premium)
                                    if (theme.isPremium && !isSelected && !ThemeService.estUtilisateurPremium)
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.lock_outline, color: Colors.white, size: 14),
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
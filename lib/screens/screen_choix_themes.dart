import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/theme/theme_service.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/apercu_theme_home.dart'; 
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
    // changerThemeVisuel affecte themeVisuelNotifier.value, ce qui notifie
    // déjà ses auditeurs — la Home écoute ce notifier. Le rebuild global
    // forcé qui suivait était redondant, et passait par une API que Flutter
    // marque comme protégée.
    ThemeService.changerThemeVisuel(theme);
  }

  void _ouvrirApercuTheme(BuildContext context, ThemeApp theme, Color textColor, Color dialogBgColor) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final double screenHeight = MediaQuery.of(dialogContext).size.height;

        // Facteurs responsives pour la modale d'aperçu, BORNÉS : sans borne,
        // ces formules indexées sur un écran de 390 pt donnaient un titre de
        // 47 pt sur un iPad.
        final double textScaleFactor = echelleEcran(dialogContext);
        final double sizeTitle = tailleAdaptee(dialogContext, 18);
        final double sizeButtonText = tailleAdaptee(dialogContext, 15);

        // CORRECTION : On se base maintenant sur UserPrefs.isPremium pour masquer le bouton définitivement
        final bool afficherBoutonPremium = theme.isPremium && !UserPrefs.isPremium;

        return Dialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(20.0 * textScaleFactor),
            child: SingleChildScrollView( 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    theme.label(context),
                    style: styleSection.copyWith(
                      fontSize: sizeTitle,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16 * textScaleFactor),
                  
                  // Image adaptative dans l'aperçu
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.45, 
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          // Plus large que la home réelle (393 / 852 ≈ 0,46) :
                          // la miniature est en BoxFit.cover, la différence de
                          // proportions se traduit donc par un rognage haut et
                          // bas. C'est voulu — ces marges sont vides, et les
                          // montrer en grand ne fait que rapetisser le décor.
                          aspectRatio: 0.72,
                          child: ApercuThemeHome(
                            theme: theme,
                            sombre: widget.isDarkMode,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bouton d'action
                  SizedBox(height: 24 * textScaleFactor),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        padding: EdgeInsets.symmetric(vertical: 14 * textScaleFactor),
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
                        textAlign: TextAlign.center,
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
    // Fond neutre sous les miniatures, et non le crème habituel : chaque
    // vignette EST une petite home crème, elle se fondrait dans un fond de la
    // même couleur.
    //
    // En mode sombre, le noir PUR et non le gris très sombre des surfaces :
    // c'est justement ce gris que les miniatures portent à l'intérieur. Les
    // deux côte à côte se confondraient, et les vignettes perdraient leur
    // contour.
    final Color bgColor = widget.isDarkMode ? black : white;
    final Color textColor = widget.isDarkMode ? white : black;
    // Le bandeau se fond dans l'écran : il porte donc la même couleur.
    final Color headerBgColor = bgColor;
    final Color dialogBgColor = widget.isDarkMode ? darkSurface : white;

    // Calculs de tailles responsives pour la grille principale, bornés.
    final double titleFontSize = tailleAdaptee(context, 18);
    final double itemFontSize = tailleAdaptee(context, 14);
    final double iconScaleFactor = tailleAdaptee(context, 14);

    // Deux colonnes de vignettes sur téléphone. Sur tablette, deux vignettes
    // occuperaient une demi-dalle chacune : on en met quatre, chaque aperçu
    // garde ainsi à peu près la taille pour laquelle il a été dessiné.
    final int colonnesThemes = estTablette(context) ? 4 : 2;

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
                      style: styleSection.copyWith(
                        fontSize: titleFontSize,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 25),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: themesTries.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: colonnesThemes,
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
                                style: styleCorps.copyWith(
                                  fontSize: itemFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Stack(
                                  children: [
                                    // Reconstitution vivante de la home sous ce
                                    // thème, à la place de l'ancienne vignette
                                    // PNG : plus d'image à redessiner quand la
                                    // home évolue, et le mode sombre suit.
                                    Positioned.fill(
                                      child: ApercuThemeHome(
                                        theme: theme,
                                        sombre: widget.isDarkMode,
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
                                            color: Colors.black.withValues(alpha: 0.3),
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
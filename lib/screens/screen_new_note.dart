import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sourire/main.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/models/theme_app.dart';
import 'package:sourire/theme/user_prefs.dart'; 
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/widgets/btn_action.dart';
import 'package:sourire/screens/screen_categorisation_note.dart';
import 'package:sourire/l10n/app_localizations.dart';

class ScreenNewNote extends StatefulWidget {
  final SourireTheme couleur; 
  final ThemeApp themeVisuel; 

  const ScreenNewNote({
    required this.couleur,
    required this.themeVisuel,
    super.key,
  });

  @override
  State<ScreenNewNote> createState() => _ScreenNewNoteState();
}

class _ScreenNewNoteState extends State<ScreenNewNote> {
  final TextEditingController _controller = TextEditingController();
  
  // Utilisation d'un ValueNotifier pour éviter le setState global sur tout l'écran
  final ValueNotifier<bool> _canValidateNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateValidationState);
  }

  void _updateValidationState() {
    final bool isNotEmpty = _controller.text.trim().isNotEmpty;
    if (_canValidateNotifier.value != isNotEmpty) {
      _canValidateNotifier.value = isNotEmpty;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateValidationState);
    _controller.dispose();
    _canValidateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    double responsiveFontSize = screenWidth * 0.05; 
    double largeurBouton = screenWidth * 0.4;
    double hauteurBouton = screenHeight * 0.065;

    final String accordAffiche = UserPrefs.accordHeureux;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentThemeMode, child) {
        // LOGIQUE CORRIGÉE : Gère le mode dynamique en suivant le système ou le choix forcé
        final bool isDarkMode = currentThemeMode == ThemeMode.system
            ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
            : (currentThemeMode == ThemeMode.dark);
        
        final Color iconColor = isDarkMode 
            ? Colors.white.withOpacity(0.25) 
            : widget.couleur.main.withOpacity(widget.themeVisuel.noteIconOpacity);

        return Scaffold(
          backgroundColor: isDarkMode ? darkBg : white,
          // Empêche le resize violent du clavier qui force la reconfiguration de l'aspectRatio
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // --- HEADER ---
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 0,
                          child: BtnChevronGauche(onTap: () => Navigator.pop(context)),
                        ),
                        const Center(
                          child: LogoSourire(color: orange),
                        ),
                      ],
                    ),
                  ),

                  // --- ZONE DE LA NOTE COMPRESSIBLE ---
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double postItSize = constraints.maxWidth;

                              return Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? darkSurface : widget.couleur.light, 
                                  borderRadius: BorderRadius.circular(radiusDefault),
                                  boxShadow: isDarkMode ? null : shadowDrop,
                                  border: Border.all(
                                    color: isDarkMode ? darkSeparateur : widget.couleur.main.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(radiusDefault),
                                  // RepaintBoundary isole le rendu du Post-it des couches système
                                  child: RepaintBoundary(
                                    child: Stack(
                                      children: [
                                        
                                        // --- 1. LES ICÔNES DE FOND (Ne bougent plus, dessinées une seule fois) ---
                                        ...widget.themeVisuel.noteIcons.map((config) {
                                          final double width = config.getWidth(postItSize);
                                          final double height = config.getHeight(postItSize);
                                          final double left = config.getX(postItSize);
                                          final double top = config.getY(postItSize);

                                          Widget iconWidget = SvgPicture.asset(
                                            config.assetPath,
                                            width: width,
                                            height: height,
                                            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                                          );

                                          if (config.rotation != 0.0) {
                                            iconWidget = Transform.rotate(
                                              angle: config.rotation * (math.pi / 180),
                                              child: iconWidget,
                                            );
                                          }

                                          return Positioned(
                                            left: left,
                                            top: top,
                                            child: iconWidget,
                                          );
                                        }),

                                        // --- 2. LA ZONE DE TEXTE ---
                                        Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.all(paddingDefault), 
                                            child: Center(
                                              child: SingleChildScrollView(
                                                physics: const BouncingScrollPhysics(),
                                                child: TextField(
                                                  controller: _controller,
                                                  autofocus: true,
                                                  maxLines: null,
                                                  keyboardType: TextInputType.multiline,
                                                  textAlign: TextAlign.center,
                                                  cursorColor: isDarkMode ? Colors.white : widget.couleur.main,
                                                  style: styleNoteLarge.copyWith(
                                                    color: isDarkMode ? Colors.white : widget.couleur.main,
                                                    fontSize: responsiveFontSize,
                                                    height: 1.2,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: AppLocalizations.of(context)!.writeHappyThought(accordAffiche),
                                                    hintStyle: styleNoteLarge.copyWith(
                                                      color: isDarkMode ? Colors.white38 : widget.couleur.main.withOpacity(0.3),
                                                      fontSize: responsiveFontSize,
                                                      height: 1.2,
                                                    ),
                                                    border: InputBorder.none,
                                                    counterText: "",
                                                  ),
                                                ),
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
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- BOUTON VALIDER ---
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + screenHeight * 0.02),
                    child: SizedBox(
                      width: largeurBouton,
                      height: hauteurBouton,
                      child: OverflowBox(
                        minWidth: largeurBouton,
                        maxWidth: largeurBouton,
                        minHeight: hauteurBouton,
                        maxHeight: hauteurBouton,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _canValidateNotifier,
                          builder: (context, canValidate, child) {
                            return BtnAction(
                              text: AppLocalizations.of(context)!.btnValidate,
                              isActive: canValidate,
                              color: widget.couleur.main,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScreenCategorisationNote(
                                      note: _controller.text,
                                      theme: widget.couleur,      
                                      themeVisuel: widget.themeVisuel, 
                                    ),
                                  ),
                                );
                              }, 
                            );
                          },
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
}
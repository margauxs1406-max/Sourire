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
  bool _canValidate = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _canValidate = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    double responsiveFontSize = screenWidth * 0.05; 
    double largeurBouton = screenWidth * 0.4;
    double hauteurBouton = screenHeight * 0.065;

    // Récupération de l'accord
    final String accordAffiche = UserPrefs.accordHeureux;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentThemeMode, child) {
        final bool isDarkMode = currentThemeMode == ThemeMode.dark;
        
        final Color iconColor = isDarkMode 
            ? Colors.white.withOpacity(0.25) 
            : widget.couleur.main.withOpacity(widget.themeVisuel.noteIconOpacity);

        return Scaffold(
          backgroundColor: isDarkMode ? darkBg : white,
          resizeToAvoidBottomInset: true,
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
                                  child: Stack(
                                    children: [
                                      
                                      // --- 1. LES ICÔNES DE FOND ---
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
                                                
                                                // Permet au TextField de mieux intercepter les clics uniques au lieu de laisser le scroll parent tout voler
                                                onTap: () {
                                                  // Optionnel : force le rafraîchissement si nécessaire, 
                                                  // mais nativement cela repositionne le curseur au bon endroit.
                                                },
                                                
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
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- BOUTON VALIDER ---
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                    child: SizedBox(
                      width: largeurBouton,
                      height: hauteurBouton,
                      child: OverflowBox(
                        minWidth: largeurBouton,
                        maxWidth: largeurBouton,
                        minHeight: hauteurBouton,
                        maxHeight: hauteurBouton,
                        child: BtnAction(
                          text: AppLocalizations.of(context)!.btnValidate,
                          isActive: _canValidate,
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
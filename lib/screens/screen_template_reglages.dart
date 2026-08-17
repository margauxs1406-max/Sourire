import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';

class ScreenTemplateReglages extends StatelessWidget {
  final String titre;
  final List<Widget> content;
  final bool? isDarkMode; // <--- Ajout d'un paramètre optionnel explicite

  const ScreenTemplateReglages({
    required this.titre,
    required this.content,
    this.isDarkMode, // <--- Intégration au constructeur
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Si isDarkMode est fourni on l'utilise, sinon on interroge le système
    final bool isDark = isDarkMode ?? (Theme.of(context).brightness == Brightness.dark);

    // Calcul de la taille de police responsive basée sur la largeur de l'écran
    // 18 est la taille de référence sur un écran classique (ex: largeur ~390-400dp)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double responsiveFontSize = (screenWidth * 18) / 390;

    return Scaffold(
      // Surface d'écran : blanc chaud, comme la home et le profil.
      backgroundColor: isDark ? darkBg : lightOrange,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER FIXE UNIQUE
            Container(
              // Le bandeau se fond dans l'écran : deux blancs différents
              // à trois points l'un de l'autre se verraient sans rien apporter.
              color: isDark ? darkSurface : lightOrange,
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
            
            // CONTENU SCROLLABLE SPÉCIFIQUE
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 30, right: 30, top: 20, bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: TextStyle(
                        fontSize: responsiveFontSize, // <--- Police responsive appliquée ici
                        fontWeight: FontWeight.bold,
                        color: isDark ? white : black, // <--- Couleur du titre adaptative
                      ),
                    ),
                    const SizedBox(height: 25),
                    ...content, // Injecte la liste des widgets spécifiques
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
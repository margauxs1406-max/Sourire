import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_historique.dart';

class HeaderApp extends StatelessWidget {
  final VoidCallback onBurgerTap;
  final VoidCallback onProfilTap;
  final Key? keyBurger;

  const HeaderApp({
    required this.onBurgerTap, 
    required this.onProfilTap, 
    this.keyBurger, 
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Récupération de la hauteur de l'écran
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,         // Prend l'intégralité de la largeur de l'écran
      height: screenHeight * 0.08,    // Fixe la hauteur à 8% de la hauteur de l'écran
      padding: const EdgeInsets.symmetric(horizontal: 20), // Marges internes latérales pour les icônes
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onProfilTap,
            child: const Icon(
              Icons.person_outline,
              color: white,
              size: 28,
            ),
          ), 
          
          const LogoSourire(), 
          
          // CORRECTION : On associe la clé keyBurger directement sur le bouton ciblé par le tutoriel
          BtnHistorique(
            key: keyBurger, 
            onTap: onBurgerTap,
          ),
        ],
      ),
    );
  }
}
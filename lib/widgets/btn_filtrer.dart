import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart'; // <--- LE BON IMPORT DEPUIS TON PROJET
import 'package:sourire/theme/tokens.dart';

class BtnFiltrer extends StatelessWidget {
  final int nombreDeFiltres;
  final VoidCallback onTap;

  const BtnFiltrer({
    required this.nombreDeFiltres,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    // Construction dynamique du libellé selon le nombre de filtres appliqués
    final String label = nombreDeFiltres > 0 
        ? (localizations.localeName == 'fr' ? "Filtré ($nombreDeFiltres)" : "Filtered ($nombreDeFiltres)") 
        : localizations.btnFilter;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Padding réduit pour compacter la largeur sans casser le texte dynamique
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: orange, 
          borderRadius: BorderRadius.circular(40), 
          boxShadow: shadowDrop, 
        ),
        // Plus besoin de Row puisqu'il n'y a plus d'icône, le texte s'auto-centre
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: styleBouton.copyWith(
            color: white,
            fontSize: 16, // Légèrement réduit pour optimiser l'espace horizontal
          ),
        ),
      ),
    );
  }
}
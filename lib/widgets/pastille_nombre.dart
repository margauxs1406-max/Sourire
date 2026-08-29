import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

/// Pastille « +N » posée sur la vignette d'un lot de souvenirs.
///
/// Elle indique combien de souvenirs SUIVENT celui qui est montré, et non le
/// total : la vignette visible se compte déjà elle-même. Dix photos donnent
/// donc « +9 », ce qui se lit « celle-ci, et neuf autres ».
///
/// Partagée par l'écran de catégorisation des photos et celui de
/// recatégorisation de l'historique — les deux entrées du mode lot.
class PastilleNombre extends StatelessWidget {
  final int nombre;

  const PastilleNombre({required this.nombre, super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: orange,
        // Une pilule et non un cercle strict : au-delà de deux chiffres, la
        // pastille s'allonge plutôt que de rogner le nombre.
        borderRadius: BorderRadius.all(Radius.circular(999)),
        boxShadow: shadowPastille,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          '+$nombre',
          textAlign: TextAlign.center,
          style: styleMention.copyWith(color: white, fontSize: 12),
        ),
      ),
    );
  }
}

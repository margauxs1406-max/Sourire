/// Liste complète et définitive des paliers de gamification.
/// Aucun palier au-delà de 5000 (pas de pop-up passé ce seuil).
const List<int> _paliersDeBase = [
  10, 50, 100, 200, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000,
];

/// Renvoie le plus haut palier atteint (ou dépassé) par [total].
/// Renvoie 0 si aucun palier n'est encore atteint.
int plusHautPalierAtteint(int total) {
  int meilleur = 0;
  for (final p in _paliersDeBase) {
    if (total >= p) meilleur = p;
  }
  return meilleur;
}

/// Renvoie le prochain palier fraîchement franchi par [total] par rapport
/// au dernier palier déjà célébré ([dernierCelebre]), ou `null` si aucun
/// nouveau palier n'a été franchi (y compris si on a déjà dépassé le
/// dernier palier existant, 5000).
///
/// S'il y en a plusieurs d'un coup (ex: import de 20 photos qui fait
/// sauter de 8 à 28 souvenirs, franchissant 10 sans jamais s'arrêter
/// dessus), on ne renvoie que le plus haut — pas la peine d'empiler
/// plusieurs pop-ups pour un seul ajout groupé.
int? prochainPalierFranchi(int total, int dernierCelebre) {
  final int meilleur = plusHautPalierAtteint(total);
  if (meilleur > dernierCelebre) return meilleur;
  return null;
}
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:sourire/theme/user_prefs.dart';

/// Ce qu'il est advenu d'une tentative d'achat ou de restauration.
enum ResultatAchat {
  /// Premium débloqué, ici et maintenant.
  succes,

  /// L'utilisateur a refermé la feuille de paiement.
  annule,

  /// Play ou l'App Store attend une validation extérieure : contrôle
  /// parental, virement en attente. L'achat aboutira peut-être plus tard,
  /// et le déblocage se fera alors tout seul.
  enAttente,

  /// Rien à restaurer sur ce compte.
  rienARestaurer,

  /// La boutique n'a pas répondu, ou le produit n'existe pas encore.
  indisponible,

  /// Refus de la boutique, réseau coupé, erreur inattendue.
  erreur,
}

/// Abonnement Premium, par StoreKit sur iOS et Play Billing sur Android.
///
/// C'est un ABONNEMENT MENSUEL À RENOUVELLEMENT AUTOMATIQUE, et cela change
/// tout par rapport à un achat unique : il se résilie. Le Premium n'est donc
/// pas un interrupteur qu'on pousse une fois, c'est une échéance qu'il faut
/// repousser tant que la boutique confirme que l'abonnement court. Voir
/// UserPrefs.confirmerPremium, et [verifierAbonnement] pour le contrôle joué
/// à chaque lancement.
///
/// Apple impose par ailleurs un bouton « Restaurer mes achats » : c'est
/// [restaurer].
///
/// ── Pourquoi aucune vérification côté serveur ──
///
/// L'usage voudrait qu'un serveur revalide le reçu auprès d'Apple et de
/// Google. Sourire n'a pas de serveur, et n'en veut pas : c'est sa promesse.
/// Ce que le Premium débloque — une limite de souvenirs et des décors — vit
/// entièrement sur le téléphone, et ne coûte rien à personne s'il est
/// contourné. Le seul risque est qu'un appareil débridé s'offre les décors
/// sans payer. C'est un risque acceptable ; monter un serveur pour l'écarter
/// coûterait la promesse de l'application.
///
/// ── Avant que cela ne fonctionne ──
///
/// Le produit [idPremium] doit exister, avec EXACTEMENT cet identifiant :
///  - App Store Connect : ABONNEMENT à renouvellement automatique, dans un
///    groupe d'abonnement, durée « 1 mois », soumis avec une version de
///    l'app (le premier abonnement l'exige) ;
///  - Play Console : ABONNEMENT avec un forfait de base mensuel, app publiée
///    au moins en test interne.
/// Dans les deux cas, les contrats commerciaux et les coordonnées bancaires
/// doivent être signés, sinon la boutique répond mais ne vend rien.
///
/// Tant que le produit n'existe pas, [produit] reste `null` et l'interface
/// affiche « bientôt disponible » au lieu d'un bouton mort.
class AchatService {
  AchatService._();

  /// Identifiant de l'abonnement, identique sur les deux boutiques.
  ///
  /// Côté Play, c'est l'identifiant de l'ABONNEMENT et non celui du forfait
  /// de base : c'est bien lui que la requête de produits attend.
  static const String idPremium = 'sourire_premium';

  static final InAppPurchase _boutique = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _abonnement;

  /// Attente de l'issue de l'achat en cours. Le résultat n'arrive pas en
  /// retour de [InAppPurchase.buyNonConsumable] mais plus tard, sur le flux.
  static Completer<ResultatAchat>? _enCours;

  /// `true` si l'attente en cours est une restauration et non un achat : le
  /// flux ne les distingue pas, et une restauration sans rien à restaurer
  /// n'émet qu'une liste vide.
  static bool _restaurationEnCours = false;

  /// Le produit tel que la boutique le décrit, prix compris.
  ///
  /// Le prix vient de la boutique, jamais du code : il est déjà dans la
  /// monnaie et le format du pays, et Apple refuse une app qui affiche un
  /// prix écrit en dur.
  static final ValueNotifier<ProductDetails?> produit =
      ValueNotifier<ProductDetails?>(null);

  /// La boutique est-elle joignable sur cet appareil ?
  static final ValueNotifier<bool> boutiqueDisponible =
      ValueNotifier<bool>(false);

  // --- DÉMARRAGE --------------------------------------------------------------

  /// À appeler une fois, au lancement, avant `runApp`.
  ///
  /// L'abonnement au flux doit vivre aussi longtemps que l'application : un
  /// achat peut aboutir alors que la modale est déjà refermée — validation
  /// parentale accordée le lendemain, paiement différé — et c'est cet
  /// abonnement, et lui seul, qui débloquera le Premium ce jour-là.
  static Future<void> initialiser() async {
    _abonnement ??= _boutique.purchaseStream.listen(
      _traiterAchats,
      onError: (Object e) => debugPrint("Flux d'achats interrompu : $e"),
    );

    try {
      boutiqueDisponible.value = await _boutique.isAvailable();
    } catch (e) {
      debugPrint("Boutique injoignable : $e");
      boutiqueDisponible.value = false;
      return;
    }

    if (!boutiqueDisponible.value) return;
    await chargerProduit();
    await verifierAbonnement();
  }

  /// L'abonnement court-il toujours ? Contrôle silencieux, à chaque lancement.
  ///
  /// `restorePurchases` ne rend que les abonnements ENCORE ACTIFS : sur
  /// Android c'est le comportement de Play Billing, et sur iOS celui de
  /// StoreKit 2, actif par défaut dans cette version du paquet. Une
  /// résiliation n'est donc plus jamais renvoyée, et l'échéance enregistrée
  /// finit par expirer d'elle-même.
  ///
  /// L'inverse est tout aussi important : si la boutique ne répond pas —
  /// avion, tunnel, coupure — on ne touche à RIEN. Un abonné en règle ne perd
  /// pas ses décors parce qu'il n'a pas de réseau.
  static Future<void> verifierAbonnement() async {
    try {
      await _boutique.restorePurchases();
    } catch (e) {
      debugPrint("Contrôle de l'abonnement impossible : $e");
    }
  }

  /// Demande à la boutique le titre, la description et le prix du Premium.
  static Future<void> chargerProduit() async {
    try {
      final ProductDetailsResponse reponse =
          await _boutique.queryProductDetails(<String>{idPremium});

      if (reponse.error != null) {
        debugPrint("Produit illisible : ${reponse.error!.message}");
        return;
      }
      if (reponse.notFoundIDs.contains(idPremium) ||
          reponse.productDetails.isEmpty) {
        // Cas normal tant que la fiche n'est pas créée dans les deux
        // consoles. L'interface affichera « bientôt disponible ».
        debugPrint("Produit $idPremium inconnu de la boutique.");
        _poserProduitDeVitrine();
        return;
      }

      produit.value = reponse.productDetails.first;
      debugPrint("Premium à ${produit.value!.price}");
    } catch (e) {
      debugPrint("Interrogation de la boutique impossible : $e");
    }
  }

  /// Produit FACTICE, uniquement en debug, pour pouvoir regarder la modale.
  ///
  /// Tant que l'abonnement n'existe pas dans les consoles, la boutique répond
  /// « inconnu » et la modale se réduit à un bouton grisé : impossible de
  /// juger la mise en page, la mention de prix ou les liens du bas.
  ///
  /// Ce produit-là n'est qu'un décor. Appuyer sur « Passer Premium » avec lui
  /// échouera, et c'est très bien : cela montre aussi à quoi ressemble le
  /// message d'erreur.
  ///
  /// `kDebugMode` est une constante de compilation : en release, le
  /// compilateur retire purement et simplement ce corps de méthode. Il n'y a
  /// donc aucun risque qu'un prix inventé parte sur les stores.
  static void _poserProduitDeVitrine() {
    if (!kDebugMode) return;
    produit.value = ProductDetails(
      id: idPremium,
      title: 'Sourire Premium',
      description: 'Souvenirs illimités et tous les décors.',
      price: '0,99 €',
      rawPrice: 0.99,
      currencyCode: 'EUR',
    );
    debugPrint("--- DEBUG : produit de vitrine posé, la modale est complète ---");
  }

  static void liberer() {
    _abonnement?.cancel();
    _abonnement = null;
  }

  // --- ACHAT ------------------------------------------------------------------

  /// Ouvre la feuille de paiement du système et attend l'issue.
  static Future<ResultatAchat> acheter() async {
    final ProductDetails? details = produit.value;
    if (details == null) return ResultatAchat.indisponible;
    if (_enCours != null) return ResultatAchat.enAttente;

    final Completer<ResultatAchat> attente = Completer<ResultatAchat>();
    _enCours = attente;
    _restaurationEnCours = false;

    try {
      // `buyNonConsumable` et non `buyConsumable`, y compris pour un
      // abonnement : c'est la méthode que le paquet prévoit pour les
      // abonnements à renouvellement automatique.
      final bool lancee = await _boutique.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!lancee) {
        _enCours = null;
        return ResultatAchat.erreur;
      }
    } catch (e) {
      debugPrint("Achat impossible à lancer : $e");
      _enCours = null;
      return ResultatAchat.erreur;
    }

    // Généreux : entre la feuille de paiement, la double authentification
    // bancaire et un utilisateur qui hésite, trois minutes ne sont pas de
    // trop. Passé ce délai on rend la main à l'interface, mais l'abonnement
    // au flux, lui, continue : si l'achat aboutit ensuite, le Premium se
    // débloque quand même.
    return attente.future
        .timeout(const Duration(minutes: 3), onTimeout: () {
      _enCours = null;
      return ResultatAchat.enAttente;
    });
  }

  /// Rend le Premium à quelqu'un qui l'a déjà payé : nouveau téléphone,
  /// réinstallation. Apple l'exige pour tout achat non consommable.
  static Future<ResultatAchat> restaurer() async {
    if (_enCours != null) return ResultatAchat.enAttente;

    final Completer<ResultatAchat> attente = Completer<ResultatAchat>();
    _enCours = attente;
    _restaurationEnCours = true;

    try {
      await _boutique.restorePurchases();
    } catch (e) {
      debugPrint("Restauration impossible : $e");
      _enCours = null;
      return ResultatAchat.erreur;
    }

    return attente.future
        .timeout(const Duration(seconds: 30), onTimeout: () {
      _enCours = null;
      return ResultatAchat.rienARestaurer;
    });
  }

  // --- RÉCEPTION --------------------------------------------------------------

  static Future<void> _traiterAchats(List<PurchaseDetails> achats) async {
    // Une liste vide pendant une restauration signifie « ce compte n'a rien
    // acheté ». Sans ce cas, l'attente irait jusqu'au bout de son délai.
    if (achats.isEmpty && _restaurationEnCours) {
      _repondre(ResultatAchat.rienARestaurer);
      return;
    }

    for (final PurchaseDetails achat in achats) {
      switch (achat.status) {
        case PurchaseStatus.pending:
          // Étape, pas issue : on ne referme pas l'attente là-dessus, on
          // laisse venir l'état définitif.
          debugPrint("Achat en attente de validation.");
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (achat.productID == idPremium) {
            await _debloquer();
            _repondre(ResultatAchat.succes);
          }
          break;

        case PurchaseStatus.canceled:
          _repondre(ResultatAchat.annule);
          break;

        case PurchaseStatus.error:
          debugPrint("Achat refusé : ${achat.error?.message}");
          _repondre(ResultatAchat.erreur);
          break;
      }

      // OBLIGATOIRE, et dans tous les cas de figure. Play annule et rembourse
      // un achat qui n'a pas été acquitté sous trois jours, et StoreKit
      // représente indéfiniment une transaction non terminée.
      if (achat.pendingCompletePurchase) {
        try {
          await _boutique.completePurchase(achat);
        } catch (e) {
          debugPrint("Acquittement impossible : $e");
        }
      }
    }
  }

  static Future<void> _debloquer() async {
    await UserPrefs.confirmerPremium();
    debugPrint("--- PREMIUM confirmé jusqu'au ${UserPrefs.premiumJusquA} ---");
  }

  /// Rend son résultat à l'attente en cours, s'il y en a une. Une attente déjà
  /// close est ignorée : le flux peut émettre après le délai imparti.
  static void _repondre(ResultatAchat resultat) {
    final Completer<ResultatAchat>? attente = _enCours;
    if (attente == null || attente.isCompleted) return;
    _enCours = null;
    _restaurationEnCours = false;
    attente.complete(resultat);
  }
}

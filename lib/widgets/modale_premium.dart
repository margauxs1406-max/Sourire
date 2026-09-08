import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/main.dart';
import 'package:sourire/services/achat_service.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// Politique de confidentialité de Sourire.
///
/// Apple exige qu'elle soit atteignable depuis l'écran qui propose un
/// abonnement, et pas seulement depuis la fiche du store (directive 3.1.2).
const String _lienConfidentialite =
    'https://mxsstudio.com/sourire/confidentialite/';

/// Conditions d'utilisation, exigées au même endroit et par la même directive.
///
/// C'est le contrat type d'Apple, que la directive autorise explicitement tant
/// qu'aucune condition propre n'est publiée. Le jour où MxS Studio publiera
/// les siennes, il suffira de changer cette adresse. Le lien n'apparaît que
/// sur iOS : ce texte est celui d'Apple, il n'a rien à faire sur Android.
const String _lienConditions =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// Propose l'abonnement Premium, avec un argumentaire propre à l'endroit d'où
/// l'on vient.
///
/// L'offre n'est pas la même chose selon le moment : quelqu'un qui bute sur la
/// limite de souvenirs ne s'abonne pas pour les mêmes raisons que quelqu'un
/// qui vient de voir sa note en thème floral. D'où le [message], donné par
/// l'appelant, plutôt qu'un texte unique qui parlerait à moitié dans les deux
/// cas.
///
/// Retourne `true` si le Premium est actif à la sortie de la modale.
///
/// Le prix affiché vient de la boutique et jamais du code : il arrive déjà
/// dans la monnaie et le format du pays. Écrire « 0,99 € » en dur donnerait un
/// prix faux dès qu'on quitte la zone euro, et Apple le refuse.
Future<bool> afficherModalePremium(
  BuildContext context, {
  required String titre,
  required String message,
}) async {
  final bool? debloque = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (contexteModale) => _ModalePremium(titre: titre, message: message),
  );
  return debloque == true;
}

class _ModalePremium extends StatefulWidget {
  final String titre;
  final String message;

  const _ModalePremium({required this.titre, required this.message});

  @override
  State<_ModalePremium> createState() => _ModalePremiumState();
}

class _ModalePremiumState extends State<_ModalePremium> {
  bool _enCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    // Le produit a normalement été chargé au démarrage. S'il manque — réseau
    // absent à ce moment-là, boutique lente — on retente ici : c'est
    // précisément l'instant où l'on en a besoin.
    if (AchatService.produit.value == null) {
      AchatService.chargerProduit();
    }
  }

  Future<void> _lancer(Future<ResultatAchat> Function() action) async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });

    final ResultatAchat resultat = await action();
    if (!mounted) return;

    final AppLocalizations mots = AppLocalizations.of(context)!;

    switch (resultat) {
      case ResultatAchat.succes:
        Navigator.of(context).pop(true);
        return;

      case ResultatAchat.annule:
        // L'utilisateur a refermé la feuille de paiement : il sait ce qu'il a
        // fait, on ne lui explique rien.
        setState(() => _enCours = false);
        return;

      case ResultatAchat.enAttente:
        setState(() {
          _enCours = false;
          _erreur = mots.premiumPending;
        });
        return;

      case ResultatAchat.rienARestaurer:
        setState(() {
          _enCours = false;
          _erreur = mots.premiumRestoreNone;
        });
        return;

      case ResultatAchat.indisponible:
        setState(() {
          _enCours = false;
          _erreur = mots.premiumUnavailable;
        });
        return;

      case ResultatAchat.erreur:
        setState(() {
          _enCours = false;
          _erreur = mots.premiumError;
        });
        return;
    }
  }

  Future<void> _ouvrir(String adresse) async {
    try {
      await launchUrl(Uri.parse(adresse), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Lien injoignable : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = MyApp.themeNotifier.value;
    final bool sombre = mode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : mode == ThemeMode.dark;

    final AppLocalizations mots = AppLocalizations.of(context)!;

    return ValueListenableBuilder<ProductDetails?>(
      valueListenable: AchatService.produit,
      builder: (context, produit, _) {
        return AlertDialog(
          backgroundColor: sombre ? darkSurface : white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          // Titre nu. L'étincelle qui l'accompagnait était une décoration de
          // plus dans une boîte qui demande déjà de l'argent : elle promettait
          // de la magie là où l'offre se suffit à elle-même.
          //
          // La croix remplace le bouton « Annuler » retiré du bas. Elle reste
          // indispensable : la modale ne se ferme pas au clic à côté, et sans
          // elle on ne pourrait plus en sortir sans payer. C'est aussi la
          // convention des autres boîtes de l'application.
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.titre,
                  style: styleTitreRecit.copyWith(color: texteTitre(sombre)),
                ),
              ),
              GestureDetector(
                onTap: _enCours ? null : () => Navigator.of(context).pop(false),
                child: Icon(Icons.close, color: texteDoux(sombre)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.message,
                style: styleSecondaire.copyWith(color: texteDoux(sombre)),
              ),

              if (_erreur != null) ...[
                const SizedBox(height: 16),
                Text(
                  _erreur!,
                  style: styleSecondaire.copyWith(color: Colors.red.shade400),
                ),
              ],

              const SizedBox(height: 24),

              // Le bouton vit dans le CONTENU et non dans les actions : c'est
              // la seule façon de poser la mention de prix juste dessous, là
              // où l'œil la lit avant d'appuyer, et non en marge.
              ElevatedButton(
                // Produit inconnu de la boutique : la fiche n'est pas encore
                // publiée. On le dit, plutôt que d'offrir un bouton qui ne
                // ferait rien.
                onPressed: (_enCours || produit == null)
                    ? null
                    : () => _lancer(AchatService.acheter),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  disabledBackgroundColor: orange.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _enCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        produit == null
                            ? mots.premiumSoon
                            : mots.btnPasserPremium,
                        style: styleCorps.copyWith(
                          color: white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              // La mention légale de l'abonnement : durée et prix par période.
              // Apple l'exige à côté du bouton d'achat (directive 3.1.2), et
              // c'est de toute façon la moindre des honnêtetés — personne ne
              // doit appuyer sans savoir ce qu'il engage.
              if (produit != null) ...[
                const SizedBox(height: 8),
                // MÊME style que le corps de la modale, centrée sous le
                // bouton : c'est une phrase qu'on lit, pas une note de bas de
                // page qu'on saute. Aucune surcharge de taille ni de couleur
                // ici, sinon elle cesserait de suivre le corps le jour où il
                // changera.
                Text(
                  mots.premiumPriceNote(produit.price),
                  textAlign: TextAlign.center,
                  style: styleSecondaire.copyWith(color: texteDoux(sombre)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    // « Restaurer mes achats » : exigé par Apple pour tout
                    // abonnement, et seul recours de qui change de téléphone.
                    _lien(
                      mots.premiumRestore,
                      _enCours ? null : () => _lancer(AchatService.restaurer),
                    ),
                    _lien(
                      mots.premiumLinkPrivacy,
                      () => _ouvrir(_lienConfidentialite),
                    ),
                    if (Platform.isIOS)
                      _lien(
                        mots.premiumLinkTerms,
                        () => _ouvrir(_lienConditions),
                      ),
                  ],
                ),
              ],
            ],
          ),
          // Aucun bandeau d'actions : le bouton d'abonnement vit dans le
          // corps, pour que la mention de prix tienne juste dessous, et la
          // sortie se fait par la croix du titre.
        );
      },
    );
  }

  Widget _lien(String texte, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        texte,
        style: styleSecondaire.copyWith(
          color: orange,
          fontSize: 12,
          decoration: TextDecoration.underline,
          decorationColor: orange,
        ),
      ),
    );
  }
}

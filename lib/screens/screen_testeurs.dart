import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:sourire/main.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_chevron_gauche.dart';
import 'package:sourire/services/database_service.dart';
import 'package:sourire/models/note_model.dart';

/// Contenu d'une semaine de test — À ÉDITER toi-même avec les vrais
/// scénarios, questions et liens Tally une fois prêts.
class SemaineTest {
  final int numero;
  final String titre;
  final String scenario;
  final List<String> questions;
  final String lienTally;

  const SemaineTest({
    required this.numero,
    required this.titre,
    required this.scenario,
    required this.questions,
    required this.lienTally,
  });
}

// --- CONTENU PROVISOIRE : remplace par tes vrais textes et liens Tally ---
const List<SemaineTest> semainesTest = [
  SemaineTest(
    numero: 1,
    titre: 'Semaine 1 — Prise en main',
    scenario:
        'Découvre l\'application librement : crée quelques souvenirs (texte et photo), '
        'tire un souvenir au hasard depuis le bocal, et explore l\'historique.',
    questions: [
      'L\'application t\'a-t-elle semblé facile à comprendre dès le départ ?',
      'As-tu rencontré des bugs ou points bloquants ?',
      'Qu\'as-tu pensé du bocal qui se remplit ?',
    ],
    lienTally: 'https://tally.so/r/44dEzX',
  ),
  SemaineTest(
    numero: 2,
    titre: 'Semaine 2 — Usage quotidien',
    scenario:
        'Essaie d\'utiliser l\'application au moins une fois par jour cette semaine. '
        'Teste les notifications de rappel et la catégorisation de tes souvenirs.',
    questions: [
      'Les notifications t\'ont-elles semblé pertinentes et bien dosées ?',
      'La catégorisation est-elle claire et utile ?',
      'As-tu débloqué un badge ? Qu\'en as-tu pensé ?',
    ],
    lienTally: 'https://tally.so/r/LZyVOj',
  ),
  SemaineTest(
    numero: 3,
    titre: 'Semaine 3 — Import massif et personnalisation',
    scenario:
        'Explore les réglages d\'apparence et les thèmes et '
        'essaie de supprimer des souvenirs et des catégories.',
    questions: [
      'Est-ce que les listes se mettent à jour dynamiquement ?',
      'Que penses-tu des thèmes visuels disponibles ?',
      'Le mode sombre fonctionne-t-il bien pour toi ?',
    ],
    lienTally: 'https://tally.so/r/2E5VRV',
  ),
  SemaineTest(
    numero: 4,
    titre: 'Semaine 4 — Bilan global',
    scenario:
        'Dernière semaine : reviens sur ton expérience globale avec l\'application '
        'depuis le début du test.',
    questions: [
      'Recommanderais-tu cette application à un proche ?',
      'Quelles fonctionnalités as-tu préférée ?',
      'Quelles fonctionnalités te semblent encore à améliorer en priorité ?'
      'Serais-tu prêt.e à payer 0,99€/mois pour disposer de l\'application ?',
    ],
    lienTally: 'https://tally.so/r/J9YGgd',
  ),
];

/// Date de démarrage de la campagne de test — LA MÊME POUR TOUS LES
/// TESTEURS. Ajuste-la à la vraie date de lancement de ton programme.
final DateTime dateDebutCampagneTest = DateTime(2026, 7, 27);

int semaineActuelle() {
  final int joursEcoules = DateTime.now().difference(dateDebutCampagneTest).inDays;
  if (joursEcoules < 0) return 0; // La campagne n'a pas encore commencé
  final int semaine = (joursEcoules ~/ 7) + 1;
  return semaine > 4 ? 5 : semaine; // 5 = campagne terminée
}

class ScreenTesteurs extends StatelessWidget {
  const ScreenTesteurs({super.key});

  /// Récupère un nom d'appareil lisible + l'OS, pour les transmettre à
  /// Tally via des "Hidden fields" (champs cachés) — voir le nom exact
  /// des champs à créer dans chaque formulaire Tally plus bas.
  Future<Map<String, String>> _obtenirInfosAppareil() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return {
          'device': '${info.manufacturer} ${info.model}',
          'os': 'Android ${info.version.release}',
        };
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return {
          'device': info.utsname.machine, // ex: "iPhone14,5"
          'os': 'iOS ${info.systemVersion}',
        };
      }
    } catch (e) {
      debugPrint('Erreur récupération infos appareil : $e');
    }
    return {'device': 'Inconnu', 'os': 'Inconnu'};
  }

  Future<void> _ouvrirLienTally(String url) async {
    final infos = await _obtenirInfosAppareil();

    // Construit l'URL avec les paramètres attendus par les Hidden fields
    // Tally — noms EXACTS à recréer dans chaque formulaire (voir README).
    final uriBase = Uri.parse(url);
    final uri = uriBase.replace(queryParameters: {
      ...uriBase.queryParameters,
      'device': infos['device'] ?? 'Inconnu',
      'os': infos['os'] ?? 'Inconnu',
    });

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentMode, _) {
        final bool isDark = currentMode == ThemeMode.system
            ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
            : (currentMode == ThemeMode.dark);

        final Color bgColor = isDark ? darkBg : white;
        final Color textColor = isDark ? white : black;
        final Color headerBgColor = isDark ? darkSurface : white;
        final Color cardColor = isDark ? darkSurface : const Color(0xFFF5F5F5);
        final Color texteSecondaire = isDark ? lightGrey : grey;

        final double screenWidth = MediaQuery.of(context).size.width;
        // --- FACTEUR RESPONSIVE GLOBAL ---
        // Basé sur une largeur de référence de 390 (iPhone standard),
        // avec des bornes (clamp) pour éviter un texte minuscule sur
        // très petits écrans ou démesuré sur tablette.
        final double scale = (screenWidth / 390).clamp(0.85, 1.35);

        final double titleFontSize = 22 * scale;
        final double sectionTitleFontSize = 18 * scale;
        final double bodyFontSize = 14 * scale;
        final double horizontalPadding = 30 * scale;

        final int semaine = semaineActuelle();

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: headerBgColor,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10 * scale),
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        child: BtnChevronGauche(onTap: () => Navigator.pop(context)),
                      ),
                      LogoSourire(color: orange),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      top: 20 * scale,
                      bottom: 30 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Espace testeurs',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          'Merci de participer au test de Sourire ! Voici tes scénarios '
                          'hebdomadaires et un aperçu de ton utilisation.',
                          style: TextStyle(fontSize: bodyFontSize, color: texteSecondaire, height: 1.4),
                        ),
                        SizedBox(height: 25 * scale),

                        _buildBlocStatistiques(context, isDark, cardColor, textColor, texteSecondaire, scale),

                        SizedBox(height: 30 * scale),
                        Text(
                          'Programme de test (4 semaines)',
                          style: TextStyle(
                            fontSize: sectionTitleFontSize,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 15 * scale),

                        if (semaine == 0)
                          Text(
                            'Le programme de test n\'a pas encore commencé.',
                            style: TextStyle(color: texteSecondaire, fontSize: bodyFontSize),
                          )
                        else if (semaine == 5)
                          Text(
                            'Le programme de test est terminé — merci infiniment pour ta '
                            'participation ! Tu peux encore consulter les semaines '
                            'ci-dessous si tu veux revenir sur un retour.',
                            style: TextStyle(color: texteSecondaire, fontSize: bodyFontSize, height: 1.4),
                          ),

                        SizedBox(height: 15 * scale),

                        ...semainesTest.map((s) => _buildCarteSemaine(
                              context,
                              s,
                              estSemaineActuelle: s.numero == semaine,
                              isDark: isDark,
                              cardColor: cardColor,
                              textColor: textColor,
                              texteSecondaire: texteSecondaire,
                              scale: scale,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlocStatistiques(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color texteSecondaire,
    double scale,
  ) {
    return StreamBuilder<List<NoteSourire>>(
      stream: DatabaseService().getNotesStream(),
      builder: (context, snapshot) {
        final List<NoteSourire> toutes = snapshot.data ?? [];
        final DateTime seuil30j = DateTime.now().subtract(const Duration(days: 30));
        final List<NoteSourire> derniers30j = toutes.where((n) => n.date.isAfter(seuil30j)).toList();

        final int total30j = derniers30j.length;
        final double moyenneParJour = total30j / 30;
        final double moyenneParSemaine = total30j / (30 / 7);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activité des 30 derniers jours',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15 * scale),
              ),
              SizedBox(height: 12 * scale),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('$total30j', 'souvenirs ajoutés', textColor, texteSecondaire, scale),
                  _buildStatItem(moyenneParSemaine.toStringAsFixed(1), 'par semaine (moy.)', textColor, texteSecondaire, scale),
                  _buildStatItem(moyenneParJour.toStringAsFixed(2), 'par jour (moy.)', textColor, texteSecondaire, scale),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String valeur, String label, Color textColor, Color texteSecondaire, double scale) {
    return Expanded(
      child: Column(
        children: [
          Text(valeur, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20 * scale, color: orange)),
          SizedBox(height: 4 * scale),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11 * scale, color: texteSecondaire),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteSemaine(
    BuildContext context,
    SemaineTest s, {
    required bool estSemaineActuelle,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color texteSecondaire,
    required double scale,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 14 * scale),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: estSemaineActuelle ? Border.all(color: orange, width: 2) : null,
      ),
      // Le Theme local supprime les 2 lignes de séparation que Flutter
      // dessine par défaut au-dessus/en dessous du contenu déplié.
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
        initiallyExpanded: estSemaineActuelle,
        iconColor: textColor,
        collapsedIconColor: textColor,
        title: Row(
          children: [
            if (estSemaineActuelle)
              Container(
                margin: EdgeInsets.only(right: 8 * scale),
                padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 3 * scale),
                decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'EN COURS',
                  style: TextStyle(color: white, fontSize: 10 * scale, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: Text(
                s.titre,
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15 * scale),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 16 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.scenario, style: TextStyle(color: texteSecondaire, height: 1.4, fontSize: 14 * scale)),
                SizedBox(height: 12 * scale),
                Text(
                  'Questions à te poser :',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13 * scale),
                ),
                SizedBox(height: 6 * scale),
                ...s.questions.map((q) => Padding(
                      padding: EdgeInsets.only(bottom: 4 * scale),
                      child: Text('• $q', style: TextStyle(color: texteSecondaire, fontSize: 13 * scale, height: 1.3)),
                    )),
                SizedBox(height: 14 * scale),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _ouvrirLienTally(s.lienTally),
                    icon: Icon(Icons.open_in_new, size: 16 * scale, color: white),
                    label: Text('Donner mon avis', style: TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 14 * scale)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
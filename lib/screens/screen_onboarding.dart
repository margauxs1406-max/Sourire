import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/l10n/langues.dart';
import 'package:sourire/screens/home.dart';
import 'package:sourire/services/biometric_service.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/widgets/btn_onboarding.dart';
import 'package:sourire/widgets/switch_biometrie.dart';
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/main.dart'; 

class ScreenOnboarding extends StatefulWidget {
  const ScreenOnboarding({super.key});

  @override
  State<ScreenOnboarding> createState() => _ScreenOnboardingState();
}

class _ScreenOnboardingState extends State<ScreenOnboarding> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Plus de champ e-mail ici. Il était obligatoire pour franchir l'étape, et
  // l'adresse n'était ensuite lue par personne : pas d'envoi, pas de
  // récupération de mot de passe, rien. Un prénom, une adresse et un mot de
  // passe exigés au premier lancement, cela se lit comme une inscription — et
  // c'est bien ainsi qu'Apple l'a lu (directive 5.1.1(v)). C'était aussi
  // contraire à la politique de confidentialité, qui promet qu'aucune adresse
  // n'est demandée. Voir UserPrefs.purgerEmail pour l'effacement des adresses
  // déjà saisies.
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedGenre = "";
  bool _biometrieValue = false;
  bool _obscurePassword = true;
  String _selectedLangue = UserPrefs.langue;

  @override
  void dispose() {
    _pageController.dispose();
    _prenomController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// `async` depuis que le mot de passe est haché : son enregistrement passe
  /// par les préférences, donc par un Future.
  Future<void> _passerALEtapeSuivante() async {
    FocusScope.of(context).unfocus();
    
    if (_validerEtapeActuelle()) {
      // Quatre et non cinq : le mot de passe et la biométrie, qui parlaient
      // tous deux de l'accès, tiennent désormais sur la même page.
      if (_currentStep < 4) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        debugPrint("ONBOARDING LOG : Validation finale de l'étape 5 lancée.");
        
        try {
          await UserPrefs.definirMotDePasse(_passwordController.text);
          UserPrefs.biomatrieActive = _biometrieValue; 
          UserPrefs.modeDemoAffiche = false; 
          
          debugPrint("ONBOARDING LOG : Données UserPrefs sauvegardées avec succès (Biométrie active : $_biometrieValue). Transition vers Home...");

          // L'enregistrement du mot de passe est un `await` : l'écran a pu
          // être démonté entre-temps.
          if (!mounted) return;

          debugPrint("ONBOARDING LOG : Exécution directe du pushReplacement de la Home.");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Home(),
            ),
          );

        } catch (prefsError, stackTrace) {
          debugPrint("ONBOARDING CRASH : Échec de l'écriture dans UserPrefs !");
          debugPrint("Détails de l'erreur : $prefsError");
          debugPrint("Stacktrace : $stackTrace");
        }
      }
    } else {
      debugPrint("ONBOARDING LOG : Le clic sur Valider a été ignoré car l'étape n'est pas valide.");
    }
  }

  void _revenirEnArriere() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validerEtapeActuelle() {
    if (_currentStep == 0) return _selectedLangue.isNotEmpty; 
    if (_currentStep == 1) return true; 
    if (_currentStep == 2) return _prenomController.text.trim().isNotEmpty; 
    if (_currentStep == 3) return _selectedGenre.isNotEmpty; 
    // Dernière étape : seul le mot de passe conditionne la validation. La
    // biométrie qui partage désormais cette page est un confort, pas une
    // obligation, et son interrupteur ne doit rien bloquer.
    if (_currentStep == 4) {
      return _passwordController.text.length >= 6;
    }
    return false;
  }

  /// Mode sombre courant. Recalculé à chaque build : `MyApp.themeNotifier`
  /// pilote le `themeMode` du MaterialApp, dont tout changement reconstruit
  /// cet écran — pas besoin d'un ValueListenableBuilder de plus.
  bool get _sombre {
    final ThemeMode mode = MyApp.themeNotifier.value;
    if (mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? localizations = AppLocalizations.of(context);

    final ScrollPhysics pagePhysics = _validerEtapeActuelle() 
        ? const BouncingScrollPhysics() 
        : const NeverScrollableScrollPhysics();

    String boutonTexte = "Suivant";
    
    if (_currentStep == 0) {
      try {
        boutonTexte = localizations?.onboardingBtnGetStarted ?? ((_selectedLangue == "en") ? "Get started" : "Commencer");
      } catch(_) {
        boutonTexte = (_selectedLangue == "en") ? "Get started" : "Commencer";
      }
    } else if (_currentStep == 4) {
      try {
        boutonTexte = localizations?.onboardingBtnValidate ?? "Valider";
      } catch(_) {
        boutonTexte = "Valider";
      }
    } else {
      try {
        boutonTexte = localizations?.onboardingBtnNext ?? "Suivant";
      } catch(_) {
        boutonTexte = "Suivant";
      }
    }

    return Scaffold(
      // Fond clair, en cohérence avec la home.
      backgroundColor: _sombre ? darkBg : lightOrange,
      resizeToAvoidBottomInset: true, 
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: _currentStep > 0
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: orange, size: 22),
                              onPressed: _revenirEnArriere,
                            )
                          : const SizedBox.shrink(),
                    ),
                    const Expanded(
                      child: Center(
                        child: LogoSourire(color: orange),
                      ),
                    ),
                    const SizedBox(width: 48), 
                  ],
                ),
              ),
            ),

            if (_currentStep > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // Trois pastilles : prénom, accord, accès. La quatrième a
                  // disparu avec la fusion du mot de passe et de la biométrie.
                  children: List.generate(3, (index) {
                    bool isSelected = (_currentStep - 2) == index;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? orange : Colors.transparent,
                        border: Border.all(color: orange, width: 2),
                      ),
                    );
                  }),
                ),
              ),

            Expanded(
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 10 && _currentStep > 0) {
                    _revenirEnArriere();
                  }
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is UserScrollNotification) {
                      FocusScope.of(context).unfocus();
                    }
                    return false;
                  },
                  // Bornée, la colonne d'onboarding garde sur tablette la
                  // même mise en page que sur téléphone : les champs restent
                  // des champs, et le regard n'a pas à traverser la dalle.
                  child: ContenuCentre(
                  child: PageView(
                    controller: _pageController,
                    physics: pagePhysics,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      _buildEtapeLangue(),
                      _buildEtapeBienvenue(localizations),          
                      _buildEtapePrenom(localizations),             
                      _buildEtapeGenre(localizations),
                      _buildEtapeSecurite(localizations),
                    ],
                  ),
                    ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: BtnOnboarding(
                text: boutonTexte,
                isActive: _validerEtapeActuelle(), 
                onTap: _passerALEtapeSuivante,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtapeLangue() {
    // Scrollable et non figée : à la fermeture du clavier, la hauteur
    // disponible passe brièvement sous celle du contenu. Une Column rigide y
    // affichait la bande jaune et noire de débordement.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              // Construits depuis le catalogue : ajouter une langue à
              // `Langues.toutes` la fait apparaître ici sans rien toucher.
              children: <Widget>[
                for (final LangueApp langue in Langues.toutes) ...<Widget>[
                  _buildLangueButton(langue),
                  if (langue != Langues.toutes.last) const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLangueButton(LangueApp langue) {
    bool isSelected = _selectedLangue == langue.code;
    return InkWell(
      onTap: () async {
        setState(() {
          _selectedLangue = langue.code;
        });
        await UserPrefs.setLangue(langue.code);
        MyApp.localeNotifier.value = langue.locale;
      },
      child: Container(
        // Plancher et non hauteur figée : au réglage d'accessibilité maximum,
        // le libellé dépasserait des 55 px et Flutter afficherait sa bande de
        // débordement. La carte s'étire désormais au lieu de rogner.
        constraints: const BoxConstraints(minHeight: 55),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _sombre ? darkSurface : white,
          borderRadius: BorderRadius.circular(8),
          // Sans ombre, ces cartes blanches se fondraient dans le lightOrange.
          // En sombre l'ombre ne sert plus à rien : c'est le contraste de la
          // surface qui détache la carte.
          boxShadow: _sombre ? null : shadowSoft,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              langue.nom,
              style: styleCorps.copyWith(color: texteFort(_sombre)),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: orange, width: 2),
                color: isSelected ? orange : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: white) : null,
            ),
          ],
        ),
      ),
    );
  }

  // --- ÉTAPE 1 : BIENVENUE ---
  Widget _buildEtapeBienvenue(AppLocalizations? localizations) {
    String msg = "Bienvenue dans ton\nespace personnel conçu\npour te redonner le\nsourire !";
    try {
      msg = localizations?.onboardingWelcomeMessage ?? msg;
    } catch(_) {}

    // Calcul de la taille de police adaptative pour le message de bienvenue (Base 32 sur écran standard de 375px)
    final double adaptiveWelcomeSize = (MediaQuery.of(context).size.width * 0.075).clamp(24.0, 40.0);

    // Scrollable et non figée : à la fermeture du clavier, la hauteur
    // disponible passe brièvement sous celle du contenu. Une Column rigide y
    // affichait la bande jaune et noire de débordement.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  msg,
                  style: styleTitreLora.copyWith(
                    fontSize: tailleLora(adaptiveWelcomeSize),
                    color: orange,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- ÉTAPE 2 : LE PRÉNOM ---
  Widget _buildEtapePrenom(AppLocalizations? localizations) {
    String question = "Comment t'appelles-tu ?";
    String hint = "Prénom";
    try {
      question = localizations?.onboardingQuestionName ?? question;
      hint = localizations?.onboardingHintName ?? hint;
    } catch(_) {}

    // Calcul de la taille de police adaptative pour les titres d'étape (Base 24 sur écran standard)
    final double adaptiveTitleSize = (MediaQuery.of(context).size.width * 0.064).clamp(18.0, 30.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      question,
                      style: styleTitreLora.copyWith(fontSize: tailleLora(adaptiveTitleSize), color: orange),
                    ),
                    const SizedBox(height: 14),
                    // Les champs sont blancs sur un fond lightOrange : une ombre
                    // très légère leur redonne un contour.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        boxShadow: _sombre ? null : shadowSoft,
                      ),
                      child: TextField(
                        controller: _prenomController,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (valeur) {
                          setState(() {
                            UserPrefs.prenom = valeur.trim();
                          });
                        },
                        style: TextStyle(color: texteFort(_sombre)),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: TextStyle(color: texteDoux(_sombre)),
                          filled: true,
                          fillColor: _sombre ? darkSurface : white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
            ),
          );
        },
      );
    }

    // --- ÉTAPE 3 : LE GENRE ---
    Widget _buildEtapeGenre(AppLocalizations? localizations) {
      String question = "Comment dois-je m'adresser à toi ?";
      String male = "Au masculin";
      String female = "Au féminin";
      String none = "En écriture inclusive";
      try {
        question = localizations?.onboardingQuestionGender ?? question;
        male = localizations?.onboardingGenderMale ?? male;
        female = localizations?.onboardingGenderFemale ?? female;
        none = localizations?.onboardingGenderNone ?? none;
      } catch(_) {}

      final double adaptiveTitleSize = (MediaQuery.of(context).size.width * 0.064).clamp(18.0, 30.0);

      // Scrollable et non figée : à la fermeture du clavier, la hauteur
      // disponible passe brièvement sous celle du contenu. Une Column rigide y
      // affichait la bande jaune et noire de débordement.
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: styleTitreLora.copyWith(fontSize: tailleLora(adaptiveTitleSize), color: orange),
              ),
              const SizedBox(height: 14),
              _buildGenreButton(male, UserPrefs.genreMasculin),
              const SizedBox(height: 14),
              _buildGenreButton(female, UserPrefs.genreFeminin),
              const SizedBox(height: 14),
              // Genre neutre : l'accord bascule alors en écriture inclusive
              // (« heureux·se ») partout dans l'app.
              _buildGenreButton(none, UserPrefs.genreNeutre),
            ],
            ),
          ),
        );
      },
    );
  }

  /// [genreLabel] est le libellé affiché (traduit), [codeGenre] la valeur
  /// réellement persistée ('f' / 'h') — pour que l'accord « heureux /
  /// heureuse » ne dépende pas de la langue active au moment de l'onboarding.
  Widget _buildGenreButton(String genreLabel, String codeGenre) {
    bool isSelected = _selectedGenre == codeGenre;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGenre = codeGenre;
          UserPrefs.genre = codeGenre;
        });
      },
      child: Container(
        // Plancher et non hauteur figée : au réglage d'accessibilité maximum,
        // le libellé dépasserait des 55 px et Flutter afficherait sa bande de
        // débordement. La carte s'étire désormais au lieu de rogner.
        constraints: const BoxConstraints(minHeight: 55),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _sombre ? darkSurface : white,
          borderRadius: BorderRadius.circular(8),
          // Sans ombre, ces cartes blanches se fondraient dans le lightOrange.
          // En sombre l'ombre ne sert plus à rien : c'est le contraste de la
          // surface qui détache la carte.
          boxShadow: _sombre ? null : shadowSoft,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              genreLabel,
              style: styleCorps.copyWith(color: texteFort(_sombre)),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: orange, width: 2),
                color: isSelected ? orange : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: white) : null,
            ),
          ],
        ),
      ),
    );
  }

  // --- ÉTAPE 4, LA DERNIÈRE : L'ACCÈS À L'ESPACE ---
  //
  // Mot de passe ET biométrie sur une seule page. Elles vivaient sur deux
  // écrans successifs, ce qui obligeait à valider le premier pour découvrir
  // que le second parlait de la même chose : comment on entre chez soi. Le
  // mot de passe pose le verrou, la biométrie choisit par quoi l'ouvrir plus
  // vite — cela se décide d'un seul regard, pas en deux temps.
  //
  // Rien d'autre n'est demandé ici : pas d'adresse e-mail, pas d'identifiant,
  // aucun compte. Ce qui est saisi ne quitte jamais l'appareil, et seule une
  // empreinte salée du mot de passe en est conservée (voir UserPrefs).
  Widget _buildEtapeSecurite(AppLocalizations? localizations) {
    String titre = "Sécurise l'accès à ton espace";
    String hintPass = "Mot de passe (6 caractères min.)";
    String bioLabel = "Activer la biométrie";

    try {
      titre = localizations?.onboardingSecurityTitle ?? titre;
      hintPass = localizations?.onboardingHintPassword ?? hintPass;
      bioLabel = localizations?.onboardingBiometricsLabel ?? bioLabel;
    } catch(_) {}

    final double adaptiveTitleSize = (MediaQuery.of(context).size.width * 0.064).clamp(18.0, 30.0);

    // Scrollable et non figée : à la fermeture du clavier, la hauteur
    // disponible passe brièvement sous celle du contenu. Une Column rigide y
    // affichait la bande jaune et noire de débordement. La page porte
    // maintenant deux blocs au lieu d'un, donc la précaution compte double.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  titre,
                  style: styleTitreLora.copyWith(fontSize: tailleLora(adaptiveTitleSize), color: orange),
                ),
                const SizedBox(height: 14),

                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    boxShadow: _sombre ? null : shadowSoft,
                  ),
                  child: TextField(
                    controller: _passwordController,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscurePassword,
                    style: TextStyle(color: texteFort(_sombre)),
                    decoration: InputDecoration(
                      hintText: hintPass,
                      hintStyle: TextStyle(color: texteDoux(_sombre)),
                      filled: true,
                      fillColor: _sombre ? darkSurface : white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: orange),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // LA BIOMÉTRIE, posée sous le mot de passe qu'elle remplace au
                // quotidien. L'ordre n'est pas indifférent : on pose d'abord le
                // verrou, on choisit ensuite le raccourci qui l'ouvre.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Le libellé et son point d'interrogation forment un seul
                    // bloc, qui prend la place restante. L'interrupteur garde
                    // la sienne, à droite. Aucune largeur n'est calculée sur
                    // celle de l'écran : voir item_categorie.dart pour ce que
                    // cela coûte sur une tablette.
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              bioLabel,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: orange),
                            ),
                          ),
                          // Collé au libellé et non rejeté au bout de la
                          // ligne : c'est le mot « biométrie » qu'il explique.
                          // La zone tapable est élargie par le padding, le
                          // dessin reste petit.
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _expliquerBiometrie(localizations, bioLabel),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              child: Icon(Icons.help_outline, color: orange, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    SwitchBiometrie(
                      key: ValueKey(_biometrieValue), 
                      initialValue: _biometrieValue,
                      isNegative: false,
                      onChanged: (val) async {
                        if (val) {
                          setState(() {
                            _biometrieValue = true;
                          });

                          bool succes = await BiometricService.authentifier();

                          if (!mounted) return;
                          setState(() {
                            _biometrieValue = succes;
                          });
                        } else {
                          setState(() {
                            _biometrieValue = false;
                          });
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dit à quoi sert la biométrie, sans jargon.
  ///
  /// Le réglage porte ce nom parce que c'est le sien, mais le mot ne dit rien
  /// à qui ne l'a jamais croisé — et Sourire s'adresse aussi à ces
  /// personnes-là. Le point d'interrogation est pour elles. Un texte d'aide
  /// affiché en permanence sous un interrupteur, lui, alourdit la page de tout
  /// le monde pour renseigner quelques-uns.
  Future<void> _expliquerBiometrie(
    AppLocalizations? localizations,
    String titre,
  ) async {
    String message =
        "L'activation de la biométrie permet de déverrouiller l'application "
        "grâce à l'empreinte digitale ou la reconnaissance faciale, sans avoir "
        "à réécrire le mot de passe à chaque connexion.";

    try {
      message = localizations?.onboardingBiometricsHelp ?? message;
    } catch(_) {}

    await showDialog<void>(
      context: context,
      builder: (contexteModale) => AlertDialog(
        backgroundColor: _sombre ? darkSurface : white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          titre,
          style: styleTitreAction.copyWith(color: texteFort(_sombre)),
        ),
        content: Text(
          message,
          style: styleSecondaire.copyWith(color: texteDoux(_sombre)),
        ),
        actions: [
          TextButton(
            // Le libellé du bouton vient de Flutter, qui le traduit déjà dans
            // les trois langues. Une clé de plus dans les .arb pour écrire
            // « OK » n'aurait servi qu'à être oubliée dans l'une des trois.
            onPressed: () => Navigator.of(contexteModale).pop(),
            child: Text(
              MaterialLocalizations.of(contexteModale).okButtonLabel,
              style: styleCorps.copyWith(color: orange, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
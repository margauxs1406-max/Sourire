import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart'; 
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

  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedGenre = ""; 
  bool _biometrieValue = false;
  bool _obscurePassword = true;
  String _selectedLangue = UserPrefs.langue; 

  bool _isEmailValid(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email.trim());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _passerALEtapeSuivante() {
    FocusScope.of(context).unfocus();
    
    if (_validerEtapeActuelle()) {
      if (_currentStep < 5) { 
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        debugPrint("ONBOARDING LOG : Validation finale de l'étape 5 lancée.");
        
        try {
          UserPrefs.email = _emailController.text.trim();
          UserPrefs.password = _passwordController.text;
          UserPrefs.biomatrieActive = _biometrieValue; 
          UserPrefs.modeDemoAffiche = false; 
          
          debugPrint("ONBOARDING LOG : Données UserPrefs sauvegardées avec succès (Biométrie active : $_biometrieValue). Transition vers Home...");

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
    if (_currentStep == 4) { 
      return _isEmailValid(_emailController.text) && _passwordController.text.length >= 6;
    }
    if (_currentStep == 5) return true; 
    return false;
  }

  @override
  Widget build(BuildContext context) {
    dynamic localizations = AppLocalizations.of(context); 

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
    } else if (_currentStep == 5) {
      try {
        boutonTexte = localizations?.onboardingBtnPhfValidate ?? "Valider";
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
      backgroundColor: orange,
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
                              icon: const Icon(Icons.arrow_back_ios_new, color: white, size: 22),
                              onPressed: _revenirEnArriere,
                            )
                          : const SizedBox.shrink(),
                    ),
                    const Expanded(
                      child: Center(
                        child: LogoSourire(color: white),
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
                  children: List.generate(4, (index) {
                    bool isSelected = (_currentStep - 2) == index;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? white : Colors.transparent,
                        border: Border.all(color: white, width: 2),
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
                      _buildEtapeBiometrie(localizations), 
                    ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLangueButton("Français", "fr", const Locale('fr', 'FR')),
          const SizedBox(height: 14),
          _buildLangueButton("English", "en", const Locale('en', 'US')),
        ],
      ),
    );
  }

  Widget _buildLangueButton(String label, String codeLangue, Locale locale) {
    bool isSelected = _selectedLangue == codeLangue;
    return InkWell(
      onTap: () async {
        setState(() {
          _selectedLangue = codeLangue;
        });
        await UserPrefs.setLangue(codeLangue);
        MyApp.localeNotifier.value = locale; 
      },
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: black, fontWeight: FontWeight.w500),
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
  Widget _buildEtapeBienvenue(localizations) {
    String msg = "Bienvenue dans ton\nespace personnel conçu\npour te redonner le\nsourire !";
    try {
      msg = localizations?.onboardingWelcomeMessage ?? msg;
    } catch(_) {}

    // Calcul de la taille de police adaptative pour le message de bienvenue (Base 32 sur écran standard de 375px)
    final double adaptiveWelcomeSize = (MediaQuery.of(context).size.width * 0.075).clamp(24.0, 40.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            msg,
            style: TextStyle(
              fontSize: adaptiveWelcomeSize, 
              color: white, 
              fontFamily: 'Lobster Two',
              height: 1.3,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  // --- ÉTAPE 2 : LE PRÉNOM ---
  Widget _buildEtapePrenom(localizations) {
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
                  style: TextStyle(fontSize: adaptiveTitleSize, color: white, fontFamily: 'Lobster Two'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _prenomController,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (valeur) {
                    setState(() {
                      UserPrefs.prenom = valeur.trim();
                    });
                  },
                  style: const TextStyle(color: black),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: grey),
                    filled: true,
                    fillColor: white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
  Widget _buildEtapeGenre(localizations) {
    String question = "Tu es...";
    String male = "Un homme";
    String female = "Une femme";
    try {
      question = localizations?.onboardingQuestionGender ?? question;
      male = localizations?.onboardingGenderMale ?? male;
      female = localizations?.onboardingGenderFemale ?? female;
    } catch(_) {}

    final double adaptiveTitleSize = (MediaQuery.of(context).size.width * 0.064).clamp(18.0, 30.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(fontSize: adaptiveTitleSize, color: white, fontFamily: 'Lobster Two'),
          ),
          const SizedBox(height: 14),
          _buildGenreButton(male),
          const SizedBox(height: 14),
          _buildGenreButton(female),
        ],
      ),
    );
  }

  Widget _buildGenreButton(String genreLabel) {
    bool isSelected = _selectedGenre == genreLabel;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGenre = genreLabel;
          UserPrefs.genre = genreLabel;
        });
      },
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              genreLabel,
              style: const TextStyle(fontSize: 16, color: black, fontWeight: FontWeight.w500),
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

  // --- ÉTAPE 4 : COMPTE + SÉCURITÉ ---
  Widget _buildEtapeSecurite(localizations) {
    String titre = "Sécurise tes données";
    String hintEmail = "Email";
    String emailValideTxt = "email valide";
    String emailInvalideTxt = "email non valide";
    String hintPass = "Mot de passe (6 caractères min.)";

    try {
      titre = localizations?.onboardingSecurityTitle ?? titre;
      hintEmail = localizations?.onboardingHintEmail ?? hintEmail;
      emailValideTxt = localizations?.onboardingEmailValid ?? emailValideTxt;
      emailInvalideTxt = localizations?.onboardingEmailInvalid ?? emailInvalideTxt;
      hintPass = localizations?.onboardingHintPassword ?? hintPass;
    } catch(_) {}

    final double adaptiveTitleSize = (MediaQuery.of(context).size.width * 0.064).clamp(18.0, 30.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final String emailSaisi = _emailController.text;
        final bool emailEstValide = _isEmailValid(emailSaisi);

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
                  titre,
                  style: TextStyle(fontSize: adaptiveTitleSize, color: white, fontFamily: 'Lobster Two'),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _emailController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: black),
                  decoration: InputDecoration(
                    hintText: hintEmail,
                    hintStyle: const TextStyle(color: grey),
                    filled: true,
                    fillColor: white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                
                if (emailSaisi.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      emailEstValide ? emailValideTxt : emailInvalideTxt,
                      style: TextStyle(
                        color: emailEstValide ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                TextField(
                  controller: _passwordController,
                  onChanged: (_) => setState(() {}),
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: black),
                  decoration: InputDecoration(
                    hintText: hintPass,
                    hintStyle: const TextStyle(color: grey),
                    filled: true,
                    fillColor: white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: orange),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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

  // --- ÉTAPE 5 : BIOMÉTRIE ---
  Widget _buildEtapeBiometrie(localizations) {
    String titreBio = "Facilite ton accès à l'application";
    String bioLabel = "Activer la biométrie";

    try {
      titreBio = localizations?.onboardingBiometricsTitle ?? titreBio;
      bioLabel = localizations?.onboardingBiometricsLabel ?? bioLabel;
    } catch(_) {}

    final double adaptiveTitleSize = (MediaQuery.of(context).size.width * 0.064).clamp(18.0, 30.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titreBio,
            style: TextStyle(fontSize: adaptiveTitleSize, color: white, fontFamily: 'Lobster Two'),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bioLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: white),
                  ),
                ),
                const SizedBox(width: 15),
                SwitchBiometrie(
                  key: ValueKey(_biometrieValue), 
                  initialValue: _biometrieValue,
                  isNegative: true,
                  onChanged: (val) async {
                    if (val) {
                      setState(() {
                        _biometrieValue = true;
                      });

                      bool succes = await BiometricService.authentifier();
                      
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
          ),
        ],
      ),
    );
  }
}
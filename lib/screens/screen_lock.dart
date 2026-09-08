import 'package:flutter/material.dart';
import 'package:sourire/main.dart';
import 'package:sourire/screens/screen_reset_password.dart';
import 'package:sourire/services/biometric_service.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/widgets/btn_onboarding.dart';
import 'package:sourire/widgets/logo_sourire.dart';
import 'package:sourire/l10n/app_localizations.dart';

class ScreenLock extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const ScreenLock({
    super.key, 
    required this.onAuthenticated,
  });

  @override
  State<ScreenLock> createState() => _ScreenLockState();
}

class _ScreenLockState extends State<ScreenLock> {
  final TextEditingController _passwordController = TextEditingController();
  bool _showPasswordInput = false;
  bool _obscureText = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (UserPrefs.biomatrieActive) {
        // Au réveil par notif, on laisse le temps au canal natif de respirer
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) {
          _authentifierBiometrie();
        }
      } else if (UserPrefs.aUnMotDePasse) {
        setState(() {
          _showPasswordInput = true;
        });
      } else {
        _traiterSuccesAuthentification();
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authentifierBiometrie() async {
    // Si l'écran n'est plus affiché ou si l'app est déjà déverrouillée entre-temps, on stoppe tout
    if (!mounted || !isAppLockedNotifier.value) return;

    final localizations = AppLocalizations.of(context);
    final reasonText = localizations?.lockBiometricReason ?? "Verrouillage de sécurité Sourire";

    try {
      bool succes = await BiometricService.authentifier(
        reason: reasonText,
      );
      
      if (!mounted) return;

      if (succes) {
        _traiterSuccesAuthentification();
      } else {
        // 🌟 SÉCURITÉ : Si la biométrie échoue, on vérifie d'abord que le verrouillage global
        // est TOUJOURS actif avant de forcer l'affichage du mot de passe.
        if (isAppLockedNotifier.value && UserPrefs.aUnMotDePasse) {
          setState(() {
            _showPasswordInput = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur biométrie interceptée : $e");
      if (mounted && UserPrefs.aUnMotDePasse) {
        setState(() {
          _showPasswordInput = true;
        });
      }
    }
  }

  void _validerMotDePasse() {
    if (UserPrefs.verifierMotDePasse(_passwordController.text)) {
      _traiterSuccesAuthentification();
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  void _traiterSuccesAuthentification() {
    // On désactive le verrouillage
    isAppLockedNotifier.value = false;
    
    // On appelle le callback qui va détruire le ScreenLock et lancer la Home
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = UserPrefs.isDark;
    final localizations = AppLocalizations.of(context);

    final String txtHint = localizations?.lockInputHint ?? "Entrez votre mot de passe";
    final String txtForgot = localizations?.lockForgotPassword ?? "Mot de passe oublié ?";
    final String txtBtnValidate = localizations?.btnValidate ?? "Valider";
    final String txtBtnBio = localizations?.lockBtnBiometric ?? "Utiliser l'empreinte";
    final String? txtError = _hasError ? (localizations?.lockErrorIncorrect ?? "Mot de passe incorrect") : null;

    return PopScope(
      canPop: false, 
      child: Scaffold(
        backgroundColor: isDark ? darkBg : orange,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            // Un champ de mot de passe large de mille points sur iPad n'est
            // pas un champ, c'est une barre. Bornée et centrée.
            child: ContenuCentre(
              largeurMax: 480,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: LogoSourire(),
                  ),
                ),
                
                const Spacer(),

                if (_showPasswordInput) ...[
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    cursorColor: orange, 
                    style: TextStyle(color: isDark ? white : black),
                    decoration: InputDecoration(
                      hintText: txtHint,
                      hintStyle: TextStyle(color: isDark ? white.withValues(alpha: 0.5) : Colors.black45),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                          color: isDark ? white.withValues(alpha: 0.6) : Colors.black45,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) => _validerMotDePasse(),
                  ),
                  
                  if (txtError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        txtError,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ScreenResetPassword(),
                          ),
                        );
                      },
                      child: Text(
                        txtForgot,
                        style: TextStyle(
                          color: white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: white,
                        ),
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                if (_showPasswordInput) ...[
                  BtnOnboarding(
                    text: txtBtnValidate,
                    onTap: _validerMotDePasse,
                  ),

                  if (UserPrefs.biomatrieActive) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showPasswordInput = false;
                          _hasError = false;
                        });
                        _authentifierBiometrie();
                      },
                      icon: const Icon(Icons.fingerprint, color: white),
                      label: Text(
                        txtBtnBio, 
                        style: const TextStyle(color: white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ],
            ),
                    ),
          ),
        ),
      ),
    );
  }
}
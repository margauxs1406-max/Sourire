import 'package:flutter/material.dart';
import 'package:sourire/l10n/app_localizations.dart';
import 'package:sourire/theme/tokens.dart';
import 'package:sourire/theme/user_prefs.dart';
import 'package:sourire/widgets/btn_onboarding.dart';
import 'package:sourire/widgets/logo_sourire.dart';

/// Choix d'un nouveau mot de passe, depuis le profil comme depuis l'écran de
/// verrouillage.
///
/// Aucune vérification préalable, et c'est un choix assumé.
///
/// Techniquement, cet écran laisse quelqu'un qui tient le téléphone
/// déverrouillé se donner un nouveau mot de passe et lire le bocal. Sans
/// serveur, les seules façons de le refuser seraient d'exiger la
/// reconnaissance du propriétaire par l'appareil, ou d'effacer les souvenirs.
/// L'une comme l'autre condamnent au silence la personne qui a simplement
/// oublié son mot de passe — et sur une application de souvenirs heureux, ce
/// cas-là est mille fois plus fréquent que le curieux malintentionné.
///
/// Le mot de passe de Sourire est donc un loquet, pas une serrure : il évite
/// qu'un proche ouvre le bocal par curiosité. La vraie serrure, c'est le code
/// de déverrouillage du téléphone. C'est aussi ce que devraient dire les
/// textes de la fiche et de la politique de confidentialité.
class ScreenResetPassword extends StatefulWidget {
  const ScreenResetPassword({super.key});

  @override
  State<ScreenResetPassword> createState() => _ScreenResetPasswordState();
}

class _ScreenResetPasswordState extends State<ScreenResetPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Une clé plutôt qu'un texte traduit : la traduction se résout à
  // l'affichage, pas au moment de l'erreur.
  String? _errorKey;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _enregistrerNouveauMotDePasse(AppLocalizations? localizations) async {
    final pwd = _passwordController.text.trim();
    final confirmPwd = _confirmPasswordController.text.trim();

    if (pwd.isEmpty || confirmPwd.isEmpty) {
      setState(() => _errorKey = "empty");
      return;
    }

    if (pwd != confirmPwd) {
      setState(() => _errorKey = "mismatch");
      return;
    }

    // `definirMotDePasse` enregistre une EMPREINTE salée, jamais le mot de
    // passe lui-même. Voir UserPrefs.
    await UserPrefs.definirMotDePasse(pwd);
    if (!mounted) return;

    final successMessage = localizations?.resetPasswordSuccess ??
        "Mot de passe réinitialisé avec succès";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = UserPrefs.isDark;
    final double adaptiveTitleSize =
        (MediaQuery.of(context).size.width * 0.064).clamp(18.0, 30.0);
    final localizations = AppLocalizations.of(context);

    final String txtTitle =
        localizations?.resetPasswordTitle ?? "Réinitialise ton mot de passe";
    final String txtHintNew =
        localizations?.resetPasswordHintNew ?? "Nouveau mot de passe";
    final String txtHintConfirm =
        localizations?.resetPasswordHintConfirm ?? "Confirmez le mot de passe";
    final String txtBtn = localizations?.btnValidate ?? "Valider";

    String? errorMessage;
    if (_errorKey == "empty") {
      errorMessage =
          localizations?.resetPasswordErrorEmpty ?? "Veuillez remplir tous les champs";
    } else if (_errorKey == "mismatch") {
      errorMessage = localizations?.resetPasswordErrorMismatch ??
          "Les mots de passe ne correspondent pas";
    }

    return Scaffold(
      backgroundColor: isDark ? darkBg : orange,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              // Sur tablette, un champ de saisie large de mille points n'est
              // plus un champ, c'est une barre. Bornée et centrée — sans effet
              // sur téléphone, déjà plus étroit que la borne.
              child: ContenuCentre(
                largeurMax: 480,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: LogoSourire(),
                          ),
                        ),

                        // Bloc central flexible
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    txtTitle,
                                    textAlign: TextAlign.left,
                                    style: styleTitreLora.copyWith(
                                      fontSize: tailleLora(adaptiveTitleSize),
                                      color: white,
                                    ),
                                  ),
                                ),
                              ),

                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                cursorColor: orange,
                                style: TextStyle(color: isDark ? white : black),
                                decoration: _inputDecoration(
                                  txtHintNew,
                                  isDark,
                                  _obscurePassword,
                                  () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),

                              const SizedBox(height: 16),

                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                cursorColor: orange,
                                style: TextStyle(color: isDark ? white : black),
                                decoration: _inputDecoration(
                                  txtHintConfirm,
                                  isDark,
                                  _obscureConfirmPassword,
                                  () => setState(() =>
                                      _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),

                              if (errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Text(
                                    errorMessage,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: BtnOnboarding(
                            text: txtBtn,
                            onTap: () => _enregistrerNouveauMotDePasse(localizations),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint, bool isDark, bool obscure, VoidCallback onToggle) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: isDark ? white.withValues(alpha: 0.5) : Colors.black45),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
            color: isDark ? white.withValues(alpha: 0.6) : Colors.black45),
        onPressed: onToggle,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sourire/main.dart';
import 'package:sourire/screens/home.dart';
import 'package:sourire/screens/screen_lock.dart';
import 'package:sourire/screens/screen_onboarding.dart';
import 'package:sourire/theme/user_prefs.dart';

class ScreenBoot extends StatefulWidget {
  const ScreenBoot({super.key});

  @override
  State<ScreenBoot> createState() => _ScreenBootState();
}

class _ScreenBootState extends State<ScreenBoot> {
  @override
  void initState() {
    super.initState();
    
    // On attend un frame complet pour s'assurer que le main() 
    // et le plugin de notification ont fini leurs initialisations réciproques.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aiguillerUtilisateur();
    });
  }

  void _aiguillerUtilisateur() {
    if (!mounted) return;

    // 1. Cas Onboarding
    if (UserPrefs.prenom.isEmpty && UserPrefs.password.isEmpty) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ScreenOnboarding()),
        (route) => false,
      );
      return;
    }

    // 2. Cas Verrouillé
    if (isAppLockedNotifier.value) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'ScreenLock'),
          builder: (context) => ScreenLock(
            onAuthenticated: () {
              isAppLockedNotifier.value = false;
              
              // SÉCURITÉ TIMING IOS : On laisse un infime répit au plugin pour inscrire l'ID en cache global
              Future.delayed(const Duration(milliseconds: 250), () {
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const Home()),
                    (route) => false,
                  );
                }
              });
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Un écran totalement neutre, pas de Home, pas de toupie, pas d'ombre.
    return const Scaffold(
      backgroundColor: Colors.white, // Ou ta couleur 'orange' / 'darkBg'
      body: Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
    );
  }
}
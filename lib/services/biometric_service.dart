import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authentifier({String? reason}) async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      
      if (!canAuthenticateWithBiometrics && !isDeviceSupported) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: reason ?? "Authentifie-toi pour accéder à tes souvenirs",
        biometricOnly: true,
      );
    } catch (e) {
      print("Erreur biométrie: $e");
      return false;
    }
  }
}
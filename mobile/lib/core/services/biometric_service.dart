import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'storage_service.dart';

/// Handles biometric availability, authentication, and secure credential storage
/// for "Sign in with Face ID / Fingerprint" flow.
class BiometricService extends GetxService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device can check biometrics (hardware support).
  Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  /// List of enrolled biometric types (e.g. face, fingerprint).
  Future<List<BiometricType>> getAvailableBiometrics() => _auth.getAvailableBiometrics();

  /// True if device has at least one enrolled biometric we can use for login.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty &&
          list.any((t) => t == BiometricType.face || t == BiometricType.fingerprint);
    } catch (_) {
      return false;
    }
  }

  /// User-facing label: "Face ID", "Fingerprint", or "Biometric".
  Future<String> getBiometricLabel() async {
    final list = await _auth.getAvailableBiometrics();
    if (list.contains(BiometricType.face)) return 'Face ID';
    if (list.contains(BiometricType.fingerprint)) return 'Fingerprint';
    return 'Biometric';
  }

  /// Persist credentials for biometric login. Call after successful password login when user opts in.
  Future<void> saveCredentialsForBiometric(String email, String password) async {
    await StorageService.saveBiometricCredentials(email, password);
  }

  /// Whether stored credentials exist (so we can show "Sign in with Face ID" etc.).
  Future<bool> hasStoredCredentials() async {
    final creds = await StorageService.getBiometricCredentials();
    return creds != null;
  }

  /// Authenticate with biometric then return stored (email, password). Returns null if cancelled or error.
  Future<({String email, String password})?> authenticateAndGetCredentials() async {
    try {
      final creds = await StorageService.getBiometricCredentials();
      if (creds == null) return null;
      final reason = await getBiometricLabel();
      final authenticated = await _auth.authenticate(
        localizedReason: 'Sign in with $reason',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!authenticated) return null;
      return creds;
    } catch (_) {
      return null;
    }
  }

  /// Clear stored biometric credentials (call on logout).
  Future<void> clearStoredCredentials() async {
    await StorageService.clearBiometricCredentials();
  }
}

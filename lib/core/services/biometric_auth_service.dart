import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Vérifie si la biométrie est disponible sur l'appareil
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Obtient les types de biométrie disponibles
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// 🚀 OPTIMISÉ: Cache pour éviter les vérifications répétées
  static bool? _cachedBiometricAvailability;
  static DateTime? _lastAvailabilityCheck;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// 🚀 OPTIMISÉ: Vérifie la disponibilité avec cache
  static Future<bool> _isBiometricAvailableOptimized() async {
    final now = DateTime.now();
    
    // Utiliser le cache si valide (5 minutes)
    if (_cachedBiometricAvailability != null && 
        _lastAvailabilityCheck != null &&
        now.difference(_lastAvailabilityCheck!) < _cacheValidityDuration) {
      return _cachedBiometricAvailability!;
    }
    
    // Vérification réelle
    final isAvailable = await isBiometricAvailable();
    _cachedBiometricAvailability = isAvailable;
    _lastAvailabilityCheck = now;
    
    return isAvailable;
  }

  /// Authentifie l'utilisateur avec la biométrie (optimisé)
  static Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Veuillez vous authentifier pour accéder à l\'application',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      // 🚀 OPTIMISÉ: Vérification avec cache
      final bool isAvailable = await _isBiometricAvailableOptimized();
      if (!isAvailable) {
        return BiometricAuthResult.biometricNotAvailable;
      }

      // Authentification biométrique
      final bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Permettre PIN/Pattern en fallback
        ),
      );

      return isAuthenticated 
          ? BiometricAuthResult.success 
          : BiometricAuthResult.failed;
          
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
          return BiometricAuthResult.biometricNotAvailable;
        case auth_error.notEnrolled:
          return BiometricAuthResult.biometricNotEnrolled;
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return BiometricAuthResult.lockedOut;
        case auth_error.biometricOnlyNotSupported:
          return BiometricAuthResult.biometricNotSupported;
        default:
          return BiometricAuthResult.failed;
      }
    } catch (e) {
      return BiometricAuthResult.failed;
    }
  }

  /// Authentification avec fallback PIN/Pattern en cas d'absence de biométrie
  static Future<BiometricAuthResult> authenticateWithFallback({
    String localizedReason = 'Veuillez vous authentifier pour accéder à l\'application',
  }) async {
    try {
      final bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: false,
          biometricOnly: false, // Permet PIN/Pattern/Password
        ),
      );

      return isAuthenticated 
          ? BiometricAuthResult.success 
          : BiometricAuthResult.failed;
          
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
          return BiometricAuthResult.biometricNotAvailable;
        case auth_error.notEnrolled:
          return BiometricAuthResult.biometricNotEnrolled;
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return BiometricAuthResult.lockedOut;
        default:
          return BiometricAuthResult.failed;
      }
    } catch (e) {
      return BiometricAuthResult.failed;
    }
  }
}

/// Résultats possibles de l'authentification biométrique
enum BiometricAuthResult {
  success,
  failed,
  biometricNotAvailable,
  biometricNotEnrolled,
  biometricNotSupported,
  lockedOut,
}

/// Extension pour obtenir des messages utilisateur
extension BiometricAuthResultExtension on BiometricAuthResult {
  String get message {
    switch (this) {
      case BiometricAuthResult.success:
        return 'Authentification réussie';
      case BiometricAuthResult.failed:
        return 'Authentification échouée';
      case BiometricAuthResult.biometricNotAvailable:
        return 'La biométrie n\'est pas disponible sur cet appareil';
      case BiometricAuthResult.biometricNotEnrolled:
        return 'Aucune biométrie configurée. Veuillez configurer Face ID, Touch ID ou empreinte digitale dans les paramètres';
      case BiometricAuthResult.biometricNotSupported:
        return 'La biométrie n\'est pas supportée';
      case BiometricAuthResult.lockedOut:
        return 'L\'authentification biométrique est temporairement désactivée. Veuillez réessayer plus tard';
    }
  }

  bool get isSuccess => this == BiometricAuthResult.success;
}
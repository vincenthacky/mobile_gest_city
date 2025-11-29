import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BiometricAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Vérifie si la biométrie est disponible sur l'appareil
  /// Compatible Face ID, Touch ID, empreinte écran/surface arrière, etc.
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      // Certains appareils Android renvoient canCheckBiometrics = false
      // alors que l'authentification système fonctionne très bien.
      // On se base donc surtout sur isDeviceSupported + la liste réelle
      // des biométries disponibles.
      final available = await _localAuth.getAvailableBiometrics();

      // Si au moins un type est présent (fingerprint, face, etc.) → OK.
      // Sur certains appareils la liste peut être vide mais isDeviceSupported
      // suffit pour afficher le prompt système, donc on accepte aussi ce cas.
      return isDeviceSupported && (available.isNotEmpty || true);
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
      // IMPORTANT: ne pas bloquer sur canCheckBiometrics (buggé sur certains Android)
      final bool isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return BiometricAuthResult.biometricNotSupported;
      }

      // Vérifier les types de biométrie disponibles pour optimiser l'authentification
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint);
      final hasFace = availableBiometrics.contains(BiometricType.face);
      final hasWeak = availableBiometrics.contains(BiometricType.weak);
      final hasStrong = availableBiometrics.contains(BiometricType.strong);
      
      // Samsung et autres Android utilisent weak/strong pour empreintes écran
      final hasBiometric = hasFingerprint || hasFace || hasWeak || hasStrong;
      final hasScreenFingerprint = hasWeak || hasStrong;
      
      // Configuration optimisée selon le type de biométrie
      final authOptions = AuthenticationOptions(
        useErrorDialogs: useErrorDialogs,
        stickyAuth: stickyAuth,
        // biometricOnly true pour tous types de capteurs biométriques
        biometricOnly: hasBiometric,
        sensitiveTransaction: hasScreenFingerprint || hasFingerprint,
      );

      // Authentification biométrique avec retry automatique pour empreintes écran
      bool isAuthenticated = false;
      int retryCount = 0;
      const maxRetries = 2;

      while (!isAuthenticated && retryCount < maxRetries) {
        try {
          debugPrint('🔐 [AUTH] Tentative ${retryCount + 1}/$maxRetries avec options: $authOptions');
          
          isAuthenticated = await _localAuth.authenticate(
            localizedReason: localizedReason,
            options: authOptions,
          );
          
          debugPrint('🔐 [AUTH] Résultat tentative ${retryCount + 1}: $isAuthenticated');
          
          if (!isAuthenticated && retryCount < maxRetries - 1) {
            // Délai court avant retry pour empreintes écran
            debugPrint('🔐 [AUTH] Retry dans 300ms...');
            await Future.delayed(const Duration(milliseconds: 300));
            retryCount++;
          } else {
            break;
          }
        } catch (e) {
          debugPrint('❌ [AUTH] Erreur tentative ${retryCount + 1}: $e');
          if (retryCount < maxRetries - 1) {
            retryCount++;
            await Future.delayed(const Duration(milliseconds: 500));
          } else {
            rethrow;
          }
        }
      }

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
          // Fallback: essayer sans biometricOnly pour les appareils problématiques
          try {
            final fallbackResult = await _localAuth.authenticate(
              localizedReason: localizedReason,
              options: AuthenticationOptions(
                useErrorDialogs: useErrorDialogs,
                stickyAuth: stickyAuth,
                biometricOnly: false,
              ),
            );
            return fallbackResult ? BiometricAuthResult.success : BiometricAuthResult.failed;
          } catch (_) {
            return BiometricAuthResult.biometricNotSupported;
          }
        default:
          return BiometricAuthResult.failed;
      }
    } catch (e) {
      return BiometricAuthResult.failed;
    }
  }

  /// Diagnostique les types de biométrie et leur fonctionnement
  static Future<Map<String, dynamic>> diagnosticBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      return {
        'isDeviceSupported': isSupported,
        'canCheckBiometrics': canCheck,
        'availableBiometrics': availableBiometrics.map((e) => e.toString()).toList(),
        'hasFingerprint': availableBiometrics.contains(BiometricType.fingerprint),
        'hasFace': availableBiometrics.contains(BiometricType.face),
        'hasIris': availableBiometrics.contains(BiometricType.iris),
        'hasWeak': availableBiometrics.contains(BiometricType.weak),
        'hasStrong': availableBiometrics.contains(BiometricType.strong),
        'recommendedSettings': _getRecommendedSettings(availableBiometrics),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'isDeviceSupported': false,
        'canCheckBiometrics': false,
        'availableBiometrics': [],
      };
    }
  }

  /// Obtient les paramètres recommandés selon le type de biométrie
  static Map<String, dynamic> _getRecommendedSettings(List<BiometricType> available) {
    final hasFingerprint = available.contains(BiometricType.fingerprint);
    final hasFace = available.contains(BiometricType.face);
    final hasWeak = available.contains(BiometricType.weak);
    final hasStrong = available.contains(BiometricType.strong);
    
    final hasBiometric = hasFingerprint || hasFace || hasWeak || hasStrong;
    final hasScreenFingerprint = hasWeak || hasStrong;
    
    return {
      'biometricOnly': hasBiometric,
      'sensitiveTransaction': hasScreenFingerprint || hasFingerprint,
      'useErrorDialogs': true,
      'stickyAuth': true,
      'reason': hasScreenFingerprint
        ? 'Empreinte écran Samsung détectée (weak/strong) - configuration optimisée'
        : hasFingerprint 
          ? 'Empreinte standard détectée - configuration optimisée'
          : hasFace 
            ? 'Face ID détecté - configuration standard'
            : 'Configuration générique',
    };
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
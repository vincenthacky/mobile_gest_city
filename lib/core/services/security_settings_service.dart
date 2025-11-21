import '../storage/secure_storage.dart';
import 'biometric_auth_service.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer les préférences de sécurité utilisateur
/// Compatible avec l'architecture existante de device auth
class SecuritySettingsService {
  static const String _biometricPreferenceKey = 'biometric_preference'; // NOUVEAU
  static const String _pinPreferenceKey = 'pin_preference'; // NOUVEAU
  static const String _appPinKey = 'app_pin'; // NOUVEAU
  static const String _firstTimePromptKey = 'first_time_security_prompt'; // NOUVEAU
  
  // Keys existantes (compatibilité)
  static const String _legacyBiometricSetupKey = 'biometric_setup';
  
  static final _secureStorage = SecureStorage();
  
  /// Obtenir les préférences de sécurité utilisateur
  static Future<SecurityPreferences> getPreferences() async {
    final biometricPreference = await _secureStorage.read(_biometricPreferenceKey);
    final pinPreference = await _secureStorage.read(_pinPreferenceKey);
    final appPin = await _secureStorage.read(_appPinKey);
    final firstTimePromptShown = await _secureStorage.read(_firstTimePromptKey) == 'true';
    
    // Détection automatique de la disponibilité biométrique
    final biometricAvailable = await BiometricAuthService.isBiometricAvailable();
    
    // Compatibilité : si legacy biometric_setup existe, migrer
    final legacySetup = await _secureStorage.read(_legacyBiometricSetupKey);
    if (legacySetup == 'true' && biometricPreference == null) {
      // Migration automatique : l'utilisateur avait activé la biométrie
      await setBiometricPreference(true);
      debugPrint('🔄 [SECURITY] Migration legacy biometric_setup → preference');
    }
    
    return SecurityPreferences(
      biometricEnabled: biometricPreference == 'true',
      pinEnabled: pinPreference == 'true',
      appPin: appPin,
      biometricAvailable: biometricAvailable,
      firstTimePromptShown: firstTimePromptShown,
    );
  }
  
  /// Définir la préférence biométrique utilisateur
  static Future<void> setBiometricPreference(bool enabled) async {
    await _secureStorage.write(_biometricPreferenceKey, enabled.toString());
    
    // IMPORTANT: Synchroniser avec l'ancien système pour compatibilité
    if (enabled) {
      await _secureStorage.write(_legacyBiometricSetupKey, 'true');
    } else {
      // Si utilisateur désactive, on garde l'ancien système mais on respecte sa préférence
      // Ne pas supprimer biometric_setup car ça peut casser les device secrets
    }
    
    debugPrint('🔐 [SECURITY] Préférence biométrique: $enabled');
  }
  
  /// Définir la préférence PIN interne
  static Future<void> setPinPreference(bool enabled, {String? pin}) async {
    await _secureStorage.write(_pinPreferenceKey, enabled.toString());
    
    if (enabled && pin != null) {
      // TODO: Hasher le PIN pour la sécurité
      await _secureStorage.write(_appPinKey, pin);
    } else if (!enabled) {
      await _secureStorage.delete(_appPinKey);
    }
    
    debugPrint('🔐 [SECURITY] Préférence PIN: $enabled');
  }
  
  /// Marquer que le prompt de première fois a été affiché
  static Future<void> markFirstTimePromptShown() async {
    await _secureStorage.write(_firstTimePromptKey, 'true');
  }
  
  /// Vérifier si l'utilisateur souhaite une sécurité applicative
  static Future<bool> shouldActivateAppLock() async {
    final prefs = await getPreferences();
    
    // Cas 1: Biométrie activée ET disponible
    if (prefs.biometricEnabled && prefs.biometricAvailable) {
      return true;
    }
    
    // Cas 2: PIN activé (pour appareils sans biométrie ou choix utilisateur)
    if (prefs.pinEnabled && prefs.appPin != null) {
      return true;
    }
    
    // Cas 3: Aucune sécurité → app s'ouvre directement (comme WhatsApp)
    return false;
  }
  
  /// Obtenir le type de verrouillage préféré
  static Future<LockType> getPreferredLockType() async {
    final prefs = await getPreferences();
    
    if (prefs.biometricEnabled && prefs.biometricAvailable) {
      return LockType.biometric;
    }
    
    if (prefs.pinEnabled && prefs.appPin != null) {
      return LockType.pin;
    }
    
    return LockType.none;
  }
  
  /// Vérifier si c'est la première fois (pour popup optionnel)
  static Future<bool> shouldShowFirstTimePrompt() async {
    final prefs = await getPreferences();
    return !prefs.firstTimePromptShown && prefs.biometricAvailable;
  }
  
  /// Réinitialiser toutes les préférences (logout)
  static Future<void> resetPreferences() async {
    await _secureStorage.delete(_biometricPreferenceKey);
    await _secureStorage.delete(_pinPreferenceKey);
    await _secureStorage.delete(_appPinKey);
    await _secureStorage.delete(_firstTimePromptKey);
    // Note: Ne pas supprimer _legacyBiometricSetupKey pour compatibilité device auth
  }
}

/// Types de verrouillage disponibles
enum LockType {
  none,      // Aucun verrouillage (WhatsApp par défaut)
  biometric, // Verrouillage biométrique
  pin,       // Verrouillage PIN interne
}

/// Modèle des préférences de sécurité utilisateur
class SecurityPreferences {
  final bool biometricEnabled;       // Utilisateur veut la biométrie
  final bool pinEnabled;             // Utilisateur veut le PIN interne
  final String? appPin;              // PIN de l'application (si activé)
  final bool biometricAvailable;     // Biométrie disponible sur l'appareil
  final bool firstTimePromptShown;   // Popup première fois déjà affiché
  
  const SecurityPreferences({
    required this.biometricEnabled,
    required this.pinEnabled,
    this.appPin,
    required this.biometricAvailable,
    required this.firstTimePromptShown,
  });
  
  /// Affichage pour debug
  @override
  String toString() {
    return 'SecurityPreferences(biometric: $biometricEnabled, pin: $pinEnabled, available: $biometricAvailable, firstTime: $firstTimePromptShown)';
  }
}
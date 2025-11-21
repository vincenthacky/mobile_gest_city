import 'package:flutter/material.dart';

/// Service de gestion du verrouillage d'application (comme WhatsApp)
/// Utilise un système d'overlay plutôt que de la navigation entre pages
class AppLockService {
  /// État du verrouillage de l'application
  static final ValueNotifier<bool> isLocked = ValueNotifier(false);
  
  /// État de l'authentification en cours
  static final ValueNotifier<bool> isAuthenticating = ValueNotifier(false);
  
  /// Verrouiller l'application (afficher l'overlay)
  static void lock() {
    if (!isLocked.value) {
      isLocked.value = true;
      isAuthenticating.value = false;
      debugPrint('🔒 [APP LOCK] Application verrouillée - overlay activé');
    }
  }
  
  /// Déverrouiller l'application (masquer l'overlay)
  static void unlock() {
    if (isLocked.value) {
      isLocked.value = false;
      isAuthenticating.value = false;
      debugPrint('🔓 [APP LOCK] Application déverrouillée - overlay retiré');
    }
  }
  
  /// Marquer le début de l'authentification
  static void startAuthentication() {
    isAuthenticating.value = true;
    debugPrint('🔐 [APP LOCK] Début de l\'authentification biométrique');
  }
  
  /// Vérifier si l'app est verrouillée
  static bool get isAppLocked => isLocked.value;
  
  /// Vérifier si l'authentification est en cours
  static bool get isAuthInProgress => isAuthenticating.value;
  
  /// Réinitialiser le service (pour les tests ou logout)
  static void reset() {
    isLocked.value = false;
    isAuthenticating.value = false;
    debugPrint('🔄 [APP LOCK] Service réinitialisé');
  }
  
  /// Nettoyer les listeners (dispose)
  static void dispose() {
    isLocked.dispose();
    isAuthenticating.dispose();
  }
}
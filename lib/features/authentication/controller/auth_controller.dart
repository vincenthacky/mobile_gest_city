import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../../core/services/crypto_service.dart';
import '../../../core/services/security_settings_service.dart';
import '../../../core/services/app_lock_service.dart';
import '../data_source/auth_data_source.dart';
import '../model/user_model.dart';
import '../../projets/services/local_storage_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error, biometricRequired }

class AuthController extends ChangeNotifier {
  final AuthDataSource _authDataSource = AuthDataSource();
  
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// 👑 MÉTHODE SUPRÊME - Point d'entrée unique pour l'authentification
  /// Cette méthode détermine le statut final de l'app et où rediriger
  Future<void> initializeAppAuthentication() async {
    debugPrint('👑 [AUTH SUPREME] Début initialisation app...');
    _setStatus(AuthStatus.loading);
    
    try {
      final secureStorage = SecureStorage();
      
      // 1. Vérifier d'abord les secrets device (priorité)
      final deviceToken = await secureStorage.read('device_token');
      final biometricSetup = await secureStorage.read('biometric_setup');
      final userId = await secureStorage.read('user_id');
      final publicKey = await secureStorage.read('public_key');
      
      debugPrint('👑 [AUTH SUPREME] Device secrets - token:${deviceToken != null}, biometric:$biometricSetup, user:${userId != null}, key:${publicKey != null}');
      
      if (deviceToken != null && userId != null && publicKey != null) {
        // Vérifier format des clés
        if (!_isNewKeyFormat(publicKey)) {
          debugPrint('👑 [AUTH SUPREME] Ancien format détecté - reset complet');
          await _resetAllSecrets();
          _setStatus(AuthStatus.unauthenticated);
          return;
        }
        
        // Device auth présent - vérifier les données utilisateur
        final userData = await SecureStorage.getUserData();
        if (userData != null) {
          try {
            final userJson = jsonDecode(userData);
            _user = UserModel.fromJson(userJson);
            
            // NOUVELLE LOGIQUE WHATSAPP : Respecter les préférences utilisateur
            final securityPrefs = await SecuritySettingsService.getPreferences();
            final shouldLock = await SecuritySettingsService.shouldActivateAppLock();
            debugPrint('👑 [AUTH SUPREME] Device auth trouvé - préférences: $securityPrefs');
            debugPrint('👑 [AUTH SUPREME] Should activate lock: $shouldLock');
            
            if (shouldLock) {
              // Utilisateur a choisi une sécurité → vérifier le type
              final lockType = await SecuritySettingsService.getPreferredLockType();
              debugPrint('👑 [AUTH SUPREME] Sécurité activée par utilisateur → Type: $lockType');
              
              if (lockType == LockType.biometric) {
                // BIOMÉTRIQUE → Aller à la page biometric-auth
                debugPrint('👑 [AUTH SUPREME] → BIOMETRIC REQUIRED (page biometric-auth)');
                _setStatus(AuthStatus.biometricRequired);
              } else if (lockType == LockType.pin) {
                // PIN → Aller directement à home mais déclencher l'overlay
                debugPrint('👑 [AUTH SUPREME] → PIN REQUIRED (home + overlay)');
                _setStatus(AuthStatus.authenticated); // On va à home
                // Déclencher l'overlay PIN
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  AppLockService.lock(); // Force l'overlay
                });
              } else {
                // Pas de sécurité → home direct
                debugPrint('👑 [AUTH SUPREME] → NO SECURITY');
                _setStatus(AuthStatus.authenticated);
              }
              return;
            } else {
              // Utilisateur n'a pas activé la sécurité → connexion directe (comme WhatsApp)
              debugPrint('👑 [AUTH SUPREME] Aucune sécurité activée → AUTHENTICATED direct');
              _setStatus(AuthStatus.authenticated);
              return;
            }
            
          } catch (e) {
            debugPrint('👑 [AUTH SUPREME] Erreur userData: $e');
            await _resetAllSecrets();
            _setStatus(AuthStatus.unauthenticated);
            return;
          }
        }
      }
      
      // 2. FALLBACK : vérifier ancien système Bearer
      debugPrint('👑 [AUTH SUPREME] Pas de device auth - vérification Bearer...');
      final bearerToken = await SecureStorage.getToken();
      final bearerUserData = await SecureStorage.getUserData();
      
      if (bearerToken != null && bearerUserData != null) {
        try {
          final userJson = jsonDecode(bearerUserData);
          _user = UserModel.fromJson(userJson);
          _setStatus(AuthStatus.authenticated);
          debugPrint('👑 [AUTH SUPREME] Bearer auth trouvé → AUTHENTICATED');
          return;
        } catch (e) {
          debugPrint('👑 [AUTH SUPREME] Erreur Bearer: $e');
          await SecureStorage.deleteToken();
          await SecureStorage.deleteUserData();
        }
      }
      
      // 3. Aucun système d'auth trouvé
      debugPrint('👑 [AUTH SUPREME] Aucune auth trouvée → UNAUTHENTICATED');
      _setStatus(AuthStatus.unauthenticated);
      
    } catch (e) {
      debugPrint('👑 [AUTH SUPREME] Erreur critique: $e');
      _setStatus(AuthStatus.error);
    }
    
    debugPrint('👑 [AUTH SUPREME] Fin initialisation - statut: $_status');
  }

  /// 🔐 Traiter la biométrie (appelé depuis biometric_auth_page)
  Future<bool> processBiometricAuthentication() async {
    debugPrint('🔐 [AUTH BIOMETRIC] Début authentification biométrique...');
    
    try {
      _setStatus(AuthStatus.loading);
      
      // Diagnostic d'abord pour voir les types disponibles
      final diagnostic = await BiometricAuthService.diagnosticBiometrics();
      debugPrint('🔍 [AUTH BIOMETRIC] Types disponibles: $diagnostic');
      
      final biometricResult = await BiometricAuthService.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à votre compte',
        useErrorDialogs: true,
        stickyAuth: true,
      );
      
      if (biometricResult.isSuccess) {
        _setStatus(AuthStatus.authenticated);
        debugPrint('🔐 [AUTH BIOMETRIC] ✅ Succès');
        return true;
      } else {
        debugPrint('🔐 [AUTH BIOMETRIC] ❌ Échec: ${biometricResult.name}');
        await _resetAllSecrets();
        _user = null;
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
    } catch (e) {
      debugPrint('🔐 [AUTH BIOMETRIC] ❌ Erreur: $e');
      await _resetAllSecrets();
      _user = null;
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    _setStatus(AuthStatus.loading);
    
    try {
      final secureStorage = SecureStorage();
      
      // NOUVEAU : Vérifier d'abord le device auth
      final deviceToken = await secureStorage.read('device_token');
      final biometricSetup = await secureStorage.read('biometric_setup');
      final userId = await secureStorage.read('user_id');
      final publicKey = await secureStorage.read('public_key');
      
      if (deviceToken != null && biometricSetup == 'true' && userId != null && publicKey != null) {
        // Vérifier si les clés sont au nouveau format (compatibles OpenSSL)
        if (!_isNewKeyFormat(publicKey)) {
          debugPrint('🔄 Ancien format de clés détecté - reset nécessaire');
          await _resetAllSecrets();
          _setStatus(AuthStatus.unauthenticated);
          return;
        }
        
        // Device auth configuré - récupérer les vraies données utilisateur stockées
        final userData = await SecureStorage.getUserData();
        if (userData != null) {
          try {
            final userJson = jsonDecode(userData);
            _user = UserModel.fromJson(userJson);
            _setStatus(AuthStatus.authenticated);
            return;
          } catch (e) {
            // Si erreur de parsing des données, reset device auth
            await _resetAllSecrets();
            _setStatus(AuthStatus.unauthenticated);
            return;
          }
        }
      }
      
      // FALLBACK : Vérifier l'ancien système Bearer token
      final token = await SecureStorage.getToken();
      final userData = await SecureStorage.getUserData();
      
      if (token != null && userData != null) {
        try {
          final userJson = jsonDecode(userData);
          _user = UserModel.fromJson(userJson);
          _setStatus(AuthStatus.authenticated);
        } catch (e) {
          await SecureStorage.deleteToken();
          await SecureStorage.deleteUserData();
          _user = null;
          _setStatus(AuthStatus.unauthenticated);
        }
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// 🔐 Nouveau login avec device auth + biométrie (comme register)
  Future<bool> loginWithDeviceAuth(String phoneOrEmail, String password) async {
    debugPrint('🔐 [LOGIN] Début login avec device auth...');
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      // 1. Générer device ID unique
      final secureStorage = SecureStorage();
      String deviceId = await secureStorage.read('device_id') ?? 
                       DateTime.now().millisecondsSinceEpoch.toString();
      
      // 2. Générer clés RSA
      final keyPair = await CryptoService.generateRSAKeyPair();
      final publicKeyPem = CryptoService.publicKeyToPem(keyPair.publicKey);
      final privateKeyPem = CryptoService.privateKeyToPem(keyPair.privateKey);
      
      debugPrint('🔐 [LOGIN] Clés générées, device_id: $deviceId');

      // 3. Obtenir les informations de l'appareil
      final deviceInfo = DeviceInfoPlugin();
      String deviceName = '';

      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceName = '${iosInfo.name} (${iosInfo.model})';
        }
      } catch (e) {
        deviceName = 'Device ${DateTime.now().day}/${DateTime.now().month}';
      }

      // 4. NOUVELLE APPROCHE WHATSAPP : Ne plus forcer la biométrie au login
      // L'utilisateur activera la biométrie dans les paramètres s'il le souhaite
      debugPrint('🚀 [LOGIN] Login sans biométrie forcée (approche WhatsApp)');

      // 5. Appel API login avec clés
      final response = await _authDataSource.loginWithDeviceAuth(
        phoneOrEmail: phoneOrEmail,
        password: password,
        deviceId: deviceId,
        deviceName: deviceName,
        publicKey: publicKeyPem,
      );

      debugPrint('🔐 [LOGIN] Réponse API: ${response['success']}');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // 6. Extraire les informations
        final deviceToken = data['tokens'] as String;
        final userMap = data['user'] as Map<String, dynamic>;
        
        // Créer l'objet utilisateur
        final user = UserModel.fromJson(userMap);
        
        debugPrint('🔐 [LOGIN] Device token reçu, stockage sécurisé...');

        // 7. Stocker les secrets selon le pattern du register
        await secureStorage.write('device_token', deviceToken);
        await secureStorage.write('private_key', privateKeyPem);
        await secureStorage.write('public_key', publicKeyPem);
        await secureStorage.write('device_id', deviceId);
        await secureStorage.write('user_id', user.id);
        await secureStorage.write('biometric_setup', 'false'); // Par défaut non activé
        
        // 8. Stocker les données utilisateur (compatibilité)
        await SecureStorage.saveUserData(jsonEncode(user.toJson()));
        
        // 9. Mettre à jour l'état
        _user = user;
        _setStatus(AuthStatus.authenticated);
        
        debugPrint('✅ [LOGIN] Login complet réussi pour: ${user.fullName}');
        return true;
        
      } else {
        final errorMessage = response['message'] ?? 'Erreur de connexion';
        debugPrint('❌ [LOGIN] Erreur API: $errorMessage');
        _setError(errorMessage);
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ [LOGIN] Exception: $e');
      _setError('Erreur lors de la connexion: $e');
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// FALLBACK: Ancien login pour rétrocompatibilité
  Future<bool> login(String phoneOrEmail, String password) async {
    // Essayer d'abord le nouveau système
    final deviceAuthSuccess = await loginWithDeviceAuth(phoneOrEmail, password);
    if (deviceAuthSuccess) return true;
    
    // Fallback vers ancien système si échec
    debugPrint('🔄 [LOGIN] Fallback vers ancien système Bearer...');
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final response = await _authDataSource.login(phoneOrEmail, password);
      
      if (response.success) {
        await SecureStorage.saveToken(response.data.token);
        await SecureStorage.saveUserData(jsonEncode(response.data.user.toJson()));
        _user = response.data.user;
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(response.message);
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de la connexion');
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<void> logout() async {
    _setStatus(AuthStatus.loading);
    
    try {
      await _authDataSource.logout();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    } finally {
      // Nettoyer TOUS les secrets (device + classique)
      await _resetAllSecrets();
      
      // ✅ NOUVEAU : Nettoyer toutes les données locales des projets
      try {
        await LocalStorageService.clearAllProjectData();
        debugPrint('🧹 [LOGOUT] Données locales des projets nettoyées');
      } catch (e) {
        debugPrint('❌ [LOGOUT] Erreur nettoyage données projets: $e');
        // Ne pas faire échouer la déconnexion pour autant
      }
      
      _user = null;
      _clearError();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Reset complet de tous les secrets selon le flow spécifié
  Future<void> _resetAllSecrets() async {
    final secureStorage = SecureStorage();
    
    // 1. Device auth secrets
    await secureStorage.delete('device_token');
    await secureStorage.delete('private_key');
    await secureStorage.delete('public_key');
    await secureStorage.delete('device_id');
    await secureStorage.delete('user_id');
    await secureStorage.delete('biometric_setup');
    
    // 2. Classic auth secrets (backward compatibility)
    await SecureStorage.deleteToken();
    await SecureStorage.deleteUserData();
  }

  /// Vérifie si la clé publique est au nouveau format X.509 (compatible OpenSSL)
  bool _isNewKeyFormat(String publicKey) {
    try {
      final stripped = publicKey
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '');
      
      final decoded = base64.decode(stripped);
      
      // Nouveau format : commence par 0x30 (SEQUENCE ASN.1)
      // Ancien format : commence par '{' en JSON
      return decoded.isNotEmpty && decoded[0] == 0x30;
    } catch (e) {
      return false;
    }
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  /// Méthode publique pour changer le statut (pour usage externe)
  void setStatus(AuthStatus status) {
    _setStatus(status);
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Méthode pour forcer la déconnexion en cas d'erreur 401
  Future<void> forceLogout() async {
    _user = null;
    _clearError();
    
    // ✅ NOUVEAU : Nettoyer aussi les données projets lors d'un force logout
    try {
      await LocalStorageService.clearAllProjectData();
      debugPrint('🧹 [FORCE-LOGOUT] Données locales des projets nettoyées');
    } catch (e) {
      debugPrint('❌ [FORCE-LOGOUT] Erreur nettoyage données projets: $e');
    }
    
    _setStatus(AuthStatus.unauthenticated);
  }

  Future<Map<String, dynamic>?> verifyVilla(String code) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final response = await _authDataSource.verifyVilla(code);
      _setStatus(AuthStatus.initial);
      return response;
    } catch (e) {
      _setError(e.toString());
      _setStatus(AuthStatus.error);
      return null;
    }
  }

  /// Vérifie s'il y a des secrets device stockés
  Future<bool> hasStoredDeviceSecrets() async {
    final secureStorage = SecureStorage();
    final deviceToken = await secureStorage.read('device_token');
    final biometricSetup = await secureStorage.read('biometric_setup');
    final privateKey = await secureStorage.read('private_key');
    
    return deviceToken != null && 
           biometricSetup == 'true' && 
           privateKey != null;
  }

  /// Force une réauthentification biométrique (comme WhatsApp)
  /// Redirige vers la page biométrique dédiée
  void requireBiometricReauth() {
    // Marquer temporairement comme en attente de biométrie
    _setStatus(AuthStatus.loading);
    debugPrint('🔐 Biométrie requise - redirection vers page d\'authentification');
    
    // La redirection sera gérée par l'AppRouter selon le statut
    // Le routeur détectera que l'utilisateur n'est plus authenticated et redirigera
  }

  /// Modifie checkAuthStatus pour inclure la vérification biométrique
  Future<void> checkAuthStatusWithBiometric() async {
    debugPrint('🔍 [AUTH] Début checkAuthStatusWithBiometric');
    _setStatus(AuthStatus.loading);
    
    try {
      final secureStorage = SecureStorage();
      
      // Vérifier d'abord le device auth
      final deviceToken = await secureStorage.read('device_token');
      final biometricSetup = await secureStorage.read('biometric_setup');
      final userId = await secureStorage.read('user_id');
      final publicKey = await secureStorage.read('public_key');
      
      debugPrint('🔍 [AUTH] Secrets trouvés: deviceToken=${deviceToken != null}, biometric=$biometricSetup, userId=${userId != null}, publicKey=${publicKey != null}');
      
      if (deviceToken != null && biometricSetup == 'true' && userId != null && publicKey != null) {
        // Vérifier si les clés sont au nouveau format
        if (!_isNewKeyFormat(publicKey)) {
          debugPrint('🔄 Ancien format de clés détecté - reset nécessaire');
          await _resetAllSecrets();
          _setStatus(AuthStatus.unauthenticated);
          return;
        }
        
        // NOUVELLE LOGIQUE WHATSAPP : Vérifier les préférences utilisateur
        debugPrint('🔐 [AUTH] Secrets trouvés - vérification préférences sécurité...');
        final securityPrefs = await SecuritySettingsService.getPreferences();
        final shouldLock = await SecuritySettingsService.shouldActivateAppLock();
        final lockType = await SecuritySettingsService.getPreferredLockType();
        
        debugPrint('🔐 [AUTH] Préférences: $securityPrefs');
        debugPrint('🔐 [AUTH] Should lock: $shouldLock, Lock type: $lockType');
        
        if (shouldLock) {
          // Utilisateur a activé la sécurité → authentication requise selon le type
          if (lockType == LockType.biometric) {
            debugPrint('🔐 [AUTH] Sécurité biométrique activée → BIOMETRIC AUTH');
            final biometricResult = await BiometricAuthService.authenticate(
              localizedReason: 'Authentifiez-vous pour accéder à votre compte',
              useErrorDialogs: true,
              stickyAuth: true,
            );
            
            if (!biometricResult.isSuccess) {
              debugPrint('❌ [AUTH] Biométrie échouée: ${biometricResult.name} - reset des secrets');
              await _resetAllSecrets();
              _setStatus(AuthStatus.unauthenticated);
              return;
            }
          } else {
            // PIN ou autre type → on laisse l'overlay s'en charger
            debugPrint('🔐 [AUTH] Sécurité PIN activée → BIOMETRIC REQUIRED (overlay gérera le PIN)');
            _setStatus(AuthStatus.biometricRequired);
            return;
          }
        } else {
          // Utilisateur n'a pas activé de sécurité → connexion directe
          debugPrint('🔓 [AUTH] Aucune sécurité activée - connexion directe (WhatsApp-like)');
        }
        
        debugPrint('✅ [AUTH] Authentification OK - récupération données utilisateur...');
        // Biométrie OK - récupérer les vraies données utilisateur
        final userData = await SecureStorage.getUserData();
        if (userData != null) {
          try {
            final userJson = jsonDecode(userData);
            _user = UserModel.fromJson(userJson);
            _setStatus(AuthStatus.authenticated);
            debugPrint('✅ [AUTH] Authentification complète réussie - utilisateur: ${_user?.fullName}');
            return;
          } catch (e) {
            debugPrint('❌ [AUTH] Erreur parsing userData: $e');
            await _resetAllSecrets();
            _setStatus(AuthStatus.unauthenticated);
            return;
          }
        } else {
          debugPrint('❌ [AUTH] Pas de userData trouvé malgré les secrets');
          await _resetAllSecrets();
          _setStatus(AuthStatus.unauthenticated);
          return;
        }
      }
      
      // FALLBACK : Vérifier l'ancien système Bearer token (sans biométrie)
      debugPrint('🔍 [AUTH] Pas de secrets device - vérification ancien système Bearer...');
      final token = await SecureStorage.getToken();
      final userData = await SecureStorage.getUserData();
      
      debugPrint('🔍 [AUTH] Bearer token présent: ${token != null}, userData présent: ${userData != null}');
      
      if (token != null && userData != null) {
        try {
          final userJson = jsonDecode(userData);
          _user = UserModel.fromJson(userJson);
          _setStatus(AuthStatus.authenticated);
          debugPrint('✅ [AUTH] Authentification Bearer réussie - utilisateur: ${_user?.fullName}');
        } catch (e) {
          debugPrint('❌ [AUTH] Erreur parsing Bearer userData: $e');
          await SecureStorage.deleteToken();
          await SecureStorage.deleteUserData();
          _user = null;
          _setStatus(AuthStatus.unauthenticated);
        }
      } else {
        debugPrint('🔍 [AUTH] Aucun système d\'auth trouvé - statut unauthenticated');
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('❌ [AUTH] Erreur checkAuthStatusWithBiometric: $e');
      _setStatus(AuthStatus.unauthenticated);
    }
    
    debugPrint('🔍 [AUTH] Fin checkAuthStatusWithBiometric - statut final: $_status');
  }
}
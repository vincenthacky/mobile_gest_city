import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../../core/services/crypto_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../data_source/register_data_source.dart';
import '../model/register_models.dart';

enum RegisterStatus { initial, loading, success, error }

class RegisterController extends ChangeNotifier {
  final RegisterDataSource _dataSource = RegisterDataSource();
  
  RegisterStatus _status = RegisterStatus.initial;
  String? _errorMessage;
  String? _successMessage;
  UserData? _userData;

  RegisterStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  UserData? get userData => _userData;
  bool get isLoading => _status == RegisterStatus.loading;
  bool get isSuccess => _status == RegisterStatus.success;
  bool get hasError => _status == RegisterStatus.error;

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String villaId,
    String birthday = '',
    bool isAnonymous = false,
  }) async {
    _setStatus(RegisterStatus.loading);
    _clearMessages();

    try {
      // 1. Créer le request d'enregistrement
      final request = RegisterRequest(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        villaId: villaId,
        birthday: birthday,
        isAnonymous: isAnonymous,
      );

      // 2. Appeler l'API d'enregistrement utilisateur
      final response = await _dataSource.register(request);

      if (!response.isSuccess) {
        _errorMessage = response.message;
        _setStatus(RegisterStatus.error);
        return false;
      }

      // 3. Générer les clés RSA pour l'appareil
      final keyPair = await CryptoService.generateRSAKeyPair();
      final publicKeyPem = CryptoService.publicKeyToPem(keyPair.publicKey);
      final privateKeyPem = CryptoService.privateKeyToPem(keyPair.privateKey);

      // 4. Obtenir les informations de l'appareil
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      String deviceName = '';

      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
          deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? '';
          deviceName = '${iosInfo.name} (${iosInfo.model})';
        }
      } catch (e) {
        deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        deviceName = 'Device ${DateTime.now().day}/${DateTime.now().month}';
      }

      // 5. Appeler l'API d'enregistrement d'appareil
      final deviceResponse = await _dataSource.registerDevice(
        phoneOrEmail: email,
        deviceId: deviceId,
        deviceName: deviceName,
        publicKey: publicKeyPem,
      );

      if (!deviceResponse.isSuccess) {
        _errorMessage = deviceResponse.message;
        _setStatus(RegisterStatus.error);
        return false;
      }

      // 6. Stocker les clés et le token dans le stockage sécurisé
      final secureStorage = SecureStorage();
      await secureStorage.write('private_key', privateKeyPem);
      await secureStorage.write('public_key', publicKeyPem);
      await secureStorage.write('device_token', deviceResponse.data?['token'] ?? '');
      await secureStorage.write('device_id', deviceId);
      await secureStorage.write('user_id', response.data?.id ?? '');
      
      // Marquer que l'utilisateur a configuré l'auth biométrique
      await secureStorage.write('biometric_setup', 'true');

      _userData = response.data;
      _successMessage = 'Inscription réussie. Votre appareil a été configuré pour l\'authentification biométrique.';
      _setStatus(RegisterStatus.success);
      return true;

    } catch (e) {
      _errorMessage = 'Erreur inattendue: $e';
      _setStatus(RegisterStatus.error);
      return false;
    }
  }

  void _setStatus(RegisterStatus status) {
    _status = status;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == RegisterStatus.error) {
      _status = RegisterStatus.initial;
    }
    notifyListeners();
  }

  void reset() {
    _status = RegisterStatus.initial;
    _userData = null;
    _clearMessages();
  }
}
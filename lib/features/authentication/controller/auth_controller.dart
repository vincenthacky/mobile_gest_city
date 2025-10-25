import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/storage/secure_storage.dart';
import '../data_source/auth_data_source.dart';
import '../model/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

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

  Future<void> checkAuthStatus() async {
    _setStatus(AuthStatus.loading);
    
    try {
      final token = await SecureStorage.getToken();
      final userData = await SecureStorage.getUserData();
      
      if (token != null && userData != null) {
        try {
          // Récupérer les données utilisateur depuis le stockage
          final userJson = jsonDecode(userData);
          _user = UserModel.fromJson(userJson);
          _setStatus(AuthStatus.authenticated);
        } catch (e) {
          // Si erreur de parsing, nettoyer et rediriger vers login
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

  Future<bool> login(String identifiant, String motDePasse) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final response = await _authDataSource.login(identifiant, motDePasse);
      
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
      _setError(e.toString());
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
      await SecureStorage.deleteToken();
      await SecureStorage.deleteUserData();
      _user = null;
      _clearError();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
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
}
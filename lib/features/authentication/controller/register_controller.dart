import 'package:flutter/material.dart';
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
  }) async {
    _setStatus(RegisterStatus.loading);
    _clearMessages();

    try {
      final request = RegisterRequest(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        villaId: villaId,
        birthday: birthday,
      );

      final response = await _dataSource.register(request);

      if (response.isSuccess) {
        _userData = response.data;
        _successMessage = response.message;
        _setStatus(RegisterStatus.success);
        return true;
      } else {
        _errorMessage = response.message;
        _setStatus(RegisterStatus.error);
        return false;
      }
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
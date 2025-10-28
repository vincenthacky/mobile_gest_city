import 'package:flutter/material.dart';
import '../data_source/payment_proof_data_source.dart';
import '../models/payment_proof_models.dart';

enum PaymentProofStatus { initial, loading, success, error }

class PaymentProofController extends ChangeNotifier {
  final PaymentProofDataSource _dataSource = PaymentProofDataSource();
  
  PaymentProofStatus _status = PaymentProofStatus.initial;
  String? _errorMessage;
  String? _successMessage;

  PaymentProofStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _status == PaymentProofStatus.loading;
  bool get isSuccess => _status == PaymentProofStatus.success;
  bool get hasError => _status == PaymentProofStatus.error;

  Future<bool> submitPaymentProof({
    required int contributionId,
    required PaymentProofRequest request,
  }) async {
    _setStatus(PaymentProofStatus.loading);
    _clearMessages();

    try {
      final response = await _dataSource.submitPaymentProof(
        contributionId: contributionId,
        request: request,
      );

      if (response.isSuccess) {
        _successMessage = response.message ?? 'Preuve de paiement envoyée avec succès !';
        _setStatus(PaymentProofStatus.success);
        return true;
      } else {
        _errorMessage = response.message ?? 'Erreur lors de l\'envoi de la preuve de paiement';
        _setStatus(PaymentProofStatus.error);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur inattendue: $e';
      _setStatus(PaymentProofStatus.error);
      return false;
    }
  }

  void _setStatus(PaymentProofStatus status) {
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
    if (_status == PaymentProofStatus.error) {
      _status = PaymentProofStatus.initial;
    }
    notifyListeners();
  }

  void reset() {
    _status = PaymentProofStatus.initial;
    _clearMessages();
  }
}
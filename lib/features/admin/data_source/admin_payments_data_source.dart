import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../models/admin_payment_model.dart';

class AdminPaymentsDataSource {
  final Dio _dio = DioClient.instance;

  /// Récupère la liste des paiements avec filtres et pagination
  ///
  /// Query params disponibles:
  /// - status: 0 (en attente), 1 (payé), 2 (en retard), 3 (en attente de confirmation), 4 (rejeté)
  /// - order: newest, oldest
  /// - per_page: nombre d'items par page (défaut: 20)
  /// - page: numéro de page (défaut: 1)
  Future<AdminPaymentsResponse> getPayments({
    String? status,
    String? order,
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      debugPrint('📡 [ADMIN PAYMENTS API] Fetching payments...');
      debugPrint(
        '   Status: $status, Order: $order, Page: $page, PerPage: $perPage',
      );

      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      if (order != null && order.isNotEmpty) {
        queryParameters['order'] = order;
      }

      final response = await _dio.get(
        '/payments',
        queryParameters: queryParameters,
      );

      debugPrint('✅ [ADMIN PAYMENTS API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final paymentsResponse = AdminPaymentsResponse.fromJson(response.data);
        debugPrint('   Loaded ${paymentsResponse.data.length} payments');
        debugPrint(
          '   Pagination: page ${paymentsResponse.pagination?.currentPage}/${paymentsResponse.pagination?.lastPage}',
        );
        return paymentsResponse;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des paiements',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS API] Error: ${e.message}');

      if (e.response?.statusCode == 401) {
        debugPrint('   Unauthorized - session expirée');
      } else if (e.response?.statusCode == 403) {
        debugPrint('   Forbidden - permissions insuffisantes');
      }

      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        error: e.error,
        message: e.message ?? 'Erreur réseau',
      );
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS API] Unexpected error: $e');
      rethrow;
    }
  }

  /// Valide un paiement
  Future<PaymentApprovalResponse> approvePayment({
    required String paymentId,
    String? notes,
  }) async {
    try {
      debugPrint('📡 [ADMIN PAYMENTS API] Approving payment: $paymentId');

      final response = await _dio.post(
        '/payments/$paymentId/validate',
        data: notes != null ? {'notes': notes} : null,
      );

      debugPrint('✅ [ADMIN PAYMENTS API] Payment approved');

      if (response.statusCode == 200) {
        return PaymentApprovalResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la validation du paiement',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS API] Approval error: ${e.message}');
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        error: e.error,
        message: e.message ?? 'Erreur lors de la validation',
      );
    }
  }

  /// Rejette un paiement
  Future<PaymentApprovalResponse> rejectPayment({
    required String paymentId,
    required String reason,
  }) async {
    try {
      debugPrint('📡 [ADMIN PAYMENTS API] Rejecting payment: $paymentId');

      final response = await _dio.post(
        '/payments/$paymentId/reject',
        data: {'reason': reason},
      );

      debugPrint('✅ [ADMIN PAYMENTS API] Payment rejected');

      if (response.statusCode == 200) {
        return PaymentApprovalResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors du rejet du paiement',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS API] Rejection error: ${e.message}');
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        error: e.error,
        message: e.message ?? 'Erreur lors du rejet',
      );
    }
  }

  /// Vérifie un QR code et récupère les informations utilisateur
  Future<QRCodeVerificationResponse> verifyQRCode(String villaNumber) async {
    try {
      debugPrint(
        '📡 [ADMIN PAYMENTS API] Verifying QR code for villa: $villaNumber',
      );

      final response = await _dio.get(
        '/contributions/verify-qrcode',
        queryParameters: {'token': villaNumber},
      );

      debugPrint('✅ [ADMIN PAYMENTS API] QR code verified');

      if (response.statusCode == 200) {
        return QRCodeVerificationResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la vérification du QR code',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS API] QR verification error: ${e.message}');
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        error: e.error,
        message: e.message ?? 'Erreur lors de la vérification du QR code',
      );
    }
  }

  /// Valide les paiements d'un utilisateur pour des périodes spécifiques
  Future<PaymentValidationResponse> validateUserPayments({
    required String userId,
    required List<Map<String, dynamic>> periods,
  }) async {
    try {
      debugPrint(
        '📡 [ADMIN PAYMENTS API] Validating payments for user: $userId',
      );
      debugPrint('   Periods: $periods');

      final response = await _dio.post(
        '/contributions/users/$userId/validate',
        data: {'periods': periods},
      );

      debugPrint('✅ [ADMIN PAYMENTS API] Payments validated');

      if (response.statusCode == 200) {
        return PaymentValidationResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la validation des paiements',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS API] Validation error: ${e.message}');
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        error: e.error,
        message: e.message ?? 'Erreur lors de la validation des paiements',
      );
    }
  }

  /// Valide un paiement scanné avec QR code
  Future<PaymentApprovalResponse> validateQRPayment({
    required String userId,
    required List<String> validatedMonths,
    String? notes,
  }) async {
    try {
      debugPrint(
        '📡 [ADMIN PAYMENTS API] Validating QR payment for user: $userId',
      );
      debugPrint('   Months: $validatedMonths');

      final response = await _dio.post(
        '/payments/validate-qr',
        data: {
          'user_id': userId,
          'validated_months': validatedMonths,
          'notes': notes,
        },
      );

      debugPrint('✅ [ADMIN PAYMENTS API] QR payment validated');

      if (response.statusCode == 200) {
        return PaymentApprovalResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la validation du paiement QR',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS API] QR validation error: ${e.message}');
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        error: e.error,
        message: e.message ?? 'Erreur lors de la validation QR',
      );
    }
  }
}

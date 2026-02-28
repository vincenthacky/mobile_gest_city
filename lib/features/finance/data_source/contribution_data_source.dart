import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/contribution_model.dart';
import '../models/qr_code_model.dart';
import '../models/unpaid_months_model.dart';
import '../models/payment_proof_model.dart';
import '../models/payment_proofs_model.dart';
import '../models/payment_list_model.dart';
import '../models/payment_periods_model.dart';
import '../models/payment_overview_model.dart';
import '../models/payment_statistics_model.dart';

class ContributionDataSource {
  final Dio _dio = DioClient.instance;

  Future<ContributionResponse> getContribution() async {
    try {
      final response = await _dio.get('/contributions');

      if (response.statusCode == 200) {
        return ContributionResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des données de cotisation',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la récupération des données de cotisation';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<void> refreshContribution() async {
    // Force refresh by making a new API call
    await getContribution();
  }

  Future<QrCodeResponse> generateQrCode() async {
    try {
      final response = await _dio.post('/contributions/generate-qrcode');

      if (response.statusCode == 200) {
        return QrCodeResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la génération du code QR',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la génération du code QR';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<UnpaidMonthsResponse> getUnpaidMonths() async {
    try {
      final response = await _dio.get('/payments/contribution/unpaid-months');

      if (response.statusCode == 200) {
        return UnpaidMonthsResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des mois impayés',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la récupération des mois impayés';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<PaymentProofResponse> submitPaymentProof(
    PaymentProofRequest request,
  ) async {
    try {
      // Créer le FormData pour l'envoi multipart
      final formData = FormData.fromMap({
        'comment': request.comment,
        'phone': request.phone,
        'provider': request.provider.apiValue,
        'file': await MultipartFile.fromFile(
          request.file.path,
          filename: request.file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/payments/proofs/contributions',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentProofResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de l\'envoi de la preuve de paiement',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de l\'envoi de la preuve de paiement';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<PaymentProofsResponse> getValidatedPayments({
    required String userId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/payments',
        queryParameters: {
          'status': 'VALIDATED',
          'user_id': userId,
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        return PaymentProofsResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des paiements validés',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la récupération des paiements validés';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<PaymentProofsResponse> getPendingPayments({
    required String userId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/payments',
        queryParameters: {'status': 'PENDING', 'user_id': userId, 'page': page},
      );

      if (response.statusCode == 200) {
        return PaymentProofsResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des paiements en attente',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la récupération des paiements en attente';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Nouvelle méthode pour récupérer tous les paiements
  Future<PaymentListResponse> getAllPayments({
    required String userId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/payments',
        queryParameters: {'user_id': userId, 'page': page},
      );

      if (response.statusCode == 200) {
        return PaymentListResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des paiements',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la récupération des paiements';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Nouvelle méthode pour récupérer les périodes de paiement
  Future<PaymentPeriodsResponse> getPaymentPeriods() async {
    try {
      final response = await _dio.get('/payments/contribution/unpaid-months');

      if (response.statusCode == 200) {
        return PaymentPeriodsResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des périodes de paiement',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la récupération des périodes de paiement';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // NOTE: submitPaymentWithPeriods est géré par PaymentUploadService
  // (optimisation JPEG + upload — voir services/upload_service.dart)

  // Méthode pour récupérer l'aperçu des paiements (tableau de ventilation)
  Future<PaymentOverviewResponse> getPaymentOverview() async {
    try {
      final response = await _dio.get('/payments/overview');

      if (response.statusCode == 200) {
        return PaymentOverviewResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération de l\'aperçu des paiements',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la récupération de l\'aperçu des paiements';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Méthode pour récupérer les statistiques de paiement par mois
  Future<PaymentStatisticsResponse> getPaymentStatistics({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _dio.get(
        '/payments/statistics-by-month',
        queryParameters: {'year': year, 'month': month},
      );

      if (response.statusCode == 200) {
        return PaymentStatisticsResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message:
              'Erreur lors de la récupération des statistiques de paiement',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la récupération des statistiques de paiement';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }
}

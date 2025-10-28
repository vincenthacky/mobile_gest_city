import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/payment_proof_models.dart';

class PaymentProofDataSource {
  final Dio _dio = DioClient.instance;

  Future<PaymentProofResponse> submitPaymentProof({
    required int contributionId,
    required PaymentProofRequest request,
  }) async {
    try {
      // Créer le FormData pour l'envoi multipart
      final formData = FormData.fromMap({
        'phone': request.phone,
        'provider': request.provider.apiValue,
        'file': await MultipartFile.fromFile(
          request.filePath,
          filename: request.filePath.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/payments/proofs/contributions/$contributionId',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return PaymentProofResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        // Retourner la réponse d'erreur de l'API
        return PaymentProofResponse.fromJson(e.response?.data ?? {
          'success': false,
          'status_code': e.response?.statusCode ?? 500,
          'message': e.response?.data['message'] ?? 'Erreur lors de l\'envoi de la preuve de paiement',
        });
      } else {
        // Erreur de réseau ou autre
        return PaymentProofResponse(
          success: false,
          statusCode: 500,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      return PaymentProofResponse(
        success: false,
        statusCode: 500,
        message: 'Erreur inattendue: $e',
      );
    }
  }
}
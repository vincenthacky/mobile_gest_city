import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/contribution_model.dart';
import '../models/qr_code_model.dart';

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
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la récupération des données de cotisation';
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
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la génération du code QR';
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
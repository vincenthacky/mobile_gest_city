import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class QrDataSource {
  final Dio _dio = DioClient.instance;

  Future<QrCodeResponse> generateQrCode(int contributionId) async {
    try {
      final response = await _dio.post('/contributions/$contributionId/generate-qrcode');

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
        final errorMessage = e.response?.data['message'] ?? 
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
}

class QrCodeResponse {
  final bool success;
  final int statusCode;
  final String message;
  final QrCodeData data;

  QrCodeResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory QrCodeResponse.fromJson(Map<String, dynamic> json) {
    return QrCodeResponse(
      success: json['success'],
      statusCode: json['status_code'],
      message: json['message'],
      data: QrCodeData.fromJson(json['data']),
    );
  }
}

class QrCodeData {
  final String token;
  final int expiresInSeconds;

  QrCodeData({
    required this.token,
    required this.expiresInSeconds,
  });

  factory QrCodeData.fromJson(Map<String, dynamic> json) {
    return QrCodeData(
      token: json['token'],
      expiresInSeconds: json['expires_in_seconds'],
    );
  }
}
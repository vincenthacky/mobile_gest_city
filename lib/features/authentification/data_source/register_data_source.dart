import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../model/register_models.dart';

class RegisterDataSource {
  final Dio _dio = DioClient.instance;

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: request.toJson(),
      );

      return RegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        // Retourner la réponse d'erreur de l'API
        return RegisterResponse.fromJson(e.response?.data ?? {
          'success': false,
          'status_code': e.response?.statusCode ?? 500,
          'message': e.response?.data['message'] ?? 'Erreur lors de l\'enregistrement',
        });
      } else {
        // Erreur de réseau ou autre
        return RegisterResponse(
          success: false,
          statusCode: 500,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      return RegisterResponse(
        success: false,
        statusCode: 500,
        message: 'Erreur inattendue: $e',
      );
    }
  }

  Future<DeviceRegisterResponse> registerDevice({
    required String phoneOrEmail,
    required String deviceId,
    required String deviceName,
    required String publicKey,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register-device',
        data: {
          'phone_or_email': phoneOrEmail,
          'device_id': deviceId,
          'device_name': deviceName,
          'public_key': publicKey,
        },
      );

      return DeviceRegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        return DeviceRegisterResponse.fromJson(e.response?.data ?? {
          'success': false,
          'status_code': e.response?.statusCode ?? 500,
          'message': e.response?.data['message'] ?? 'Erreur lors de l\'enregistrement de l\'appareil',
        });
      } else {
        return DeviceRegisterResponse(
          success: false,
          statusCode: 500,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      return DeviceRegisterResponse(
        success: false,
        statusCode: 500,
        message: 'Erreur inattendue: $e',
      );
    }
  }
}
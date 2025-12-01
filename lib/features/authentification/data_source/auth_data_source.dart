import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../model/login_response.dart';
import '../model/user_model.dart';

class AuthDataSource {
  final Dio _dio = DioClient.instance;

  /// Login avec nouveau système device auth + clés cryptographiques
  Future<Map<String, dynamic>> loginWithDeviceAuth({
    required String phoneOrEmail, 
    required String password,
    required String deviceId,
    required String deviceName,
    required String publicKey,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'phone_or_email': phoneOrEmail,
          'password': password,
          'device_id': deviceId,
          'device_name': deviceName,
          'public_key': publicKey,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        final errorMessage = response.data['message'] ?? 'Erreur de connexion';
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: errorMessage,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Invalid credentials';
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

  /// FALLBACK: Ancien login pour rétrocompatibilité
  Future<LoginResponse> login(String phoneOrEmail, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'phone_or_email': phoneOrEmail,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur de connexion',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur de connexion';
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

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération du profil',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la récupération du profil';
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

  Future<Map<String, dynamic>> verifyVilla(String code) async {
    try {
      final response = await _dio.get(
        '/auth/verify-villa',
        queryParameters: {
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la vérification du QR code',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la vérification du QR code';
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
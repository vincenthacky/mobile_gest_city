import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../model/login_response.dart';
import '../model/user_model.dart';

class AuthDataSource {
  final Dio _dio = DioClient.instance;

  Future<LoginResponse> login(String identifiant, String motDePasse) async {
    try {
      final response = await _dio.post(
        '/api/login',
        data: {
          'identifiant': identifiant,
          'mot_de_passe': motDePasse,
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
      await _dio.post('/api/logout');
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/api/profile');

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
}
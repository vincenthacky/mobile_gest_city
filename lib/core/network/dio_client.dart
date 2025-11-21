import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import '../storage/secure_storage.dart';
import 'device_auth_interceptor.dart';

class DioClient {
  static Dio? _dio;
  static late GoRouter _router;
  static Function()? _onUnauthorized;

  static void setRouter(GoRouter router) {
    _router = router;
  }

  static void setUnauthorizedCallback(Function() callback) {
    _onUnauthorized = callback;
  }

  static Dio get instance {
    if (_dio == null) {
      _dio = Dio();
      _setupInterceptors();
    }
    return _dio!;
  }

  static void _setupInterceptors() {
    _dio!.options.baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _dio!.options.connectTimeout = const Duration(seconds: 30);
    _dio!.options.receiveTimeout = const Duration(seconds: 30);
    _dio!.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Device Auth Interceptor - remplace l'ancien Bearer token
    _dio!.interceptors.add(DeviceAuthInterceptor());

    // Error Interceptor pour gérer les erreurs de sécurité
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) async {
          print('DioClient onError: ${error.response?.statusCode} - ${error.message}');
          
          if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
            print('${error.response?.statusCode} detected - security session expired');
            
            // NOUVEAU : Reset complet de la sécurité device
            await _resetDeviceSecurity();
            
            // Appeler le callback pour notifier l'AuthController
            if (_onUnauthorized != null) {
              _onUnauthorized!();
            }
            
            // Rediriger vers la page d'introduction
            _router.go('/onboarding');
            
            return;
          }
          
          handler.next(error);
        },
      ),
    );

    _dio!.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
    ));
  }

  static void resetClient() {
    _dio?.close();
    _dio = null;
  }

  /// Reset complet de la sécurité device selon le flow spécifié
  static Future<void> _resetDeviceSecurity() async {
    final secureStorage = SecureStorage();
    
    // 1. Supprimer TOUS les secrets locaux
    await secureStorage.delete('device_token');
    await secureStorage.delete('private_key');
    await secureStorage.delete('public_key');
    await secureStorage.delete('device_id');
    await secureStorage.delete('user_id');
    await secureStorage.delete('biometric_setup');
    
    // 2. Nettoyer aussi l'ancien système (si présent)
    await SecureStorage.deleteToken();
    await SecureStorage.deleteUserData();
    
    print('Device security reset completed - all secrets cleared');
  }
}
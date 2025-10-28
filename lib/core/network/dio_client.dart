import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import '../storage/secure_storage.dart';

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

    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          print('DioClient onError: ${error.response?.statusCode} - ${error.message}');
          
          if (error.response?.statusCode == 401) {
            print('401 Unauthorized detected - clearing token and redirecting to login');
            
            // Nettoyer toutes les données d'authentification
            await SecureStorage.deleteToken();
            await SecureStorage.deleteUserData();
            
            // Appeler le callback pour notifier l'AuthController
            if (_onUnauthorized != null) {
              _onUnauthorized!();
            }
            
            // Rediriger vers la page de login
            _router.go('/login');
            
            // Ne pas continuer avec l'erreur pour éviter d'afficher des messages d'erreur
            return;
          }
          
          // Pour toutes les autres erreurs, continuer normalement
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
}
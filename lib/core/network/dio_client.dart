import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static Dio? _dio;
  static late GoRouter _router;

  static void setRouter(GoRouter router) {
    _router = router;
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
          if (error.response?.statusCode == 401) {
            await SecureStorage.deleteToken();
            _router.go('/login');
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
}
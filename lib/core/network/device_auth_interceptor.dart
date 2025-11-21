import 'dart:convert';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../services/crypto_service.dart';

class DeviceAuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Vérifier si l'auth device est configurée
      final secureStorage = SecureStorage();
      final deviceToken = await secureStorage.read('device_token');
      final deviceId = await secureStorage.read('device_id');
      final privateKeyPem = await secureStorage.read('private_key');

      // Si l'auth device n'est pas configurée, passer sans modification
      if (deviceToken == null || deviceId == null || privateKeyPem == null) {
        handler.next(options);
        return;
      }

      // Exclure les routes d'authentification qui n'ont pas besoin du device auth
      final excludedPaths = [
        '/auth/register',
        '/auth/register-device', 
        '/auth/login',
        '/auth/verify-villa',
        '/auth/logout', // Géré différemment
      ];
      
      final isExcluded = excludedPaths.any((path) => options.path.endsWith(path));
      if (isExcluded) {
        handler.next(options);
        return;
      }

      // Générer le payload à signer selon DeviceGuard
      final payload = _generatePayload(options);
      
      // Parser la clé privée et signer le payload
      final privateKey = CryptoService.parsePrivateKeyFromPem(privateKeyPem);
      final signature = CryptoService.signData(payload, privateKey);

      // Ajouter les 4 headers requis par DeviceGuard
      options.headers['Authorization'] = 'DeviceToken $deviceToken';
      options.headers['X-DEVICE-ID'] = deviceId;
      options.headers['X-SIGNATURE'] = signature;
      options.headers['X-PAYLOAD'] = payload;

      // Logs pour debug
      print('📤 DeviceAuth Headers:');
      print('  Authorization: DeviceToken ${deviceToken.substring(0, 10)}...');
      print('  X-DEVICE-ID: $deviceId');
      print('  X-PAYLOAD: ${payload.length} chars');
      print('  X-SIGNATURE: ${signature.substring(0, 20)}...');

      handler.next(options);
    } catch (e) {
      print('DeviceAuthInterceptor Error: $e');
      handler.next(options);
    }
  }

  /// Génère le payload standardisé à signer
  String _generatePayload(RequestOptions options) {
    // Payload simple mais reproductible
    final payloadData = {
      'method': options.method,
      'path': options.path,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Ajouter query parameters s'ils existent
    if (options.queryParameters.isNotEmpty) {
      payloadData['query'] = Map<String, dynamic>.from(options.queryParameters);
    }

    // Ajouter le body pour POST/PUT/PATCH
    if (options.data != null && ['POST', 'PUT', 'PATCH'].contains(options.method)) {
      if (options.data is Map) {
        payloadData['body'] = Map<String, dynamic>.from(options.data);
      } else if (options.data is String) {
        try {
          payloadData['body'] = jsonDecode(options.data);
        } catch (e) {
          payloadData['body'] = options.data.toString();
        }
      } else {
        payloadData['body'] = options.data.toString();
      }
    }

    // Retourner JSON string ordonné pour signature cohérente
    return jsonEncode(payloadData);
  }
}
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import '../models/payment_periods_model.dart';
import 'image_optimizer.dart';

/// Gère l'upload des preuves de paiement avec optimisation automatique.
///
/// Responsabilités :
/// 1. Optimiser toutes les images via [ImageOptimizer]
/// 2. Construire le FormData multipart
/// 3. Envoyer la requête HTTP POST
///
/// Toutes les images sont converties en JPEG avant envoi
/// → MIME type forcé à `image/jpeg`, jamais de rejet backend.
class PaymentUploadService {
  final Dio _dio = DioClient.instance;

  /// Soumet un paiement avec ses périodes et ses preuves photos.
  ///
  /// [request.images] sont optimisées automatiquement avant envoi :
  /// HEIC converti, EXIF supprimé, orientation corrigée, taille réduite si nécessaire.
  Future<PaymentSubmissionResponse> submitPaymentWithPeriods(
    PaymentSubmissionRequest request,
  ) async {
    // Étape 1 : Optimiser toutes les images en parallèle
    debugPrint(
      '🔄 [UploadService] Optimisation de ${request.images.length} image(s)...',
    );
    final optimizedImages = await ImageOptimizer.optimizeAll(request.images);
    debugPrint('✅ [UploadService] Optimisation terminée');

    // Étape 2 : Construire le FormData
    final formFields = <String, dynamic>{};
    for (int i = 0; i < request.periods.length; i++) {
      formFields['periods[$i][year]'] = request.periods[i].year;
      formFields['periods[$i][month]'] = request.periods[i].month;
    }
    final formData = FormData.fromMap(formFields);

    // Toutes les images sont garanties JPEG après optimisation
    for (int i = 0; i < optimizedImages.length; i++) {
      final file = optimizedImages[i];

      if (!await file.exists()) {
        throw Exception('Fichier image introuvable après optimisation : ${file.path}');
      }

      final bytes = await file.readAsBytes();
      final sizeKb = bytes.length ~/ 1024;
      debugPrint('📤 [UploadService] Image $i : $sizeKb KB → upload');

      formData.files.add(
        MapEntry(
          'images[$i]',
          MultipartFile.fromBytes(
            bytes,
            filename: 'proof_$i.jpg',
            contentType: DioMediaType.parse('image/jpeg'),
          ),
        ),
      );
    }

    // Étape 3 : Envoyer
    try {
      final response = await _dio.post(
        '/payments/contributions',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [UploadService] Paiement soumis avec succès');
        return PaymentSubmissionResponse.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Erreur lors de la soumission du paiement',
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ??
          (e.response != null
              ? 'Erreur serveur (${e.response!.statusCode})'
              : 'Erreur réseau. Vérifiez votre connexion.');
      debugPrint('❌ [UploadService] $message');
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        message: message,
      );
    } catch (e) {
      debugPrint('❌ [UploadService] Erreur inattendue : $e');
      throw Exception('Erreur inattendue : $e');
    }
  }
}

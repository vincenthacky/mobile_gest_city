import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/api_response.dart';

class SignalementDataSource {
  final Dio _dio = DioClient.instance;

  Future<SignalementApiResponse> createSignalement({
    required String title,
    required String description,
    required String reportType,
    required String place,
    required String priority,
    required bool anonymous,
    required List<File> images,
  }) async {
    try {
      final formData = FormData();

      // Ajouter les champs texte
      formData.fields.addAll([
        MapEntry('title', title),
        MapEntry('description', description),
        MapEntry('report_type', reportType),
        MapEntry('place', place),
        MapEntry('priority', priority),
        MapEntry('anonymous', anonymous.toString()),
      ]);

      // Ajouter les images
      for (final image in images) {
        final multipartFile = await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        );
        formData.files.add(MapEntry('images[]', multipartFile));
      }

      final response = await _dio.post(
        '/reports',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SignalementApiResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la création du signalement',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la création du signalement';
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
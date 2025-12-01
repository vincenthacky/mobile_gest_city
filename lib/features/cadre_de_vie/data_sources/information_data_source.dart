import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/sync_models.dart';

class InformationDataSource {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> getInformation({
    String? status,
    String? priority,
    String? reportType,
    int perPage = 15,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      if (reportType != null) queryParams['report_type'] = reportType;
      queryParams['per_page'] = perPage.toString();
      queryParams['page'] = page.toString();

      final response = await _dio.get(
        '/information',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des informations',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la récupération des informations';
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

  Future<InformationApiResponse> createInformation({
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

      formData.fields.addAll([
        MapEntry('title', title),
        MapEntry('description', description),
        MapEntry('report_type', reportType),
        MapEntry('place', place),
        MapEntry('priority', priority),
        MapEntry('anonymous', anonymous.toString()),
      ]);

      for (final image in images) {
        final multipartFile = await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        );
        formData.files.add(MapEntry('images[]', multipartFile));
      }

      final response = await _dio.post(
        '/information',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return InformationApiResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la création de l\'information',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la création de l\'information';
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

  /// Synchronise les informations avec le serveur
  Future<InformationSyncResponse> syncInformation(
    InformationSyncRequest request,
  ) async {
    try {
      final data = request.toJson();

      final response = await _dio.post(
        '/information/sync',
        queryParameters: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return InformationSyncResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la synchronisation des informations',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data['message'] ??
            'Erreur lors de la synchronisation des informations';
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
      throw Exception('Erreur inattendue lors de la synchronisation: $e');
    }
  }
}

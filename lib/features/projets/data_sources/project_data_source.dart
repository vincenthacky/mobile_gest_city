import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/project_model.dart';

class ProjectDataSource {
  final Dio _dio = DioClient.instance;

  Future<ApiResponse> createProject({
    required String title,
    required String briefDescription,
    required String detailedDescription,
    required String estimatedBudget,
    required String startDate,
    required String estimatedCompletionDate,
    required String dateLapses,
    required bool withCallForTenders,
    required bool withServiceProvider,
    required List<File> images,
  }) async {
    try {
      final formData = FormData();

      // Ajouter les champs texte
      formData.fields.addAll([
        MapEntry('title', title),
        MapEntry('brief_description', briefDescription),
        MapEntry('detailed_description', detailedDescription),
        MapEntry('estimated_budget', estimatedBudget),
        MapEntry('start_date', startDate),
        MapEntry('estimated_completion_date', estimatedCompletionDate),
        MapEntry('date_lapses', dateLapses),
        MapEntry('with_call_for_tenders', withCallForTenders.toString()),
        MapEntry('with_service_provider', withServiceProvider.toString()),
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
        '/projects',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la création du projet',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la création du projet';
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

  Future<Map<String, dynamic>> getProjects({
    String? status,
    bool? alreadyVoted,
    String? search,
    String? createdBy,
    int perPage = 10,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (status != null) queryParams['status'] = status;
      if (alreadyVoted != null) queryParams['already_voted'] = alreadyVoted.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (createdBy != null) queryParams['created_by'] = createdBy;
      queryParams['per_page'] = perPage.toString();
      queryParams['page'] = page.toString();

      final response = await _dio.get(
        '/projects',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des projets',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la récupération des projets';
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

  Future<ApiResponse> voteYes(String projectId) async {
    try {
      final response = await _dio.post('/projects/$projectId/votes/yes');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors du vote',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors du vote';
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

  Future<ApiResponse> voteNo(String projectId) async {
    try {
      final response = await _dio.post('/projects/$projectId/votes/no');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors du vote',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors du vote';
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

  Future<ApiResponse> voteNeutral(String projectId) async {
    try {
      final response = await _dio.post('/projects/$projectId/votes/neutral');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors du vote',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors du vote';
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

  Future<ApiResponse> voteYesWithReserve(String projectId, String conditions) async {
    try {
      final response = await _dio.post(
        '/projects/$projectId/votes/yes-subject-to',
        data: {'conditions': conditions},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors du vote',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors du vote';
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

  Future<Map<String, dynamic>> getProjectDetails(String projectId) async {
    try {
      final response = await _dio.get('/projects/$projectId');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des détails du projet',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la récupération des détails du projet';
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
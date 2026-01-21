import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/project_model.dart';
import '../models/sync_models.dart';

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

  Future<Map<String, dynamic>> voteYes(String projectId) async {
    try {
      final response = await _dio.post('/projects/$projectId/votes/yes');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> voteNo(String projectId) async {
    try {
      final response = await _dio.post('/projects/$projectId/votes/no');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> voteNeutral(String projectId) async {
    try {
      final response = await _dio.post('/projects/$projectId/votes/neutral');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> voteYesWithReserve(String projectId, String conditions) async {
    try {
      final response = await _dio.post(
        '/projects/$projectId/votes/yes-subject-to',
        data: {'conditions': conditions},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> modifyVote(String projectId, String voteType, {String? conditions}) async {
    try {
      final data = <String, dynamic>{'vote_type': voteType};
      if (conditions != null && conditions.isNotEmpty) {
        data['conditions'] = conditions;
      }

      final response = await _dio.put(
        '/projects/$projectId/votes',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la modification du vote',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la modification du vote';
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

  Future<ApiResponse> prioritizeProjects(List<String> projectIds) async {
    try {
      print('🔥 DEBUG - Envoi priorisation:');
      print('🔥 projectIds: $projectIds');
      print('🔥 URL: /projects/prioritize');
      print('🔥 Data: ${{'projects': projectIds}}');
      
      final response = await _dio.post(
        '/projects/prioritize',
        data: {'projects': projectIds},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      print('🔥 Response status: ${response.statusCode}');
      print('🔥 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la priorisation des projets',
        );
      }
    } on DioException catch (e) {
      print('🔥 DEBUG - DioException:');
      print('🔥 Status code: ${e.response?.statusCode}');
      print('🔥 Response data: ${e.response?.data}');
      print('🔥 Error: $e');
      
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la priorisation des projets';
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
      print('🔥 DEBUG - Exception générique: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Synchronise les projets avec le serveur
  Future<SyncResponse> syncProjects(SyncRequest request) async {
    try {
      final data = request.toJson();
      
      final response = await _dio.post(
        '/projects/sync',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SyncResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la synchronisation',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la synchronisation';
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
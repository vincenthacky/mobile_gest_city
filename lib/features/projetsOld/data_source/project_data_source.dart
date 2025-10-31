import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/project_response.dart';

class ProjectDataSource {
  final Dio _dio = DioClient.instance;

  /// Récupère la liste des projets avec filtres optionnels
  /// [status] : 'ongoing', 'upcoming', 'ended', ou null
  /// [alreadyVoted] : true, false, ou null
  /// [search] : terme de recherche
  /// [perPage] : nombre d'éléments par page (défaut: 10)
  /// [page] : numéro de page (défaut: 1)
  Future<ProjectListResponse> getProjects({
    String? status,
    bool? alreadyVoted,
    String? search,
    int perPage = 10,
    int page = 1,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'per_page': perPage,
        'page': page,
      };

      // Ajouter les filtres optionnels
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      if (alreadyVoted != null) {
        queryParameters['already_voted'] = alreadyVoted;
      }

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get('/projects', queryParameters: queryParameters);

      if (response.statusCode == 200) {
        return ProjectListResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des projets',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 
            'Erreur lors de la récupération des projets';
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

  /// Récupère un projet spécifique par son ID
  Future<ProjectResponse> getProject(int projectId) async {
    try {
      final response = await _dio.get('/projects/$projectId');

      if (response.statusCode == 200) {
        return ProjectResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération du projet',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 
            'Erreur lors de la récupération du projet';
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

  /// Vote sur un projet
  /// [projectId] : ID du projet
  /// [vote] : true pour "oui", false pour "non"
  Future<void> voteOnProject(int projectId, bool vote) async {
    try {
      final endpoint = vote ? '/projects/$projectId/vote-yes' : '/projects/$projectId/vote-no';
      final response = await _dio.post(endpoint);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors du vote',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 
            'Erreur lors du vote';
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

  /// Crée un nouveau projet
  /// [projectData] : Les données du projet à créer
  Future<ProjectResponse> createProject(Map<String, dynamic> projectData) async {
    try {
      final response = await _dio.post('/projects', data: projectData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProjectResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la création du projet',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 
            'Erreur lors de la création du projet';
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
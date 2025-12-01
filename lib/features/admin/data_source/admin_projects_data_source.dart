import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../../projets/models/project_model.dart';

/// Réponse de l'API pour la liste des projets
class AdminProjectsResponse {
  final bool success;
  final List<ProjectModel> data;
  final ProjectsPagination? pagination;
  final String? message;

  AdminProjectsResponse({
    required this.success,
    required this.data,
    this.pagination,
    this.message,
  });

  factory AdminProjectsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final projects = data.map((item) => ProjectModel.fromJson(item)).toList();

    ProjectsPagination? pagination;
    if (json['pagination'] != null) {
      pagination = ProjectsPagination.fromJson(json['pagination']);
    }

    return AdminProjectsResponse(
      success: json['success'] ?? true,
      data: projects,
      pagination: pagination,
      message: json['message'],
    );
  }
}

/// Pagination pour les projets
class ProjectsPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;

  ProjectsPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
  });

  bool get hasNextPage => currentPage < lastPage;

  factory ProjectsPagination.fromJson(Map<String, dynamic> json) {
    return ProjectsPagination(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
    );
  }
}

/// Réponse pour l'ouverture du vote
class OpenVoteResponse {
  final bool success;
  final String message;
  final ProjectModel? project;

  OpenVoteResponse({
    required this.success,
    required this.message,
    this.project,
  });

  factory OpenVoteResponse.fromJson(Map<String, dynamic> json) {
    return OpenVoteResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      project: json['data'] != null ? ProjectModel.fromJson(json['data']) : null,
    );
  }
}

/// Data source pour la gestion admin des projets
class AdminProjectsDataSource {
  final Dio _dio = DioClient.instance;

  /// Récupère la liste des projets avec filtres et pagination
  ///
  /// Query params disponibles:
  /// - status: open, not_open, closed, project_accepted, project_rejected
  /// - sort: total_score
  /// - search: recherche par titre
  /// - per_page: nombre d'items par page (défaut: 20)
  /// - page: numéro de page (défaut: 1)
  Future<AdminProjectsResponse> getProjects({
    String? status,
    String? sort,
    String? search,
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      debugPrint('📡 [ADMIN PROJECTS API] Fetching projects...');
      debugPrint(
        '   Status: $status, Sort: $sort, Search: $search, Page: $page, PerPage: $perPage',
      );

      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      if (sort != null && sort.isNotEmpty) {
        queryParameters['sort'] = sort;
      }

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get(
        '/projects',
        queryParameters: queryParameters,
      );

      debugPrint('✅ [ADMIN PROJECTS API] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final projectsResponse = AdminProjectsResponse.fromJson(response.data);
        debugPrint('   Loaded ${projectsResponse.data.length} projects');
        debugPrint(
          '   Pagination: page ${projectsResponse.pagination?.currentPage}/${projectsResponse.pagination?.lastPage}',
        );
        return projectsResponse;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des projets',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [ADMIN PROJECTS API] Error: ${e.message}');

      if (e.response?.statusCode == 401) {
        debugPrint('   Unauthorized - session expirée');
      } else if (e.response?.statusCode == 403) {
        debugPrint('   Forbidden - permissions insuffisantes');
      }

      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        error: e.error,
        message: e.message ?? 'Erreur réseau',
      );
    } catch (e) {
      debugPrint('❌ [ADMIN PROJECTS API] Unexpected error: $e');
      rethrow;
    }
  }

  /// Ouvre la période de vote pour un projet
  ///
  /// Endpoint: PUT /projects/:projectId
  /// Body: {"status": "vote_open"}
  Future<OpenVoteResponse> openVotePeriod(String projectId) async {
    try {
      debugPrint('📡 [ADMIN PROJECTS API] Opening vote period for project: $projectId');

      final response = await _dio.put(
        '/projects/$projectId',
        data: {'status': 'vote_open'},
      );

      debugPrint('✅ [ADMIN PROJECTS API] Vote period opened');

      if (response.statusCode == 200) {
        return OpenVoteResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de l\'ouverture du vote',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [ADMIN PROJECTS API] Open vote error: ${e.message}');
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        error: e.error,
        message: e.message ?? 'Erreur lors de l\'ouverture du vote',
      );
    }
  }
}

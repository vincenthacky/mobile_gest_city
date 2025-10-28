import 'project_model.dart';
import '../../../core/models/contribution_response.dart'; // Pour réutiliser PaginationModel

class ProjectResponse {
  final bool success;
  final int statusCode;
  final String message;
  final ProjectModel data;

  ProjectResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory ProjectResponse.fromJson(Map<String, dynamic> json) {
    return ProjectResponse(
      success: json['success'],
      statusCode: json['status_code'],
      message: json['message'],
      data: ProjectModel.fromJson(json['data']),
    );
  }
}

class ProjectListResponse {
  final bool success;
  final int statusCode;
  final String message;
  final List<ProjectModel> data;
  final PaginationModel? pagination;

  ProjectListResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory ProjectListResponse.fromJson(Map<String, dynamic> json) {
    return ProjectListResponse(
      success: json['success'],
      statusCode: json['status_code'],
      message: json['message'],
      data: (json['data'] as List)
          .map((item) => ProjectModel.fromJson(item))
          .toList(),
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'])
          : null,
    );
  }
}
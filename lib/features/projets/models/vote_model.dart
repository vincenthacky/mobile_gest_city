import 'project_model.dart';

class VoteModel {
  final String id;
  final String projectId;
  final String userId;
  final VoteChoice choice;
  final String? justification;
  final DateTime createdAt;
  final DateTime updatedAt;

  VoteModel({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.choice,
    this.justification,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VoteModel.fromJson(Map<String, dynamic> json) {
    return VoteModel(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      userId: json['user_id'] ?? '',
      choice: VoteChoice.values.firstWhere(
        (e) => e.toString().split('.').last == json['choice'],
        orElse: () => VoteChoice.blank,
      ),
      justification: json['justification'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'user_id': userId,
      'choice': choice.toString().split('.').last,
      'justification': justification,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ProjectPriorityModel {
  final String userId;
  final List<String> projectIds;
  final DateTime updatedAt;

  ProjectPriorityModel({
    required this.userId,
    required this.projectIds,
    required this.updatedAt,
  });

  factory ProjectPriorityModel.fromJson(Map<String, dynamic> json) {
    return ProjectPriorityModel(
      userId: json['user_id'] ?? '',
      projectIds: List<String>.from(json['project_ids'] ?? []),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'project_ids': projectIds,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
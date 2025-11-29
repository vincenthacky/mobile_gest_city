import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'project_model.dart';
import 'voter_model.dart';

/// Modèle pour les détails complets d'un projet incluant la liste des votants
class ProjectDetailModel {
  final ProjectModel project;
  final List<VoterModel> voters;
  final DateTime cachedAt;

  ProjectDetailModel({
    required this.project,
    required this.voters,
    required this.cachedAt,
  });

  factory ProjectDetailModel.fromJson(Map<String, dynamic> json) {
    final projectData = json['project'] as Map<String, dynamic>;
    final votersData = json['voters'] as List<dynamic>? ?? [];
    
    return ProjectDetailModel(
      project: ProjectModel.fromJson(projectData),
      voters: votersData
          .map((voterJson) => VoterModel.fromJson(voterJson as Map<String, dynamic>))
          .toList(),
      cachedAt: DateTime.parse(json['cached_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project': project.toJson(),
      'voters': voters.map((voter) => voter.toJson()).toList(),
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  /// Vérifie si les données sont récentes (moins de 30 minutes)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(cachedAt);
    return difference.inMinutes < 30;
  }
}

/// Classe pour le cache Hive des détails de projet
class CachedProjectDetail extends HiveObject {
  String projectId;
  String detailJson;
  DateTime cachedAt;

  CachedProjectDetail({
    required this.projectId,
    required this.detailJson,
    required this.cachedAt,
  });

  static CachedProjectDetail create({
    required String projectId,
    required String detailJson,
    required DateTime cachedAt,
  }) {
    return CachedProjectDetail(
      projectId: projectId,
      detailJson: detailJson,
      cachedAt: cachedAt,
    );
  }

  ProjectDetailModel toProjectDetailModel() {
    final json = jsonDecode(detailJson) as Map<String, dynamic>;
    return ProjectDetailModel.fromJson(json);
  }
}

/// Adapter Hive pour CachedProjectDetail
class CachedProjectDetailAdapter extends TypeAdapter<CachedProjectDetail> {
  @override
  final int typeId = 2;

  @override
  CachedProjectDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedProjectDetail(
      projectId: fields[0] as String,
      detailJson: fields[1] as String,
      cachedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedProjectDetail obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.projectId)
      ..writeByte(1)
      ..write(obj.detailJson)
      ..writeByte(2)
      ..write(obj.cachedAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedProjectDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
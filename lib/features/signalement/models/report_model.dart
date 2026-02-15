import 'package:flutter/material.dart';

enum ReportType { security, drugs, suspect, nuisance, infrastructure, other }

enum ReportStatus { pending, inProgress, resolved }

enum PriorityLevel { low, medium, high, urgent }

class ReportModel {
  final String id;
  final String title;
  final String description;
  final ReportType reportType;
  final ReportStatus status;
  final String? place;
  final PriorityLevel priority;
  final bool anonymous;
  final String? reportedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isNew;
  final List<String> images;
  final String? userName;

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.reportType,
    required this.status,
    this.place,
    required this.priority,
    required this.anonymous,
    this.reportedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isNew,
    required this.images,
    this.userName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportModel &&
          id == other.id &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Mapper les types de rapport depuis l'API
    ReportType mapReportType(String apiType) {
      switch (apiType) {
        case 'security':
          return ReportType.security;
        case 'drugs':
          return ReportType.drugs;
        case 'suspect':
          return ReportType.suspect;
        case 'nuisance':
          return ReportType.nuisance;
        case 'infrastructure':
          return ReportType.infrastructure;
        default:
          return ReportType.other;
      }
    }

    // Mapper les statuts depuis l'API
    ReportStatus mapStatus(String apiStatus) {
      switch (apiStatus) {
        case 'pending':
          return ReportStatus.pending;
        case 'in_progress':
          return ReportStatus.inProgress;
        case 'resolved':
          return ReportStatus.resolved;
        default:
          return ReportStatus.pending;
      }
    }

    // Mapper les priorités depuis l'API
    PriorityLevel mapPriority(String apiPriority) {
      switch (apiPriority) {
        case 'low':
          return PriorityLevel.low;
        case 'medium':
          return PriorityLevel.medium;
        case 'high':
          return PriorityLevel.high;
        case 'urgent':
          return PriorityLevel.urgent;
        default:
          return PriorityLevel.medium;
      }
    }

    final imagesData = json['images'] as List<dynamic>? ?? [];
    final user = json['user'] as Map<String, dynamic>?;

    return ReportModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      reportType: mapReportType(json['report_type'] ?? 'other'),
      status: mapStatus(json['status'] ?? 'pending'),
      place: json['place'],
      priority: mapPriority(json['priority'] ?? 'medium'),
      anonymous: json['anonymous'] ?? false,
      reportedBy: json['reported_by'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      isNew: json['new'] ?? false,
      images: imagesData.map((img) => img['url'] as String? ?? '').where((url) => url.isNotEmpty).toList(),
      userName: user?['full_name'],
    );
  }

  // Getters pour l'UI
  IconData get typeIcon {
    switch (reportType) {
      case ReportType.security:
        return Icons.security;
      case ReportType.drugs:
        return Icons.medical_services;
      case ReportType.suspect:
        return Icons.person_search;
      case ReportType.nuisance:
        return Icons.volume_up;
      case ReportType.infrastructure:
        return Icons.construction;
      case ReportType.other:
        return Icons.report;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case PriorityLevel.low:
        return const Color(0xFF10B981);
      case PriorityLevel.medium:
        return const Color(0xFFF59E0B);
      case PriorityLevel.high:
        return const Color(0xFFEF4444);
      case PriorityLevel.urgent:
        return const Color(0xFF7C2D12);
    }
  }

  String get priorityText {
    switch (priority) {
      case PriorityLevel.low:
        return 'Faible';
      case PriorityLevel.medium:
        return 'Moyen';
      case PriorityLevel.high:
        return 'Élevé';
      case PriorityLevel.urgent:
        return 'Urgent';
    }
  }

  Color get statusColor {
    switch (status) {
      case ReportStatus.pending:
        return const Color(0xFF3B82F6);
      case ReportStatus.inProgress:
        return const Color(0xFFF59E0B);
      case ReportStatus.resolved:
        return const Color(0xFF10B981);
    }
  }

  String get statusText {
    switch (status) {
      case ReportStatus.pending:
        return 'En attente';
      case ReportStatus.inProgress:
        return 'En cours';
      case ReportStatus.resolved:
        return 'Résolu';
    }
  }

  String get typeText {
    switch (reportType) {
      case ReportType.security:
        return 'Sécurité';
      case ReportType.drugs:
        return 'Drogue';
      case ReportType.suspect:
        return 'Suspect';
      case ReportType.nuisance:
        return 'Nuisance';
      case ReportType.infrastructure:
        return 'Infrastructure';
      case ReportType.other:
        return 'Autre';
    }
  }

  String get authorText {
    if (anonymous) {
      return 'Signalement anonyme';
    } else {
      return userName ?? 'Utilisateur inconnu';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  bool get hasImages => images.isNotEmpty;
  int get imageCount => images.length;

  /// Convertit le modèle en JSON pour la sérialisation
  Map<String, dynamic> toJson() {
    // Mapper les enums vers leurs valeurs string pour l'API
    String reportTypeToString(ReportType type) {
      switch (type) {
        case ReportType.security:
          return 'security';
        case ReportType.drugs:
          return 'drugs';
        case ReportType.suspect:
          return 'suspect';
        case ReportType.nuisance:
          return 'nuisance';
        case ReportType.infrastructure:
          return 'infrastructure';
        case ReportType.other:
          return 'other';
      }
    }

    String statusToString(ReportStatus status) {
      switch (status) {
        case ReportStatus.pending:
          return 'pending';
        case ReportStatus.inProgress:
          return 'in_progress';
        case ReportStatus.resolved:
          return 'resolved';
      }
    }

    String priorityToString(PriorityLevel priority) {
      switch (priority) {
        case PriorityLevel.low:
          return 'low';
        case PriorityLevel.medium:
          return 'medium';
        case PriorityLevel.high:
          return 'high';
        case PriorityLevel.urgent:
          return 'urgent';
      }
    }

    return {
      'id': id,
      'title': title,
      'description': description,
      'report_type': reportTypeToString(reportType),
      'status': statusToString(status),
      'place': place,
      'priority': priorityToString(priority),
      'anonymous': anonymous,
      'reported_by': reportedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'new': isNew,
      'images': images.map((url) => {'url': url}).toList(),
      'user': userName != null ? {'full_name': userName} : null,
    };
  }
}
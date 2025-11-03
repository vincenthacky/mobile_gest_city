import 'package:flutter/material.dart';

enum InformationType { security, drugs, suspect, nuisance, infrastructure, other }

enum InformationStatus { pending, inProgress, resolved }

enum PriorityLevel { low, medium, high, urgent }

class InformationModel {
  final int id;
  final String title;
  final String description;
  final InformationType reportType;
  final InformationStatus status;
  final String? place;
  final PriorityLevel priority;
  final bool anonymous;
  final int? reportedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isNew;
  final List<String> images;
  final String? userName;

  InformationModel({
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

  factory InformationModel.fromJson(Map<String, dynamic> json) {
    InformationType mapReportType(String apiType) {
      switch (apiType) {
        case 'security':
          return InformationType.security;
        case 'drugs':
          return InformationType.drugs;
        case 'suspect':
          return InformationType.suspect;
        case 'nuisance':
          return InformationType.nuisance;
        case 'infrastructure':
          return InformationType.infrastructure;
        default:
          return InformationType.other;
      }
    }

    InformationStatus mapStatus(String apiStatus) {
      switch (apiStatus) {
        case 'pending':
          return InformationStatus.pending;
        case 'in_progress':
          return InformationStatus.inProgress;
        case 'resolved':
          return InformationStatus.resolved;
        default:
          return InformationStatus.pending;
      }
    }

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

    return InformationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      reportType: mapReportType(json['report_type'] ?? 'other'),
      status: mapStatus(json['status'] ?? 'pending'),
      place: json['place'],
      priority: mapPriority(json['priority'] ?? 'medium'),
      anonymous: json['anonymous'] ?? false,
      reportedBy: json['reported_by'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      isNew: json['new'] ?? false,
      images: imagesData.map((img) => img['url'] as String? ?? '').where((url) => url.isNotEmpty).toList(),
      userName: user?['full_name'],
    );
  }

  IconData get typeIcon {
    switch (reportType) {
      case InformationType.security:
        return Icons.security;
      case InformationType.drugs:
        return Icons.medical_services;
      case InformationType.suspect:
        return Icons.person_search;
      case InformationType.nuisance:
        return Icons.volume_up;
      case InformationType.infrastructure:
        return Icons.construction;
      case InformationType.other:
        return Icons.info;
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
      case InformationStatus.pending:
        return const Color(0xFF3B82F6);
      case InformationStatus.inProgress:
        return const Color(0xFFF59E0B);
      case InformationStatus.resolved:
        return const Color(0xFF10B981);
    }
  }

  String get statusText {
    switch (status) {
      case InformationStatus.pending:
        return 'En attente';
      case InformationStatus.inProgress:
        return 'En cours';
      case InformationStatus.resolved:
        return 'Résolu';
    }
  }

  String get typeText {
    switch (reportType) {
      case InformationType.security:
        return 'Sécurité';
      case InformationType.drugs:
        return 'Drogue';
      case InformationType.suspect:
        return 'Suspect';
      case InformationType.nuisance:
        return 'Nuisance';
      case InformationType.infrastructure:
        return 'Infrastructure';
      case InformationType.other:
        return 'Autre';
    }
  }

  String get authorText {
    if (anonymous) {
      return 'Information anonyme';
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
}
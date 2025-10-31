import 'package:flutter/material.dart';

enum ProjectStatus { upcoming, ongoing, ended }
enum VoteStatus { notVoted, yesVoted, noVoted }

class ProjectModel {
  final int id;
  final String title;
  final String description;
  final DateTime voteStartDate;
  final DateTime voteEndDate;
  final double? budget;
  final String? icon;
  final String? color;
  final String userVoteStatus; // 'not_voted', 'voted_yes', 'voted_no'
  final int votesYes;
  final int votesNo;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.voteStartDate,
    required this.voteEndDate,
    this.budget,
    this.icon,
    this.color,
    required this.userVoteStatus,
    required this.votesYes,
    required this.votesNo,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      voteStartDate: DateTime.parse(json['vote_start_date']),
      voteEndDate: DateTime.parse(json['vote_end_date']),
      budget: _parseBudget(json['budget']),
      icon: json['icon'],
      color: json['color'],
      userVoteStatus: json['user_vote_status'] ?? 'not_voted',
      votesYes: json['votes_yes'] ?? 0,
      votesNo: json['votes_no'] ?? 0,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  static double? _parseBudget(dynamic budget) {
    if (budget == null) return null;
    if (budget is double) return budget;
    if (budget is int) return budget.toDouble();
    if (budget is String) {
      try {
        return double.parse(budget);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'vote_start_date': voteStartDate.toIso8601String(),
      'vote_end_date': voteEndDate.toIso8601String(),
      'budget': budget,
      'icon': icon,
      'color': color,
      'user_vote_status': userVoteStatus,
      'votes_yes': votesYes,
      'votes_no': votesNo,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Getters pour le statut du projet
  ProjectStatus get status {
    final now = DateTime.now();
    if (now.isBefore(voteStartDate)) {
      return ProjectStatus.upcoming;
    } else if (now.isAfter(voteEndDate)) {
      return ProjectStatus.ended;
    } else {
      return ProjectStatus.ongoing;
    }
  }

  // Getters pour le statut de vote
  VoteStatus get voteStatus {
    switch (userVoteStatus) {
      case 'voted_yes':
        return VoteStatus.yesVoted;
      case 'voted_no':
        return VoteStatus.noVoted;
      default:
        return VoteStatus.notVoted;
    }
  }

  // Propriétés calculées
  bool get isUpcoming => status == ProjectStatus.upcoming;
  bool get isOngoing => status == ProjectStatus.ongoing;
  bool get isEnded => status == ProjectStatus.ended;
  bool get canVote => isOngoing && userVoteStatus == 'not_voted';
  bool get hasVoted => userVoteStatus != 'not_voted';
  
  int get totalVotes => votesYes + votesNo;
  double get approvalPercentage => totalVotes > 0 ? votesYes / totalVotes : 0.0;

  // Formatage des dates
  String get formattedStartDate {
    return '${voteStartDate.day.toString().padLeft(2, '0')}/${voteStartDate.month.toString().padLeft(2, '0')}/${voteStartDate.year}';
  }

  String get formattedEndDate {
    return '${voteEndDate.day.toString().padLeft(2, '0')}/${voteEndDate.month.toString().padLeft(2, '0')}/${voteEndDate.year}';
  }

  // Texte de statut
  String get statusText {
    switch (status) {
      case ProjectStatus.upcoming:
        return 'À venir';
      case ProjectStatus.ongoing:
        return 'En cours';
      case ProjectStatus.ended:
        return 'Terminé';
    }
  }

  // Couleur du statut
  Color get statusColor {
    switch (status) {
      case ProjectStatus.upcoming:
        return Colors.orange;
      case ProjectStatus.ongoing:
        return const Color(0xFF10B981);
      case ProjectStatus.ended:
        return Colors.grey;
    }
  }

  // Icône par défaut si aucune icône n'est fournie
  IconData get iconData {
    if (icon != null && icon!.isNotEmpty) {
      // Mapper les noms d'icônes vers IconData
      return _getIconFromString(icon!);
    }
    return Icons.folder_outlined; // Icône par défaut
  }

  // Couleur du projet (API ou aléatoire basée sur l'ID)
  Color get projectColor {
    if (color != null && color!.isNotEmpty) {
      try {
        // Convertir la couleur hexadécimale en Color
        String hexColor = color!;
        if (hexColor.startsWith('#')) {
          hexColor = hexColor.substring(1);
        }
        if (hexColor.length == 6) {
          hexColor = 'FF$hexColor'; // Ajouter l'alpha
        }
        return Color(int.parse(hexColor, radix: 16));
      } catch (e) {
        // Si la conversion échoue, utiliser une couleur aléatoire
      }
    }
    
    // Couleur aléatoire basée sur l'ID du projet
    final colors = [
      const Color(0xFF3B82F6), // Bleu
      const Color(0xFF10B981), // Vert
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEC4899), // Rose
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Rouge
      const Color(0xFF84CC16), // Lime
    ];
    return colors[id % colors.length];
  }

  // Mapper les noms d'icônes vers IconData
  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'fence':
        return Icons.fence;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'water_drop':
        return Icons.water_drop;
      case 'park':
        return Icons.park;
      case 'build':
        return Icons.build;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'nature':
        return Icons.nature;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'directions_car':
        return Icons.directions_car;
      default:
        return Icons.folder_outlined;
    }
  }
}
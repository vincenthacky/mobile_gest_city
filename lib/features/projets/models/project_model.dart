import 'package:flutter/material.dart';

enum ProjectStatus {
  voteNotOpen,
  voteOpen,
  voteClosed,
  accepted,
  rejected,
}

enum VoteChoice {
  yes,
  no,
  yesWithReserve,
  blank,
}

enum ImplementationType {
  withTender,
  knownProvider,
  withoutProvider,
}

class ProjectModel {
  final String id;
  final String title;
  final String shortDescription;
  final String longDescription;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? deadlineDate;
  final double estimatedAmount;
  final ImplementationType implementationType;
  final String? providerName;
  final double? providerAmount;
  final List<String> attachments;
  final ProjectStatus status;
  final DateTime? voteCloseDate;
  final int votesYes;
  final int votesNo;
  final int votesYesWithReserve;
  final int votesBlank;
  final VoteChoice? userVote;
  final String? userVoteJustification;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorId;
  final String authorName;

  ProjectModel({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.longDescription,
    this.startDate,
    this.endDate,
    this.deadlineDate,
    required this.estimatedAmount,
    required this.implementationType,
    this.providerName,
    this.providerAmount,
    this.attachments = const [],
    required this.status,
    this.voteCloseDate,
    this.votesYes = 0,
    this.votesNo = 0,
    this.votesYesWithReserve = 0,
    this.votesBlank = 0,
    this.userVote,
    this.userVoteJustification,
    required this.createdAt,
    required this.updatedAt,
    required this.authorId,
    required this.authorName,
  });

  int get totalVotes => votesYes + votesNo + votesYesWithReserve + votesBlank;
  
  double get yesPercentage => totalVotes > 0 ? votesYes / totalVotes : 0.0;
  double get noPercentage => totalVotes > 0 ? votesNo / totalVotes : 0.0;
  double get yesWithReservePercentage => totalVotes > 0 ? votesYesWithReserve / totalVotes : 0.0;
  double get blankPercentage => totalVotes > 0 ? votesBlank / totalVotes : 0.0;

  bool get hasUserVoted => userVote != null;
  bool get canVote => status == ProjectStatus.voteOpen && !hasUserVoted;
  bool get hasAttachments => attachments.isNotEmpty;
  
  List<String> get imageAttachments {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    return attachments.where((attachment) {
      final lowercaseAttachment = attachment.toLowerCase();
      return imageExtensions.any((ext) => lowercaseAttachment.endsWith(ext));
    }).toList();
  }
  
  bool get hasImages => imageAttachments.isNotEmpty;
  int get imageCount => imageAttachments.length;

  String get statusText {
    switch (status) {
      case ProjectStatus.voteNotOpen:
        return 'Vote pas encore ouvert';
      case ProjectStatus.voteOpen:
        return 'Vote ouvert';
      case ProjectStatus.voteClosed:
        return 'Vote clos';
      case ProjectStatus.accepted:
        return 'Projet accepté';
      case ProjectStatus.rejected:
        return 'Projet rejeté';
    }
  }

  Color get statusColor {
    switch (status) {
      case ProjectStatus.voteNotOpen:
        return const Color(0xFFF97316); // Orange
      case ProjectStatus.voteOpen:
        return const Color(0xFF10B981); // Vert
      case ProjectStatus.voteClosed:
        return const Color(0xFF6B7280); // Gris
      case ProjectStatus.accepted:
        return const Color(0xFF10B981); // Vert
      case ProjectStatus.rejected:
        return const Color(0xFFEF4444); // Rouge
    }
  }

  String get implementationTypeText {
    switch (implementationType) {
      case ImplementationType.withTender:
        return 'Avec appel d\'offre';
      case ImplementationType.knownProvider:
        return 'Prestataire connu';
      case ImplementationType.withoutProvider:
        return 'Sans prestataire';
    }
  }

  String get voteChoiceText {
    if (userVote == null) return '';
    switch (userVote!) {
      case VoteChoice.yes:
        return 'OUI';
      case VoteChoice.no:
        return 'NON';
      case VoteChoice.yesWithReserve:
        return 'OUI SOUS RÉSERVE';
      case VoteChoice.blank:
        return 'BLANC';
    }
  }

  Color get voteChoiceColor {
    if (userVote == null) return Colors.grey;
    switch (userVote!) {
      case VoteChoice.yes:
        return const Color(0xFF10B981);
      case VoteChoice.no:
        return const Color(0xFFEF4444);
      case VoteChoice.yesWithReserve:
        return const Color(0xFFF97316);
      case VoteChoice.blank:
        return const Color(0xFF6B7280);
    }
  }

  String get formattedEstimatedAmount {
    if (estimatedAmount >= 1000000) {
      return '${(estimatedAmount / 1000000).toStringAsFixed(1)}M FCFA';
    } else if (estimatedAmount >= 1000) {
      return '${(estimatedAmount / 1000).toStringAsFixed(1)}k FCFA';
    } else {
      return '${estimatedAmount.toStringAsFixed(0)} FCFA';
    }
  }

  String get formattedVoteCloseDate {
    if (voteCloseDate == null) return 'Non définie';
    final now = DateTime.now();
    final difference = voteCloseDate!.difference(now);
    
    if (difference.isNegative) {
      return 'Terminé';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}min';
    }
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final votes = json['votes'] as Map<String, dynamic>? ?? {};
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final images = json['images'] as List<dynamic>? ?? [];
    
    // Mapping des statuts de l'API vers les statuts du modèle
    ProjectStatus mapStatus(String apiStatus) {
      switch (apiStatus) {
        case 'vote_open':
          return ProjectStatus.voteOpen;
        case 'vote_not_open':
          return ProjectStatus.voteNotOpen;
        case 'vote_closed':
          return ProjectStatus.voteClosed;
        case 'project_accepted':
          return ProjectStatus.accepted;
        case 'project_rejected':
          return ProjectStatus.rejected;
        default:
          return ProjectStatus.voteNotOpen;
      }
    }

    // Déterminer le type d'implémentation selon l'API
    ImplementationType getImplementationType() {
      final withTender = json['with_call_for_tenders'] as bool? ?? false;
      final withProvider = json['with_service_provider'] as bool? ?? false;
      
      if (withTender) {
        return ImplementationType.withTender;
      } else if (withProvider) {
        return ImplementationType.knownProvider;
      } else {
        return ImplementationType.withoutProvider;
      }
    }

    // Mapper le vote utilisateur depuis l'API
    VoteChoice? mapUserVote(dynamic userVoteData) {
      if (userVoteData == null) return null;
      
      // L'API retourne directement une string pour user_vote
      if (userVoteData is String) {
        switch (userVoteData) {
          case 'yes':
          case 'positive':
            return VoteChoice.yes;
          case 'no':
          case 'negative':
            return VoteChoice.no;
          case 'neutral':
            return VoteChoice.blank;
          case 'yes_to_subject':
          case 'yes-subject-to':
            return VoteChoice.yesWithReserve;
          default:
            return null;
        }
      }
      
      // Fallback si c'est un objet vote avec le type
      if (userVoteData is Map<String, dynamic>) {
        final voteType = userVoteData['vote_type'] as String?;
        switch (voteType) {
          case 'positive':
            return VoteChoice.yes;
          case 'negative':
            return VoteChoice.no;
          case 'neutral':
            return VoteChoice.blank;
          case 'yes_to_subject':
            return VoteChoice.yesWithReserve;
          default:
            return null;
        }
      }
      return null;
    }
    
    return ProjectModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      shortDescription: json['brief_description'] ?? '',
      longDescription: json['detailed_description'] ?? '',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['estimated_completion_date'] != null ? DateTime.parse(json['estimated_completion_date']) : null,
      deadlineDate: json['date_lapses'] != null ? DateTime.parse(json['date_lapses']) : null,
      estimatedAmount: double.tryParse(json['estimated_budget']?.toString() ?? '0') ?? 0.0,
      implementationType: getImplementationType(),
      providerName: json['service_provider_name'],
      providerAmount: double.tryParse(json['service_provider_budget']?.toString() ?? '0'),
      attachments: images.map((img) => img['url'] as String? ?? '').where((url) => url.isNotEmpty).toList(),
      status: mapStatus(json['status'] ?? 'vote_not_open'),
      voteCloseDate: json['date_lapses'] != null ? DateTime.parse(json['date_lapses']) : null,
      votesYes: votes['positive_votes'] ?? 0,
      votesNo: votes['negative_votes'] ?? 0,
      votesYesWithReserve: votes['yes_to_subject_votes'] ?? 0,
      votesBlank: votes['neutral_votes'] ?? 0,
      userVote: mapUserVote(votes['user_vote']),
      userVoteJustification: votes['user_vote_justification'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      authorId: json['created_by']?.toString() ?? '',
      authorName: user['full_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'short_description': shortDescription,
      'long_description': longDescription,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'deadline_date': deadlineDate?.toIso8601String(),
      'estimated_amount': estimatedAmount,
      'implementation_type': implementationType.toString().split('.').last,
      'provider_name': providerName,
      'provider_amount': providerAmount,
      'attachments': attachments,
      'status': status.toString().split('.').last,
      'vote_close_date': voteCloseDate?.toIso8601String(),
      'votes_yes': votesYes,
      'votes_no': votesNo,
      'votes_yes_with_reserve': votesYesWithReserve,
      'votes_blank': votesBlank,
      'user_vote': userVote?.toString().split('.').last,
      'user_vote_justification': userVoteJustification,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'author_id': authorId,
      'author_name': authorName,
    };
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? shortDescription,
    String? longDescription,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? deadlineDate,
    double? estimatedAmount,
    ImplementationType? implementationType,
    String? providerName,
    double? providerAmount,
    List<String>? attachments,
    ProjectStatus? status,
    DateTime? voteCloseDate,
    int? votesYes,
    int? votesNo,
    int? votesYesWithReserve,
    int? votesBlank,
    VoteChoice? userVote,
    String? userVoteJustification,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorId,
    String? authorName,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      implementationType: implementationType ?? this.implementationType,
      providerName: providerName ?? this.providerName,
      providerAmount: providerAmount ?? this.providerAmount,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      voteCloseDate: voteCloseDate ?? this.voteCloseDate,
      votesYes: votesYes ?? this.votesYes,
      votesNo: votesNo ?? this.votesNo,
      votesYesWithReserve: votesYesWithReserve ?? this.votesYesWithReserve,
      votesBlank: votesBlank ?? this.votesBlank,
      userVote: userVote ?? this.userVote,
      userVoteJustification: userVoteJustification ?? this.userVoteJustification,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
    );
  }
}
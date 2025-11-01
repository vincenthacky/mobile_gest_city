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
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      shortDescription: json['short_description'] ?? '',
      longDescription: json['long_description'] ?? '',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      deadlineDate: json['deadline_date'] != null ? DateTime.parse(json['deadline_date']) : null,
      estimatedAmount: (json['estimated_amount'] ?? 0).toDouble(),
      implementationType: ImplementationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['implementation_type'],
        orElse: () => ImplementationType.withoutProvider,
      ),
      providerName: json['provider_name'],
      providerAmount: json['provider_amount']?.toDouble(),
      attachments: List<String>.from(json['attachments'] ?? []),
      status: ProjectStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ProjectStatus.voteNotOpen,
      ),
      voteCloseDate: json['vote_close_date'] != null ? DateTime.parse(json['vote_close_date']) : null,
      votesYes: json['votes_yes'] ?? 0,
      votesNo: json['votes_no'] ?? 0,
      votesYesWithReserve: json['votes_yes_with_reserve'] ?? 0,
      votesBlank: json['votes_blank'] ?? 0,
      userVote: json['user_vote'] != null
          ? VoteChoice.values.firstWhere(
              (e) => e.toString().split('.').last == json['user_vote'],
              orElse: () => VoteChoice.blank,
            )
          : null,
      userVoteJustification: json['user_vote_justification'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
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
import '../../../features/projets/models/project_model.dart';

class VoterModel {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String? imageUrl;
  final VoteChoice voteType;
  final DateTime votedAt;

  VoterModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.imageUrl,
    required this.voteType,
    required this.votedAt,
  });

  factory VoterModel.fromJson(Map<String, dynamic> json) {
    // Mapper le vote type depuis l'API
    VoteChoice mapVoteType(String apiVoteType) {
      switch (apiVoteType) {
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
          return VoteChoice.blank;
      }
    }

    return VoterModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      imageUrl: json['image_url'],
      voteType: mapVoteType(json['vote_type'] ?? 'neutral'),
      votedAt: DateTime.parse(json['voted_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get voteText {
    switch (voteType) {
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

  String get formattedVoteDate {
    final now = DateTime.now();
    final difference = now.difference(votedAt);
    
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
      return '${votedAt.day}/${votedAt.month}/${votedAt.year}';
    }
  }

  Map<String, dynamic> toJson() {
    String voteTypeToApi() {
      switch (voteType) {
        case VoteChoice.yes:
          return 'yes';
        case VoteChoice.no:
          return 'no';
        case VoteChoice.yesWithReserve:
          return 'yes_to_subject';
        case VoteChoice.blank:
          return 'neutral';
      }
    }

    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'image_url': imageUrl,
      'vote_type': voteTypeToApi(),
      'voted_at': votedAt.toIso8601String(),
    };
  }
}
class MemberOverviewModel {
  final int villaInscrit; // villas_with_users_count
  final int projetEnCours; // accepted_projects_count
  final int vigilance; // incident_reports_count
  final int solde; // wallet_balance
  final int pendingPaymentsCount;
  final WalletDetails walletDetails;
  final DateTime lastUpdated; // Pour le cache

  const MemberOverviewModel({
    required this.villaInscrit,
    required this.projetEnCours,
    required this.vigilance,
    required this.solde,
    required this.pendingPaymentsCount,
    required this.walletDetails,
    required this.lastUpdated,
  });

  factory MemberOverviewModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    
    return MemberOverviewModel(
      villaInscrit: data['villas_with_users_count'] ?? 0,
      projetEnCours: data['accepted_projects_count'] ?? 0,
      vigilance: data['incident_reports_count'] ?? 0,
      solde: data['wallet_balance'] ?? 0,
      pendingPaymentsCount: data['pending_payments_count'] ?? 0,
      walletDetails: WalletDetails.fromJson(data['wallet_details'] ?? {}),
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'villas_with_users_count': villaInscrit,
      'accepted_projects_count': projetEnCours,
      'incident_reports_count': vigilance,
      'wallet_balance': solde,
      'pending_payments_count': pendingPaymentsCount,
      'wallet_details': walletDetails.toJson(),
      'last_updated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  MemberOverviewModel copyWith({
    int? villaInscrit,
    int? projetEnCours,
    int? vigilance,
    int? solde,
    int? pendingPaymentsCount,
    WalletDetails? walletDetails,
    DateTime? lastUpdated,
  }) {
    return MemberOverviewModel(
      villaInscrit: villaInscrit ?? this.villaInscrit,
      projetEnCours: projetEnCours ?? this.projetEnCours,
      vigilance: vigilance ?? this.vigilance,
      solde: solde ?? this.solde,
      pendingPaymentsCount: pendingPaymentsCount ?? this.pendingPaymentsCount,
      walletDetails: walletDetails ?? this.walletDetails,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Vérifie si les données sont récentes (moins de 30 minutes)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inMinutes < 30;
  }

  /// Formate le solde en string avec devise
  String get soldeFormatted {
    return '${solde.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} FCFA';
  }
}

class WalletDetails {
  final int totalReceipts;
  final int totalExpenses;

  const WalletDetails({
    required this.totalReceipts,
    required this.totalExpenses,
  });

  factory WalletDetails.fromJson(Map<String, dynamic> json) {
    return WalletDetails(
      totalReceipts: json['total_receipts'] ?? 0,
      totalExpenses: json['total_expenses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_receipts': totalReceipts,
      'total_expenses': totalExpenses,
    };
  }

  WalletDetails copyWith({
    int? totalReceipts,
    int? totalExpenses,
  }) {
    return WalletDetails(
      totalReceipts: totalReceipts ?? this.totalReceipts,
      totalExpenses: totalExpenses ?? this.totalExpenses,
    );
  }
}
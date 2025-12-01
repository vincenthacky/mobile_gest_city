class WalletDetails {
  final double totalReceipts;
  final double totalExpenses;

  WalletDetails({required this.totalReceipts, required this.totalExpenses});

  factory WalletDetails.fromJson(Map<String, dynamic> json) {
    return WalletDetails(
      totalReceipts:
          double.tryParse(json['total_receipts']?.toString() ?? '0') ?? 0.0,
      totalExpenses:
          double.tryParse(json['total_expenses']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total_receipts': totalReceipts, 'total_expenses': totalExpenses};
  }
}

class AdminOverviewModel {
  final int acceptedProjectsCount;
  final int pendingPaymentsCount;
  final int villasWithUsersCount;
  final double walletBalance;
  final WalletDetails walletDetails;

  AdminOverviewModel({
    required this.acceptedProjectsCount,
    required this.pendingPaymentsCount,
    required this.villasWithUsersCount,
    required this.walletBalance,
    required this.walletDetails,
  });

  factory AdminOverviewModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return AdminOverviewModel(
      acceptedProjectsCount: data['accepted_projects_count'] ?? 0,
      pendingPaymentsCount: data['pending_payments_count'] ?? 0,
      villasWithUsersCount: data['villas_with_users_count'] ?? 0,
      walletBalance:
          double.tryParse(data['wallet_balance']?.toString() ?? '0') ?? 0.0,
      walletDetails: WalletDetails.fromJson(
        data['wallet_details'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accepted_projects_count': acceptedProjectsCount,
      'pending_payments_count': pendingPaymentsCount,
      'villas_with_users_count': villasWithUsersCount,
      'wallet_balance': walletBalance,
      'wallet_details': walletDetails.toJson(),
    };
  }

  String get formattedWalletBalance {
    final amount = walletBalance.toStringAsFixed(0);
    final parts = <String>[];
    var remaining = amount;

    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return '${parts.join(' ')} FCFA';
  }
}

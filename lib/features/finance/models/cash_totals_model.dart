class CashTotalsResponse {
  final bool success;
  final String message;
  final CashTotalsData data;

  const CashTotalsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CashTotalsResponse.fromJson(Map<String, dynamic> json) {
    return CashTotalsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: CashTotalsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class CashTotalsData {
  final CashTotals totals;

  const CashTotalsData({
    required this.totals,
  });

  factory CashTotalsData.fromJson(Map<String, dynamic> json) {
    return CashTotalsData(
      totals: CashTotals.fromJson(json['totals'] as Map<String, dynamic>),
    );
  }
}

class CashTotals {
  final int totalReceipts;
  final int totalExpenses;
  final int balance;

  const CashTotals({
    required this.totalReceipts,
    required this.totalExpenses,
    required this.balance,
  });

  factory CashTotals.fromJson(Map<String, dynamic> json) {
    return CashTotals(
      totalReceipts: json['total_receipts'] as int,
      totalExpenses: json['total_expenses'] as int,
      balance: json['balance'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_receipts': totalReceipts,
      'total_expenses': totalExpenses,
      'balance': balance,
    };
  }

  String get formattedBalance => _formatAmount(balance);
  String get formattedReceipts => _formatAmount(totalReceipts);
  String get formattedExpenses => _formatAmount(totalExpenses);

  String _formatAmount(int amount) {
    return amount
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }
}
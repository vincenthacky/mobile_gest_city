import 'cash_movement_model.dart';

class CashMovementsResponse {
  final bool success;
  final String message;
  final CashMovementsData data;
  final Pagination pagination;

  const CashMovementsResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory CashMovementsResponse.fromJson(Map<String, dynamic> json) {
    return CashMovementsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: CashMovementsData.fromJson(json['data'] as Map<String, dynamic>),
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class CashMovementsData {
  final List<CashMovement> cashMovements;

  const CashMovementsData({
    required this.cashMovements,
  });

  factory CashMovementsData.fromJson(Map<String, dynamic> json) {
    return CashMovementsData(
      cashMovements: (json['cash_movements'] as List<dynamic>)
          .map((item) => CashMovement.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Totals {
  final int totalReceipts;
  final int totalExpenses;
  final int balance;

  const Totals({
    required this.totalReceipts,
    required this.totalExpenses,
    required this.balance,
  });

  factory Totals.fromJson(Map<String, dynamic> json) {
    return Totals(
      totalReceipts: json['total_receipts'] as int,
      totalExpenses: json['total_expenses'] as int,
      balance: json['balance'] as int,
    );
  }
}

class Pagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int? from;
  final int? to;

  const Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    this.from,
    this.to,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int,
      perPage: json['per_page'] as int,
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      from: json['from'] as int?,
      to: json['to'] as int?,
    );
  }
}
import 'package:intl/intl.dart';

class PaymentBreakdownModel {
  final List<PaymentItemModel> items;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final DateTime? dueDate;

  PaymentBreakdownModel({
    required this.items,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    this.dueDate,
  });

  factory PaymentBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdownModel(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => PaymentItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    );
  }

  String get formattedTotalAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(totalAmount);

  String get formattedPaidAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(paidAmount);

  String get formattedRemainingAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(remainingAmount);

  double get paymentProgress => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  String get statusText {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'partial':
        return 'Partiellement payé';
      case 'pending':
        return 'En attente';
      case 'overdue':
        return 'En retard';
      default:
        return status;
    }
  }

  String? get formattedDueDate => dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : null;
}

class PaymentItemModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final double paidAmount;
  final String status;
  final DateTime? dueDate;
  final List<PaymentVentilationModel> ventilations;

  PaymentItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.paidAmount,
    required this.status,
    this.dueDate,
    required this.ventilations,
  });

  factory PaymentItemModel.fromJson(Map<String, dynamic> json) {
    return PaymentItemModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      ventilations: (json['ventilations'] as List<dynamic>? ?? [])
          .map((v) => PaymentVentilationModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(amount);

  String get formattedPaidAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(paidAmount);

  double get remainingAmount => amount - paidAmount;

  String get formattedRemainingAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(remainingAmount);

  double get paymentProgress => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;

  bool get isPaid => status == 'paid';
  bool get isPartiallyPaid => status == 'partial';
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue';

  String get statusText {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'partial':
        return 'Partiel';
      case 'pending':
        return 'En attente';
      case 'overdue':
        return 'En retard';
      default:
        return status;
    }
  }

  String? get formattedDueDate => dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : null;
}

class PaymentVentilationModel {
  final String id;
  final String category;
  final String description;
  final double amount;
  final double percentage;

  PaymentVentilationModel({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.percentage,
  });

  factory PaymentVentilationModel.fromJson(Map<String, dynamic> json) {
    return PaymentVentilationModel(
      id: json['id'].toString(),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  String get formattedAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(amount);

  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';
}
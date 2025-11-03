import 'package:intl/intl.dart';

class WalletModel {
  final double totalBalance;
  final double pendingAmount;
  final double availableBalance;
  final double monthlyTarget;
  final double currentMonthContribution;
  final List<TransactionModel> recentTransactions;
  final List<PaymentMethodModel> paymentMethods;

  WalletModel({
    required this.totalBalance,
    required this.pendingAmount,
    required this.availableBalance,
    required this.monthlyTarget,
    required this.currentMonthContribution,
    required this.recentTransactions,
    required this.paymentMethods,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      totalBalance: (json['total_balance'] ?? 0).toDouble(),
      pendingAmount: (json['pending_amount'] ?? 0).toDouble(),
      availableBalance: (json['available_balance'] ?? 0).toDouble(),
      monthlyTarget: (json['monthly_target'] ?? 0).toDouble(),
      currentMonthContribution: (json['current_month_contribution'] ?? 0).toDouble(),
      recentTransactions: (json['recent_transactions'] as List<dynamic>? ?? [])
          .map((tx) => TransactionModel.fromJson(tx as Map<String, dynamic>))
          .toList(),
      paymentMethods: (json['payment_methods'] as List<dynamic>? ?? [])
          .map((pm) => PaymentMethodModel.fromJson(pm as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedTotalBalance => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(totalBalance);

  String get formattedAvailableBalance => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(availableBalance);

  String get formattedPendingAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(pendingAmount);

  String get formattedMonthlyTarget => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(monthlyTarget);

  String get formattedCurrentMonthContribution => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(currentMonthContribution);

  double get monthlyProgress => monthlyTarget > 0 ? (currentMonthContribution / monthlyTarget).clamp(0.0, 1.0) : 0.0;
}

class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String status;
  final DateTime date;
  final String? reference;
  final String? paymentMethod;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.date,
    this.reference,
    this.paymentMethod,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      reference: json['reference'],
      paymentMethod: json['payment_method'],
    );
  }

  String get formattedAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(amount);

  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(date);

  bool get isCredit => type == 'credit' || type == 'contribution';
  bool get isDebit => type == 'debit' || type == 'expense';

  String get typeText {
    switch (type) {
      case 'contribution':
        return 'Cotisation';
      case 'payment':
        return 'Paiement';
      case 'refund':
        return 'Remboursement';
      case 'fee':
        return 'Frais';
      default:
        return type.toUpperCase();
    }
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'completed':
        return 'Terminé';
      case 'failed':
        return 'Échoué';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }
}

class PaymentMethodModel {
  final String id;
  final String type;
  final String name;
  final String? last4;
  final bool isDefault;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  PaymentMethodModel({
    required this.id,
    required this.type,
    required this.name,
    this.last4,
    required this.isDefault,
    required this.isActive,
    this.metadata,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      last4: json['last4'],
      isDefault: json['is_default'] ?? false,
      isActive: json['is_active'] ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  String get displayName {
    if (last4 != null) {
      return '$name •••• $last4';
    }
    return name;
  }
}
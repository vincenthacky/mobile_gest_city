import 'package:intl/intl.dart';

class ContributionResponse {
  final bool success;
  final String message;
  final ContributionData data;

  ContributionResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ContributionResponse.fromJson(Map<String, dynamic> json) {
    try {
      return ContributionResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
        data: ContributionData.fromJson(json['data'] ?? {}),
      );
    } catch (e) {
      print('Erreur lors du parsing ContributionResponse: $e');
      print('JSON reçu: $json');
      rethrow;
    }
  }
}

class ContributionData {
  final String id;
  final String name;
  final String? description;
  final double amountByPerson;
  final int deadlineDay;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalAmountPaymentCollectedCurrentPeriod;
  final double totalExpectedAmountThisMonth;
  final String currentPeriod;

  ContributionData({
    required this.id,
    required this.name,
    this.description,
    required this.amountByPerson,
    required this.deadlineDay,
    required this.createdAt,
    required this.updatedAt,
    required this.totalAmountPaymentCollectedCurrentPeriod,
    required this.totalExpectedAmountThisMonth,
    required this.currentPeriod,
  });

  factory ContributionData.fromJson(Map<String, dynamic> json) {
    try {
      return ContributionData(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        amountByPerson: (json['amount_by_person'] ?? 0).toDouble(),
        deadlineDay: json['deadline_day'] ?? 0,
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
        totalAmountPaymentCollectedCurrentPeriod: (json['total_amount_payment_collected_current_period'] ?? 0).toDouble(),
        totalExpectedAmountThisMonth: (json['total_expected_amount_this_month'] ?? 0).toDouble(),
        currentPeriod: json['current_period'] ?? '',
      );
    } catch (e) {
      print('Erreur lors du parsing ContributionData: $e');
      print('JSON reçu: $json');
      rethrow;
    }
  }

  String get formattedAmountByPerson => NumberFormat.currency(
        locale: 'fr_FR',
        symbol: '',
        decimalDigits: 0,
      ).format(amountByPerson);

  String get formattedTotalAmountPaymentCollectedCurrentPeriod => NumberFormat.currency(
        locale: 'fr_FR',
        symbol: '',
        decimalDigits: 0,
      ).format(totalAmountPaymentCollectedCurrentPeriod);

  String get formattedTotalExpectedAmountThisMonth => NumberFormat.currency(
        locale: 'fr_FR',
        symbol: '',
        decimalDigits: 0,
      ).format(totalExpectedAmountThisMonth);

  String get deadlineDayFormatted => deadlineDay.toString();

  double get amountByPersonDouble => amountByPerson;

  String get formattedCreatedAt => DateFormat('dd/MM/yyyy').format(createdAt);
  
  String get formattedUpdatedAt => DateFormat('dd/MM/yyyy').format(updatedAt);

  // Pour la compatibilité avec le widget existant
  String get formattedTotalCollected => formattedTotalAmountPaymentCollectedCurrentPeriod;
  String get formattedCollectedThisMonth => formattedTotalAmountPaymentCollectedCurrentPeriod;
  String get formattedExpectedThisMonth => formattedTotalExpectedAmountThisMonth;
  
  // Alias pour compatibilité
  double get totalAmountPaymentCollectedCurrentMonth => totalAmountPaymentCollectedCurrentPeriod;
  
  double get progressPercentage {
    if (totalExpectedAmountThisMonth == 0) return 0.0;
    return (totalAmountPaymentCollectedCurrentPeriod / totalExpectedAmountThisMonth).clamp(0.0, 1.0);
  }
}
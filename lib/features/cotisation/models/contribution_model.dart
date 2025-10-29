class ContributionResponse {
  final bool success;
  final int statusCode;
  final String message;
  final ContributionData data;

  ContributionResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory ContributionResponse.fromJson(Map<String, dynamic> json) {
    return ContributionResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
      data: ContributionData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status_code': statusCode,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class ContributionData {
  final int id;
  final String name;
  final String? description;
  final String amountByPerson;
  final int deadlineDay;
  final String createdAt;
  final String updatedAt;
  final double totalAmountPaymentCollected;
  final double totalAmountPaymentCollectedCurrentMonth;
  final double totalExpectedAmountThisMonth;

  ContributionData({
    required this.id,
    required this.name,
    this.description,
    required this.amountByPerson,
    required this.deadlineDay,
    required this.createdAt,
    required this.updatedAt,
    required this.totalAmountPaymentCollected,
    required this.totalAmountPaymentCollectedCurrentMonth,
    required this.totalExpectedAmountThisMonth,
  });

  factory ContributionData.fromJson(Map<String, dynamic> json) {
    return ContributionData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      amountByPerson: json['amount_by_person'] ?? '0.00',
      deadlineDay: json['deadline_day'] ?? 1,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      totalAmountPaymentCollected: double.tryParse(json['total_amount_payment_collected']?.toString() ?? '0') ?? 0.0,
      totalAmountPaymentCollectedCurrentMonth: double.tryParse(json['total_amount_payment_collected_current_month']?.toString() ?? '0') ?? 0.0,
      totalExpectedAmountThisMonth: double.tryParse(json['total_expected_amount_this_month']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount_by_person': amountByPerson,
      'deadline_day': deadlineDay,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'total_amount_payment_collected': totalAmountPaymentCollected,
      'total_amount_payment_collected_current_month': totalAmountPaymentCollectedCurrentMonth,
      'total_expected_amount_this_month': totalExpectedAmountThisMonth,
    };
  }

  // Getters pour faciliter l'utilisation
  double get amountByPersonDouble => double.tryParse(amountByPerson) ?? 0.0;
  
  String get formattedAmountByPerson => '${amountByPersonDouble.toStringAsFixed(0)} FCFA/mois';
  
  String get formattedTotalCollected => '${totalAmountPaymentCollected.toStringAsFixed(0)} FCFA';
  
  String get formattedCollectedThisMonth => '${totalAmountPaymentCollectedCurrentMonth.toStringAsFixed(0)} FCFA';
  
  String get formattedExpectedThisMonth => '${totalExpectedAmountThisMonth.toStringAsFixed(0)} FCFA';
  
  String get deadlineDayFormatted => '$deadlineDay du mois';
  
  double get progressPercentage {
    if (totalExpectedAmountThisMonth == 0) return 0.0;
    return (totalAmountPaymentCollectedCurrentMonth / totalExpectedAmountThisMonth).clamp(0.0, 1.0);
  }
}
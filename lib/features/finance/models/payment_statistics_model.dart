class PaymentPeriod {
  final int year;
  final int month;
  final String label;

  PaymentPeriod({
    required this.year,
    required this.month,
    required this.label,
  });

  factory PaymentPeriod.fromJson(Map<String, dynamic> json) {
    return PaymentPeriod(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      label: json['label'] ?? '',
    );
  }
}

class PaymentBreakdownDetail {
  final int amount;
  final int count;

  PaymentBreakdownDetail({
    required this.amount,
    required this.count,
  });

  factory PaymentBreakdownDetail.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdownDetail(
      amount: json['amount'] ?? 0,
      count: json['count'] ?? 0,
    );
  }

  String get formattedAmount {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

class PaymentBreakdown {
  final PaymentBreakdownDetail forCurrentMonth;
  final PaymentBreakdownDetail catchUp;
  final PaymentBreakdownDetail advance;

  PaymentBreakdown({
    required this.forCurrentMonth,
    required this.catchUp,
    required this.advance,
  });

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdown(
      forCurrentMonth: PaymentBreakdownDetail.fromJson(json['for_current_month'] ?? {}),
      catchUp: PaymentBreakdownDetail.fromJson(json['catch_up'] ?? {}),
      advance: PaymentBreakdownDetail.fromJson(json['advance'] ?? {}),
    );
  }
}

class PaymentsMade {
  final int totalAmount;
  final int count;
  final PaymentBreakdown breakdown;

  PaymentsMade({
    required this.totalAmount,
    required this.count,
    required this.breakdown,
  });

  factory PaymentsMade.fromJson(Map<String, dynamic> json) {
    return PaymentsMade(
      totalAmount: json['total_amount'] ?? 0,
      count: json['count'] ?? 0,
      breakdown: PaymentBreakdown.fromJson(json['breakdown'] ?? {}),
    );
  }

  String get formattedTotalAmount {
    return totalAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

class PaymentsFor {
  final int totalAmount;
  final int count;

  PaymentsFor({
    required this.totalAmount,
    required this.count,
  });

  factory PaymentsFor.fromJson(Map<String, dynamic> json) {
    return PaymentsFor(
      totalAmount: json['total_amount'] ?? 0,
      count: json['count'] ?? 0,
    );
  }

  String get formattedTotalAmount {
    return totalAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

class PaymentStatisticsData {
  final PaymentPeriod period;
  final PaymentsMade paymentsMadeInMonth;
  final PaymentsFor paymentsForMonth;

  PaymentStatisticsData({
    required this.period,
    required this.paymentsMadeInMonth,
    required this.paymentsForMonth,
  });

  factory PaymentStatisticsData.fromJson(Map<String, dynamic> json) {
    return PaymentStatisticsData(
      period: PaymentPeriod.fromJson(json['period'] ?? {}),
      paymentsMadeInMonth: PaymentsMade.fromJson(json['payments_made_in_month'] ?? {}),
      paymentsForMonth: PaymentsFor.fromJson(json['payments_for_month'] ?? {}),
    );
  }

  // Getters pour la SummaryCard
  String get montantReel => paymentsMadeInMonth.breakdown.forCurrentMonth.formattedAmount;
  String get montantRemboursement => paymentsMadeInMonth.breakdown.catchUp.formattedAmount;
  String get montantAvance => paymentsMadeInMonth.breakdown.advance.formattedAmount;
  String get montantRecu => paymentsMadeInMonth.formattedTotalAmount;

  // Getters pour les montants numériques
  int get montantReelInt => paymentsMadeInMonth.breakdown.forCurrentMonth.amount;
  int get montantRemboursementInt => paymentsMadeInMonth.breakdown.catchUp.amount;
  int get montantAvanceInt => paymentsMadeInMonth.breakdown.advance.amount;
  int get montantRecuInt => paymentsMadeInMonth.totalAmount;
}

class PaymentStatisticsResponse {
  final bool success;
  final int statusCode;
  final String message;
  final PaymentStatisticsData data;

  PaymentStatisticsResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory PaymentStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatisticsResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 200,
      message: json['message'] ?? '',
      data: PaymentStatisticsData.fromJson(json['data'] ?? {}),
    );
  }
}
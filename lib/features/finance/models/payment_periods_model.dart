import 'dart:io';

class PaymentPeriod {
  final int year;
  final int month;
  final String period;
  bool isSelected;

  PaymentPeriod({
    required this.year,
    required this.month,
    required this.period,
    this.isSelected = false,
  });

  factory PaymentPeriod.fromJson(Map<String, dynamic> json) {
    return PaymentPeriod(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      period: json['period'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
    };
  }

  String get monthName {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month];
  }

  String get shortDisplayName => '$monthName $year';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentPeriod &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}

class PaymentPeriodsData {
  final List<PaymentPeriod> unpaidMonths;
  final List<PaymentPeriod> upcomingMonths;

  PaymentPeriodsData({
    required this.unpaidMonths,
    required this.upcomingMonths,
  });

  factory PaymentPeriodsData.fromJson(Map<String, dynamic> json) {
    final unpaidList = json['unpaid-months'] as List<dynamic>? ?? [];
    final upcomingList = json['upcoming-months'] as List<dynamic>? ?? [];
    
    return PaymentPeriodsData(
      unpaidMonths: unpaidList.map((item) => PaymentPeriod.fromJson(item)).toList(),
      upcomingMonths: upcomingList.map((item) => PaymentPeriod.fromJson(item)).toList(),
    );
  }

  List<PaymentPeriod> get allAvailablePeriods {
    return [...unpaidMonths, ...upcomingMonths];
  }

  List<PaymentPeriod> get selectedPeriods {
    return allAvailablePeriods.where((period) => period.isSelected).toList();
  }

  bool get hasUnpaidMonths => unpaidMonths.isNotEmpty;
  bool get hasUpcomingMonths => upcomingMonths.isNotEmpty;
  bool get hasAnyPeriods => unpaidMonths.isNotEmpty || upcomingMonths.isNotEmpty;
}

class PaymentPeriodsResponse {
  final bool success;
  final int statusCode;
  final String message;
  final PaymentPeriodsData data;

  PaymentPeriodsResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory PaymentPeriodsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentPeriodsResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 200,
      message: json['message'] ?? '',
      data: PaymentPeriodsData.fromJson(json['data'] ?? {}),
    );
  }
}

class PaymentSubmissionRequest {
  final List<PaymentPeriod> periods;
  final List<File> images;

  PaymentSubmissionRequest({
    required this.periods,
    required this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      'periods': periods.map((period) => period.toJson()).toList(),
    };
  }

  bool get isValid => periods.isNotEmpty && images.isNotEmpty;
  
  int get totalAmount => periods.length; // Sera multiplié par le montant par personne
  
  String get periodsDisplayText {
    if (periods.isEmpty) return 'Aucune période sélectionnée';
    if (periods.length == 1) return periods.first.period;
    return '${periods.length} périodes sélectionnées';
  }
}

class PaymentSubmissionResponse {
  final bool success;
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  PaymentSubmissionResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory PaymentSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return PaymentSubmissionResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 200,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}
class UnpaidMonthsResponse {
  final bool success;
  final String message;
  final List<UnpaidMonth> data;

  UnpaidMonthsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UnpaidMonthsResponse.fromJson(Map<String, dynamic> json) {
    return UnpaidMonthsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) => UnpaidMonth.fromJson(item))
          .toList(),
    );
  }
}

class UnpaidMonth {
  final String period;
  final int year;
  final int month;

  UnpaidMonth({
    required this.period,
    required this.year,
    required this.month,
  });

  factory UnpaidMonth.fromJson(Map<String, dynamic> json) {
    return UnpaidMonth(
      period: json['period'] ?? '',
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
    );
  }

  String getTitle(String contributionName) {
    return '$contributionName $period';
  }

  String getDeadline(int deadlineDay) {
    // Calculer la date limite en fonction du jour limite et de la période
    final deadline = DateTime(year, month, deadlineDay);
    return '${deadline.day.toString().padLeft(2, '0')}/${deadline.month.toString().padLeft(2, '0')}/${deadline.year}';
  }

  String getFormattedAmount(double amount) {
    return amount.toStringAsFixed(0);
  }
}
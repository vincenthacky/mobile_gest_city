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
      data: _parseUnpaidMonths(json['data']),
    );
  }

  static List<UnpaidMonth> _parseUnpaidMonths(dynamic data) {
    if (data == null) return [];
    
    // Si data est un Map (nouveau format API)
    if (data is Map<String, dynamic>) {
      final unpaidMonths = (data['unpaid-months'] as List<dynamic>? ?? [])
          .map((item) => UnpaidMonth.fromJson(item))
          .toList();
      
      final upcomingMonths = (data['upcoming-months'] as List<dynamic>? ?? [])
          .map((item) => UnpaidMonth.fromJson(item))
          .toList();
      
      // Combiner les deux listes
      return [...unpaidMonths, ...upcomingMonths];
    }
    
    // Si data est une List (ancien format API) - fallback
    if (data is List<dynamic>) {
      return data.map((item) => UnpaidMonth.fromJson(item)).toList();
    }
    
    return [];
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
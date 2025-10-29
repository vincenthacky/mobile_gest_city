class UnpaidMonthsResponse {
  final bool success;
  final int statusCode;
  final String message;
  final List<UnpaidMonth> data;

  UnpaidMonthsResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory UnpaidMonthsResponse.fromJson(Map<String, dynamic> json) {
    return UnpaidMonthsResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => UnpaidMonth.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status_code': statusCode,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class UnpaidMonth {
  final int year;
  final int month;
  final String period;

  UnpaidMonth({
    required this.year,
    required this.month,
    required this.period,
  });

  factory UnpaidMonth.fromJson(Map<String, dynamic> json) {
    return UnpaidMonth(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      period: json['period'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'period': period,
    };
  }

  // Getters pour faciliter l'utilisation avec contribution data
  String getTitle(String contributionName) {
    return '$contributionName $period';
  }

  String getDeadline(int deadlineDay) {
    // Déterminer le mois suivant pour la date d'échéance
    final deadlineMonth = month == 12 ? 1 : month + 1;
    final deadlineYear = month == 12 ? year + 1 : year;
    
    // Obtenir le nom du mois en français
    final monthNames = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    
    final monthName = deadlineMonth <= 12 ? monthNames[deadlineMonth] : '';
    return 'Échéance: $deadlineDay $monthName $deadlineYear';
  }

  String getFormattedAmount(String amountByPerson) {
    final amount = double.tryParse(amountByPerson) ?? 0.0;
    return '${amount.toStringAsFixed(0)}';
  }

  // Méthode pour obtenir la date d'échéance comme DateTime
  DateTime getDeadlineDate(int deadlineDay) {
    final deadlineMonth = month == 12 ? 1 : month + 1;
    final deadlineYear = month == 12 ? year + 1 : year;
    return DateTime(deadlineYear, deadlineMonth, deadlineDay);
  }

  // Vérifier si c'est vraiment en retard (après la date d'échéance)
  bool isOverdue(int deadlineDay) {
    final deadlineDate = getDeadlineDate(deadlineDay);
    return DateTime.now().isAfter(deadlineDate);
  }
}
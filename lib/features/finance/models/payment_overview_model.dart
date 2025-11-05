class PaymentOverviewUser {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final List<MonthlyPayment> payments;

  PaymentOverviewUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.payments,
  });

  factory PaymentOverviewUser.fromJson(Map<String, dynamic> json) {
    final paymentsList = json['payments'] as List<dynamic>? ?? [];
    
    return PaymentOverviewUser(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      payments: paymentsList.map((item) => MonthlyPayment.fromJson(item)).toList(),
    );
  }

  // Obtenir le statut pour un mois donné
  String getStatusForMonth(int monthNumber) {
    try {
      final payment = payments.firstWhere((p) => p.monthNumber == monthNumber);
      return payment.status;
    } catch (e) {
      return 'unpaid'; // Par défaut si pas de paiement trouvé
    }
  }

  // Obtenir le statut d'affichage pour le tableau avec la nouvelle logique
  String getDisplayStatusForMonth(int monthNumber) {
    final status = getStatusForMonth(monthNumber);
    final statusInt = int.tryParse(status) ?? 0;
    final currentMonth = DateTime.now().month;
    
    // debugPrint('DEBUG: Mois $monthNumber, status: $status ($statusInt), mois actuel: $currentMonth');
    
    // Logique globale indépendante du mois
    if (statusInt == 1) return "paid"; // payé - ✅
    if (statusInt == 0 || statusInt == 3) return "pending"; // attente - 🟠
    if (statusInt == 2 || statusInt == 4) return "unpaid"; // non payé ou failed ou late - ❌
    
    // Pour les mois futurs sans données de paiement
    if (monthNumber > currentMonth) {
      return "future"; // rien si pas encore de tentative de paiement - ➖
    }
    
    return "unpaid"; // par défaut pour les mois passés
  }
  
  // Obtenir le symbole d'affichage
  String getSymbolForMonth(int monthNumber) {
    final status = getStatusForMonth(monthNumber);
    final statusInt = int.tryParse(status) ?? 0;
    final currentMonth = DateTime.now().month;
    
    // Paiement futur
    if (monthNumber > currentMonth) {
      if (statusInt == 1) return "✅"; // payé en avance
      if (statusInt == 0 || statusInt == 3) return "🟠"; // attente
      return "➖"; // rien si pas encore payé
    }

    // Mois passé ou en cours
    if (statusInt == 1) return "✅"; // payé
    if (statusInt == 0 || statusInt == 3) return "🟠"; // attente
    return "❌"; // non payé ou failed ou late
  }
}

class MonthlyPayment {
  final int monthNumber;
  final String status;

  MonthlyPayment({
    required this.monthNumber,
    required this.status,
  });

  factory MonthlyPayment.fromJson(Map<String, dynamic> json) {
    return MonthlyPayment(
      monthNumber: json['month_number'] ?? 0,
      status: json['status'] ?? '0',
    );
  }

  PaymentStatus get paymentStatus {
    switch (status) {
      case '0':
        return PaymentStatus.pending;
      case '1':
        return PaymentStatus.completed;
      case '2':
        return PaymentStatus.late;
      case '3':
        return PaymentStatus.confirmationPending;
      case '4':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  String get statusDisplayName {
    return paymentStatus.displayName;
  }

  bool get isPaid => paymentStatus == PaymentStatus.completed;
  bool get isPending => paymentStatus == PaymentStatus.pending || paymentStatus == PaymentStatus.confirmationPending;
  bool get isLate => paymentStatus == PaymentStatus.late || paymentStatus == PaymentStatus.failed;
}

enum PaymentStatus {
  pending,
  completed,
  late,
  confirmationPending,
  failed,
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.completed:
        return 'Payé';
      case PaymentStatus.late:
        return 'En retard';
      case PaymentStatus.confirmationPending:
        return 'En attente';
      case PaymentStatus.failed:
        return 'Échoué';
    }
  }
}

class PaymentOverviewResponse {
  final bool success;
  final int statusCode;
  final String message;
  final List<PaymentOverviewUser> data;

  PaymentOverviewResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory PaymentOverviewResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    
    return PaymentOverviewResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 200,
      message: json['message'] ?? '',
      data: dataList.map((item) => PaymentOverviewUser.fromJson(item)).toList(),
    );
  }
}
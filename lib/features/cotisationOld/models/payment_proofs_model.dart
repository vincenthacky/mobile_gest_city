class PaymentProofsResponse {
  final bool success;
  final int statusCode;
  final String message;
  final List<PaymentProof> data;
  final PaginationInfo pagination;

  PaymentProofsResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory PaymentProofsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentProofsResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => PaymentProof.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaymentProof {
  final int id;
  final int contributionId;
  final int userId;
  final double amountPaid;
  final String paymentDate;
  final String paymentMethod;
  final String status;
  final dynamic processedBy;
  final String? processedAt;
  final int paymentYear;
  final int paymentMonth;
  final String createdAt;
  final String period;
  final PaymentUser user;

  PaymentProof({
    required this.id,
    required this.contributionId,
    required this.userId,
    required this.amountPaid,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    this.processedBy,
    this.processedAt,
    required this.paymentYear,
    required this.paymentMonth,
    required this.createdAt,
    required this.period,
    required this.user,
  });

  factory PaymentProof.fromJson(Map<String, dynamic> json) {
    return PaymentProof(
      id: json['id'] ?? 0,
      contributionId: json['contribution_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      amountPaid: (json['amount_paid'] ?? 0).toDouble(),
      paymentDate: json['payment_date'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? '',
      processedBy: json['processed_by'],
      processedAt: json['processed_at'],
      paymentYear: json['payment_year'] ?? 0,
      paymentMonth: json['payment_month'] ?? 0,
      createdAt: json['created_at'] ?? '',
      period: json['period'] ?? '',
      user: PaymentUser.fromJson(json['user'] ?? {}),
    );
  }

  // Getters pour l'affichage
  String get formattedAmount {
    return '${amountPaid.toStringAsFixed(0)} FCFA';
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(paymentDate);
      final months = [
        '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
      ];
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '${date.day} ${months[date.month]} ${date.year} à $hour:$minute';
    } catch (e) {
      return paymentDate;
    }
  }

  String get displayTitle {
    return 'Cotisation Mensuelle $period';
  }

  String get formattedPaymentMethod {
    switch (paymentMethod.toLowerCase()) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'hand_hand':
        return 'Main à main';
      default:
        return paymentMethod;
    }
  }

  bool get isValidated => status == 'VALIDATED';
  bool get isPending => status == 'PENDING';
}

class PaymentUser {
  final int id;
  final String fullName;
  final String phone;

  PaymentUser({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  factory PaymentUser.fromJson(Map<String, dynamic> json) {
    return PaymentUser(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class PaginationInfo {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  PaginationInfo({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 10,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
}
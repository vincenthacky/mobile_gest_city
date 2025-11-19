class PaymentUser {
  final String? id;
  final String name;
  final String phone;
  final String email;
  final bool anonymity;
  final String villaNumber;

  PaymentUser({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.anonymity,
    required this.villaNumber,
  });

  factory PaymentUser.fromJson(Map<String, dynamic> json) {
    return PaymentUser(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      anonymity: json['anonymity'] ?? false,
      villaNumber: json['villa']?['number'] ?? 'Villa non spécifiée',
    );
  }

  String get displayName {
    if (anonymity) {
      return villaNumber;
    }
    return name.isNotEmpty ? name : villaNumber;
  }
}

class PaymentItem {
  final String id;
  final String contributionId;
  final int amountPaid;
  final String? paymentDate;
  final String? paymentMethod;
  final String status;
  final String? processedBy;
  final String? processedAt;
  final int? paymentYear;
  final int? paymentMonth;
  final String period;
  final String createdAt;
  final PaymentUser user;

  PaymentItem({
    required this.id,
    required this.contributionId,
    required this.amountPaid,
    this.paymentDate,
    this.paymentMethod,
    required this.status,
    this.processedBy,
    this.processedAt,
    this.paymentYear,
    this.paymentMonth,
    required this.period,
    required this.createdAt,
    required this.user,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    try {
      return PaymentItem(
        id: json['id'] ?? '',
        contributionId: json['contribution_id'] ?? '',
        amountPaid: json['amount_paid'] ?? 0,
        paymentDate: json['payment_date'],
        paymentMethod: json['payment_method'],
        status: json['status'] ?? 'pending',
        processedBy: json['processed_by'],
        processedAt: json['processed_at'],
        paymentYear: json['payment_year'] is int ? json['payment_year'] : (json['payment_year'] != null ? int.tryParse(json['payment_year'].toString()) : null),
        paymentMonth: json['payment_month'] is int ? json['payment_month'] : (json['payment_month'] != null ? int.tryParse(json['payment_month'].toString()) : null),
        period: json['period'] ?? '',
        createdAt: json['created_at'] ?? '',
        user: PaymentUser.fromJson(json['user'] ?? {}),
      );
    } catch (e) {
      print('Erreur lors du parsing PaymentItem: $e');
      print('JSON reçu: $json');
      rethrow;
    }
  }

  String get formattedAmount {
    return amountPaid.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  String get formattedDate {
    if (paymentDate != null && paymentDate!.isNotEmpty) {
      try {
        final date = DateTime.parse(paymentDate!);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        // Si le parsing échoue, retourner la date telle quelle
        return paymentDate!;
      }
    }
    
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Date non disponible';
    }
  }

  PaymentStatus get paymentStatus {
    switch (status) {
      case 'pending':
      case '0':
        return PaymentStatus.pending;
      case 'completed':
      case '1':
        return PaymentStatus.completed;
      case 'late':
      case '2':
        return PaymentStatus.late;
      case 'confirmation_pending':
      case '3':
        return PaymentStatus.confirmationPending;
      case 'failed':
      case '4':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  String get statusDisplayName {
    return paymentStatus.displayName;
  }

  String get displayTitle {
    return 'Cotisation $period';
  }

  String get formattedPaymentMethod {
    if (paymentMethod != null && paymentMethod!.isNotEmpty) {
      return paymentMethod!;
    }
    return 'Méthode non spécifiée';
  }
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
        return 'En attente de validation';
      case PaymentStatus.completed:
        return 'Validé';
      case PaymentStatus.late:
        return 'En retard';
      case PaymentStatus.confirmationPending:
        return 'En attente de validation';
      case PaymentStatus.failed:
        return 'Échoué';
    }
  }

  bool get isCompleted {
    return this == PaymentStatus.completed;
  }

  bool get isPending {
    return this == PaymentStatus.pending || this == PaymentStatus.confirmationPending;
  }

  bool get isError {
    return this == PaymentStatus.late || this == PaymentStatus.failed;
  }
}

class PaymentPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  PaymentPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory PaymentPagination.fromJson(Map<String, dynamic> json) {
    return PaymentPagination(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 10,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

class PaymentListResponse {
  final bool success;
  final int statusCode;
  final String message;
  final List<PaymentItem> data;
  final PaymentPagination pagination;

  PaymentListResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory PaymentListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final payments = dataList.map((item) => PaymentItem.fromJson(item)).toList();
    
    return PaymentListResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 200,
      message: json['message'] ?? '',
      data: payments,
      pagination: PaymentPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}
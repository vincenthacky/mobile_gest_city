import 'package:intl/intl.dart';

class PaymentProofsResponse {
  final bool success;
  final String message;
  final List<PaymentProof> data;
  final PaginationInfo? pagination;

  PaymentProofsResponse({
    required this.success,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory PaymentProofsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentProofsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) => PaymentProof.fromJson(item))
          .toList(),
      pagination: json['pagination'] != null 
          ? PaginationInfo.fromJson(json['pagination'])
          : null,
    );
  }
}

class PaymentProof {
  final String id;
  final String title;
  final DateTime createdAt;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? comment;
  final String? phone;
  final String? fileUrl;

  PaymentProof({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.comment,
    this.phone,
    this.fileUrl,
  });

  factory PaymentProof.fromJson(Map<String, dynamic> json) {
    return PaymentProof(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? '',
      comment: json['comment'],
      phone: json['phone'],
      fileUrl: json['file_url'],
    );
  }

  String get displayTitle => title.isNotEmpty ? title : 'Cotisation';

  String get formattedDate => DateFormat('dd/MM/yyyy').format(createdAt);

  String get formattedAmount => amount.toStringAsFixed(0);

  String get formattedPaymentMethod => paymentMethod;

  bool get isValidated => status == 'VALIDATED';
  bool get isPending => status == 'PENDING';
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalItems: json['total_items'] ?? 0,
      hasNextPage: json['has_next_page'] ?? false,
      hasPreviousPage: json['has_previous_page'] ?? false,
    );
  }
}
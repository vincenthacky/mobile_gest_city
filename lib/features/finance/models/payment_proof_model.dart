import 'dart:io';

enum PaymentProvider {
  orangeMoney,
  mtnMoney,
  wave,
  moovMoney,
}

extension PaymentProviderExtension on PaymentProvider {
  String get displayName {
    switch (this) {
      case PaymentProvider.orangeMoney:
        return 'Orange Money';
      case PaymentProvider.mtnMoney:
        return 'MTN Money';
      case PaymentProvider.wave:
        return 'Wave';
      case PaymentProvider.moovMoney:
        return 'Moov Money';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentProvider.orangeMoney:
        return 'orange_money';
      case PaymentProvider.mtnMoney:
        return 'mtn_money';
      case PaymentProvider.wave:
        return 'wave';
      case PaymentProvider.moovMoney:
        return 'moov_money';
    }
  }

  static PaymentProvider fromDisplayName(String displayName) {
    switch (displayName) {
      case 'Orange Money':
        return PaymentProvider.orangeMoney;
      case 'MTN Money':
        return PaymentProvider.mtnMoney;
      case 'Wave':
        return PaymentProvider.wave;
      case 'Moov Money':
        return PaymentProvider.moovMoney;
      default:
        return PaymentProvider.orangeMoney;
    }
  }
}

class PaymentProofRequest {
  final String comment;
  final String phone;
  final PaymentProvider provider;
  final File file;

  PaymentProofRequest({
    required this.comment,
    required this.phone,
    required this.provider,
    required this.file,
  });
}

class PaymentProofResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  PaymentProofResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PaymentProofResponse.fromJson(Map<String, dynamic> json) {
    return PaymentProofResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}
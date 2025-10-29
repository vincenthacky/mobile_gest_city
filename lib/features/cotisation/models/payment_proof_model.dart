import 'dart:io';

enum PaymentProvider {
  wave,
  mtnMoney,
  orangeMoney,
  moovMoney,
}

extension PaymentProviderExtension on PaymentProvider {
  String get apiValue {
    switch (this) {
      case PaymentProvider.wave:
        return 'wave';
      case PaymentProvider.mtnMoney:
        return 'mtn_money';
      case PaymentProvider.orangeMoney:
        return 'orange_money';
      case PaymentProvider.moovMoney:
        return 'moov_money';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentProvider.wave:
        return 'Wave';
      case PaymentProvider.mtnMoney:
        return 'MTN Money';
      case PaymentProvider.orangeMoney:
        return 'Orange Money';
      case PaymentProvider.moovMoney:
        return 'Moov Money';
    }
  }

  static PaymentProvider fromDisplayName(String displayName) {
    switch (displayName) {
      case 'Wave':
        return PaymentProvider.wave;
      case 'MTN Money':
        return PaymentProvider.mtnMoney;
      case 'Orange Money':
        return PaymentProvider.orangeMoney;
      case 'Moov Money':
        return PaymentProvider.moovMoney;
      default:
        return PaymentProvider.orangeMoney; // default
    }
  }

  static PaymentProvider fromApiValue(String apiValue) {
    switch (apiValue) {
      case 'wave':
        return PaymentProvider.wave;
      case 'mtn_money':
        return PaymentProvider.mtnMoney;
      case 'orange_money':
        return PaymentProvider.orangeMoney;
      case 'moov_money':
        return PaymentProvider.moovMoney;
      default:
        return PaymentProvider.orangeMoney; // default
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

  Map<String, dynamic> toFormData() {
    return {
      'comment': comment,
      'phone': phone,
      'provider': provider.apiValue,
      'file': file,
    };
  }
}

class PaymentProofResponse {
  final bool success;
  final int statusCode;
  final String message;
  final dynamic data;

  PaymentProofResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory PaymentProofResponse.fromJson(Map<String, dynamic> json) {
    return PaymentProofResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status_code': statusCode,
      'message': message,
      'data': data,
    };
  }
}
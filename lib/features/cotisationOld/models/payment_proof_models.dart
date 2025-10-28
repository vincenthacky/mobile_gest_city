enum PaymentProvider {
  wave,
  orangeMoney,
  mtnMoney,
  moovMoney,
}

extension PaymentProviderExtension on PaymentProvider {
  String get apiValue {
    switch (this) {
      case PaymentProvider.wave:
        return 'wave';
      case PaymentProvider.orangeMoney:
        return 'orange_money';
      case PaymentProvider.mtnMoney:
        return 'mtn_money';
      case PaymentProvider.moovMoney:
        return 'moov_money';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentProvider.wave:
        return 'Wave';
      case PaymentProvider.orangeMoney:
        return 'Orange Money';
      case PaymentProvider.mtnMoney:
        return 'MTN Money';
      case PaymentProvider.moovMoney:
        return 'Moov Money';
    }
  }

  static PaymentProvider fromDisplayName(String displayName) {
    switch (displayName) {
      case 'Wave':
        return PaymentProvider.wave;
      case 'Orange Money':
        return PaymentProvider.orangeMoney;
      case 'MTN Money':
        return PaymentProvider.mtnMoney;
      case 'Moov Money':
        return PaymentProvider.moovMoney;
      default:
        return PaymentProvider.orangeMoney;
    }
  }
}

class PaymentProofRequest {
  final String phone;
  final PaymentProvider provider;
  final String filePath;

  PaymentProofRequest({
    required this.phone,
    required this.provider,
    required this.filePath,
  });
}

class PaymentProofResponse {
  final bool success;
  final int statusCode;
  final String? message;

  PaymentProofResponse({
    required this.success,
    required this.statusCode,
    this.message,
  });

  factory PaymentProofResponse.fromJson(Map<String, dynamic> json) {
    return PaymentProofResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 500,
      message: json['message'],
    );
  }

  bool get isSuccess => success && statusCode >= 200 && statusCode < 300;
}
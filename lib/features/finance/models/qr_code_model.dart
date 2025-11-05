class QrCodeResponse {
  final bool success;
  final String message;
  final QrCodeData data;

  QrCodeResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory QrCodeResponse.fromJson(Map<String, dynamic> json) {
    return QrCodeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: QrCodeData.fromJson(json['data'] ?? {}),
    );
  }
}

class QrCodeData {
  final String token;
  final int expiresInSeconds;
  final DateTime expiresAt;

  QrCodeData({
    required this.token,
    required this.expiresInSeconds,
    required this.expiresAt,
  });

  factory QrCodeData.fromJson(Map<String, dynamic> json) {
    return QrCodeData(
      token: json['token'] ?? '',
      expiresInSeconds: json['expires_in_seconds'] ?? 300,
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().add(const Duration(minutes: 5)).toIso8601String()),
    );
  }
}
class QrCodeResponse {
  final bool success;
  final int statusCode;
  final String message;
  final QrCodeData data;

  QrCodeResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory QrCodeResponse.fromJson(Map<String, dynamic> json) {
    return QrCodeResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
      data: QrCodeData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status_code': statusCode,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class QrCodeData {
  final String token;
  final int expiresInSeconds;

  QrCodeData({
    required this.token,
    required this.expiresInSeconds,
  });

  factory QrCodeData.fromJson(Map<String, dynamic> json) {
    return QrCodeData(
      token: json['token'] ?? '',
      expiresInSeconds: json['expires_in_seconds'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expires_in_seconds': expiresInSeconds,
    };
  }

  // Getters pour faciliter l'utilisation
  bool get isExpired => expiresInSeconds <= 0;
  
  Duration get expirationDuration => Duration(seconds: expiresInSeconds);
  
  String get formattedExpiration {
    final minutes = expiresInSeconds ~/ 60;
    final seconds = expiresInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
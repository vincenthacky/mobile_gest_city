class SignalementApiResponse {
  final bool success;
  final int statusCode;
  final String message;
  final dynamic data;

  SignalementApiResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory SignalementApiResponse.fromJson(Map<String, dynamic> json) {
    return SignalementApiResponse(
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
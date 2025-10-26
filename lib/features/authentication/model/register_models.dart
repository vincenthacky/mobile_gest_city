class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String villaId;
  final String birthday;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.villaId,
    required this.birthday,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      'villa_id': villaId,
      'birthday': birthday,
    };
  }
}

class RegisterResponse {
  final bool success;
  final int statusCode;
  final String message;
  final UserData? data;

  RegisterResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 500,
      message: json['message'] ?? '',
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
    );
  }

  bool get isSuccess => success && statusCode >= 200 && statusCode < 300;
}

class UserData {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final int villaId;
  final String? imageUrl;
  final String role;

  UserData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.villaId,
    this.imageUrl,
    required this.role,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      villaId: json['villa_id'] ?? 0,
      imageUrl: json['image_url'],
      role: json['role'] ?? '',
    );
  }
}
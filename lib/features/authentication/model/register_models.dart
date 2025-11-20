class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String villaId;
  final String birthday;
  final bool isAnonymous;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.villaId,
    required this.birthday,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      'villa_id': villaId,
      'birthday': birthday,
      'is_anonymous': isAnonymous,
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

class DeviceRegisterResponse {
  final bool success;
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  DeviceRegisterResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory DeviceRegisterResponse.fromJson(Map<String, dynamic> json) {
    return DeviceRegisterResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 500,
      message: json['message'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  bool get isSuccess => success && statusCode >= 200 && statusCode < 300;
}

class UserData {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? villaId;
  final String? imageUrl;
  final String role;

  UserData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.villaId,
    this.imageUrl,
    required this.role,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      villaId: json['villa_id']?.toString(),
      imageUrl: json['image_url'],
      role: json['role'] ?? '',
    );
  }
}
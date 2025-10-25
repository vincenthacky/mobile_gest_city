import 'user_model.dart';

class LoginResponse {
  final bool success;
  final int statusCode;
  final String message;
  final LoginData data;

  LoginResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'],
      statusCode: json['status_code'],
      message: json['message'],
      data: LoginData.fromJson(json['data']),
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

class LoginData {
  final UserModel user;
  final String token;

  LoginData({
    required this.user,
    required this.token,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: UserModel.fromJson(json['user']),
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
    };
  }
}
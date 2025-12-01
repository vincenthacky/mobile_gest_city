class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? villaId;
  final String? imageUrl;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.villaId,
    this.imageUrl,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      villaId: json['villa_id']?.toString(),
      imageUrl: json['image_url'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'villa_id': villaId,
      'image_url': imageUrl,
      'role': role,
    };
  }
}
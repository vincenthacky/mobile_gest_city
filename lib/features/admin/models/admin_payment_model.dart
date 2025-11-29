class AdminPaymentItem {
  final String id;
  final String checksum;
  final String contributionId;
  final double amountPaid;
  final String paymentDate;
  final String paymentMethod;
  final String status; // confirmation_pending, validated, rejected, etc.
  final String? processedBy;
  final String? processedAt;
  final int paymentYear;
  final int paymentMonth;
  final String period; // "December 2025"
  final DateTime createdAt;

  // User info
  final bool userAnonymity;
  final String userId;
  final String userFullName;
  final String userEmail;
  final String userPhone;
  final String? userImageUrl;
  final String villaId;
  final String villaNumber;
  final String villaCode;

  // Proofs
  final List<PaymentProof> proofs;

  AdminPaymentItem({
    required this.id,
    required this.checksum,
    required this.contributionId,
    required this.amountPaid,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    this.processedBy,
    this.processedAt,
    required this.paymentYear,
    required this.paymentMonth,
    required this.period,
    required this.createdAt,
    required this.userAnonymity,
    required this.userId,
    required this.userFullName,
    required this.userEmail,
    required this.userPhone,
    this.userImageUrl,
    required this.villaId,
    required this.villaNumber,
    required this.villaCode,
    required this.proofs,
  });

  factory AdminPaymentItem.fromJson(Map<String, dynamic> json) {
    // L'API peut retourner les données de deux façons:
    // 1. Avec un objet 'user' contenant les infos (liste des paiements)
    // 2. Sans objet 'user' après validation/rejet (réponse single payment)
    final user = json['user'] as Map<String, dynamic>?;
    final villa = user?['villa'] as Map<String, dynamic>?;
    final proofsList = json['proofs'] as List<dynamic>? ?? [];

    return AdminPaymentItem(
      id: json['id']?.toString() ?? '',
      checksum: json['checksum']?.toString() ?? '',
      contributionId: json['contribution_id']?.toString() ?? '',
      amountPaid: (json['amount_paid'] ?? 0).toDouble(),
      paymentDate: json['payment_date']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      processedBy: json['processed_by']?.toString(),
      processedAt: json['processed_at']?.toString(),
      paymentYear: json['payment_year'] ?? 0,
      paymentMonth: json['payment_month'] ?? 0,
      period: json['period']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      userAnonymity: user?['anonymity'] ?? false,
      userId: user?['id']?.toString() ?? json['user_id']?.toString() ?? '',
      userFullName: user?['full_name']?.toString() ?? 'Utilisateur inconnu',
      userEmail: user?['email']?.toString() ?? '',
      userPhone: user?['phone']?.toString() ?? '',
      userImageUrl: user?['image_url']?.toString(),
      villaId: villa?['id']?.toString() ?? '',
      villaNumber: villa?['number']?.toString() ?? 'Villa inconnue',
      villaCode: villa?['code']?.toString() ?? '',
      proofs: proofsList.map((e) => PaymentProof.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checksum': checksum,
      'contribution_id': contributionId,
      'amount_paid': amountPaid,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      'status': status,
      'processed_by': processedBy,
      'processed_at': processedAt,
      'payment_year': paymentYear,
      'payment_month': paymentMonth,
      'period': period,
      'created_at': createdAt.toIso8601String(),
      'user': {
        'anonymity': userAnonymity,
        'id': userId,
        'full_name': userFullName,
        'email': userEmail,
        'phone': userPhone,
        'image_url': userImageUrl,
        'villa': {'id': villaId, 'number': villaNumber, 'code': villaCode},
      },
      'proofs': proofs.map((e) => e.toJson()).toList(),
    };
  }

  /// Nom à afficher (Numéro de villa pour l'admin)
  String get displayName {
    return villaNumber;
  }

  /// Initiales pour l'avatar
  String get initials {
    if (userAnonymity) {
      // Extraire le numéro de la villa (ex: "Villa-522" -> "522")
      final match = RegExp(r'\d+').firstMatch(villaNumber);
      if (match != null) {
        return match.group(0)?.substring(0, 2) ?? '?';
      }
      return villaNumber.substring(0, 1).toUpperCase();
    }
    return userFullName.isNotEmpty
        ? userFullName.substring(0, 1).toUpperCase()
        : '?';
  }

  /// Helper pour obtenir le statut en texte français
  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente de paiement';
      case 'validated':
      case 'completed':
      case 'paid':
        return 'Payé';
      case 'late':
      case 'overdue':
        return 'En retard';
      case 'confirmation_pending':
        return 'En attente de confirmation';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }

  /// Helper pour obtenir la couleur du statut
  int get statusColorValue {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0xFFF59E0B; // Orange - En attente de paiement
      case 'validated':
      case 'completed':
      case 'paid':
        return 0xFF10B981; // Vert - Payé
      case 'late':
      case 'overdue':
        return 0xFFEF4444; // Rouge - En retard
      case 'confirmation_pending':
        return 0xFF3B82F6; // Bleu - En attente de confirmation
      case 'rejected':
        return 0xFF6B7280; // Gris - Rejeté
      default:
        return 0xFF6B7280;
    }
  }

  /// Méthode de paiement en français
  String get paymentMethodText {
    switch (paymentMethod.toLowerCase()) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'cash':
        return 'Espèces';
      case 'bank_transfer':
        return 'Virement bancaire';
      case 'check':
        return 'Chèque';
      default:
        return paymentMethod;
    }
  }

  /// Helper pour obtenir toutes les images de preuve
  List<PaymentImage> get allProofImages {
    return proofs.expand((p) => p.images).toList();
  }

  /// Helper pour obtenir le nombre total d'images de preuve
  int get totalProofImages => allProofImages.length;
}

class PaymentProof {
  final List<PaymentImage> images;

  PaymentProof({required this.images});

  factory PaymentProof.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List<dynamic>? ?? [];
    return PaymentProof(
      images: imagesList.map((e) => PaymentImage.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'images': images.map((e) => e.toJson()).toList()};
  }
}

class PaymentImage {
  final String id;
  final String filepath;
  final String? publicId;

  PaymentImage({required this.id, required this.filepath, this.publicId});

  factory PaymentImage.fromJson(Map<String, dynamic> json) {
    return PaymentImage(
      id: json['id']?.toString() ?? '',
      filepath: json['filepath']?.toString() ?? '',
      publicId: json['public_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'filepath': filepath, 'public_id': publicId};
  }
}

class PaymentPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  PaymentPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory PaymentPagination.fromJson(Map<String, dynamic> json) {
    return PaymentPagination(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 20,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'per_page': perPage,
      'current_page': currentPage,
      'last_page': lastPage,
      'from': from,
      'to': to,
    };
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

class AdminPaymentsResponse {
  final bool success;
  final int statusCode;
  final String message;
  final List<AdminPaymentItem> data;
  final PaymentPagination? pagination;

  AdminPaymentsResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory AdminPaymentsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final payments = dataList
        .map((item) => AdminPaymentItem.fromJson(item))
        .toList();

    return AdminPaymentsResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 200,
      message: json['message'] ?? '',
      data: payments,
      pagination: json['pagination'] != null
          ? PaymentPagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class PaymentApprovalResponse {
  final bool success;
  final String message;
  final AdminPaymentItem? payment;

  PaymentApprovalResponse({
    required this.success,
    required this.message,
    this.payment,
  });

  factory PaymentApprovalResponse.fromJson(Map<String, dynamic> json) {
    return PaymentApprovalResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      payment: json['data'] != null
          ? AdminPaymentItem.fromJson(json['data'])
          : null,
    );
  }
}

class UnpaidPeriod {
  final int year;
  final int month;
  final String period;

  UnpaidPeriod({
    required this.year,
    required this.month,
    required this.period,
  });

  factory UnpaidPeriod.fromJson(Map<String, dynamic> json) {
    return UnpaidPeriod(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      period: json['period']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'period': period,
    };
  }
}

class QRUserVilla {
  final String id;
  final String number;
  final String latitude;
  final String longitude;
  final String? addressDetails;
  final String code;
  final bool isActivated;
  final String? qrCode;

  QRUserVilla({
    required this.id,
    required this.number,
    required this.latitude,
    required this.longitude,
    this.addressDetails,
    required this.code,
    required this.isActivated,
    this.qrCode,
  });

  factory QRUserVilla.fromJson(Map<String, dynamic> json) {
    return QRUserVilla(
      id: json['id']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      addressDetails: json['address_details']?.toString(),
      code: json['code']?.toString() ?? '',
      isActivated: json['is_activated'] ?? false,
      qrCode: json['qr_code']?.toString(),
    );
  }
}

class QRUserData {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? imageUrl;
  final String? birthdate;
  final String villaId;
  final String role;
  final bool isAnonymous;
  final QRUserVilla villa;
  final List<UnpaidPeriod> unpaidPeriods;

  QRUserData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.imageUrl,
    this.birthdate,
    required this.villaId,
    required this.role,
    required this.isAnonymous,
    required this.villa,
    required this.unpaidPeriods,
  });

  factory QRUserData.fromJson(Map<String, dynamic> json) {
    final unpaidList = json['unpaid_periods'] as List<dynamic>? ?? [];

    return QRUserData(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      birthdate: json['birthdate']?.toString(),
      villaId: json['villa_id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      isAnonymous: json['is_anonymous'] ?? false,
      villa: QRUserVilla.fromJson(json['villa'] ?? {}),
      unpaidPeriods: unpaidList.map((e) => UnpaidPeriod.fromJson(e)).toList(),
    );
  }
}

class QRCodeVerificationResponse {
  final bool success;
  final int statusCode;
  final String message;
  final QRUserData data;

  QRCodeVerificationResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory QRCodeVerificationResponse.fromJson(Map<String, dynamic> json) {
    return QRCodeVerificationResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 200,
      message: json['message'] ?? '',
      data: QRUserData.fromJson(json['data'] ?? {}),
    );
  }
}

class PaymentValidationResponse {
  final bool success;
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  PaymentValidationResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory PaymentValidationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentValidationResponse(
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 200,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

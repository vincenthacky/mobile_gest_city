class CashMovement {
  final int id;
  final int userId;
  final int? contributionId;
  final int amount;
  final DateTime date;
  final String kind;
  final String method;
  final String status;
  final int? projectId;

  const CashMovement({
    required this.id,
    required this.userId,
    this.contributionId,
    required this.amount,
    required this.date,
    required this.kind,
    required this.method,
    required this.status,
    this.projectId,
  });

  factory CashMovement.fromJson(Map<String, dynamic> json) {
    return CashMovement(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      contributionId: json['contribution_id'] as int?,
      amount: json['amount'] as int,
      date: DateTime.parse(json['date'] as String),
      kind: json['kind'] as String,
      method: json['method'] as String,
      status: json['status'] as String,
      projectId: json['project_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'contribution_id': contributionId,
      'amount': amount,
      'date': date.toIso8601String(),
      'kind': kind,
      'method': method,
      'status': status,
      'project_id': projectId,
    };
  }

  bool get isCredit => kind == 'payment';
  bool get isDebit => kind == 'transaction';

  String get typeDisplay {
    if (contributionId != null) {
      return 'Cotisation';
    } else if (projectId != null) {
      return 'Projet';
    } else {
      return 'Transaction';
    }
  }

  String get methodDisplay {
    switch (method) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'hand-to-hand':
        return 'Main à main';
      case 'bank_transfer':
        return 'Virement bancaire';
      default:
        return method;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'VALIDATED':
        return 'Validé';
      case 'PENDING':
        return 'En attente';
      case 'REJECTED':
        return 'Rejeté';
      default:
        return status;
    }
  }
}
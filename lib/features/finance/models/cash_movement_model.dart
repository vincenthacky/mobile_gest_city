class CashMovement {
  final String id;
  final String contributionId;
  final int amount;
  final DateTime date;
  final String kind;
  final String? method;
  final String status;
  final String? projectId;
  final CashMovementUser? user;
  final CashMovementProject? project;

  const CashMovement({
    required this.id,
    required this.contributionId,
    required this.amount,
    required this.date,
    required this.kind,
    this.method,
    required this.status,
    this.projectId,
    this.user,
    this.project,
  });

  factory CashMovement.fromJson(Map<String, dynamic> json) {
    return CashMovement(
      id: json['id'] as String,
      contributionId: json['contribution_id'] as String,
      amount: json['amount'] as int,
      date: DateTime.parse(json['date'] as String),
      kind: json['kind'] as String,
      method: json['method'] as String?,
      status: json['status'] as String,
      projectId: json['project_id'] as String?,
      user: json['user'] != null
          ? CashMovementUser.fromJson(json['user'])
          : null,
      project: json['project'] != null
          ? CashMovementProject.fromJson(json['project'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contribution_id': contributionId,
      'amount': amount,
      'date': date.toIso8601String(),
      'kind': kind,
      'method': method,
      'status': status,
      'project_id': projectId,
      'user': user?.toJson(),
      'project': project?.toJson(),
    };
  }

  bool get isCredit => kind == 'deposit' || kind == 'contribution_payment';
  bool get isDebit => kind == 'withdrawal';

  String get typeDisplay {
    switch (kind) {
      case 'contribution_payment':
        return 'Cotisation';
      case 'withdrawal':
        if (project != null) {
          return 'Financement Projet';
        } else if (user != null) {
          return 'Remboursement';
        } else {
          return 'Retrait';
        }
      case 'deposit':
        return 'Dépôt';
      default:
        return 'Transaction';
    }
  }

  String get methodDisplay {
    if (method == null) return 'Non spécifié';
    switch (method!) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'hand-to-hand':
        return 'Main à main';
      case 'bank_transfer':
        return 'Virement bancaire';
      default:
        return method!;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'completed':
      case '1':
        return 'Validé';
      case 'pending':
      case '0':
        return 'En attente';
      case 'rejected':
      case '-1':
        return 'Rejeté';
      default:
        return status;
    }
  }

  String get description {
    if (kind == 'contribution_payment' && user != null) {
      return 'Cotisation de ${user!.fullName}';
    } else if (kind == 'withdrawal' && project != null) {
      return 'Financement pour ${project!.title}';
    } else if (kind == 'withdrawal' && user != null) {
      return 'Remboursement à ${user!.fullName}';
    } else if (kind == 'deposit') {
      if (user != null) {
        return 'Dépôt de ${user!.fullName}';
      } else {
        return 'Dépôt système';
      }
    }
    return typeDisplay;
  }
}

class CashMovementUser {
  final String userId;
  final String fullName;
  final String email;
  final String phone;

  const CashMovementUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory CashMovementUser.fromJson(Map<String, dynamic> json) {
    return CashMovementUser(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
    };
  }
}

class CashMovementProject {
  final String projectId;
  final String title;
  final int estimatedBudget;

  const CashMovementProject({
    required this.projectId,
    required this.title,
    required this.estimatedBudget,
  });

  factory CashMovementProject.fromJson(Map<String, dynamic> json) {
    return CashMovementProject(
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      estimatedBudget: json['estimated_budget'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'title': title,
      'estimated_budget': estimatedBudget,
    };
  }
}

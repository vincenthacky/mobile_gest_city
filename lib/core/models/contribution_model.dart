class ContributionModel {
  final int id;
  final String name;
  final String? description;
  final int amount;
  final int amountBy;
  final String periodicity;
  final String beginDate;
  final String endDate;
  final bool isDefault;
  final int amountReachedByPeriodicity;
  final int amountReachedTotal;
  final bool alreadyPaid;
  final String? createdAt;

  ContributionModel({
    required this.id,
    required this.name,
    this.description,
    required this.amount,
    required this.amountBy,
    required this.periodicity,
    required this.beginDate,
    required this.endDate,
    required this.isDefault,
    required this.amountReachedByPeriodicity,
    required this.amountReachedTotal,
    required this.alreadyPaid,
    this.createdAt,
  });

  factory ContributionModel.fromJson(Map<String, dynamic> json) {
    return ContributionModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      amount: json['amount'],
      amountBy: json['amount_by'],
      periodicity: json['periodicity'],
      beginDate: json['begin_date'],
      endDate: json['end_date'],
      isDefault: json['is_default'],
      amountReachedByPeriodicity: json['amount_reached_by_periodicity'],
      amountReachedTotal: json['amount_reached_total'],
      alreadyPaid: json['already_paid'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'amount_by': amountBy,
      'periodicity': periodicity,
      'begin_date': beginDate,
      'end_date': endDate,
      'is_default': isDefault,
      'amount_reached_by_periodicity': amountReachedByPeriodicity,
      'amount_reached_total': amountReachedTotal,
      'already_paid': alreadyPaid,
      'created_at': createdAt,
    };
  }

  String get periodicityDisplay {
    switch (periodicity) {
      case 'MONTHLY':
        return 'Mensuellement';
      case 'WEEKLY':
        return 'Hebdomadairement';
      case 'YEARLY':
        return 'Annuellement';
      default:
        return periodicity;
    }
  }

  String get formattedBeginDate {
    try {
      final date = DateTime.parse(beginDate);
      return '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return beginDate;
    }
  }

  String get formattedEndDate {
    try {
      final date = DateTime.parse(endDate);
      return '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return endDate;
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month];
  }
}
import 'package:intl/intl.dart';

class MonthlyContributionsModel {
  final List<ContributionPeriodModel> periods;
  final double totalContributions;
  final double averageMonthlyContribution;
  final ContributionStatsModel stats;

  MonthlyContributionsModel({
    required this.periods,
    required this.totalContributions,
    required this.averageMonthlyContribution,
    required this.stats,
  });

  factory MonthlyContributionsModel.fromJson(Map<String, dynamic> json) {
    return MonthlyContributionsModel(
      periods: (json['periods'] as List<dynamic>? ?? [])
          .map((period) => ContributionPeriodModel.fromJson(period as Map<String, dynamic>))
          .toList(),
      totalContributions: (json['total_contributions'] ?? 0).toDouble(),
      averageMonthlyContribution: (json['average_monthly_contribution'] ?? 0).toDouble(),
      stats: ContributionStatsModel.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
    );
  }

  String get formattedTotalContributions => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(totalContributions);

  String get formattedAverageMonthlyContribution => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(averageMonthlyContribution);
}

class ContributionPeriodModel {
  final String id;
  final String year;
  final String month;
  final double targetAmount;
  final double collectedAmount;
  final double remainingAmount;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final List<MemberContributionModel> memberContributions;

  ContributionPeriodModel({
    required this.id,
    required this.year,
    required this.month,
    required this.targetAmount,
    required this.collectedAmount,
    required this.remainingAmount,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.memberContributions,
  });

  factory ContributionPeriodModel.fromJson(Map<String, dynamic> json) {
    return ContributionPeriodModel(
      id: json['id'].toString(),
      year: json['year'] ?? '',
      month: json['month'] ?? '',
      targetAmount: (json['target_amount'] ?? 0).toDouble(),
      collectedAmount: (json['collected_amount'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
      memberContributions: (json['member_contributions'] as List<dynamic>? ?? [])
          .map((mc) => MemberContributionModel.fromJson(mc as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedTargetAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(targetAmount);

  String get formattedCollectedAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(collectedAmount);

  String get formattedRemainingAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(remainingAmount);

  double get collectionProgress => targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  String get periodName => '$month $year';

  String get statusText {
    switch (status) {
      case 'active':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'overdue':
        return 'En retard';
      case 'closed':
        return 'Clôturé';
      default:
        return status;
    }
  }

  String get formattedStartDate => DateFormat('dd/MM/yyyy').format(startDate);
  String get formattedEndDate => DateFormat('dd/MM/yyyy').format(endDate);
}

class MemberContributionModel {
  final String memberId;
  final String memberName;
  final String memberEmail;
  final double expectedAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final DateTime? lastPaymentDate;
  final List<ContributionPaymentModel> payments;

  MemberContributionModel({
    required this.memberId,
    required this.memberName,
    required this.memberEmail,
    required this.expectedAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    this.lastPaymentDate,
    required this.payments,
  });

  factory MemberContributionModel.fromJson(Map<String, dynamic> json) {
    return MemberContributionModel(
      memberId: json['member_id'].toString(),
      memberName: json['member_name'] ?? '',
      memberEmail: json['member_email'] ?? '',
      expectedAmount: (json['expected_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      lastPaymentDate: json['last_payment_date'] != null 
          ? DateTime.parse(json['last_payment_date']) 
          : null,
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((p) => ContributionPaymentModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedExpectedAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(expectedAmount);

  String get formattedPaidAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(paidAmount);

  String get formattedRemainingAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(remainingAmount);

  double get paymentProgress => expectedAmount > 0 ? (paidAmount / expectedAmount).clamp(0.0, 1.0) : 0.0;

  bool get isPaidInFull => status == 'paid';
  bool get isPartiallyPaid => status == 'partial';
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue';

  String get statusText {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'partial':
        return 'Partiel';
      case 'pending':
        return 'En attente';
      case 'overdue':
        return 'En retard';
      default:
        return status;
    }
  }

  String? get formattedLastPaymentDate => lastPaymentDate != null 
      ? DateFormat('dd/MM/yyyy').format(lastPaymentDate!) 
      : null;
}

class ContributionPaymentModel {
  final String id;
  final double amount;
  final DateTime paymentDate;
  final String method;
  final String reference;
  final String status;

  ContributionPaymentModel({
    required this.id,
    required this.amount,
    required this.paymentDate,
    required this.method,
    required this.reference,
    required this.status,
  });

  factory ContributionPaymentModel.fromJson(Map<String, dynamic> json) {
    return ContributionPaymentModel(
      id: json['id'].toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] ?? DateTime.now().toIso8601String()),
      method: json['method'] ?? '',
      reference: json['reference'] ?? '',
      status: json['status'] ?? '',
    );
  }

  String get formattedAmount => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(amount);

  String get formattedPaymentDate => DateFormat('dd/MM/yyyy HH:mm').format(paymentDate);
}

class ContributionStatsModel {
  final int totalMembers;
  final int paidMembers;
  final int partialMembers;
  final int pendingMembers;
  final double averageContribution;
  final double highestContribution;
  final double lowestContribution;

  ContributionStatsModel({
    required this.totalMembers,
    required this.paidMembers,
    required this.partialMembers,
    required this.pendingMembers,
    required this.averageContribution,
    required this.highestContribution,
    required this.lowestContribution,
  });

  factory ContributionStatsModel.fromJson(Map<String, dynamic> json) {
    return ContributionStatsModel(
      totalMembers: json['total_members'] ?? 0,
      paidMembers: json['paid_members'] ?? 0,
      partialMembers: json['partial_members'] ?? 0,
      pendingMembers: json['pending_members'] ?? 0,
      averageContribution: (json['average_contribution'] ?? 0).toDouble(),
      highestContribution: (json['highest_contribution'] ?? 0).toDouble(),
      lowestContribution: (json['lowest_contribution'] ?? 0).toDouble(),
    );
  }

  double get paidPercentage => totalMembers > 0 ? (paidMembers / totalMembers) * 100 : 0.0;
  double get partialPercentage => totalMembers > 0 ? (partialMembers / totalMembers) * 100 : 0.0;
  double get pendingPercentage => totalMembers > 0 ? (pendingMembers / totalMembers) * 100 : 0.0;

  String get formattedAverageContribution => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(averageContribution);

  String get formattedHighestContribution => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(highestContribution);

  String get formattedLowestContribution => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(lowestContribution);
}
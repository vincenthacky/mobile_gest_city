import 'package:hive_flutter/hive_flutter.dart';

part 'pending_project_models.g.dart';

/// Modèle pour un projet en attente de synchronisation
@HiveType(typeId: 20)
class PendingProject extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String shortDescription;

  @HiveField(3)
  String longDescription;

  @HiveField(4)
  String estimatedAmount;

  @HiveField(5)
  DateTime? startDate;

  @HiveField(6)
  DateTime? endDate;

  @HiveField(7)
  DateTime deadlineDate;

  @HiveField(8)
  bool withCallForTenders;

  @HiveField(9)
  bool withServiceProvider;

  @HiveField(10)
  String? providerName;

  @HiveField(11)
  String? providerAmount;

  @HiveField(12)
  List<String> attachments;

  @HiveField(13)
  List<String> imagePaths;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  int retryCount;

  @HiveField(16)
  String? lastError;

  @HiveField(17)
  PendingProjectStatus status;

  PendingProject({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.longDescription,
    required this.estimatedAmount,
    this.startDate,
    this.endDate,
    required this.deadlineDate,
    required this.withCallForTenders,
    required this.withServiceProvider,
    this.providerName,
    this.providerAmount,
    required this.attachments,
    required this.imagePaths,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.status = PendingProjectStatus.pending,
  });

  /// Factory pour créer un projet en attente depuis les paramètres de création
  factory PendingProject.fromCreateParams({
    required String title,
    required String briefDescription,
    required String detailedDescription,
    required String estimatedBudget,
    required String startDate,
    required String estimatedCompletionDate,
    required String dateLapses,
    required bool withCallForTenders,
    required bool withServiceProvider,
    List<String>? imagePaths,
  }) {
    return PendingProject(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      shortDescription: briefDescription,
      longDescription: detailedDescription,
      estimatedAmount: estimatedBudget,
      startDate: startDate.isNotEmpty ? DateTime.tryParse(startDate) : null,
      endDate: estimatedCompletionDate.isNotEmpty ? DateTime.tryParse(estimatedCompletionDate) : null,
      deadlineDate: DateTime.parse(dateLapses),
      withCallForTenders: withCallForTenders,
      withServiceProvider: withServiceProvider,
      attachments: [],
      imagePaths: imagePaths ?? [],
      createdAt: DateTime.now(),
    );
  }

  /// Convertit le projet en attente vers les paramètres API
  Map<String, dynamic> toApiParams() {
    return {
      'title': title,
      'brief_description': shortDescription,
      'detailed_description': longDescription,
      'estimated_budget': estimatedAmount,
      'start_date': startDate?.toIso8601String() ?? '',
      'estimated_completion_date': endDate?.toIso8601String() ?? '',
      'date_lapses': deadlineDate.toIso8601String(),
      'with_call_for_tenders': withCallForTenders,
      'with_service_provider': withServiceProvider,
      if (providerName != null) 'provider_name': providerName,
      if (providerAmount != null) 'provider_amount': providerAmount,
    };
  }

  /// Met à jour le statut d'erreur
  void markAsError(String error) {
    status = PendingProjectStatus.failed;
    lastError = error;
    retryCount++;
  }

  /// Marque comme en cours de synchronisation
  void markAsSyncing() {
    status = PendingProjectStatus.syncing;
    lastError = null;
  }

  /// Marque comme synchronisé avec succès
  void markAsCompleted() {
    status = PendingProjectStatus.completed;
    lastError = null;
  }

  /// Remet le projet en attente pour un nouveau tentative
  void resetForRetry() {
    status = PendingProjectStatus.pending;
    lastError = null;
  }

  /// Vérifie si le projet peut être retenté
  bool get canRetry => retryCount < 3 && status == PendingProjectStatus.failed;

  /// Vérifie si le projet est prêt pour synchronisation
  bool get canSync => status == PendingProjectStatus.pending;
}

/// Statuts possibles pour un projet en attente
@HiveType(typeId: 21)
enum PendingProjectStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  syncing,

  @HiveField(2)
  completed,

  @HiveField(3)
  failed,
}

/// Extension pour obtenir un libellé lisible du statut
extension PendingProjectStatusExtension on PendingProjectStatus {
  String get label {
    switch (this) {
      case PendingProjectStatus.pending:
        return 'En attente';
      case PendingProjectStatus.syncing:
        return 'Synchronisation...';
      case PendingProjectStatus.completed:
        return 'Synchronisé';
      case PendingProjectStatus.failed:
        return 'Échec';
    }
  }

  String get icon {
    switch (this) {
      case PendingProjectStatus.pending:
        return '⏳';
      case PendingProjectStatus.syncing:
        return '🔄';
      case PendingProjectStatus.completed:
        return '✅';
      case PendingProjectStatus.failed:
        return '❌';
    }
  }
}
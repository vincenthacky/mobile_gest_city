import 'package:hive_flutter/hive_flutter.dart';

part 'pending_sync_models.g.dart';

/// Type de données en attente de synchronisation
@HiveType(typeId: 22)
enum PendingDataType {
  @HiveField(0)
  project,

  @HiveField(1)
  signalement,

  @HiveField(2)
  cadreDeVie,
}

/// Statuts possibles pour les données en attente
@HiveType(typeId: 23)
enum PendingSyncStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  syncing,

  @HiveField(2)
  completed,

  @HiveField(3)
  failed,
}

/// Modèle unifié pour toutes les données en attente de synchronisation
@HiveType(typeId: 24)
class PendingSyncItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  PendingDataType type;

  @HiveField(2)
  String title;

  @HiveField(3)
  String description;

  @HiveField(4)
  Map<String, dynamic> data; // Données spécifiques au type

  @HiveField(5)
  List<String> imagePaths;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  int retryCount;

  @HiveField(8)
  String? lastError;

  @HiveField(9)
  PendingSyncStatus status;

  @HiveField(10)
  String? syncedId; // ID retourné par l'API après synchronisation

  PendingSyncItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.data,
    required this.imagePaths,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.status = PendingSyncStatus.pending,
    this.syncedId,
  });

  /// Factory pour créer un projet en attente
  factory PendingSyncItem.project({
    required String title,
    required String briefDescription,
    required String detailedDescription,
    required String estimatedBudget,
    required String startDate,
    required String estimatedCompletionDate,
    required String dateLapses,
    required bool withCallForTenders,
    required bool withServiceProvider,
    String? providerName,
    String? providerAmount,
    List<String>? imagePaths,
  }) {
    return PendingSyncItem(
      id: 'project_${DateTime.now().millisecondsSinceEpoch}',
      type: PendingDataType.project,
      title: title,
      description: briefDescription,
      data: {
        'brief_description': briefDescription,
        'detailed_description': detailedDescription,
        'estimated_budget': estimatedBudget,
        'start_date': startDate,
        'estimated_completion_date': estimatedCompletionDate,
        'date_lapses': dateLapses,
        'with_call_for_tenders': withCallForTenders,
        'with_service_provider': withServiceProvider,
        if (providerName != null) 'provider_name': providerName,
        if (providerAmount != null) 'provider_amount': providerAmount,
      },
      imagePaths: imagePaths ?? [],
      createdAt: DateTime.now(),
    );
  }

  /// Factory pour créer un signalement en attente
  factory PendingSyncItem.signalement({
    required String title,
    required String description,
    required String place,
    required String type,
    required String priority,
    required bool isAnonymous,
    List<String>? imagePaths,
  }) {
    return PendingSyncItem(
      id: 'signalement_${DateTime.now().millisecondsSinceEpoch}',
      type: PendingDataType.signalement,
      title: title,
      description: description,
      data: {
        'description': description,
        'place': place,
        'type': type,
        'priority': priority,
        'is_anonymous': isAnonymous,
      },
      imagePaths: imagePaths ?? [],
      createdAt: DateTime.now(),
    );
  }

  /// Factory pour créer une information cadre de vie en attente
  factory PendingSyncItem.cadreDeVie({
    required String title,
    required String description,
    required String place,
    required String type,
    required String priority,
    List<String>? imagePaths,
  }) {
    return PendingSyncItem(
      id: 'cadrevie_${DateTime.now().millisecondsSinceEpoch}',
      type: PendingDataType.cadreDeVie,
      title: title,
      description: description,
      data: {
        'description': description,
        'place': place,
        'type': type,
        'priority': priority,
      },
      imagePaths: imagePaths ?? [],
      createdAt: DateTime.now(),
    );
  }

  /// Marque comme en cours de synchronisation
  void markAsSyncing() {
    status = PendingSyncStatus.syncing;
    lastError = null;
  }

  /// Marque comme synchronisé avec succès
  void markAsCompleted({String? syncedId}) {
    status = PendingSyncStatus.completed;
    lastError = null;
    if (syncedId != null) {
      this.syncedId = syncedId;
    }
  }

  /// Met à jour le statut d'erreur
  void markAsError(String error) {
    status = PendingSyncStatus.failed;
    lastError = error;
    retryCount++;
  }

  /// Remet en attente pour un nouveau tentative
  void resetForRetry() {
    status = PendingSyncStatus.pending;
    lastError = null;
  }

  /// Vérifie si l'élément peut être retenté
  bool get canRetry => retryCount < 3 && status == PendingSyncStatus.failed;

  /// Vérifie si l'élément est prêt pour synchronisation
  bool get canSync => status == PendingSyncStatus.pending;

  /// Retourne l'icône selon le type
  String get typeIcon {
    switch (type) {
      case PendingDataType.project:
        return '📋';
      case PendingDataType.signalement:
        return '⚠️';
      case PendingDataType.cadreDeVie:
        return 'ℹ️';
    }
  }

  /// Retourne le label du type
  String get typeLabel {
    switch (type) {
      case PendingDataType.project:
        return 'Projet';
      case PendingDataType.signalement:
        return 'Signalement';
      case PendingDataType.cadreDeVie:
        return 'Cadre de vie';
    }
  }
}

/// Extensions pour obtenir des libellés lisibles
extension PendingSyncStatusExtension on PendingSyncStatus {
  String get label {
    switch (this) {
      case PendingSyncStatus.pending:
        return 'En attente';
      case PendingSyncStatus.syncing:
        return 'Synchronisation...';
      case PendingSyncStatus.completed:
        return 'Synchronisé';
      case PendingSyncStatus.failed:
        return 'Échec';
    }
  }

  String get icon {
    switch (this) {
      case PendingSyncStatus.pending:
        return '⏳';
      case PendingSyncStatus.syncing:
        return '🔄';
      case PendingSyncStatus.completed:
        return '✅';
      case PendingSyncStatus.failed:
        return '❌';
    }
  }
}

extension PendingDataTypeExtension on PendingDataType {
  String get label {
    switch (this) {
      case PendingDataType.project:
        return 'Projets';
      case PendingDataType.signalement:
        return 'Signalements';
      case PendingDataType.cadreDeVie:
        return 'Cadre de vie';
    }
  }
}
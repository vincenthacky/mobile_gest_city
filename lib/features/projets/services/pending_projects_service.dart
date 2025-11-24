import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/pending_project_models.dart';
import '../../../core/services/connectivity_service.dart';
import '../data_sources/project_data_source.dart';

/// Service pour gérer les projets en attente de synchronisation
class PendingProjectsService extends ChangeNotifier {
  static const String _boxName = 'pending_projects';
  static Box<PendingProject>? _box;
  
  final ConnectivityService _connectivityService = ConnectivityService();
  final ProjectDataSource _projectDataSource = ProjectDataSource();
  
  /// Instance singleton
  static final PendingProjectsService _instance = PendingProjectsService._internal();
  factory PendingProjectsService() => _instance;
  PendingProjectsService._internal() {
    // Écouter les changements de connectivité pour synchroniser automatiquement
    _connectivityService.addListener(_onConnectivityChanged);
  }

  /// Initialise Hive et ouvre la box
  static Future<Box<PendingProject>> get instance async {
    if (_box != null && _box!.isOpen) return _box!;
    
    await Hive.initFlutter();
    
    // Enregistrer les adapters si pas déjà fait
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(PendingProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(PendingProjectStatusAdapter());
    }
    
    _box = await Hive.openBox<PendingProject>(_boxName);
    return _box!;
  }

  /// Ajoute un projet en attente de synchronisation
  Future<String> addPendingProject({
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
    String? providerName,
    String? providerAmount,
  }) async {
    final box = await instance;
    
    final pendingProject = PendingProject.fromCreateParams(
      title: title,
      briefDescription: briefDescription,
      detailedDescription: detailedDescription,
      estimatedBudget: estimatedBudget,
      startDate: startDate,
      estimatedCompletionDate: estimatedCompletionDate,
      dateLapses: dateLapses,
      withCallForTenders: withCallForTenders,
      withServiceProvider: withServiceProvider,
      imagePaths: imagePaths,
    );

    if (providerName != null) pendingProject.providerName = providerName;
    if (providerAmount != null) pendingProject.providerAmount = providerAmount;
    
    await box.put(pendingProject.id, pendingProject);
    
    debugPrint('📤 [PENDING] Projet "$title" ajouté en attente de synchronisation');
    notifyListeners();
    
    // Tenter une synchronisation immédiate si connecté
    if (_connectivityService.isConnected) {
      _syncPendingProjects();
    }
    
    return pendingProject.id;
  }

  /// Récupère tous les projets en attente
  Future<List<PendingProject>> getAllPendingProjects() async {
    final box = await instance;
    final projects = box.values.toList();
    
    // Trier par date de création (plus récent en premier)
    projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return projects;
  }

  /// Récupère les projets par statut
  Future<List<PendingProject>> getProjectsByStatus(PendingProjectStatus status) async {
    final box = await instance;
    return box.values.where((project) => project.status == status).toList();
  }

  /// Compte le nombre de projets non synchronisés (pending + failed)
  Future<int> getUnsyncedCount() async {
    final box = await instance;
    return box.values.where((project) => 
      project.status == PendingProjectStatus.pending || 
      project.status == PendingProjectStatus.failed
    ).length;
  }

  /// Supprime un projet en attente
  Future<void> removePendingProject(String projectId) async {
    final box = await instance;
    await box.delete(projectId);
    
    debugPrint('🗑️ [PENDING] Projet "$projectId" supprimé de la liste d\'attente');
    notifyListeners();
  }

  /// Supprime tous les projets synchronisés avec succès
  Future<void> clearCompletedProjects() async {
    final box = await instance;
    final completedKeys = box.values
        .where((project) => project.status == PendingProjectStatus.completed)
        .map((project) => project.id)
        .toList();
    
    await box.deleteAll(completedKeys);
    
    debugPrint('🧹 [PENDING] ${completedKeys.length} projets synchronisés supprimés');
    notifyListeners();
  }

  /// Supprime tous les projets en attente
  Future<void> clearAllPendingProjects() async {
    final box = await instance;
    await box.clear();
    
    debugPrint('🗑️ [PENDING] Tous les projets en attente supprimés');
    notifyListeners();
  }

  /// Synchronise tous les projets en attente
  Future<void> syncAllPendingProjects() async {
    if (!_connectivityService.isConnected) {
      debugPrint('📵 [PENDING] Pas de connexion - synchronisation impossible');
      return;
    }

    await _syncPendingProjects();
  }

  /// Synchronise un projet spécifique
  Future<bool> syncProject(String projectId) async {
    if (!_connectivityService.isConnected) {
      debugPrint('📵 [PENDING] Pas de connexion pour synchroniser "$projectId"');
      return false;
    }

    final box = await instance;
    final project = box.get(projectId);
    
    if (project == null) {
      debugPrint('❌ [PENDING] Projet "$projectId" introuvable');
      return false;
    }

    if (!project.canSync) {
      debugPrint('⚠️ [PENDING] Projet "$projectId" ne peut pas être synchronisé (statut: ${project.status})');
      return false;
    }

    return await _syncSingleProject(project);
  }

  /// Remet en attente tous les projets en échec qui peuvent être retentés
  Future<void> retryFailedProjects() async {
    final box = await instance;
    final failedProjects = box.values
        .where((project) => project.canRetry)
        .toList();

    for (final project in failedProjects) {
      project.resetForRetry();
      await project.save();
    }

    debugPrint('🔄 [PENDING] ${failedProjects.length} projets remis en attente');
    notifyListeners();

    // Tenter la synchronisation si connecté
    if (_connectivityService.isConnected) {
      _syncPendingProjects();
    }
  }

  /// Callback appelé lors du changement de connectivité
  void _onConnectivityChanged() {
    if (_connectivityService.isConnected) {
      debugPrint('🌐 [PENDING] Connexion rétablie - synchronisation automatique');
      _syncPendingProjects();
    }
  }

  /// Synchronise tous les projets en attente (méthode privée)
  Future<void> _syncPendingProjects() async {
    final pendingProjects = await getProjectsByStatus(PendingProjectStatus.pending);
    
    if (pendingProjects.isEmpty) {
      debugPrint('ℹ️ [PENDING] Aucun projet en attente à synchroniser');
      return;
    }

    debugPrint('🔄 [PENDING] Synchronisation de ${pendingProjects.length} projets');

    int successCount = 0;
    int failureCount = 0;

    for (final project in pendingProjects) {
      final success = await _syncSingleProject(project);
      if (success) {
        successCount++;
      } else {
        failureCount++;
      }

      // Petit délai entre les requêtes pour éviter de surcharger l'API
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('✅ [PENDING] Synchronisation terminée: $successCount succès, $failureCount échecs');
    notifyListeners();
  }

  /// Synchronise un projet individuel
  Future<bool> _syncSingleProject(PendingProject project) async {
    try {
      // Marquer comme en cours de synchronisation
      project.markAsSyncing();
      await project.save();
      notifyListeners();

      // Convertir les images en List<File> pour l'API
      final imageFiles = <File>[];
      for (final imagePath in project.imagePaths) {
        if (File(imagePath).existsSync()) {
          imageFiles.add(File(imagePath));
        }
      }

      // Préparer les paramètres
      final params = project.toApiParams();
      
      // Appeler l'API pour créer le projet
      final response = await _projectDataSource.createProject(
        title: params['title'],
        briefDescription: params['brief_description'],
        detailedDescription: params['detailed_description'],
        estimatedBudget: params['estimated_budget'],
        startDate: params['start_date'],
        estimatedCompletionDate: params['estimated_completion_date'],
        dateLapses: params['date_lapses'],
        withCallForTenders: params['with_call_for_tenders'],
        withServiceProvider: params['with_service_provider'],
        images: imageFiles,
      );

      if (response.success) {
        // Marquer comme terminé
        project.markAsCompleted();
        await project.save();
        
        debugPrint('✅ [PENDING] Projet "${project.title}" synchronisé avec succès');
        return true;
      } else {
        // Marquer comme en échec
        final error = response.message;
        project.markAsError(error);
        await project.save();
        
        debugPrint('❌ [PENDING] Échec synchronisation "${project.title}": $error');
        return false;
      }
    } catch (e) {
      // Marquer comme en échec
      project.markAsError(e.toString());
      await project.save();
      
      debugPrint('❌ [PENDING] Erreur synchronisation "${project.title}": $e');
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Ferme la base de données
  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
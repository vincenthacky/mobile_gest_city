import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data_sources/project_data_source.dart';
import '../models/project_model.dart';
import '../models/voter_model.dart';
import '../models/sync_models.dart';
import '../services/sync_service.dart';
import '../services/local_storage_service.dart';
import '../../../core/services/unified_sync_service.dart';
import '../../../core/widgets/sync_notification.dart';
import '../../../core/services/connectivity_service.dart';

enum ProjectSubmissionStatus { initial, loading, success, error }
enum ProjectLoadingStatus { initial, loading, success, error }
enum VoteStatus { initial, loading, success, error }
enum ProjectDetailStatus { initial, loading, success, error }
enum PrioritizationStatus { initial, loading, success, error }

class ProjectController extends ChangeNotifier {
  final ProjectDataSource _projectDataSource = ProjectDataSource();
  final ImagePicker _imagePicker = ImagePicker();
  final UnifiedSyncService _unifiedSyncService = UnifiedSyncService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  ProjectSubmissionStatus _status = ProjectSubmissionStatus.initial;
  String? _errorMessage;
  List<File> _selectedImages = [];

  // Pour la récupération des projets
  ProjectLoadingStatus _loadingStatus = ProjectLoadingStatus.initial;
  List<ProjectModel> _allProjects = []; // Cache complet comme WhatsApp
  List<ProjectModel> _projects = []; // Données filtrées affichées
  Map<String, dynamic>? _pagination;
  String? _loadingErrorMessage;
  
  // Filtres locaux (comme WhatsApp)
  ProjectStatus? _currentFilter;
  String? _currentSearch;

  // Pour les votes
  VoteStatus _voteStatus = VoteStatus.initial;
  String? _voteErrorMessage;

  // Pour les détails du projet
  ProjectDetailStatus _detailStatus = ProjectDetailStatus.initial;
  ProjectModel? _selectedProject;
  List<VoterModel> _voters = [];
  String? _detailErrorMessage;

  // Pour la priorisation
  PrioritizationStatus _prioritizationStatus = PrioritizationStatus.initial;
  String? _prioritizationErrorMessage;

  // Pour la synchronisation
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _syncErrorMessage;
  String? _syncMessage;
  
  // Pour les notifications de synchronisation
  SyncNotificationType _notificationType = SyncNotificationType.none;
  String? _notificationMessage;

  // Getters pour la soumission de projet
  ProjectSubmissionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<File> get selectedImages => List.unmodifiable(_selectedImages);
  bool get isLoading => _status == ProjectSubmissionStatus.loading;
  bool get hasImages => _selectedImages.isNotEmpty;

  // Getters pour la récupération des projets
  ProjectLoadingStatus get loadingStatus => _loadingStatus;
  List<ProjectModel> get projects => List.unmodifiable(_projects);
  List<ProjectModel> get allProjects => List.unmodifiable(_allProjects);
  Map<String, dynamic>? get pagination => _pagination;
  String? get loadingErrorMessage => _loadingErrorMessage;
  bool get isLoadingProjects => _loadingStatus == ProjectLoadingStatus.loading;
  
  // Getters pour les filtres
  ProjectStatus? get currentFilter => _currentFilter;
  String? get currentSearch => _currentSearch;
  int get totalProjectsCount => _allProjects.length;
  int get filteredProjectsCount => _projects.length;

  // Getters pour les votes
  VoteStatus get voteStatus => _voteStatus;
  String? get voteErrorMessage => _voteErrorMessage;
  bool get isVoting => _voteStatus == VoteStatus.loading;

  // Getters pour les détails du projet
  ProjectDetailStatus get detailStatus => _detailStatus;
  ProjectModel? get selectedProject => _selectedProject;
  List<VoterModel> get voters => List.unmodifiable(_voters);
  String? get detailErrorMessage => _detailErrorMessage;
  bool get isLoadingDetail => _detailStatus == ProjectDetailStatus.loading;

  // Getters pour la priorisation
  PrioritizationStatus get prioritizationStatus => _prioritizationStatus;
  String? get prioritizationErrorMessage => _prioritizationErrorMessage;
  bool get isPrioritizing => _prioritizationStatus == PrioritizationStatus.loading;

  // Getters pour la synchronisation
  SyncStatus get syncStatus => _syncStatus;
  String? get syncErrorMessage => _syncErrorMessage;
  String? get syncMessage => _syncMessage;
  bool get isSyncing => _syncStatus == SyncStatus.syncing;
  
  // Getters pour les notifications
  SyncNotificationType get notificationType => _notificationType;
  String? get notificationMessage => _notificationMessage;

  Future<void> pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur lors de la sélection des images: $e');
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        _selectedImages.add(File(image.path));
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur lors de la prise de photo: $e');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  void clearImages() {
    _selectedImages.clear();
    notifyListeners();
  }

  Future<bool> createProject({
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
  }) async {
    _setStatus(ProjectSubmissionStatus.loading);
    _clearError();

    try {
      // Vérifier la connectivité
      if (_connectivityService.isConnected) {
        // Connexion disponible - tenter l'envoi direct
        final response = await _projectDataSource.createProject(
          title: title,
          briefDescription: briefDescription,
          detailedDescription: detailedDescription,
          estimatedBudget: estimatedBudget,
          startDate: startDate,
          estimatedCompletionDate: estimatedCompletionDate,
          dateLapses: dateLapses,
          withCallForTenders: withCallForTenders,
          withServiceProvider: withServiceProvider,
          images: _selectedImages,
        );
        
        if (response.success) {
          _setStatus(ProjectSubmissionStatus.success);
          _selectedImages.clear();
          
          // ✅ SYNCHRONISER les données après création pour maintenir la cohérence
          try {
            await syncProjects(showNotifications: false);
            debugPrint('✅ [PROJECT] Synchronisation post-création réussie');
          } catch (e) {
            debugPrint('⚠️ [PROJECT] Erreur sync post-création: $e');
            // Ne pas faire échouer la création pour autant
          }
          
          return true;
        } else {
          _setError(response.message);
          _setStatus(ProjectSubmissionStatus.error);
          return false;
        }
      } else {
        // Pas de connexion - sauvegarder en local
        debugPrint('📵 [PROJECT] Pas de connexion - sauvegarde en local');
        
        // Copier les images dans un dossier temporaire pour les garder
        final imagePaths = <String>[];
        for (final image in _selectedImages) {
          imagePaths.add(image.path);
        }
        
        // Sauvegarder le projet en attente
        final pendingProjectId = await _unifiedSyncService.addPendingProject(
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
          providerName: providerName,
          providerAmount: providerAmount,
        );
        
        debugPrint('💾 [PROJECT] Projet "$title" sauvegardé en local avec ID: $pendingProjectId');
        
        // Note: Pas de sync ici car c'est un mode hors ligne
        // La sync se fera automatiquement quand la connexion reviendra
        
        _setStatus(ProjectSubmissionStatus.success);
        _selectedImages.clear();
        return true;
      }
    } catch (e) {
      debugPrint('❌ [PROJECT] Erreur lors de la création: $e');
      _setError(e.toString());
      _setStatus(ProjectSubmissionStatus.error);
      return false;
    }
  }

  void _setStatus(ProjectSubmissionStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  void resetStatus() {
    _status = ProjectSubmissionStatus.initial;
    _clearError();
    notifyListeners();
  }

  // Méthodes pour récupérer les projets - VERSION AVEC SYNCHRONISATION INTELLIGENTE

  // Liste des projets avec votes oui/oui sous réserve
  List<ProjectModel> _userProjectsVotedYes = [];
  List<ProjectModel> get userProjectsVotedYes => List.unmodifiable(_userProjectsVotedYes);

  // Méthodes pour les votes
  Future<Map<String, dynamic>?> voteOnProject(String projectId, VoteChoice choice, {String? justification}) async {
    _setVoteStatus(VoteStatus.loading);
    _clearVoteError();

    try {
      Map<String, dynamic>? response;
      
      switch (choice) {
        case VoteChoice.yes:
          response = await _projectDataSource.voteYes(projectId);
          break;
        case VoteChoice.no:
          await _projectDataSource.voteNo(projectId);
          break;
        case VoteChoice.blank:
          await _projectDataSource.voteNeutral(projectId);
          break;
        case VoteChoice.yesWithReserve:
          response = await _projectDataSource.voteYesWithReserve(projectId, justification ?? '');
          break;
      }

      _setVoteStatus(VoteStatus.success);
      
      // Mettre à jour le projet dans la liste locale immédiatement pour une UX fluide
      _updateProjectAfterVote(projectId, choice, justification);
      
      // Mettre à jour la liste des projets avec votes oui/oui sous réserve
      if (response != null && response['data'] != null) {
        _updateUserProjectsVotedYes(response['data']);
      }
      
      // ✅ SYNCHRONISATION INTELLIGENTE : Sync rapide au lieu de fetchProjects complet
      try {
        await syncProjects(showNotifications: false);
        debugPrint('✅ [VOTE] Synchronisation post-vote réussie');
      } catch (e) {
        debugPrint('⚠️ [VOTE] Erreur sync post-vote: $e');
        // Fallback : rechargement classique
        fetchProjects();
      }
      
      return response;
    } catch (e) {
      _setVoteError(e.toString());
      _setVoteStatus(VoteStatus.error);
      return null;
    }
  }

  Future<Map<String, dynamic>?> modifyVote(String projectId, VoteChoice choice, {String? justification}) async {
    _setVoteStatus(VoteStatus.loading);
    _clearVoteError();

    try {
      String voteType;
      switch (choice) {
        case VoteChoice.yes:
          voteType = 'yes';
          break;
        case VoteChoice.no:
          voteType = 'no';
          break;
        case VoteChoice.blank:
          voteType = 'neutral';
          break;
        case VoteChoice.yesWithReserve:
          voteType = 'yes_to_subject';
          break;
      }

      final response = await _projectDataSource.modifyVote(projectId, voteType, conditions: justification);

      _setVoteStatus(VoteStatus.success);
      
      // Mettre à jour le projet dans la liste locale immédiatement pour une UX fluide
      _updateProjectAfterVote(projectId, choice, justification);
      
      // Mettre à jour la liste des projets avec votes oui/oui sous réserve
      if (response['data'] != null) {
        _updateUserProjectsVotedYes(response['data']);
      }
      
      // ✅ SYNCHRONISATION INTELLIGENTE : Sync rapide au lieu de fetchProjects complet
      try {
        await syncProjects(showNotifications: false);
        debugPrint('✅ [MODIFY-VOTE] Synchronisation post-modification réussie');
      } catch (e) {
        debugPrint('⚠️ [MODIFY-VOTE] Erreur sync post-modification: $e');
        // Fallback : rechargement classique
        fetchProjects();
      }
      
      return response;
    } catch (e) {
      _setVoteError(e.toString());
      _setVoteStatus(VoteStatus.error);
      return null;
    }
  }

  void _updateProjectAfterVote(String projectId, VoteChoice choice, String? justification) {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex != -1) {
      final project = _projects[projectIndex];
      final updatedProject = project.copyWith(
        userVote: choice,
        userVoteJustification: justification,
      );
      _projects[projectIndex] = updatedProject;
      notifyListeners();
    }
  }

  // Méthodes utilitaires pour le chargement des projets
  void _setLoadingStatus(ProjectLoadingStatus status) {
    _loadingStatus = status;
    notifyListeners();
  }

  void _setLoadingError(String error) {
    _loadingErrorMessage = error;
    notifyListeners();
  }

  void _clearLoadingError() {
    _loadingErrorMessage = null;
    notifyListeners();
  }

  // Méthodes utilitaires pour les votes
  void _setVoteStatus(VoteStatus status) {
    _voteStatus = status;
    notifyListeners();
  }

  void _setVoteError(String error) {
    _voteErrorMessage = error;
    notifyListeners();
  }

  void _clearVoteError() {
    _voteErrorMessage = null;
    notifyListeners();
  }

  void clearVoteError() {
    _clearVoteError();
  }

  void resetVoteStatus() {
    _voteStatus = VoteStatus.initial;
    _clearVoteError();
    notifyListeners();
  }

  // Méthode pour filtrer les projets localement
  List<ProjectModel> getFilteredProjects({
    String? searchQuery,
    ProjectStatus? statusFilter,
  }) {
    var filteredProjects = _projects;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredProjects = filteredProjects.where((project) {
        return project.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
               project.shortDescription.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (statusFilter != null) {
      filteredProjects = filteredProjects.where((project) => project.status == statusFilter).toList();
    }

    return filteredProjects;
  }

  // Méthode pour rafraîchir les projets
  Future<void> refreshProjects() async {
    await fetchProjects();
  }

  // Méthodes pour récupérer les détails du projet
  Future<void> fetchProjectDetails(String projectId) async {
    _setDetailStatus(ProjectDetailStatus.loading);
    _clearDetailError();

    try {
      // 1. D'abord vérifier le cache local
      final cachedDetails = await LocalStorageService.getProjectDetails(projectId);
      
      // 2. Si connecté → Essayer de récupérer depuis l'API et mettre à jour le cache
      if (_connectivityService.isConnected) {
        try {
          debugPrint('🌐 [DETAILS] Récupération des détails depuis l\'API pour projet $projectId');
          final response = await _projectDataSource.getProjectDetails(projectId);
          
          if (response['success'] == true) {
            final projectData = response['data'] as Map<String, dynamic>;
            
            // Créer le projet avec les données détaillées
            _selectedProject = ProjectModel.fromJson(projectData);
            
            // Extraire les voteurs
            final votersData = projectData['voters'] as List<dynamic>? ?? [];
            _voters = votersData.map((voterJson) => VoterModel.fromJson(voterJson as Map<String, dynamic>)).toList();
            
            // Sauvegarder en cache pour utilisation future
            await LocalStorageService.saveProjectDetails(projectId, _selectedProject!, _voters);
            
            _setDetailStatus(ProjectDetailStatus.success);
            debugPrint('✅ [DETAILS] Détails récupérés depuis l\'API et sauvegardés (${_voters.length} votants)');
            return;
          }
        } catch (e) {
          debugPrint('⚠️ [DETAILS] Erreur API pour projet $projectId: $e');
          // Continuer vers le fallback cache
        }
      } else {
        debugPrint('📱 [DETAILS] Mode hors ligne - utilisation du cache');
      }
      
      // 3. Fallback → Utiliser le cache s'il existe
      if (cachedDetails != null) {
        _selectedProject = cachedDetails.project;
        _voters = cachedDetails.voters;
        _setDetailStatus(ProjectDetailStatus.success);
        debugPrint('📂 [DETAILS] Détails récupérés depuis le cache (${cachedDetails.voters.length} votants)');
        return;
      }
      
      // 4. Dernier fallback → Projet de base de la liste sans votants
      ProjectModel? projectFromList;
      try {
        projectFromList = _allProjects.firstWhere((p) => p.id == projectId);
      } catch (e) {
        try {
          projectFromList = _projects.firstWhere((p) => p.id == projectId);
        } catch (e) {
          projectFromList = null;
        }
      }
      
      if (projectFromList != null) {
        _selectedProject = projectFromList;
        _voters = [];
        _setDetailStatus(ProjectDetailStatus.success);
        debugPrint('📋 [DETAILS] Projet trouvé dans la liste sans détails votants');
        return;
      }
      
      // Aucune donnée disponible
      _setDetailError('Aucune donnée disponible pour ce projet.');
      _setDetailStatus(ProjectDetailStatus.error);
      
    } catch (e) {
      _setDetailError('Erreur lors de la récupération des détails: $e');
      _setDetailStatus(ProjectDetailStatus.error);
    }
  }

  // Méthodes utilitaires pour les détails du projet
  void _setDetailStatus(ProjectDetailStatus status) {
    _detailStatus = status;
    notifyListeners();
  }

  void _setDetailError(String error) {
    _detailErrorMessage = error;
    notifyListeners();
  }

  void _clearDetailError() {
    _detailErrorMessage = null;
    notifyListeners();
  }

  void clearDetailError() {
    _clearDetailError();
  }

  void resetDetailStatus() {
    _detailStatus = ProjectDetailStatus.initial;
    _selectedProject = null;
    _voters = [];
    _clearDetailError();
    notifyListeners();
  }

  // Méthodes pour la priorisation
  Future<bool> prioritizeProjects(List<int> projectIds) async {
    _setPrioritizationStatus(PrioritizationStatus.loading);
    _clearPrioritizationError();

    try {
      final response = await _projectDataSource.prioritizeProjects(projectIds);
      
      if (response.success) {
        _setPrioritizationStatus(PrioritizationStatus.success);
        // Rafraîchir la liste des projets après priorisation
        await fetchProjects();
        return true;
      } else {
        _setPrioritizationError(response.message);
        _setPrioritizationStatus(PrioritizationStatus.error);
        return false;
      }
    } catch (e) {
      _setPrioritizationError(e.toString());
      _setPrioritizationStatus(PrioritizationStatus.error);
      return false;
    }
  }

  // Méthodes utilitaires pour la priorisation
  void _setPrioritizationStatus(PrioritizationStatus status) {
    _prioritizationStatus = status;
    notifyListeners();
  }

  void _setPrioritizationError(String error) {
    _prioritizationErrorMessage = error;
    notifyListeners();
  }

  void _clearPrioritizationError() {
    _prioritizationErrorMessage = null;
    notifyListeners();
  }

  void clearPrioritizationError() {
    _clearPrioritizationError();
  }

  void resetPrioritizationStatus() {
    _prioritizationStatus = PrioritizationStatus.initial;
    _clearPrioritizationError();
    notifyListeners();
  }

  // Méthode pour mettre à jour les projets avec votes oui/oui sous réserve
  void _updateUserProjectsVotedYes(Map<String, dynamic> responseData) {
    if (responseData['user_projects_voted_yes'] != null) {
      final projectsData = responseData['user_projects_voted_yes'] as List<dynamic>;
      _userProjectsVotedYes = projectsData
          .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  // Méthode pour gérer la priorisation automatique
  Future<PrioritizationAction> handlePrioritizationAfterVote() async {
    final projectCount = _userProjectsVotedYes.length;
    
    if (projectCount == 0) {
      return PrioritizationAction.none;
    } else if (projectCount == 1) {
      // Priorisation automatique pour un seul projet
      final success = await prioritizeProjects([int.parse(_userProjectsVotedYes.first.id)]);
      return success ? PrioritizationAction.autoCompleted : PrioritizationAction.error;
    } else {
      // Afficher le modal pour prioriser plusieurs projets
      return PrioritizationAction.showModal;
    }
  }

  // ============ MÉTHODES DE NOTIFICATION ============
  
  /// Met à jour le type de notification
  void _setNotificationType(SyncNotificationType type, [String? message]) {
    _notificationType = type;
    _notificationMessage = message;
    notifyListeners();
  }
  
  /// Efface la notification
  void clearNotification() {
    _setNotificationType(SyncNotificationType.none);
  }
  
  /// Affiche la notification de données hors ligne
  void showOfflineNotification() {
    _setNotificationType(SyncNotificationType.offline);
  }
  
  /// Affiche la notification de synchronisation en cours
  void showSyncingNotification([String? message]) {
    _setNotificationType(SyncNotificationType.syncing, message);
  }
  
  /// Affiche la notification de synchronisation terminée
  void showSyncCompleteNotification([String? message]) {
    _setNotificationType(
      SyncNotificationType.syncComplete, 
      message ?? 'Données synchronisées avec succès'
    );
  }
  
  /// Affiche la notification de données déjà à jour
  void showUpToDateNotification([String? message]) {
    _setNotificationType(
      SyncNotificationType.upToDate, 
      message ?? 'Données à jour • Aucune synchronisation nécessaire'
    );
  }

  // ============ MÉTHODES DE FILTRAGE LOCAL (WhatsApp Style) ============
  
  /// Applique un filtre de statut localement (SANS API)
  void applyStatusFilter(ProjectStatus? status) {
    _currentFilter = status;
    _applyLocalFilters();
  }
  
  /// Applique une recherche localement (SANS API)
  void applySearchFilter(String? search) {
    _currentSearch = search;
    _applyLocalFilters();
  }
  
  /// Efface tous les filtres et affiche tous les projets du cache
  void clearAllFilters() {
    _currentFilter = null;
    _currentSearch = null;
    _applyLocalFilters();
  }
  
  /// Méthode publique pour rafraîchir les filtres
  void refreshFilters() {
    _applyLocalFilters();
  }

  // ============ MÉTHODES DE SYNCHRONISATION ============

  /// Synchronise les projets avec le serveur
  Future<void> syncProjects({
    SyncFilters? filters,
    bool forceFullSync = false,
    bool showNotifications = true, // Nouveau paramètre
  }) async {
    _setSyncStatus(SyncStatus.syncing);
    _clearSyncMessages();
    
    // Afficher notification de synchronisation si demandé
    if (showNotifications) {
      showSyncingNotification();
    }

    try {
      // 1. Déterminer le type de synchronisation
      final operation = await SyncService.determineSyncOperation(
        filters: filters,
        forceFullSync: forceFullSync,
      );
      print('📋 [SYNC] Type d\'opération: ${operation.name}');

      // 2. Préparer la requête
      final request = await SyncService.prepareSyncRequest(
        operation: operation,
        filters: filters,
      );
      print('📤 [SYNC] Requête préparée: ${request.toJson()}');

      // 3. Appeler l'API
      final response = await _projectDataSource.syncProjects(request);
      print('📥 [SYNC] Réponse reçue: ${response.syncType}');

      // 4. Traiter la réponse
      final result = await SyncService.processSyncResponse(response, _projects);
      print('🔄 [SYNC] Résultat traité: ${result.projects.length} projets, hasChanges: ${result.hasChanges}');

      // 5. Mettre à jour les données locales dans le cache complet
      if (result.hasChanges) {
        // ✅ FUSION INTELLIGENTE : Maintenir les données existantes
        if (result.operation == SyncOperation.fullSync) {
          // Full sync : remplacement complet
          _allProjects = result.projects;
        } else {
          // Sync différentielle : fusion intelligente
          _mergeProjectsIntelligently(result.projects, result.changes);
        }
        _applyLocalFilters(); // Filtrage local
        _pagination = null; // Reset pagination après sync
      }

      _setSyncMessage(result.message);
      _setSyncStatus(SyncStatus.success);
      
      // Afficher notification appropriée selon le résultat
      if (showNotifications) {
        if (result.hasChanges) {
          showSyncCompleteNotification(result.message);
        } else {
          // Données déjà à jour - pas de sync nécessaire
          showUpToDateNotification();
        }
      }
      
    } catch (e) {
      _setSyncError(e.toString());
      _setSyncStatus(SyncStatus.error);
      
      // En cas d'erreur, effacer la notification de syncing
      if (showNotifications) {
        clearNotification();
      }
    }
  }

  /// Synchronise avec des filtres spécifiques
  Future<void> syncWithFilters(SyncFilters filters) async {
    await syncProjects(filters: filters);
  }

  /// Force une synchronisation complète
  Future<void> forceFullSync() async {
    await syncProjects(forceFullSync: true);
  }

  /// Synchronise de manière intelligente (détection automatique)
  Future<void> smartSync() async {
    await syncProjects();
  }

  /// Vérifie et synchronise si nécessaire
  Future<bool> checkAndSync({SyncFilters? filters}) async {
    try {
      await syncProjects(filters: filters);
      return _syncStatus == SyncStatus.success;
    } catch (e) {
      return false;
    }
  }

  /// Méthode principale pour récupérer les projets avec synchronisation intelligente
  Future<void> fetchProjects({
    String? status,
    bool? alreadyVoted,
    String? search,
    String? createdBy,
    int perPage = 10,
    int page = 1,
    bool append = false,
    bool useSync = true, // Nouveau paramètre pour activer/désactiver la sync
    bool showNotifications = false, // Afficher les notifications durant la sync
    bool forceFreshData = false, // Forcer un full sync pour migration
  }) async {
    print('📲 [FETCH] fetchProjects appelée - useSync: $useSync, status: $status, search: $search');
    
    if (useSync) {
      // 1. Charger d'abord les données du cache si disponibles (sauf si forceFreshData)
      if (!forceFreshData) {
        await _loadFromCacheIfNeeded();
      }
      
      // 2. Utiliser la synchronisation intelligente
      print('🔄 [FETCH] Utilisation de la synchronisation intelligente');
      final filters = SyncFilters(
        status: status,
        search: search,
        createdBy: createdBy,
      );
      print('📋 [FETCH] Filtres: ${filters.toJson()}');
      
      try {
        await syncProjects(
          filters: filters.isEmpty ? null : filters,
          showNotifications: showNotifications,
          forceFullSync: forceFreshData, // Force full sync si migration
        );
      } catch (e) {
        // En cas d'erreur réseau, on garde les données du cache
        _setLoadingStatus(ProjectLoadingStatus.success);
      }
    } else {
      // Utiliser l'ancienne méthode (fallback)
      print('🔙 [FETCH] Utilisation de la méthode legacy');
      await _fetchProjectsLegacy(
        status: status,
        alreadyVoted: alreadyVoted,
        search: search,
        createdBy: createdBy,
        perPage: perPage,
        page: page,
        append: append,
      );
    }
    print('📱 [FETCH] fetchProjects terminée - ${_projects.length} projets en mémoire');
  }

  /// Charge les projets depuis le cache si nécessaire (architecture WhatsApp)
  Future<void> _loadFromCacheIfNeeded() async {
    // Charger dans _allProjects (cache complet)
    if (_allProjects.isEmpty) {
      final cachedProjects = await LocalStorageService.getCachedProjects();
      if (cachedProjects.isNotEmpty) {
        _allProjects = cachedProjects;
        _applyLocalFilters(); // Appliquer les filtres localement
        _setLoadingStatus(ProjectLoadingStatus.success);
        // Afficher notification si hors ligne
        // (sera géré dans la page selon la connectivité)
      }
    }
  }
  
  /// Fusionne intelligemment les projets avec les changements
  void _mergeProjectsIntelligently(List<ProjectModel> syncedProjects, SyncChanges? changes) {
    if (changes == null) {
      // Pas de changements spécifiques, utiliser la liste syncée
      _allProjects = syncedProjects;
      return;
    }
    
    // Fusionner intelligemment selon les types de changements
    final updatedProjects = List<ProjectModel>.from(_allProjects);
    
    // Traiter les suppressions
    for (final deletedId in changes.deleted) {
      updatedProjects.removeWhere((project) => project.id == deletedId);
    }
    
    // Traiter les ajouts et mises à jour
    for (final newProject in syncedProjects) {
      final existingIndex = updatedProjects.indexWhere((p) => p.id == newProject.id);
      if (existingIndex != -1) {
        // Mettre à jour le projet existant
        updatedProjects[existingIndex] = newProject;
      } else {
        // Ajouter le nouveau projet
        updatedProjects.add(newProject);
      }
    }
    
    _allProjects = updatedProjects;
  }
  
  /// Applique les filtres localement comme WhatsApp (SANS API)
  void _applyLocalFilters() {
    var filteredProjects = List<ProjectModel>.from(_allProjects);
    
    // Filtrer par statut
    if (_currentFilter != null) {
      filteredProjects = filteredProjects.where((project) {
        return project.status == _currentFilter;
      }).toList();
    }
    
    // Filtrer par recherche
    if (_currentSearch != null && _currentSearch!.length >= 2) {
      final searchLower = _currentSearch!.toLowerCase();
      filteredProjects = filteredProjects.where((project) {
        return project.title.toLowerCase().contains(searchLower) ||
               project.shortDescription.toLowerCase().contains(searchLower) ||
               project.longDescription.toLowerCase().contains(searchLower);
      }).toList();
    }
    
    _projects = filteredProjects;
    notifyListeners();
  }

  /// Ancienne méthode fetchProjects (fallback)
  Future<void> _fetchProjectsLegacy({
    String? status,
    bool? alreadyVoted,
    String? search,
    String? createdBy,
    int perPage = 10,
    int page = 1,
    bool append = false,
  }) async {
    if (!append) {
      _setLoadingStatus(ProjectLoadingStatus.loading);
      _clearLoadingError();
    }

    try {
      final response = await _projectDataSource.getProjects(
        status: status,
        alreadyVoted: alreadyVoted,
        search: search,
        createdBy: createdBy,
        perPage: perPage,
        page: page,
      );

      if (response['success'] == true) {
        final projectsData = response['data'] as List<dynamic>;
        final newProjects = projectsData.map((json) => ProjectModel.fromJson(json as Map<String, dynamic>)).toList();
        
        if (append) {
          _allProjects.addAll(newProjects);
        } else {
          _allProjects = newProjects;
        }
        
        // Appliquer les filtres après mise à jour du cache
        _applyLocalFilters();
        
        _pagination = response['pagination'] as Map<String, dynamic>?;
        _setLoadingStatus(ProjectLoadingStatus.success);
      } else {
        _setLoadingError(response['message'] ?? 'Erreur lors de la récupération des projets');
        _setLoadingStatus(ProjectLoadingStatus.error);
      }
    } catch (e) {
      _setLoadingError(e.toString());
      _setLoadingStatus(ProjectLoadingStatus.error);
    }
  }

  /// Obtient les statistiques de synchronisation
  Future<Map<String, dynamic>> getSyncStats() async {
    return await SyncService.getSyncStats();
  }

  /// Valide la cohérence des données locales
  Future<SyncValidation> validateLocalData() async {
    return await SyncService.validateLocalData(_projects);
  }

  /// Nettoie les données de synchronisation
  Future<void> clearSyncData() async {
    await SyncService.clearLocalData();
    await LocalStorageService.clearCachedProjects(); // Vider aussi les projets en cache
    _setSyncMessage('Données de synchronisation effacées');
  }

  // Méthodes utilitaires pour la synchronisation
  void _setSyncStatus(SyncStatus status) {
    print('🔄 [SYNC] Changement de statut: ${_syncStatus.name} → ${status.name}');
    _syncStatus = status;
    notifyListeners();
  }

  void _setSyncError(String error) {
    print('❌ [SYNC] Erreur: $error');
    _syncErrorMessage = error;
    notifyListeners();
  }

  void _setSyncMessage(String message) {
    print('💬 [SYNC] Message: $message');
    _syncMessage = message;
    notifyListeners();
  }

  void _clearSyncMessages() {
    _syncErrorMessage = null;
    _syncMessage = null;
    notifyListeners();
  }

  void clearSyncError() {
    _syncErrorMessage = null;
    notifyListeners();
  }

  void resetSyncStatus() {
    _syncStatus = SyncStatus.idle;
    _clearSyncMessages();
    notifyListeners();
  }
  
  /// Méthode de validation pour déboguer les problèmes de synchronisation
  Future<Map<String, dynamic>> debugSyncState() async {
    final cacheCount = await LocalStorageService.getCachedProjectsCount();
    final checksumCount = await LocalStorageService.getChecksumsCount();
    final storageStats = await LocalStorageService.getStorageStats();
    
    return {
      'memory_projects': _allProjects.length,
      'displayed_projects': _projects.length,
      'cache_count': cacheCount,
      'checksum_count': checksumCount,
      'storage_stats': storageStats,
      'current_filter': _currentFilter?.toString(),
      'current_search': _currentSearch,
      'sync_status': _syncStatus.toString(),
      'has_cache': await LocalStorageService.hasCachedProjects(),
    };
  }
  
  /// Force une synchronisation complète pour corriger les incohérences
  Future<void> forceSyncRepair() async {
    debugPrint('🔄 [REPAIR] Début de la réparation de synchronisation');
    
    try {
      // 1. Nettoyer les données incohérentes
      await LocalStorageService.clearCachedProjects();
      await LocalStorageService.clearAllChecksums();
      
      // 2. Forcer une synchronisation complète
      await syncProjects(forceFullSync: true, showNotifications: true);
      
      debugPrint('✅ [REPAIR] Réparation de synchronisation terminée');
    } catch (e) {
      debugPrint('❌ [REPAIR] Erreur lors de la réparation: $e');
      rethrow;
    }
  }
}

// Enum pour les actions de priorisation
enum PrioritizationAction {
  none,           // Pas de priorisation nécessaire
  autoCompleted,  // Priorisation automatique effectuée
  showModal,      // Afficher le modal de priorisation
  error,          // Erreur lors de la priorisation automatique
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data_sources/project_data_source.dart';
import '../models/project_model.dart';
import '../models/voter_model.dart';
import '../models/sync_models.dart';
import '../services/sync_service.dart';

enum ProjectSubmissionStatus { initial, loading, success, error }
enum ProjectLoadingStatus { initial, loading, success, error }
enum VoteStatus { initial, loading, success, error }
enum ProjectDetailStatus { initial, loading, success, error }
enum PrioritizationStatus { initial, loading, success, error }

class ProjectController extends ChangeNotifier {
  final ProjectDataSource _projectDataSource = ProjectDataSource();
  final ImagePicker _imagePicker = ImagePicker();
  
  ProjectSubmissionStatus _status = ProjectSubmissionStatus.initial;
  String? _errorMessage;
  List<File> _selectedImages = [];

  // Pour la récupération des projets
  ProjectLoadingStatus _loadingStatus = ProjectLoadingStatus.initial;
  List<ProjectModel> _projects = [];
  Map<String, dynamic>? _pagination;
  String? _loadingErrorMessage;

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

  // Getters pour la soumission de projet
  ProjectSubmissionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<File> get selectedImages => List.unmodifiable(_selectedImages);
  bool get isLoading => _status == ProjectSubmissionStatus.loading;
  bool get hasImages => _selectedImages.isNotEmpty;

  // Getters pour la récupération des projets
  ProjectLoadingStatus get loadingStatus => _loadingStatus;
  List<ProjectModel> get projects => List.unmodifiable(_projects);
  Map<String, dynamic>? get pagination => _pagination;
  String? get loadingErrorMessage => _loadingErrorMessage;
  bool get isLoadingProjects => _loadingStatus == ProjectLoadingStatus.loading;

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
  }) async {
    _setStatus(ProjectSubmissionStatus.loading);
    _clearError();

    try {
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
        return true;
      } else {
        _setError(response.message);
        _setStatus(ProjectSubmissionStatus.error);
        return false;
      }
    } catch (e) {
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
      
      // Recharger les projets depuis l'API pour avoir l'état exact (en arrière-plan)
      fetchProjects();
      
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
      
      // Recharger les projets depuis l'API pour avoir l'état exact (en arrière-plan)
      fetchProjects();
      
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
      final response = await _projectDataSource.getProjectDetails(projectId);

      if (response['success'] == true) {
        final projectData = response['data'] as Map<String, dynamic>;
        
        // Créer le projet avec les données détaillées
        _selectedProject = ProjectModel.fromJson(projectData);
        
        // Extraire les voteurs
        final votersData = projectData['voters'] as List<dynamic>? ?? [];
        _voters = votersData.map((voterJson) => VoterModel.fromJson(voterJson as Map<String, dynamic>)).toList();
        
        _setDetailStatus(ProjectDetailStatus.success);
      } else {
        _setDetailError(response['message'] ?? 'Erreur lors de la récupération des détails du projet');
        _setDetailStatus(ProjectDetailStatus.error);
      }
    } catch (e) {
      _setDetailError(e.toString());
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

  // ============ MÉTHODES DE SYNCHRONISATION ============

  /// Synchronise les projets avec le serveur
  Future<void> syncProjects({
    SyncFilters? filters,
    bool forceFullSync = false,
  }) async {
    _setSyncStatus(SyncStatus.syncing);
    _clearSyncMessages();

    try {
      // 1. Déterminer le type de synchronisation
      final operation = await SyncService.determineSyncOperation(
        filters: filters,
        forceFullSync: forceFullSync,
      );

      // 2. Préparer la requête
      final request = await SyncService.prepareSyncRequest(
        operation: operation,
        filters: filters,
      );

      // 3. Appeler l'API
      final response = await _projectDataSource.syncProjects(request);

      // 4. Traiter la réponse
      final result = await SyncService.processSyncResponse(response, _projects);

      // 5. Mettre à jour les données locales
      if (result.hasChanges) {
        _projects = result.projects;
        _pagination = null; // Reset pagination après sync
      }

      _setSyncMessage(result.message);
      _setSyncStatus(SyncStatus.success);
      
    } catch (e) {
      _setSyncError(e.toString());
      _setSyncStatus(SyncStatus.error);
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
  }) async {
    if (useSync) {
      // Utiliser la synchronisation intelligente
      final filters = SyncFilters(
        status: status,
        search: search,
        createdBy: createdBy,
      );
      await syncProjects(filters: filters.isEmpty ? null : filters);
    } else {
      // Utiliser l'ancienne méthode (fallback)
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
          _projects.addAll(newProjects);
        } else {
          _projects = newProjects;
        }
        
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
    _setSyncMessage('Données de synchronisation effacées');
  }

  // Méthodes utilitaires pour la synchronisation
  void _setSyncStatus(SyncStatus status) {
    _syncStatus = status;
    notifyListeners();
  }

  void _setSyncError(String error) {
    _syncErrorMessage = error;
    notifyListeners();
  }

  void _setSyncMessage(String message) {
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
}

// Enum pour les actions de priorisation
enum PrioritizationAction {
  none,           // Pas de priorisation nécessaire
  autoCompleted,  // Priorisation automatique effectuée
  showModal,      // Afficher le modal de priorisation
  error,          // Erreur lors de la priorisation automatique
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data_sources/project_data_source.dart';
import '../models/project_model.dart';

enum ProjectSubmissionStatus { initial, loading, success, error }
enum ProjectLoadingStatus { initial, loading, success, error }
enum VoteStatus { initial, loading, success, error }

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

  // Méthodes pour récupérer les projets
  Future<void> fetchProjects({
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

  // Méthodes pour les votes
  Future<bool> voteOnProject(String projectId, VoteChoice choice, {String? justification}) async {
    _setVoteStatus(VoteStatus.loading);
    _clearVoteError();

    try {
      switch (choice) {
        case VoteChoice.yes:
          await _projectDataSource.voteYes(projectId);
          break;
        case VoteChoice.no:
          await _projectDataSource.voteNo(projectId);
          break;
        case VoteChoice.blank:
          await _projectDataSource.voteNeutral(projectId);
          break;
        case VoteChoice.yesWithReserve:
          await _projectDataSource.voteYesWithReserve(projectId, justification ?? '');
          break;
      }

      _setVoteStatus(VoteStatus.success);
      
      // Mettre à jour le projet dans la liste locale immédiatement pour une UX fluide
      _updateProjectAfterVote(projectId, choice, justification);
      
      // Recharger les projets depuis l'API pour avoir l'état exact (en arrière-plan)
      fetchProjects();
      
      return true;
    } catch (e) {
      _setVoteError(e.toString());
      _setVoteStatus(VoteStatus.error);
      return false;
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
}
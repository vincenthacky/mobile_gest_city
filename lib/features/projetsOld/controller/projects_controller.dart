import 'package:flutter/material.dart';
import '../data_source/project_data_source.dart';
import '../models/project_model.dart';
import '../../../core/models/contribution_response.dart';

enum ProjectsStatus { initial, loading, loaded, error, loadingMore }

class ProjectsController extends ChangeNotifier {
  final ProjectDataSource _projectDataSource = ProjectDataSource();
  
  ProjectsStatus _status = ProjectsStatus.initial;
  List<ProjectModel> _projects = [];
  PaginationModel? _pagination;
  String? _errorMessage;

  // Filtres
  String? _selectedStatus;
  bool? _alreadyVoted;
  String? _searchQuery;
  int _perPage = 10;

  // Getters
  ProjectsStatus get status => _status;
  List<ProjectModel> get projects => _projects;
  PaginationModel? get pagination => _pagination;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProjectsStatus.loading;
  bool get isLoadingMore => _status == ProjectsStatus.loadingMore;
  bool get hasError => _status == ProjectsStatus.error;
  bool get isLoaded => _status == ProjectsStatus.loaded;
  bool get hasMorePages => _pagination != null && _pagination!.currentPage < _pagination!.lastPage;

  String? get selectedStatus => _selectedStatus;
  bool? get alreadyVoted => _alreadyVoted;
  String? get searchQuery => _searchQuery;

  /// Charge la première page des projets avec les filtres actuels
  Future<void> loadProjects() async {
    _setStatus(ProjectsStatus.loading);
    _clearError();

    try {
      final response = await _projectDataSource.getProjects(
        status: _selectedStatus,
        alreadyVoted: _alreadyVoted,
        search: _searchQuery,
        perPage: _perPage,
        page: 1,
      );

      _projects = response.data;
      _pagination = response.pagination;
      
      _setStatus(ProjectsStatus.loaded);
    } catch (e) {
      _setError(e.toString());
      _setStatus(ProjectsStatus.error);
    }
  }

  /// Charge la page suivante des projets (pagination)
  Future<void> loadMoreProjects() async {
    if (!hasMorePages || isLoadingMore) return;

    _setStatus(ProjectsStatus.loadingMore);

    try {
      final nextPage = (_pagination?.currentPage ?? 0) + 1;
      
      final response = await _projectDataSource.getProjects(
        status: _selectedStatus,
        alreadyVoted: _alreadyVoted,
        search: _searchQuery,
        perPage: _perPage,
        page: nextPage,
      );

      _projects.addAll(response.data);
      _pagination = response.pagination;
      
      _setStatus(ProjectsStatus.loaded);
    } catch (e) {
      _setError(e.toString());
      _setStatus(ProjectsStatus.error);
    }
  }

  /// Actualise la liste complète
  Future<void> refreshProjects() async {
    await loadProjects();
  }

  /// Applique un filtre de statut
  void setStatusFilter(String? status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      loadProjects(); // Recharge avec le nouveau filtre
    }
  }

  /// Applique un filtre de vote
  void setVotedFilter(bool? voted) {
    if (_alreadyVoted != voted) {
      _alreadyVoted = voted;
      loadProjects(); // Recharge avec le nouveau filtre
    }
  }

  /// Applique une recherche
  void setSearch(String? search) {
    if (_searchQuery != search) {
      _searchQuery = search;
      loadProjects(); // Recharge avec la nouvelle recherche
    }
  }

  /// Réinitialise tous les filtres
  void clearAllFilters() {
    bool shouldReload = false;
    
    if (_selectedStatus != null) {
      _selectedStatus = null;
      shouldReload = true;
    }
    
    if (_alreadyVoted != null) {
      _alreadyVoted = null;
      shouldReload = true;
    }
    
    if (_searchQuery != null) {
      _searchQuery = null;
      shouldReload = true;
    }

    if (shouldReload) {
      loadProjects();
    }
  }

  /// Vote sur un projet
  Future<void> voteOnProject(int projectId, bool vote) async {
    try {
      await _projectDataSource.voteOnProject(projectId, vote);
      
      // Mettre à jour le projet localement
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final updatedProject = ProjectModel(
          id: _projects[projectIndex].id,
          title: _projects[projectIndex].title,
          description: _projects[projectIndex].description,
          voteStartDate: _projects[projectIndex].voteStartDate,
          voteEndDate: _projects[projectIndex].voteEndDate,
          budget: _projects[projectIndex].budget,
          icon: _projects[projectIndex].icon,
          color: _projects[projectIndex].color,
          userVoteStatus: vote ? 'voted_yes' : 'voted_no',
          votesYes: _projects[projectIndex].votesYes + (vote ? 1 : 0),
          votesNo: _projects[projectIndex].votesNo + (vote ? 0 : 1),
          isActive: _projects[projectIndex].isActive,
          createdAt: _projects[projectIndex].createdAt,
          updatedAt: _projects[projectIndex].updatedAt,
        );
        
        _projects[projectIndex] = updatedProject;
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
      rethrow; // Relancer l'erreur pour que la UI puisse la gérer
    }
  }

  /// Obtient les projets filtrés par statut local (pour les filtres UI)
  List<ProjectModel> getProjectsByLocalStatus(ProjectStatus statusFilter) {
    return _projects.where((project) => project.status == statusFilter).toList();
  }

  /// Obtient les projets filtrés par vote local
  List<ProjectModel> getProjectsByVoteStatus(bool voted) {
    return _projects.where((project) => project.hasVoted == voted).toList();
  }

  void _setStatus(ProjectsStatus status) {
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

  /// Crée un nouveau projet
  Future<void> createProject({
    required String title,
    String? description,
    required DateTime voteStartDate,
    required DateTime voteEndDate,
    double? budget,
    String? icon,
    String? color,
  }) async {
    try {
      final projectData = {
        'title': title,
        'description': description,
        'vote_start_date': voteStartDate.toIso8601String(),
        'vote_end_date': voteEndDate.toIso8601String(),
        'budget': budget,
        'icon': icon,
        'color': color,
      };

      await _projectDataSource.createProject(projectData);
      
      // Recharger la liste des projets après création
      await loadProjects();
    } catch (e) {
      _setError(e.toString());
      rethrow; // Relancer l'erreur pour que la UI puisse la gérer
    }
  }
}
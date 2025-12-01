import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';
import '../data_source/admin_projects_data_source.dart';
import '../../projets/models/project_model.dart';

/// Status de chargement des projets admin
enum AdminProjectsStatus { initial, loading, loaded, error }

/// Contrôleur pour la gestion admin des projets
class AdminProjectsController extends ChangeNotifier {
  final AdminProjectsDataSource _dataSource = AdminProjectsDataSource();
  final ConnectivityService _connectivityService = ConnectivityService();

  // État
  AdminProjectsStatus _status = AdminProjectsStatus.initial;
  List<ProjectModel> _projects = [];
  ProjectsPagination? _pagination;
  String? _errorMessage;

  // Filtres actifs
  String? _statusFilter;
  String? _sortFilter;
  String? _searchQuery;

  // État de chargement de pagination
  bool _isLoadingMore = false;
  bool _isOpeningVote = false;

  // Getters
  AdminProjectsStatus get status => _status;
  List<ProjectModel> get projects => _projects;
  ProjectsPagination? get pagination => _pagination;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AdminProjectsStatus.loading;
  bool get hasData => _projects.isNotEmpty;
  bool get isLoadingMore => _isLoadingMore;
  bool get isOpeningVote => _isOpeningVote;
  String? get currentStatusFilter => _statusFilter;
  String? get currentSortFilter => _sortFilter;
  String? get currentSearchQuery => _searchQuery;

  // Getters de filtres calculés
  bool get hasNextPage => _pagination?.hasNextPage ?? false;
  int get currentPage => _pagination?.currentPage ?? 0;
  int get totalPages => _pagination?.lastPage ?? 0;
  int get totalItems => _pagination?.total ?? 0;

  /// Charge les projets
  Future<void> loadProjects({
    String? status,
    String? sort,
    String? search,
    bool forceRefresh = false,
  }) async {
    debugPrint('🔄 [ADMIN PROJECTS CONTROLLER] Loading projects...');
    debugPrint('   Status: $status, Sort: $sort, Search: $search');

    // Mettre à jour les filtres
    _statusFilter = status;
    _sortFilter = sort;
    _searchQuery = search;

    _setStatus(AdminProjectsStatus.loading);
    _clearError();

    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Pas de connexion Internet');
      }

      final response = await _dataSource.getProjects(
        status: _statusFilter,
        sort: _sortFilter,
        search: _searchQuery,
        perPage: 20,
        page: 1,
      );

      if (response.success) {
        _projects = response.data;
        _pagination = response.pagination;

        debugPrint('✅ [ADMIN PROJECTS CONTROLLER] ${_projects.length} projets chargés');
        _setStatus(AdminProjectsStatus.loaded);
      }
    } catch (e) {
      debugPrint('❌ [ADMIN PROJECTS CONTROLLER] Erreur: $e');
      _setError(e.toString());
      _setStatus(AdminProjectsStatus.error);
    }
  }

  /// Charge plus de projets (pagination infinie)
  Future<void> loadMoreProjects() async {
    if (!hasNextPage || _isLoadingMore) {
      debugPrint('⚠️ [ADMIN PROJECTS CONTROLLER] Pas de page suivante ou déjà en chargement');
      return;
    }

    if (!_connectivityService.isConnected) {
      debugPrint('📱 [ADMIN PROJECTS CONTROLLER] Pas de connexion pour charger plus');
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = currentPage + 1;
      debugPrint('📄 [ADMIN PROJECTS CONTROLLER] Chargement page $nextPage...');

      final response = await _dataSource.getProjects(
        status: _statusFilter,
        sort: _sortFilter,
        search: _searchQuery,
        perPage: 20,
        page: nextPage,
      );

      if (response.success) {
        // Ajouter les nouveaux projets à la liste existante
        _projects.addAll(response.data);
        _pagination = response.pagination;

        debugPrint(
          '✅ [ADMIN PROJECTS CONTROLLER] ${response.data.length} projets ajoutés (total: ${_projects.length})',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [ADMIN PROJECTS CONTROLLER] Erreur chargement page: $e');
      _setError('Erreur lors du chargement des projets supplémentaires');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Rafraîchit les données (pull-to-refresh)
  Future<void> refreshProjects() async {
    debugPrint('🔄 [ADMIN PROJECTS CONTROLLER] Rafraîchissement...');
    await loadProjects(
      status: _statusFilter,
      sort: _sortFilter,
      search: _searchQuery,
      forceRefresh: true,
    );
  }

  /// Change le filtre de statut
  Future<void> changeStatusFilter(String? status) async {
    if (_statusFilter == status) {
      debugPrint('ℹ️ [ADMIN PROJECTS CONTROLLER] Filtre déjà appliqué');
      return;
    }

    debugPrint('🔍 [ADMIN PROJECTS CONTROLLER] Changement de filtre: $status');
    _statusFilter = status;

    // Recharger avec le nouveau filtre
    await loadProjects(
      status: status,
      sort: _sortFilter,
      search: _searchQuery,
    );
  }

  /// Change le tri
  Future<void> changeSortFilter(String? sort) async {
    if (_sortFilter == sort) {
      debugPrint('ℹ️ [ADMIN PROJECTS CONTROLLER] Tri déjà appliqué');
      return;
    }

    debugPrint('🔄 [ADMIN PROJECTS CONTROLLER] Changement de tri: $sort');
    _sortFilter = sort;

    // Recharger avec le nouveau tri
    await loadProjects(
      status: _statusFilter,
      sort: sort,
      search: _searchQuery,
    );
  }

  /// Applique la recherche
  Future<void> applySearch(String? query) async {
    if (_searchQuery == query) {
      debugPrint('ℹ️ [ADMIN PROJECTS CONTROLLER] Recherche déjà appliquée');
      return;
    }

    debugPrint('🔍 [ADMIN PROJECTS CONTROLLER] Recherche: $query');
    _searchQuery = query;

    // Recharger avec la nouvelle recherche
    await loadProjects(
      status: _statusFilter,
      sort: _sortFilter,
      search: query,
    );
  }

  /// Ouvre la période de vote pour un projet
  Future<bool> openVotePeriod(String projectId) async {
    try {
      debugPrint('✅ [ADMIN PROJECTS CONTROLLER] Ouverture du vote pour projet: $projectId');

      _isOpeningVote = true;
      notifyListeners();

      final response = await _dataSource.openVotePeriod(projectId);

      if (response.success && response.project != null) {
        // Mettre à jour le projet dans la liste locale
        final index = _projects.indexWhere((p) => p.id == projectId);
        if (index != -1) {
          _projects[index] = response.project!;
          notifyListeners();
        }

        debugPrint('✅ [ADMIN PROJECTS CONTROLLER] Vote ouvert avec succès');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [ADMIN PROJECTS CONTROLLER] Erreur ouverture vote: $e');
      _setError('Erreur lors de l\'ouverture du vote');
      return false;
    } finally {
      _isOpeningVote = false;
      notifyListeners();
    }
  }

  /// Calcule le nombre de jours restants pour voter
  int getDaysRemainingToVote(ProjectModel project) {
    if (project.voteCloseDate == null) return 0;

    final now = DateTime.now();
    final difference = project.voteCloseDate!.difference(now);

    if (difference.isNegative) return 0;
    return difference.inDays;
  }

  /// Vérifie si un projet peut avoir son vote ouvert
  bool canOpenVote(ProjectModel project) {
    return project.status == ProjectStatus.voteNotOpen;
  }

  // Helpers privés
  void _setStatus(AdminProjectsStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    debugPrint('❌ [ADMIN PROJECTS CONTROLLER] Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    debugPrint('🔴 [ADMIN PROJECTS CONTROLLER] Dispose');
    super.dispose();
  }
}

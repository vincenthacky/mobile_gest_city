import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/project_card.dart';
import '../widgets/project_filters.dart';
import '../widgets/priority_modal.dart';
import '../widgets/project_detail_modal.dart';
import '../../models/project_model.dart';
import '../../controllers/project_controller.dart';
import 'create_project_page.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/sync_notification.dart';
import '../../../../core/services/connectivity_service.dart';

export '../widgets/project_filters.dart' show VoteFilter;

class ProjetsPage extends StatefulWidget {
  const ProjetsPage({super.key});

  @override
  State<ProjetsPage> createState() => _ProjetsPageState();
}

class _ProjetsPageState extends State<ProjetsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey<SliverAnimatedListState>();
  List<ProjectModel> _displayedProjects = [];
  String _searchQuery = '';
  ProjectStatus? _statusFilter = ProjectStatus.voteOpen;
  VoteFilter? _voteFilter;
  late ProjectController _projectController;
  late ConnectivityService _connectivityService;
  Timer? _searchTimer;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _projectController = Provider.of<ProjectController>(context, listen: false);
    _connectivityService = ConnectivityService();
    _setupScrollListener();
    _setupSearchListener();
    _setupConnectivityListener();
    
    // Charger les projets après que le widget soit complètement initialisé
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _connectivityService.startMonitoring();
      
      // Vérifier l'état initial de connexion après un court délai
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_connectivityService.isConnected && _projectController.allProjects.isNotEmpty) {
        _projectController.showOfflineNotification();
      }
      
      _loadProjects();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreProjects();
      }
    });
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      final query = _searchController.text;
      if (query != _searchQuery) {
        _searchQuery = query;
        _searchTimer?.cancel();
        
        // Recherche locale instantanée comme WhatsApp
        if (query.length >= 2 || query.isEmpty) {
          _searchTimer = Timer(const Duration(milliseconds: 150), () {
            _resetAndSearch(); // Maintenant c'est du filtrage local
          });
        }
      }
    });
  }

  void _setupConnectivityListener() {
    _connectivityService.addListener(() {
      if (_connectivityService.isConnected) {
        // Quand la connexion revient, déclencher une synchronisation
        debugPrint('🌐 [PROJETS] Connexion détectée - synchronisation automatique');
        // Synchronisation avec notification
        _projectController.syncProjects(showNotifications: true);
      } else {
        // Afficher notification hors ligne si on a des données en cache
        if (_projectController.allProjects.isNotEmpty) {
          _projectController.showOfflineNotification();
        }
      }
    });
  }

  Future<void> _loadProjects() async {
    _currentPage = 1;
    
    // Si pas de connexion et qu'on a du cache, afficher notification
    if (!_connectivityService.isConnected && _projectController.allProjects.isNotEmpty) {
      _projectController.showOfflineNotification();
    }
    
    // 🧹 MIGRATION: Force fresh data pour récupérer avec nouveau format
    // MIGRATION TERMINÉE - Test correction checksums validé
    await _projectController.fetchProjects(
      useSync: true, // Activer la synchronisation intelligente
      showNotifications: _connectivityService.isConnected, // Afficher notifications si en ligne
      // forceFreshData: true, // COMMENTÉ - Test correction checksums terminé
    );
    // Appliquer les filtres après chargement
    _projectController.applyStatusFilter(_statusFilter);
    _projectController.applySearchFilter(_searchQuery.length >= 2 ? _searchQuery : null);
  }

  Future<void> _loadMoreProjects() async {
    if (_isLoadingMore || _projectController.isLoadingProjects) return;
    
    final pagination = _projectController.pagination;
    if (pagination != null && _currentPage < pagination['last_page']) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });

      // Charger plus de projets dans le cache complet
      await _projectController.fetchProjects(
        page: _currentPage,
        append: true,
        useSync: false, // Pour pagination, utiliser mode legacy
        showNotifications: false, // Pas de notification pour pagination
      );
      
      // Réappliquer les filtres après ajout
      _projectController.refreshFilters();

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _resetAndSearch() async {
    // Recherche locale instantanée (style WhatsApp)
    _projectController.applySearchFilter(_searchQuery.length >= 2 ? _searchQuery : null);
  }

  // Méthode _mapStatusToApi supprimée - plus besoin avec filtrage local

  List<ProjectModel> _computeFilteredProjects() {
    // Récupérer tous les projets (pas encore filtrés par le controller si on utilise les filtres de vote)
    var projects = _voteFilter != null
        ? _projectController.allProjects  // Utiliser tous les projets si on filtre par vote
        : _projectController.projects;     // Sinon utiliser les projets déjà filtrés par statut

    // Appliquer le filtre de vote si actif
    if (_voteFilter != null) {
      if (_voteFilter == VoteFilter.notVoted) {
        projects = projects.where((p) => !p.hasUserVoted && p.status == ProjectStatus.voteOpen).toList();
      } else if (_voteFilter == VoteFilter.alreadyVoted) {
        projects = projects.where((p) => p.hasUserVoted).toList();
      }
    }

    // Tri spécial pour "Vote ouvert" : projets non votés d'abord (plus récent en haut), puis votés en bas
    if (_statusFilter == ProjectStatus.voteOpen && _voteFilter == null) {
      final notVoted = projects.where((p) => !p.hasUserVoted).toList();
      final voted = projects.where((p) => p.hasUserVoted).toList();
      notVoted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      voted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return [...notVoted, ...voted];
    }

    // Tri par défaut : plus récent en haut
    final sorted = projects.toList();
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Synchronise _displayedProjects avec la nouvelle liste et anime les différences
  void _syncDisplayedList(List<ProjectModel> newList) {
    final listState = _listKey.currentState;
    if (listState == null) {
      // Première construction, initialiser directement
      _displayedProjects = List.from(newList);
      return;
    }

    // 1. Détection des suppressions (parcourir à l'envers)
    for (int i = _displayedProjects.length - 1; i >= 0; i--) {
      final oldProject = _displayedProjects[i];
      final existsInNew = newList.any((p) => p.id == oldProject.id);
      if (!existsInNew) {
        final removed = _displayedProjects.removeAt(i);
        listState.removeItem(
          i,
          (context, animation) => _buildRemovedCard(removed, animation),
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    // 2. Détection des ajouts
    for (int i = 0; i < newList.length; i++) {
      final newProject = newList[i];
      final existsInOld = _displayedProjects.any((p) => p.id == newProject.id);
      if (!existsInOld) {
        final insertIndex = i.clamp(0, _displayedProjects.length);
        _displayedProjects.insert(insertIndex, newProject);
        listState.insertItem(
          insertIndex,
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    // 3. Détection des mises à jour (remplacer le ProjectModel in-place)
    for (int i = 0; i < _displayedProjects.length; i++) {
      final displayed = _displayedProjects[i];
      final updated = newList.firstWhere(
        (p) => p.id == displayed.id,
        orElse: () => displayed,
      );
      if (displayed != updated) {
        _displayedProjects[i] = updated;
      }
    }

    // 4. Réordonner si nécessaire (les IDs dans newList définissent l'ordre)
    final newOrder = <ProjectModel>[];
    for (final p in newList) {
      final match = _displayedProjects.firstWhere(
        (d) => d.id == p.id,
        orElse: () => p,
      );
      newOrder.add(match);
    }
    _displayedProjects = newOrder;

    // Si la liste est devenue vide, forcer un rebuild pour afficher l'état vide.
    // Sans ça, le SliverAnimatedList reste dans l'arbre avec un count interne = 0,
    // et le prochain changement de filtre tombe sur un écran blanc permanent.
    if (_displayedProjects.isEmpty && mounted) {
      setState(() {});
    }
  }

  Widget _buildAnimatedCard(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) {
    if (index >= _displayedProjects.length) return const SizedBox.shrink();
    final project = _displayedProjects[index];
    final card = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RepaintBoundary(
        child: ProjectCard(
          key: ValueKey(project.id),
          project: project,
          onTap: () => _showProjectDetails(project),
          onVote: (choice, justification) =>
              _handleVoteSubmitted(project, choice, justification),
        ),
      ),
    );

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: card,
        ),
      ),
    );
  }

  Widget _buildRemovedCard(
    ProjectModel project,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInCubic,
          )),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RepaintBoundary(
              child: ProjectCard(
                key: ValueKey(project.id),
                project: project,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    _connectivityService.stopMonitoring();
    super.dispose();
  }

  void _onFilterChanged(ProjectStatus? status) {
    setState(() {
      _statusFilter = status;
      _voteFilter = null; // Reset vote filter when status filter changes
    });
    // Filtrage local instantané (style WhatsApp)
    _projectController.applyStatusFilter(status);
  }

  void _onVoteFilterChanged(VoteFilter? filter) {
    setState(() {
      _voteFilter = filter;
      _statusFilter = null; // Reset status filter when vote filter changes
    });
    // Synchroniser l'état du contrôleur : sans filtre de statut, montrer tous les projets
    _projectController.applyStatusFilter(null);
  }


  Future<void> _handleVoteSubmitted(ProjectModel project, VoteChoice choice, String? justification) async {
    Map<String, dynamic>? response;
    if (project.hasUserVoted) {
      response = await _projectController.modifyVote(
        project.id,
        choice,
        justification: justification,
      );
    } else {
      response = await _projectController.voteOnProject(
        project.id,
        choice,
        justification: justification,
      );
    }

    if (response != null) {
      final messageText = project.hasUserVoted 
          ? 'Vote modifié: ${_getVoteText(choice)}'
          : 'Vote enregistré: ${_getVoteText(choice)}';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messageText),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      // Gérer la priorisation basée sur user_projects_voted_yes
      if (choice == VoteChoice.yes || choice == VoteChoice.yesWithReserve) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          await _handlePrioritizationLogic();
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_projectController.voteErrorMessage ?? 'Erreur lors du vote'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  String _getVoteText(VoteChoice choice) {
    switch (choice) {
      case VoteChoice.yes:
        return 'OUI';
      case VoteChoice.no:
        return 'NON';
      case VoteChoice.yesWithReserve:
        return 'OUI SOUS RÉSERVE';
      case VoteChoice.blank:
        return 'BLANC';
    }
  }

  Future<void> _handlePrioritizationLogic() async {
    final action = await _projectController.handlePrioritizationAfterVote();
    
    if (!mounted) return;

    switch (action) {
      case PrioritizationAction.none:
        // Rien à faire
        break;
        
      case PrioritizationAction.autoCompleted:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Priorisation automatique effectuée'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        break;
        
      case PrioritizationAction.showModal:
        _showPriorityModal();
        break;
        
      case PrioritizationAction.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la priorisation automatique'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        break;
    }
  }

  void _showPriorityModal() {
    final yesVotedProjects = _projectController.userProjectsVotedYes;

    if (yesVotedProjects.length < 2) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PriorityModal(
        projects: yesVotedProjects,
        onPrioritySubmitted: (projectIds) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final success = await _projectController.prioritizeProjects(projectIds);
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(success ? 'Classement enregistré !' : 'Erreur lors du classement'),
                backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
      ),
    );
  }

  void _showProjectDetails(ProjectModel project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProjectDetailModal(
        project: project,
        onVoteSubmitted: _handleVoteSubmitted,
      ),
    );
  }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: const AppHeader(
                    title: 'Projets de la cité',
                  ),
                ),
            
            // Notification de synchronisation
            Consumer<ProjectController>(
              builder: (context, projectController, child) {
                return SyncNotification(
                  type: projectController.notificationType,
                  customMessage: projectController.notificationMessage,
                  onDismiss: () {
                    projectController.clearNotification();
                  },
                );
              },
            ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProjects,
                color: const Color(0xFF3B82F6),
                child: Consumer<ProjectController>(
                  builder: (context, projectController, child) {
                    if (projectController.isLoadingProjects && projectController.projects.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                      );
                    }

                    if (projectController.loadingStatus == ProjectLoadingStatus.error) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur de chargement',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              projectController.loadingErrorMessage ?? 'Une erreur est survenue',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                fontFamily: 'Nunito',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProjects,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Sync la liste animée avec les nouvelles données
                    final newFiltered = _computeFilteredProjects();
                    // Initialiser immédiatement si on revient sur la page avec des données déjà en mémoire
                    if (_displayedProjects.isEmpty && newFiltered.isNotEmpty) {
                      _displayedProjects = List.from(newFiltered);
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _syncDisplayedList(newFiltered);
                      }
                    });

                    return CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Barre de recherche + Filtres
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: 'Rechercher un projet (2+ caractères)...',
                                            hintStyle: const TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontFamily: 'Nunito',
                                              fontSize: 14,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.search,
                                              color: Color(0xFF6B7280),
                                              size: 20,
                                            ),
                                            suffixIcon: _searchController.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(Icons.clear, size: 18),
                                                    onPressed: () {
                                                      _searchController.clear();
                                                    },
                                                  )
                                                : null,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const CreateProjectPage(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ProjectFilters(
                                  selectedStatus: _statusFilter,
                                  selectedVoteFilter: _voteFilter,
                                  onFilterChanged: _onFilterChanged,
                                  onVoteFilterChanged: _onVoteFilterChanged,
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),

                        // Liste animée ou message vide
                        if (_displayedProjects.isEmpty && !projectController.isLoadingProjects)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun projet trouvé',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Essayez de modifier vos filtres de recherche',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                        fontFamily: 'Nunito',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverAnimatedList(
                              key: _listKey,
                              initialItemCount: _displayedProjects.length,
                              itemBuilder: _buildAnimatedCard,
                            ),
                          ),

                        // Indicateur de pagination
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              if (_isLoadingMore)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF3B82F6),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Chargement...',
                                        style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (projectController.pagination != null && !_isLoadingMore)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    '${projectController.pagination!['from']} - ${projectController.pagination!['to']} sur ${projectController.pagination!['total']} projets',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontFamily: 'Nunito',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      // Loader centralisé pour le vote
      Consumer<ProjectController>(
        builder: (context, projectController, child) {
          if (projectController.isVoting) {
            return Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Vote en cours...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
        ],
      ),
    );
  }
}
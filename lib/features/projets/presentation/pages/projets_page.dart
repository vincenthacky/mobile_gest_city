import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controller/projects_controller.dart';
import '../../models/project_model.dart';

enum ProjectFilter { tous, nonVoter, dejaVoter, aVenir, enCours, finir }

class ProjetsPage extends StatefulWidget {
  const ProjetsPage({super.key});

  @override
  State<ProjetsPage> createState() => _ProjetsPageState();
}

class _ProjetsPageState extends State<ProjetsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ProjectFilter _selectedFilter = ProjectFilter.tous;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialiser le contrôleur des projets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectsController = context.read<ProjectsController>();
      if (projectsController.status == ProjectsStatus.initial) {
        projectsController.loadProjects();
      }
    });

    // Écouter le scroll pour la pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // L'utilisateur a atteint le bas de la liste
      final projectsController = context.read<ProjectsController>();
      if (projectsController.hasMorePages && !projectsController.isLoadingMore) {
        projectsController.loadMoreProjects();
      }
    }
  }

  List<ProjectModel> _getFilteredProjects(List<ProjectModel> projects) {
    List<ProjectModel> filtered = projects.where((project) {
      // Le filtrage par recherche et statut API est déjà fait côté serveur
      // Ici on applique seulement les filtres UI supplémentaires si nécessaire
      switch (_selectedFilter) {
        case ProjectFilter.tous:
          return true;
        case ProjectFilter.nonVoter:
          return !project.hasVoted;
        case ProjectFilter.dejaVoter:
          return project.hasVoted;
        case ProjectFilter.aVenir:
          return project.isUpcoming;
        case ProjectFilter.enCours:
          return project.isOngoing;
        case ProjectFilter.finir:
          return project.isEnded;
      }
    }).toList();

    return filtered;
  }

  void _applyFilter(ProjectFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
    
    final projectsController = context.read<ProjectsController>();
    
    // Mapper les filtres UI vers les filtres API
    switch (filter) {
      case ProjectFilter.tous:
        projectsController.setStatusFilter(null);
        projectsController.setVotedFilter(null);
        break;
      case ProjectFilter.nonVoter:
        projectsController.setStatusFilter(null); // Reset status filter
        projectsController.setVotedFilter(false);
        break;
      case ProjectFilter.dejaVoter:
        projectsController.setStatusFilter(null); // Reset status filter
        projectsController.setVotedFilter(true);
        break;
      case ProjectFilter.aVenir:
        projectsController.setVotedFilter(null); // Reset voted filter
        projectsController.setStatusFilter('upcoming');
        break;
      case ProjectFilter.enCours:
        projectsController.setVotedFilter(null); // Reset voted filter
        projectsController.setStatusFilter('ongoing');
        break;
      case ProjectFilter.finir:
        projectsController.setVotedFilter(null); // Reset voted filter
        projectsController.setStatusFilter('ended');
        break;
    }
  }

  void _performSearch(String query) {
    final projectsController = context.read<ProjectsController>();
    // Déclencher la recherche seulement si 2+ caractères ou vide (pour reset)
    if (query.isEmpty || query.length >= 2) {
      projectsController.setSearch(query.isEmpty ? null : query);
    }
  }

  void _debounceSearch(String query) {
    // Annuler le timer précédent
    _debounceTimer?.cancel();
    
    // Créer un nouveau timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, projectsController, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => projectsController.refreshProjects(),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          const Text(
                            'Votes sur les projets',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Barre de recherche et bouton ajouter
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _debounceSearch,
                                    decoration: InputDecoration(
                                      hintText: 'Rechercher un projet (min. 2 caractères)',
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Color(0xFF6B7280),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    context.go('/projets/ajouter');
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Filtres
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildFilterChip('Tous', ProjectFilter.tous),
                                const SizedBox(width: 8),
                                _buildFilterChip('Non voté', ProjectFilter.nonVoter),
                                const SizedBox(width: 8),
                                _buildFilterChip('Déjà voté', ProjectFilter.dejaVoter),
                                const SizedBox(width: 8),
                                _buildFilterChip('À venir', ProjectFilter.aVenir),
                                const SizedBox(width: 8),
                                _buildFilterChip('En cours', ProjectFilter.enCours),
                                const SizedBox(width: 8),
                                _buildFilterChip('Fini', ProjectFilter.finir),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // État de chargement initial
                          if (projectsController.isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(50),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          // État d'erreur
                          else if (projectsController.hasError)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Erreur de chargement',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    projectsController.errorMessage ?? 'Une erreur est survenue',
                                    style: TextStyle(color: Colors.red.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => projectsController.loadProjects(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Réessayer'),
                                  ),
                                ],
                              ),
                            )
                          // Liste des projets
                          else if (_getFilteredProjects(projectsController.projects).isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Aucun projet trouvé',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                ..._getFilteredProjects(projectsController.projects).map((project) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildProjetCard(project),
                                  );
                                }),
                                
                                // Indicateur de chargement pour la pagination
                                if (projectsController.isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                
                                // Message fin de liste si plus de pages
                                if (!projectsController.hasMorePages && projectsController.projects.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Tous les projets ont été chargés',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjetCard(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: project.hasVoted
            ? Border.all(color: project.projectColor.withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: project.projectColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  project.iconData,
                  color: project.projectColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Clôture: ${project.formattedEndDate}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: project.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: project.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            project.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          
          // Statistiques de vote
          if (project.totalVotes > 0) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Votes Oui',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${project.votesYes} votes',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Votes Non',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${project.votesNo} votes',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Approbation',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${(project.approvalPercentage * 100).round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: project.projectColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Barre de progression
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                children: [
                  if (project.approvalPercentage > 0)
                    Container(
                      width: (MediaQuery.of(context).size.width - 80) * project.approvalPercentage,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  if (project.approvalPercentage < 1)
                    Container(
                      width: (MediaQuery.of(context).size.width - 80) * (1 - project.approvalPercentage),
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Boutons de vote
          if (project.canVote) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _vote(project, true),
                    icon: const Icon(Icons.thumb_up, size: 18),
                    label: const Text('Oui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _vote(project, false),
                    icon: const Icon(Icons.thumb_down, size: 18),
                    label: const Text('Non'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (project.hasVoted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: project.voteStatus == VoteStatus.yesVoted
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    project.voteStatus == VoteStatus.yesVoted
                        ? Icons.thumb_up
                        : Icons.thumb_down,
                    size: 18,
                    color: project.voteStatus == VoteStatus.yesVoted
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vous avez voté ${project.voteStatus == VoteStatus.yesVoted ? "OUI" : "NON"}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: project.voteStatus == VoteStatus.yesVoted
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (project.isUpcoming) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Vote pas encore ouvert',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Vote terminé',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ProjectFilter filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => _applyFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Future<void> _vote(ProjectModel project, bool isYes) async {
    try {
      final projectsController = context.read<ProjectsController>();
      await projectsController.voteOnProject(project.id, isYes);

      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vote enregistré : ${isYes ? "OUI" : "NON"}'),
            backgroundColor: isYes ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du vote : ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
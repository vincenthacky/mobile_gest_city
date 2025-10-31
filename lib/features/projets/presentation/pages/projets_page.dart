import 'package:flutter/material.dart';
import '../widgets/project_card.dart';
import '../widgets/project_filters.dart';
import '../widgets/vote_popup.dart';
import '../widgets/priority_modal.dart';
import '../../models/project_model.dart';
import 'create_project_page.dart';
import '../../../../core/widgets/app_header.dart';

class ProjetsPage extends StatefulWidget {
  const ProjetsPage({super.key});

  @override
  State<ProjetsPage> createState() => _ProjetsPageState();
}

class _ProjetsPageState extends State<ProjetsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  ProjectStatus? _statusFilter;

  List<ProjectModel> get _mockProjects => [
    ProjectModel(
      id: '1',
      title: 'Aménagement parc central',
      shortDescription: 'Rénovation complète du parc avec nouvelles aires de jeux et espaces verts',
      longDescription: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      estimatedAmount: 150000,
      implementationType: ImplementationType.withTender,
      status: ProjectStatus.voteOpen,
      voteCloseDate: DateTime.now().add(const Duration(days: 7)),
      votesYes: 45,
      votesNo: 12,
      votesYesWithReserve: 8,
      votesBlank: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
      authorId: 'user1',
      authorName: 'Marie Dupont',
    ),
    ProjectModel(
      id: '2',
      title: 'Installation éclairage LED',
      shortDescription: 'Remplacement de tous les lampadaires par des LED économiques',
      longDescription: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      estimatedAmount: 80000,
      implementationType: ImplementationType.knownProvider,
      providerName: 'Éclairage Plus',
      providerAmount: 75000,
      status: ProjectStatus.voteOpen,
      voteCloseDate: DateTime.now().add(const Duration(days: 3)),
      votesYes: 32,
      votesNo: 18,
      votesYesWithReserve: 5,
      votesBlank: 2,
      userVote: VoteChoice.yes,
      userVoteJustification: 'Excellent projet pour l\'environnement',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
      authorId: 'user2',
      authorName: 'Jean Martin',
    ),
    ProjectModel(
      id: '3',
      title: 'Aire de fitness extérieure',
      shortDescription: 'Installation d\'équipements de fitness en plein air',
      longDescription: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      estimatedAmount: 25000,
      implementationType: ImplementationType.withoutProvider,
      status: ProjectStatus.voteNotOpen,
      voteCloseDate: DateTime.now().add(const Duration(days: 15)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
      authorId: 'user3',
      authorName: 'Sophie Bernard',
    ),
    ProjectModel(
      id: '4',
      title: 'Réfection de la voirie',
      shortDescription: 'Réparation des nids de poule et marquage au sol',
      longDescription: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      estimatedAmount: 200000,
      implementationType: ImplementationType.withTender,
      status: ProjectStatus.accepted,
      votesYes: 78,
      votesNo: 15,
      votesYesWithReserve: 12,
      votesBlank: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      authorId: 'user4',
      authorName: 'Pierre Lefebvre',
    ),
  ];

  List<ProjectModel> get _filteredProjects {
    return _mockProjects.where((project) {
      final matchesSearch = _searchQuery.isEmpty ||
          project.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.shortDescription.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == null || project.status == _statusFilter;
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFilterChanged(ProjectStatus? status) {
    setState(() {
      _statusFilter = status;
    });
  }

  void _showVotePopup(ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => VotePopup(
        project: project,
        onVoteSubmitted: (choice, justification) {
          _handleVoteSubmitted(project, choice, justification);
        },
      ),
    );
  }

  void _handleVoteSubmitted(ProjectModel project, VoteChoice choice, String? justification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vote enregistré: ${_getVoteText(choice)}'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    final yesVotedProjects = _mockProjects
        .where((p) => p.userVote == VoteChoice.yes || p.userVote == VoteChoice.yesWithReserve)
        .length;

    if ((choice == VoteChoice.yes || choice == VoteChoice.yesWithReserve) && yesVotedProjects >= 1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showPriorityModal();
      });
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

  void _showPriorityModal() {
    final yesVotedProjects = _mockProjects
        .where((p) => p.userVote == VoteChoice.yes || p.userVote == VoteChoice.yesWithReserve)
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PriorityModal(
        projects: yesVotedProjects,
        onPrioritySubmitted: (projectIds) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Classement enregistré !'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }

  void _showProjectDetails(ProjectModel project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProjectDetailsModal(project),
    );
  }

  Widget _buildProjectDetailsModal(ProjectModel project) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Par ${project.authorName}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: project.statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          project.statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: project.statusColor,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description complète',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          project.longDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations du projet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('💰', 'Budget estimé', project.formattedEstimatedAmount),
                        _buildInfoRow('⚙️', 'Mise en œuvre', project.implementationTypeText),
                        if (project.providerName != null)
                          _buildInfoRow('🏢', 'Prestataire', project.providerName!),
                        if (project.voteCloseDate != null)
                          _buildInfoRow('⏰', 'Clôture du vote', project.formattedVoteCloseDate),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (project.totalVotes > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Résultats du vote',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildVoteResult('👍', 'Oui', project.votesYes, project.yesPercentage, const Color(0xFF10B981)),
                          _buildVoteResult('👎', 'Non', project.votesNo, project.noPercentage, const Color(0xFFEF4444)),
                          _buildVoteResult('⚠️', 'Oui sous réserve', project.votesYesWithReserve, project.yesWithReservePercentage, const Color(0xFFF97316)),
                          _buildVoteResult('⚪', 'Blanc', project.votesBlank, project.blankPercentage, const Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (project.canVote) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                          const Text(
                            'Votre vote',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showVotePopup(project);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Voter sur ce projet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (project.hasUserVoted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: project.voteChoiceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: project.voteChoiceColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.how_to_vote,
                                color: project.voteChoiceColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Vous avez voté: ${project.voteChoiceText}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: project.voteChoiceColor,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          if (project.userVoteJustification != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              project.userVoteJustification!,
                              style: TextStyle(
                                fontSize: 14,
                                color: project.voteChoiceColor,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Nunito',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteResult(String emoji, String label, int votes, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Nunito',
                      ),
                    ),
                    Text(
                      '$votes votes (${(percentage * 100).round()}%)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
                title: 'Projets communautaires',
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                },
                color: const Color(0xFF3B82F6),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barre de recherche et bouton ajouter
                      Row(
                        children: [
                          Expanded(
                            child: Container(
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
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un projet...',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'Nunito',
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF6B7280),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
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
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      ProjectFilters(
                        selectedStatus: _statusFilter,
                        onFilterChanged: _onFilterChanged,
                      ),
                      const SizedBox(height: 24),
                      
                      if (_filteredProjects.isEmpty)
                        Container(
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
                        )
                      else
                        Column(
                          children: _filteredProjects.map((project) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ProjectCard(
                                project: project,
                                onTap: () => _showProjectDetails(project),
                                onVote: () => _showVotePopup(project),
                              ),
                            );
                          }).toList(),
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
  }
}
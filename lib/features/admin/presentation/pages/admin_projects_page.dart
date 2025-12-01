import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_projects_controller.dart';
import '../../../projets/models/project_model.dart';

class AdminProjectsPage extends StatefulWidget {
  const AdminProjectsPage({super.key});

  @override
  State<AdminProjectsPage> createState() => _AdminProjectsPageState();
}

class _AdminProjectsPageState extends State<AdminProjectsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    // Charger les projets au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<AdminProjectsController>();
      controller.loadProjects();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  /// Détecte quand on approche du bas de la liste
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMoreProjects();
    }
  }

  /// Gère le changement de texte de recherche avec debounce
  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      final controller = context.read<AdminProjectsController>();
      controller.applySearch(
        _searchController.text.isEmpty ? null : _searchController.text,
      );
    });
  }

  /// Charge plus de projets (pagination infinie)
  Future<void> _loadMoreProjects() async {
    if (_isLoadingMore) return;

    final controller = context.read<AdminProjectsController>();

    if (!controller.hasNextPage) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await controller.loadMoreProjects();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  /// Pull-to-refresh
  Future<void> _onRefresh() async {
    final controller = context.read<AdminProjectsController>();
    await controller.refreshProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec titre et bouton rafraîchir
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1F2937),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Gestion des projets',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Consumer<AdminProjectsController>(
                    builder: (context, controller, child) {
                      return IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: controller.isLoading
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                              : const Color(0xFF3B82F6),
                        ),
                        tooltip: 'Rafraîchir la liste',
                        onPressed: controller.isLoading
                            ? null
                            : () => controller.refreshProjects(),
                      );
                    },
                  ),
                ],
              ),
            ),

            Consumer<AdminProjectsController>(
              builder: (context, controller, child) {
                return Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: const Color(0xFF3B82F6),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Barre de recherche
                          _buildSearchBar(),
                          const SizedBox(height: 12),

                          // Tri
                          _buildSortRow(controller),
                          const SizedBox(height: 12),

                          // Filtres de statut
                          _buildStatusFilters(controller),
                          const SizedBox(height: 12),

                          // Message d'aide intuitif
                          _buildHelpMessage(),
                          const SizedBox(height: 12),

                          // Liste ou état
                          _buildContent(controller),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
          hintText: 'Rechercher un projet...',
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
    );
  }

  Widget _buildSortRow(AdminProjectsController controller) {
    return Row(
      children: [
        const Icon(Icons.sort, size: 18, color: Color(0xFF6B7280)),
        const SizedBox(width: 8),
        const Text(
          'Tri :',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: controller.currentSortFilter,
                isExpanded: true,
                hint: const Text(
                  'Sans tri',
                  style: TextStyle(fontFamily: 'Nunito'),
                ),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Sans tri',
                      style: TextStyle(fontFamily: 'Nunito'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'total_score',
                    child: Text(
                      'Score total',
                      style: TextStyle(fontFamily: 'Nunito'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  controller.changeSortFilter(value);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilters(AdminProjectsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.filter_list, size: 18, color: Color(0xFF6B7280)),
            SizedBox(width: 8),
            Text(
              'Filtrer par statut :',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Tous',
                null,
                controller.currentStatusFilter == null,
                controller,
                Icons.apps,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Pas encore ouvert',
                'vote_not_open',
                controller.currentStatusFilter == 'vote_not_open',
                controller,
                Icons.schedule,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Vote ouvert',
                'vote_open',
                controller.currentStatusFilter == 'vote_open',
                controller,
                Icons.how_to_vote,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Vote clos',
                'vote_closed',
                controller.currentStatusFilter == 'vote_closed',
                controller,
                Icons.event_busy,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Accepté',
                'project_accepted',
                controller.currentStatusFilter == 'project_accepted',
                controller,
                Icons.check_circle,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Rejeté',
                'project_rejected',
                controller.currentStatusFilter == 'project_rejected',
                controller,
                Icons.cancel,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    bool isSelected,
    AdminProjectsController controller,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        controller.changeStatusFilter(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.08),
            const Color(0xFF3B82F6).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF3B82F6),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Touchez un projet pour voir les détails et ouvrir le vote',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AdminProjectsController controller) {
    // État de chargement initial
    if (controller.isLoading && controller.projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const CircularProgressIndicator(color: Color(0xFF3B82F6)),
            const SizedBox(height: 16),
            Text(
              'Chargement des projets...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      );
    }

    // État d'erreur
    if (controller.status == AdminProjectsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
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
              controller.errorMessage ?? 'Une erreur est survenue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontFamily: 'Nunito',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.refreshProjects(),
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

    // État vide
    if (controller.projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(Icons.folder_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Aucun projet trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Essayez de modifier vos filtres de recherche',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Nunito',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Liste des projets
    return Column(
      children: [
        ...controller.projects.map((project) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AdminProjectCard(
              project: project,
              onTap: () => _showProjectDetails(project, controller),
              onOpenVote: controller.canOpenVote(project)
                  ? () => _handleOpenVote(project, controller)
                  : null,
            ),
          );
        }),

        // Indicateur de chargement pour la pagination
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

        // Information sur la pagination
        if (controller.pagination != null && !_isLoadingMore)
          Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              controller.hasNextPage
                  ? '${controller.pagination!.from} - ${controller.pagination!.to} sur ${controller.pagination!.total} projets'
                  : 'Tous les projets chargés (${controller.pagination!.total})',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontFamily: 'Nunito',
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// Gère l'ouverture du vote avec confirmation en 2 étapes
  Future<void> _handleOpenVote(
    ProjectModel project,
    AdminProjectsController controller,
  ) async {
    // PREMIÈRE MODAL: Confirmation simple
    final firstConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber,
                color: Color(0xFFF59E0B),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirmation requise',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous vraiment ouvrir la période de vote pour :',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'Continuer',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    if (!mounted) return;

    // DEUXIÈME MODAL: Confirmation finale avec détails
    final finalConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.how_to_vote,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Dernière confirmation',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations importantes',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '• Le vote sera ouvert pendant 8 jours\n• Les résidents pourront voter immédiatement\n• Cette action est irréversible\n• Vous ne pourrez pas fermer le vote avant la fin',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: const Color(
                              0xFF92400E,
                            ).withValues(alpha: 0.9),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'Ouvrir le vote',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

    if (!mounted) return;

    // MODAL DE CHARGEMENT avec loader
    // Capture du contexte de la dialog pour pouvoir la fermer correctement
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Color(0xFF10B981),
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ouverture du vote en cours...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez patienter quelques instants',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: const Color(0xFF6B7280).withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Exécuter l'ouverture du vote
    final success = await controller.openVotePeriod(project.id);

    // Fermer la modal de chargement en utilisant le contexte capturé
    if (dialogContext != null && dialogContext!.mounted) {
      Navigator.of(dialogContext!).pop();
    }

    if (success) {
      // SUCCÈS: Toast de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vote ouvert avec succès !',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Les résidents peuvent maintenant voter pendant 8 jours',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
    } else {
      // ERREUR: Modal d'erreur
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Erreur',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.errorMessage ??
                            'Impossible d\'ouvrir la période de vote. Veuillez réessayer plus tard.',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF991B1B),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
              ),
              child: const Text(
                'Fermer',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Affiche les détails d'un projet
  void _showProjectDetails(
    ProjectModel project,
    AdminProjectsController controller,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: screenHeight * 0.83,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screenWidth > 500 ? 24 : 20),
            topRight: Radius.circular(screenWidth > 500 ? 24 : 20),
          ),
        ),
        child: AdminProjectDetailModal(
          project: project,
          controller: controller,
          onOpenVote: () {
            Navigator.pop(context);
            _handleOpenVote(project, controller);
          },
        ),
      ),
    );
  }
}

// Card de projet pour l'admin (réutilise le design de ProjectCard)
class AdminProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback? onOpenVote;

  const AdminProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onOpenVote,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 12,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              project.displayAuthorName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                                fontFamily: 'Nunito',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: project.statusColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              project.statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: project.statusColor,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // DESCRIPTION
            Text(
              project.shortDescription,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
                fontFamily: 'Nunito',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // BUDGET & DATE
            Row(
              children: [
                _pillWithIcon(
                  icon: Icons.attach_money,
                  label: project.formattedEstimatedAmount,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                if (project.voteCloseDate != null &&
                    project.status != ProjectStatus.voteNotOpen)
                  _pillWithIcon(
                    icon: Icons.schedule,
                    label: project.formattedVoteCloseDate,
                    color: Colors.orange,
                  ),
                const Spacer(),
                if (project.hasImages)
                  _pillWithIcon(
                    icon: Icons.photo_library,
                    label: '${project.imageCount}',
                    color: const Color(0xFF8B5CF6),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // BOUTON OUVRIR VOTE ou MESSAGE
            if (onOpenVote != null) ...[
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: onOpenVote,
                  icon: const Icon(Icons.how_to_vote, size: 18),
                  label: const Text(
                    'Ouvrir le vote',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              _buildAdminStatusMessage(project),
            ],

            const SizedBox(height: 8),

            // RÉSULTATS DES VOTES (toujours afficher si votes > 0)
            if (project.totalVotes > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _voteItemWithIcon(
                    'Votes Oui',
                    Icons.thumb_up,
                    project.votesYes,
                    const Color(0xFF10B981),
                  ),
                  _voteItemWithIcon(
                    'Oui sous réserve',
                    Icons.edit_note,
                    project.votesYesWithReserve,
                    const Color(0xFFF97316),
                  ),
                  _voteItemWithIcon(
                    'Neutres',
                    Icons.radio_button_unchecked,
                    project.votesBlank,
                    const Color(0xFF6B7280),
                  ),
                  _voteItemWithIcon(
                    'Votes Non',
                    Icons.thumb_down,
                    project.votesNo,
                    const Color(0xFFEF4444),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _pillWithIcon({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _voteItemWithIcon(
    String label,
    IconData icon,
    int value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF475569),
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatusMessage(ProjectModel project) {
    String message;
    IconData icon;
    Color color;

    if (project.status == ProjectStatus.voteOpen) {
      message = 'Vote en cours';
      icon = Icons.how_to_vote;
      color = const Color(0xFF10B981);
    } else if (project.status == ProjectStatus.voteClosed) {
      message = 'Vote terminé';
      icon = Icons.how_to_vote_outlined;
      color = const Color(0xFF475569);
    } else if (project.status == ProjectStatus.accepted) {
      message = 'Projet accepté';
      icon = Icons.check_circle;
      color = const Color(0xFF10B981);
    } else if (project.status == ProjectStatus.rejected) {
      message = 'Projet rejeté';
      icon = Icons.cancel;
      color = const Color(0xFFEF4444);
    } else {
      message = 'En attente d\'ouverture';
      icon = Icons.schedule;
      color = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// Modal de détails pour l'admin (réutilise le design de ProjectDetailModal)
class AdminProjectDetailModal extends StatelessWidget {
  final ProjectModel project;
  final AdminProjectsController controller;
  final VoidCallback onOpenVote;

  const AdminProjectDetailModal({
    super.key,
    required this.project,
    required this.controller,
    required this.onOpenVote,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Column(
      children: [
        Container(
          width: screenWidth * 0.1,
          height: 4,
          margin: EdgeInsets.only(
            top: screenHeight > 700 ? 12 : 8,
            bottom: screenHeight > 700 ? 20 : 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              screenWidth > 500 ? 20 : 16,
              0,
              screenWidth > 500 ? 20 : 16,
              screenHeight > 700 ? 20 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProjectHeader(),
                SizedBox(height: screenHeight > 700 ? 24 : 20),
                _buildDescriptionSection(),
                SizedBox(height: screenHeight > 700 ? 20 : 16),
                if (project.hasImages) ...[
                  _buildImagesSection(),
                  SizedBox(height: screenHeight > 700 ? 20 : 16),
                ],
                _buildProjectInfoSection(),
                SizedBox(height: screenHeight > 700 ? 20 : 16),
                // Toujours afficher les résultats si totalVotes > 0
                if (project.totalVotes > 0) ...[
                  _buildVoteResultsSection(),
                  SizedBox(height: screenHeight > 700 ? 20 : 16),
                ],
                // Bouton ouvrir vote si applicable
                if (controller.canOpenVote(project)) _buildOpenVoteSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectHeader() {
    return Column(
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Par ${project.displayAuthorName}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          // Brief description
          Text(
            project.shortDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              height: 1.5,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Detailed description
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
    );
  }

  Widget _buildImagesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF8B5CF6),
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Images du projet (${project.imageCount})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: project.imageAttachments.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < project.imageAttachments.length - 1 ? 12 : 0,
                  ),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            color: Color(0xFF8B5CF6),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfoSection() {
    final daysRemaining = controller.getDaysRemainingToVote(project);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
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
          _buildInfoRow(
            Icons.euro,
            'Budget estimé',
            project.formattedEstimatedAmount,
            const Color(0xFF10B981),
          ),
          _buildInfoRow(
            Icons.settings,
            'Mise en œuvre',
            project.implementationTypeText,
            const Color(0xFF8B5CF6),
          ),
          if (project.providerName != null)
            _buildInfoRow(
              Icons.business,
              'Prestataire',
              project.providerName!,
              const Color(0xFF3B82F6),
            ),
          if (project.startDate != null)
            _buildInfoRow(
              Icons.play_circle_outline,
              'Date de début',
              _formatDate(project.startDate!),
              const Color(0xFF3B82F6),
            ),
          if (project.endDate != null)
            _buildInfoRow(
              Icons.flag_outlined,
              'Date de fin estimée',
              _formatDate(project.endDate!),
              const Color(0xFF8B5CF6),
            ),
          if (project.deadlineDate != null)
            _buildInfoRow(
              Icons.warning_amber_outlined,
              'Date de caducité',
              _formatDate(project.deadlineDate!),
              const Color(0xFFF59E0B),
            ),
          if (project.status == ProjectStatus.voteOpen && daysRemaining > 0)
            _buildInfoRow(
              Icons.schedule,
              'Jours restants pour voter',
              '$daysRemaining jour${daysRemaining > 1 ? 's' : ''}',
              const Color(0xFFEF4444),
            ),
        ],
      ),
    );
  }

  Widget _buildVoteResultsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
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
          _buildVoteResult(
            Icons.thumb_up,
            'Oui',
            project.votesYes,
            project.yesPercentage,
            const Color(0xFF10B981),
          ),
          _buildVoteResult(
            Icons.thumb_down,
            'Non',
            project.votesNo,
            project.noPercentage,
            const Color(0xFFEF4444),
          ),
          _buildVoteResult(
            Icons.edit_note,
            'Oui sous réserve',
            project.votesYesWithReserve,
            project.yesWithReservePercentage,
            const Color(0xFFF97316),
          ),
          _buildVoteResult(
            Icons.radio_button_unchecked,
            'Neutre',
            project.votesBlank,
            project.blankPercentage,
            const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenVoteSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.1),
            const Color(0xFF10B981).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text(
                'Action administrative',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Ouvrez la période de vote pour permettre aux résidents de voter sur ce projet pendant 8 jours.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontFamily: 'Nunito',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenVote,
              icon: const Icon(Icons.how_to_vote, size: 20),
              label: const Text(
                'Ouvrir la période de vote',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  Widget _buildVoteResult(
    IconData icon,
    String label,
    int votes,
    double percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
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
}

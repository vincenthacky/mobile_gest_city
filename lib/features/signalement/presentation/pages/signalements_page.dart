import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_header.dart';
import '../../models/report_model.dart';
import '../../controllers/report_controller.dart';

enum SignalementFilter { tous, nouveaux, enCours, resolus, urgents }


class SignalementsPage extends StatefulWidget {
  const SignalementsPage({super.key});

  @override
  State<SignalementsPage> createState() => _SignalementsPageState();
}

class _SignalementsPageState extends State<SignalementsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SignalementFilter _selectedFilter = SignalementFilter.tous;
  late ReportController _reportController;
  Timer? _searchTimer;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _reportController = Provider.of<ReportController>(context, listen: false);
    _loadReports();
    _setupScrollListener();
    _setupSearchListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreReports();
      }
    });
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      final query = _searchController.text;
      if (query != _searchQuery) {
        _searchQuery = query;
        _searchTimer?.cancel();
        
        // Démarrer la recherche après 300ms de délai
        _searchTimer = Timer(const Duration(milliseconds: 300), () {
          _resetAndSearch();
        });
      }
    });
  }

  Future<void> _loadReports() async {
    _currentPage = 1;
    await _reportController.fetchReports(
      status: _mapFilterToStatus(_selectedFilter),
      priority: _mapFilterToPriority(_selectedFilter),
      page: _currentPage,
    );
  }

  Future<void> _loadMoreReports() async {
    if (_isLoadingMore || _reportController.isLoadingReports) return;
    
    final pagination = _reportController.pagination;
    if (pagination != null && _currentPage < pagination['last_page']) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });

      await _reportController.fetchReports(
        status: _mapFilterToStatus(_selectedFilter),
        priority: _mapFilterToPriority(_selectedFilter),
        page: _currentPage,
        append: true,
      );

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _resetAndSearch() async {
    _currentPage = 1;
    await _reportController.fetchReports(
      status: _mapFilterToStatus(_selectedFilter),
      priority: _mapFilterToPriority(_selectedFilter),
      page: _currentPage,
    );
  }

  String? _mapFilterToStatus(SignalementFilter filter) {
    switch (filter) {
      case SignalementFilter.nouveaux:
        return 'pending';
      case SignalementFilter.enCours:
        return 'in_progress';
      case SignalementFilter.resolus:
        return 'resolved';
      default:
        return null;
    }
  }

  String? _mapFilterToPriority(SignalementFilter filter) {
    switch (filter) {
      case SignalementFilter.urgents:
        return 'urgent';
      default:
        return null;
    }
  }

  List<ReportModel> get _filteredReports {
    return _reportController.getFilteredReports(
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onFilterChanged(SignalementFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _resetAndSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header fixe
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: const AppHeader(
                title: 'Signalements',
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadReports,
                child: Consumer<ReportController>(
                  builder: (context, reportController, child) {
                    if (reportController.isLoadingReports && reportController.reports.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFEF4444),
                        ),
                      );
                    }

                    if (reportController.loadingStatus == ReportLoadingStatus.error) {
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
                              reportController.loadingErrorMessage ?? 'Une erreur est survenue',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                fontFamily: 'Nunito',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadReports,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un signalement...',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF6B7280),
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
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
                              color: const Color(0xFFEF4444),
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
                                context.go('/signalements/ajouter');
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
                            _buildFilterChip('Tous', SignalementFilter.tous),
                            const SizedBox(width: 8),
                            _buildFilterChip('En attente', SignalementFilter.nouveaux),
                            const SizedBox(width: 8),
                            _buildFilterChip('En cours', SignalementFilter.enCours),
                            const SizedBox(width: 8),
                            _buildFilterChip('Résolus', SignalementFilter.resolus),
                            const SizedBox(width: 8),
                            _buildFilterChip('Urgents', SignalementFilter.urgents),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Liste des signalements
                      if (_filteredReports.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Aucun signalement trouvé',
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
                            ..._filteredReports.map((report) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildSignalementCard(report),
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
                                        color: Color(0xFFEF4444),
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
                            if (reportController.pagination != null && !_isLoadingMore)
                              Container(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  '${reportController.pagination!['from']} - ${reportController.pagination!['to']} sur ${reportController.pagination!['total']} signalements',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalementCard(ReportModel report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: report.priority == PriorityLevel.urgent
            ? Border.all(color: report.priorityColor, width: 2)
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
                  color: report.priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  report.typeIcon,
                  color: report.priorityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
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
                          report.formattedDate,
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
                  color: report.priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.priorityText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: report.priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            report.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Localisation
          if (report.place != null) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.place!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Auteur et statut
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      report.anonymous ? Icons.visibility_off : Icons.person,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      report.authorText,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: report.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: report.statusColor,
                  ),
                ),
              ),
            ],
          ),
          
          // Images attachées
          if (report.hasImages) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: report.images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < report.images.length - 1 ? 8 : 0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          report.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: Colors.grey.shade400,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Image',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.photo_camera,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  '${report.imageCount} photo(s) attachée(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SignalementFilter filter) {
    final isSelected = _selectedFilter == filter;
    Color chipColor = const Color(0xFF4F46E5);
    
    if (filter == SignalementFilter.urgents) {
      chipColor = const Color(0xFFEF4444);
    }
    
    return GestureDetector(
      onTap: () => _onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : const Color(0xFFE5E7EB),
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
}
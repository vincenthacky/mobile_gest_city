import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ajouter_information_page.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/sync_notification.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../controllers/sync_information_controller.dart';
import '../../models/information_model.dart';

enum InformationFilter { tous, recents, security, drugs, suspect, nuisance, infrastructure, autres }


class CadreDeViePage extends StatefulWidget {
  const CadreDeViePage({super.key});

  @override
  State<CadreDeViePage> createState() => _CadreDeViePageState();
}

class _CadreDeViePageState extends State<CadreDeViePage> {
  final TextEditingController _searchController = TextEditingController();
  InformationFilter _selectedFilter = InformationFilter.tous;
  late SyncInformationController _informationController;
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _informationController = Provider.of<SyncInformationController>(context, listen: false);
    _connectivityService = ConnectivityService();
    
    _setupConnectivityListener();
    
    // Démarrer le monitoring de connectivité
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivityService.startMonitoring();
    });
    
    // Charger les informations après que le widget soit complètement initialisé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInformations();
    });
  }

  void _setupConnectivityListener() {
    _connectivityService.addListener(() {
      if (_connectivityService.isConnected) {
        // Quand la connexion revient, déclencher une synchronisation
        debugPrint('🌐 [CADRE DE VIE] Connexion détectée - synchronisation automatique');
        // Synchronisation avec notification
        _informationController.syncInformations(showNotifications: true);
      } else {
        // Afficher notification hors ligne si on a des données en cache
        if (_informationController.allInformations.isNotEmpty) {
          _informationController.showOfflineNotification();
        }
      }
    });
  }

  Future<void> _loadInformations() async {
    // Si pas de connexion et qu'on a du cache, afficher notification
    if (!_connectivityService.isConnected && _informationController.allInformations.isNotEmpty) {
      _informationController.showOfflineNotification();
    }
    
    await _informationController.fetchInformations(
      useSync: true, // Activer la synchronisation intelligente
      showNotifications: _connectivityService.isConnected, // Afficher notifications si en ligne
    );
  }


  List<InformationModel> get _filteredInformations {
    final allInformations = _informationController.informations;
    List<InformationModel> filtered = allInformations.where((information) {
      final matchesSearch = _searchController.text.isEmpty ||
          information.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          information.description.toLowerCase().contains(_searchController.text.toLowerCase());
      
      bool matchesFilter = true;
      switch (_selectedFilter) {
        case InformationFilter.tous:
          matchesFilter = true;
          break;
        case InformationFilter.recents:
          matchesFilter = information.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));
          break;
        case InformationFilter.security:
          matchesFilter = information.reportType == InformationType.security;
          break;
        case InformationFilter.drugs:
          matchesFilter = information.reportType == InformationType.drugs;
          break;
        case InformationFilter.suspect:
          matchesFilter = information.reportType == InformationType.suspect;
          break;
        case InformationFilter.nuisance:
          matchesFilter = information.reportType == InformationType.nuisance;
          break;
        case InformationFilter.infrastructure:
          matchesFilter = information.reportType == InformationType.infrastructure;
          break;
        case InformationFilter.autres:
          matchesFilter = information.reportType == InformationType.other;
          break;
      }
      
      return matchesSearch && matchesFilter;
    }).toList();

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _connectivityService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                title: 'Cadre de vie',
              ),
            ),
            
            // Notification de synchronisation
            Consumer<SyncInformationController>(
              builder: (context, informationController, child) {
                return SyncNotification(
                  type: informationController.notificationType,
                  customMessage: informationController.notificationMessage,
                  onDismiss: () {
                    informationController.clearNotification();
                  },
                );
              },
            ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _informationController.refreshInformations();
                },
                color: const Color(0xFF10B981),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                                onChanged: (value) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Rechercher une information...',
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
                              color: const Color(0xFF10B981),
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
                                    builder: (context) => const AjouterInformationPage(),
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
                      
                      // Filtres
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip('Tous', InformationFilter.tous, Icons.apps),
                            const SizedBox(width: 8),
                            _buildFilterChip('Récents', InformationFilter.recents, Icons.schedule),
                            const SizedBox(width: 8),
                            _buildFilterChip('Sécurité', InformationFilter.security, Icons.security),
                            const SizedBox(width: 8),
                            _buildFilterChip('Drogue', InformationFilter.drugs, Icons.medical_services),
                            const SizedBox(width: 8),
                            _buildFilterChip('Suspect', InformationFilter.suspect, Icons.person_search),
                            const SizedBox(width: 8),
                            _buildFilterChip('Nuisance', InformationFilter.nuisance, Icons.volume_up),
                            const SizedBox(width: 8),
                            _buildFilterChip('Infrastructure', InformationFilter.infrastructure, Icons.construction),
                            const SizedBox(width: 8),
                            _buildFilterChip('Autres', InformationFilter.autres, Icons.more_horiz),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Liste des informations
                      Consumer<SyncInformationController>(
                        builder: (context, controller, child) {
                          if (controller.isLoadingInformations) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF10B981),
                              ),
                            );
                          }

                          if (controller.loadingErrorMessage != null) {
                            return Container(
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
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red.shade400,
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
                                    controller.loadingErrorMessage!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                      fontFamily: 'Nunito',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          final filteredInformations = _filteredInformations;
                          
                          if (filteredInformations.isEmpty) {
                            return Container(
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
                                    'Aucune information trouvée',
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
                            );
                          }
                          
                          return Column(
                            children: filteredInformations.map((information) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildInformationCard(information),
                              );
                            }).toList(),
                          );
                        },
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

  Widget _buildFilterChip(String label, InformationFilter filter, IconData icon) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF10B981) 
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF374151),
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard(InformationModel information) {
    return GestureDetector(
      onTap: () => _showInformationDetails(information),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: information.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    information.typeIcon,
                    color: information.statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        information.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 11,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              information.authorText,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontFamily: 'Nunito',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: information.priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              information.priorityText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: information.priorityColor,
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
            
            Text(
              information.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
                fontFamily: 'Nunito',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                if (information.place != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          information.place!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        information.formattedDate,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (information.hasImages) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7280).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${information.imageCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _showInformationDetails(information),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Voir plus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInformationDetails(InformationModel information) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final screenHeight = screenSize.height;
        final screenWidth = screenSize.width;
        
        // Hauteur fixe: 83% pour tous les écrans
        final modalHeight = screenHeight * 0.83;
        
        return Container(
          height: modalHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(screenWidth > 500 ? 24 : 20),
              topRight: Radius.circular(screenWidth > 500 ? 24 : 20),
            ),
          ),
        child: Column(
          children: [
            Container(
              width: screenWidth * 0.1, // 10% de la largeur d'écran
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
                  screenWidth > 500 ? 20 : 16, // Padding adaptatif
                  0, 
                  screenWidth > 500 ? 20 : 16, 
                  screenHeight > 700 ? 20 : 16
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Première ligne: Icône et titre avec auteur
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth > 500 ? 12 : 10),
                              decoration: BoxDecoration(
                                color: information.statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(screenWidth > 500 ? 12 : 10),
                              ),
                              child: Icon(
                                information.typeIcon,
                                color: information.statusColor,
                                size: screenWidth > 500 ? 24 : 20,
                              ),
                            ),
                            SizedBox(width: screenWidth > 500 ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    information.title,
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
                                    'Par ${information.authorText}',
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
                        // Deuxième ligne: Statut aligné à droite
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: information.statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                information.statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: information.statusColor,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                          ],
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
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            information.description,
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
                            'Informations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (information.place != null)
                            _buildInfoRow('📍', 'Lieu', information.place!),
                          _buildInfoRow('📋', 'Type', information.typeText),
                          _buildInfoRow('🔥', 'Priorité', information.priorityText),
                          _buildInfoRow('📊', 'Statut', information.statusText),
                          _buildInfoRow('⏰', 'Publié', information.formattedDate),
                          _buildInfoRow('👤', 'Auteur', information.authorText),
                        ],
                      ),
                    ),
                    
                    if (information.hasImages) ...[
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
                            Text(
                              'Photos (${information.imageCount})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: information.imageCount,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    margin: EdgeInsets.only(
                                      right: index < information.imageCount - 1 ? 12 : 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                      image: information.images.isNotEmpty && index < information.images.length
                                          ? DecorationImage(
                                              image: NetworkImage(information.images[index]),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: information.images.isEmpty || index >= information.images.length
                                        ? const Icon(
                                            Icons.image,
                                            size: 40,
                                            color: Color(0xFF6B7280),
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ),
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
      },
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
}
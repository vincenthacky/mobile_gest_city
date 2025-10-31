import 'package:flutter/material.dart';
import 'ajouter_activite_page.dart';
import '../../../../core/widgets/app_header.dart';

enum ActivityFilter { tous, recents, evenements, mariages, naissances, deces, autres }

enum ActivityType { mariage, naissance, deces, reunion, fete, travaux, visite, autre }

class CadreDeVieActivity {
  final int id;
  final String titre;
  final String description;
  final ActivityType type;
  final DateTime dateCreation;
  final DateTime? dateEvenement;
  final String? lieu;
  final List<String>? photos;
  final String auteur;
  final bool isPublic;

  CadreDeVieActivity({
    required this.id,
    required this.titre,
    required this.description,
    required this.type,
    required this.dateCreation,
    this.dateEvenement,
    this.lieu,
    this.photos,
    required this.auteur,
    this.isPublic = true,
  });

  IconData get typeIcon {
    switch (type) {
      case ActivityType.mariage:
        return Icons.favorite;
      case ActivityType.naissance:
        return Icons.child_care;
      case ActivityType.deces:
        return Icons.local_florist;
      case ActivityType.reunion:
        return Icons.groups;
      case ActivityType.fete:
        return Icons.celebration;
      case ActivityType.travaux:
        return Icons.construction;
      case ActivityType.visite:
        return Icons.visibility;
      case ActivityType.autre:
        return Icons.event;
    }
  }

  Color get typeColor {
    switch (type) {
      case ActivityType.mariage:
        return const Color(0xFFEC4899); // Rose
      case ActivityType.naissance:
        return const Color(0xFF10B981); // Vert
      case ActivityType.deces:
        return const Color(0xFF6B7280); // Gris
      case ActivityType.reunion:
        return const Color(0xFF3B82F6); // Bleu
      case ActivityType.fete:
        return const Color(0xFFF59E0B); // Orange
      case ActivityType.travaux:
        return const Color(0xFFEF4444); // Rouge
      case ActivityType.visite:
        return const Color(0xFF8B5CF6); // Violet
      case ActivityType.autre:
        return const Color(0xFF6B7280); // Gris
    }
  }

  String get typeText {
    switch (type) {
      case ActivityType.mariage:
        return 'Mariage';
      case ActivityType.naissance:
        return 'Naissance';
      case ActivityType.deces:
        return 'Décès';
      case ActivityType.reunion:
        return 'Réunion';
      case ActivityType.fete:
        return 'Fête';
      case ActivityType.travaux:
        return 'Travaux';
      case ActivityType.visite:
        return 'Visite';
      case ActivityType.autre:
        return 'Autre';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(dateCreation);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${dateCreation.day}/${dateCreation.month}/${dateCreation.year}';
    }
  }
}

class CadreDeViePage extends StatefulWidget {
  const CadreDeViePage({super.key});

  @override
  State<CadreDeViePage> createState() => _CadreDeViePageState();
}

class _CadreDeViePageState extends State<CadreDeViePage> {
  final TextEditingController _searchController = TextEditingController();
  ActivityFilter _selectedFilter = ActivityFilter.tous;

  final List<CadreDeVieActivity> _activities = [
    CadreDeVieActivity(
      id: 1,
      titre: 'Mariage de Marie et Jean',
      description: 'Célébration du mariage de Marie Dupont et Jean Martin dans la rue des Roses. Grande fête prévue avec tous les voisins !',
      type: ActivityType.mariage,
      dateCreation: DateTime.now().subtract(const Duration(days: 2)),
      dateEvenement: DateTime.now().add(const Duration(days: 15)),
      lieu: 'Rue des Roses, n°15',
      auteur: 'Sophie Bernard',
      photos: ['mariage1.jpg'],
    ),
    CadreDeVieActivity(
      id: 2,
      titre: 'Naissance de petit Lucas',
      description: 'Félicitations à la famille Moreau pour la naissance de leur petit Lucas ! Un nouveau membre de notre communauté.',
      type: ActivityType.naissance,
      dateCreation: DateTime.now().subtract(const Duration(days: 1)),
      lieu: 'Avenue des Lilas, n°8',
      auteur: 'Pierre Lefebvre',
    ),
    CadreDeVieActivity(
      id: 3,
      titre: 'Travaux de rénovation rue Principale',
      description: 'Début des travaux de réfection de la chaussée rue Principale. Circulation perturbée pendant 2 semaines.',
      type: ActivityType.travaux,
      dateCreation: DateTime.now().subtract(const Duration(days: 3)),
      dateEvenement: DateTime.now().add(const Duration(days: 1)),
      lieu: 'Rue Principale',
      auteur: 'Mairie',
      photos: ['travaux1.jpg', 'travaux2.jpg'],
    ),
    CadreDeVieActivity(
      id: 4,
      titre: 'Fête de quartier place centrale',
      description: 'Organisation d\'une grande fête de quartier avec musique, stands et activités pour toute la famille.',
      type: ActivityType.fete,
      dateCreation: DateTime.now().subtract(const Duration(days: 5)),
      dateEvenement: DateTime.now().add(const Duration(days: 10)),
      lieu: 'Place Centrale',
      auteur: 'Comité des fêtes',
      photos: ['fete1.jpg'],
    ),
    CadreDeVieActivity(
      id: 5,
      titre: 'Visite du député',
      description: 'Visite officielle du député local pour rencontrer les habitants et discuter des projets d\'aménagement.',
      type: ActivityType.visite,
      dateCreation: DateTime.now().subtract(const Duration(days: 7)),
      dateEvenement: DateTime.now().subtract(const Duration(days: 1)),
      lieu: 'Salle communale',
      auteur: 'Secrétariat mairie',
    ),
    CadreDeVieActivity(
      id: 6,
      titre: 'Décès de Madame Petit',
      description: 'Nos pensées vont à la famille de Madame Marguerite Petit, figure respectée de notre communauté.',
      type: ActivityType.deces,
      dateCreation: DateTime.now().subtract(const Duration(days: 4)),
      lieu: 'Rue des Érables, n°22',
      auteur: 'Famille Petit',
    ),
  ];

  List<CadreDeVieActivity> get _filteredActivities {
    List<CadreDeVieActivity> filtered = _activities.where((activity) {
      final matchesSearch = _searchController.text.isEmpty ||
          activity.titre.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          activity.description.toLowerCase().contains(_searchController.text.toLowerCase());
      
      bool matchesFilter = true;
      switch (_selectedFilter) {
        case ActivityFilter.tous:
          matchesFilter = true;
          break;
        case ActivityFilter.recents:
          matchesFilter = activity.dateCreation.isAfter(DateTime.now().subtract(const Duration(days: 7)));
          break;
        case ActivityFilter.evenements:
          matchesFilter = activity.dateEvenement != null;
          break;
        case ActivityFilter.mariages:
          matchesFilter = activity.type == ActivityType.mariage;
          break;
        case ActivityFilter.naissances:
          matchesFilter = activity.type == ActivityType.naissance;
          break;
        case ActivityFilter.deces:
          matchesFilter = activity.type == ActivityType.deces;
          break;
        case ActivityFilter.autres:
          matchesFilter = ![ActivityType.mariage, ActivityType.naissance, ActivityType.deces].contains(activity.type);
          break;
      }
      
      return matchesSearch && matchesFilter;
    }).toList();

    // Trier par date de création (plus récent en premier)
    filtered.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                title: 'Cadre de vie',
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                },
                color: const Color(0xFF10B981),
                child: SingleChildScrollView(
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
                                onChanged: (value) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Rechercher une activité...',
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
                              color: const Color(0xFF10B981),
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
                                    builder: (context) => const AjouterActivitePage(),
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
                      
                      // Filtres
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip('Tous', ActivityFilter.tous, Icons.apps),
                            const SizedBox(width: 12),
                            _buildFilterChip('Récents', ActivityFilter.recents, Icons.schedule),
                            const SizedBox(width: 12),
                            _buildFilterChip('Événements', ActivityFilter.evenements, Icons.event),
                            const SizedBox(width: 12),
                            _buildFilterChip('Mariages', ActivityFilter.mariages, Icons.favorite),
                            const SizedBox(width: 12),
                            _buildFilterChip('Naissances', ActivityFilter.naissances, Icons.child_care),
                            const SizedBox(width: 12),
                            _buildFilterChip('Décès', ActivityFilter.deces, Icons.local_florist),
                            const SizedBox(width: 12),
                            _buildFilterChip('Autres', ActivityFilter.autres, Icons.more_horiz),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Liste des activités
                      if (_filteredActivities.isEmpty)
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
                                'Aucune activité trouvée',
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
                          children: _filteredActivities.map((activity) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildActivityCard(activity),
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

  Widget _buildFilterChip(String label, ActivityFilter filter, IconData icon) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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

  Widget _buildActivityCard(CadreDeVieActivity activity) {
    return GestureDetector(
      onTap: () => _showActivityDetails(activity),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: activity.typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    activity.typeIcon,
                    color: activity.typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.titre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            activity.auteur,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: activity.typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activity.typeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: activity.typeColor,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              activity.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
                fontFamily: 'Nunito',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                if (activity.lieu != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activity.lieu!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activity.formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (activity.photos != null && activity.photos!.isNotEmpty) ...[
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
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.photos!.length}',
                          style: const TextStyle(
                            fontSize: 12,
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
            
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showActivityDetails(activity),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                        fontSize: 14,
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

  void _showActivityDetails(CadreDeVieActivity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                            color: activity.typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            activity.typeIcon,
                            color: activity.typeColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.titre,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Par ${activity.auteur}',
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
                            color: activity.typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            activity.typeText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: activity.typeColor,
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
                            activity.description,
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
                          if (activity.lieu != null)
                            _buildInfoRow('📍', 'Lieu', activity.lieu!),
                          if (activity.dateEvenement != null)
                            _buildInfoRow('📅', 'Date de l\'événement', 
                              '${activity.dateEvenement!.day}/${activity.dateEvenement!.month}/${activity.dateEvenement!.year}'),
                          _buildInfoRow('⏰', 'Publié', activity.formattedDate),
                          _buildInfoRow('👤', 'Auteur', activity.auteur),
                        ],
                      ),
                    ),
                    
                    if (activity.photos != null && activity.photos!.isNotEmpty) ...[
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
                              'Photos (${activity.photos!.length})',
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
                                itemCount: activity.photos!.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    margin: EdgeInsets.only(
                                      right: index < activity.photos!.length - 1 ? 12 : 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Color(0xFF6B7280),
                                    ),
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
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SignalementFilter { tous, nouveaux, enCours, resolus, urgents }

enum SignalementType { securite, drogue, suspect, nuisance, infrastructure, autre }

enum SignalementStatus { nouveau, enCours, resolu }

enum PriorityLevel { faible, moyen, eleve, urgent }

class Signalement {
  final int id;
  final String titre;
  final String description;
  final SignalementType type;
  final SignalementStatus status;
  final PriorityLevel priority;
  final DateTime dateCreation;
  final String? location;
  final List<String>? photos;
  final String? video;
  final String auteur;

  Signalement({
    required this.id,
    required this.titre,
    required this.description,
    required this.type,
    required this.status,
    required this.priority,
    required this.dateCreation,
    this.location,
    this.photos,
    this.video,
    required this.auteur,
  });

  IconData get typeIcon {
    switch (type) {
      case SignalementType.securite:
        return Icons.security;
      case SignalementType.drogue:
        return Icons.medical_services;
      case SignalementType.suspect:
        return Icons.person_search;
      case SignalementType.nuisance:
        return Icons.volume_up;
      case SignalementType.infrastructure:
        return Icons.construction;
      case SignalementType.autre:
        return Icons.report;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case PriorityLevel.faible:
        return const Color(0xFF10B981);
      case PriorityLevel.moyen:
        return const Color(0xFFF59E0B);
      case PriorityLevel.eleve:
        return const Color(0xFFEF4444);
      case PriorityLevel.urgent:
        return const Color(0xFF7C2D12);
    }
  }

  String get priorityText {
    switch (priority) {
      case PriorityLevel.faible:
        return 'Faible';
      case PriorityLevel.moyen:
        return 'Moyen';
      case PriorityLevel.eleve:
        return 'Élevé';
      case PriorityLevel.urgent:
        return 'Urgent';
    }
  }
}

class SignalementsPage extends StatefulWidget {
  const SignalementsPage({super.key});

  @override
  State<SignalementsPage> createState() => _SignalementsPageState();
}

class _SignalementsPageState extends State<SignalementsPage> {
  final TextEditingController _searchController = TextEditingController();
  SignalementFilter _selectedFilter = SignalementFilter.tous;

  final List<Signalement> _signalements = [
    Signalement(
      id: 1,
      titre: 'Enfants fumant de la drogue',
      description: 'J\'ai vu des enfants en train de fumer de la drogue derrière ma maison. C\'est très inquiétant pour la sécurité du quartier.',
      type: SignalementType.drogue,
      status: SignalementStatus.nouveau,
      priority: PriorityLevel.urgent,
      dateCreation: DateTime.now().subtract(const Duration(hours: 2)),
      location: 'Derrière résidence A, bloc 3',
      photos: ['../../enfant_fumant.jpg'],
      auteur: 'Marie Dupont',
    ),
    Signalement(
      id: 2,
      titre: 'Individu suspect dans la cité',
      description: 'J\'ai aperçu un gars très bizarre dans la cité qui rôdait autour des voitures et regardait par les fenêtres.',
      type: SignalementType.suspect,
      status: SignalementStatus.enCours,
      priority: PriorityLevel.eleve,
      dateCreation: DateTime.now().subtract(const Duration(hours: 5)),
      location: 'Parking central',
      photos: ['../../individue_suspect.jpg'],
      auteur: 'Ahmed Ben Ali',
    ),
    Signalement(
      id: 3,
      titre: 'Bruit excessif la nuit',
      description: 'Musique très forte jusqu\'à 3h du matin tous les weekends. Impossible de dormir avec les enfants.',
      type: SignalementType.nuisance,
      status: SignalementStatus.nouveau,
      priority: PriorityLevel.moyen,
      dateCreation: DateTime.now().subtract(const Duration(hours: 12)),
      location: 'Appartement 2B, immeuble 5',
      auteur: 'Fatima Alaoui',
    ),
    Signalement(
      id: 4,
      titre: 'Éclairage public défaillant',
      description: 'Plusieurs lampadaires ne fonctionnent plus dans l\'allée principale, rendant le passage dangereux la nuit.',
      type: SignalementType.infrastructure,
      status: SignalementStatus.resolu,
      priority: PriorityLevel.moyen,
      dateCreation: DateTime.now().subtract(const Duration(days: 3)),
      location: 'Allée principale, zone 2',
      auteur: 'Jean Kouassi',
    ),
    Signalement(
      id: 5,
      titre: 'Agression près du marché',
      description: 'Une dame a été agressée hier soir près du petit marché. Il faut plus de sécurité dans cette zone.',
      type: SignalementType.securite,
      status: SignalementStatus.enCours,
      priority: PriorityLevel.urgent,
      dateCreation: DateTime.now().subtract(const Duration(days: 1)),
      location: 'Près du marché, rue principale',
      auteur: 'Koffi Assan',
    ),
  ];

  List<Signalement> get _filteredSignalements {
    List<Signalement> filtered = _signalements.where((signalement) {
      // Filtre par recherche
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        if (!signalement.titre.toLowerCase().contains(searchTerm) &&
            !signalement.description.toLowerCase().contains(searchTerm) &&
            !signalement.location!.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }

      // Filtre par statut
      switch (_selectedFilter) {
        case SignalementFilter.tous:
          return true;
        case SignalementFilter.nouveaux:
          return signalement.status == SignalementStatus.nouveau;
        case SignalementFilter.enCours:
          return signalement.status == SignalementStatus.enCours;
        case SignalementFilter.resolus:
          return signalement.status == SignalementStatus.resolu;
        case SignalementFilter.urgents:
          return signalement.priority == PriorityLevel.urgent;
      }
    }).toList();

    // Trier par priorité et date (les plus récents et urgents en premier)
    filtered.sort((a, b) {
      // D'abord par priorité
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      
      // Puis par date
      return b.dateCreation.compareTo(a.dateCreation);
    });
    
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() {});
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        'Signalements',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_filteredSignalements.length} signalement(s)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
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
                                onChanged: (value) {
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un signalement',
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
                            _buildFilterChip('Nouveaux', SignalementFilter.nouveaux),
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
                      if (_filteredSignalements.isEmpty)
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
                          children: _filteredSignalements.map((signalement) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildSignalementCard(signalement),
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

  Widget _buildSignalementCard(Signalement signalement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: signalement.priority == PriorityLevel.urgent
            ? Border.all(color: signalement.priorityColor, width: 2)
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
                  color: signalement.priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  signalement.typeIcon,
                  color: signalement.priorityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signalement.titre,
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
                          _formatDate(signalement.dateCreation),
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
                  color: signalement.priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  signalement.priorityText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: signalement.priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            signalement.description,
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
          if (signalement.location != null) ...[
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
                    signalement.location!,
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
                      Icons.person,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Par ${signalement.auteur}',
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
                  color: _getStatusColor(signalement.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusText(signalement.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(signalement.status),
                  ),
                ),
              ),
            ],
          ),
          
          // Images attachées
          if (signalement.photos != null && signalement.photos!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: signalement.photos!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < signalement.photos!.length - 1 ? 8 : 0,
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
                        child: Image.asset(
                          signalement.photos![index],
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
                  '${signalement.photos!.length} photo(s) attachée(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
          
          // Indicateur vidéo
          if (signalement.video != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.videocam,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  'Vidéo attachée',
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
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getStatusColor(SignalementStatus status) {
    switch (status) {
      case SignalementStatus.nouveau:
        return const Color(0xFF3B82F6);
      case SignalementStatus.enCours:
        return const Color(0xFFF59E0B);
      case SignalementStatus.resolu:
        return const Color(0xFF10B981);
    }
  }

  String _getStatusText(SignalementStatus status) {
    switch (status) {
      case SignalementStatus.nouveau:
        return 'Nouveau';
      case SignalementStatus.enCours:
        return 'En cours';
      case SignalementStatus.resolu:
        return 'Résolu';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ProjectFilter { tous, nonVoter, dejaVoter, enCours, finir }

enum VoteStatus { nonVote, ouiVote, nonVote2 }

class Projet {
  final int id;
  final String titre;
  final String description;
  final DateTime dateDebut;
  final DateTime dateCloture;
  final VoteStatus voteStatus;
  final int votesOui;
  final int votesNon;
  final bool isActive;
  final IconData icon;
  final Color color;

  Projet({
    required this.id,
    required this.titre,
    required this.description,
    required this.dateDebut,
    required this.dateCloture,
    required this.voteStatus,
    required this.votesOui,
    required this.votesNon,
    required this.isActive,
    required this.icon,
    required this.color,
  });

  bool get isFinished => DateTime.now().isAfter(dateCloture);
  bool get isActive2 => DateTime.now().isBefore(dateCloture) && DateTime.now().isAfter(dateDebut);
  int get totalVotes => votesOui + votesNon;
  double get pourcentageOui => totalVotes > 0 ? votesOui / totalVotes : 0.0;
}

class ProjetsPage extends StatefulWidget {
  const ProjetsPage({super.key});

  @override
  State<ProjetsPage> createState() => _ProjetsPageState();
}

class _ProjetsPageState extends State<ProjetsPage> {
  final TextEditingController _searchController = TextEditingController();
  ProjectFilter _selectedFilter = ProjectFilter.tous;

  final List<Projet> _projets = [
    Projet(
      id: 1,
      titre: 'Clôture du terrain',
      description: 'Construction d\'une clôture autour du terrain communautaire pour sécuriser l\'espace et délimiter les propriétés',
      dateDebut: DateTime.now().subtract(const Duration(days: 5)),
      dateCloture: DateTime.now().add(const Duration(days: 10)),
      voteStatus: VoteStatus.nonVote,
      votesOui: 25,
      votesNon: 8,
      isActive: true,
      icon: Icons.fence,
      color: const Color(0xFF3B82F6),
    ),
    Projet(
      id: 2,
      titre: 'Balayage quotidien',
      description: 'Mise en place d\'un système de balayage quotidien des rues du quartier avec équipe dédiée',
      dateDebut: DateTime.now().subtract(const Duration(days: 3)),
      dateCloture: DateTime.now().add(const Duration(days: 7)),
      voteStatus: VoteStatus.ouiVote,
      votesOui: 42,
      votesNon: 15,
      isActive: true,
      icon: Icons.cleaning_services,
      color: const Color(0xFF10B981),
    ),
    Projet(
      id: 3,
      titre: 'Éclairage public',
      description: 'Installation de lampadaires solaires le long des principales artères du quartier',
      dateDebut: DateTime.now().subtract(const Duration(days: 1)),
      dateCloture: DateTime.now().add(const Duration(days: 15)),
      voteStatus: VoteStatus.nonVote,
      votesOui: 18,
      votesNon: 22,
      isActive: true,
      icon: Icons.lightbulb,
      color: const Color(0xFFF59E0B),
    ),
    Projet(
      id: 4,
      titre: 'Point d\'eau communautaire',
      description: 'Construction d\'un point d\'eau potable accessible à tous les résidents du quartier',
      dateDebut: DateTime.now().subtract(const Duration(days: 15)),
      dateCloture: DateTime.now().subtract(const Duration(days: 2)),
      voteStatus: VoteStatus.ouiVote,
      votesOui: 67,
      votesNon: 12,
      isActive: false,
      icon: Icons.water_drop,
      color: const Color(0xFF06B6D4),
    ),
    Projet(
      id: 5,
      titre: 'Aire de jeux enfants',
      description: 'Aménagement d\'une aire de jeux sécurisée pour les enfants du quartier avec équipements modernes',
      dateDebut: DateTime.now().add(const Duration(days: 5)),
      dateCloture: DateTime.now().add(const Duration(days: 20)),
      voteStatus: VoteStatus.nonVote,
      votesOui: 0,
      votesNon: 0,
      isActive: false,
      icon: Icons.park,
      color: const Color(0xFFEC4899),
    ),
  ];

  List<Projet> get _filteredProjets {
    List<Projet> filtered = _projets.where((projet) {
      // Filtre par recherche
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        if (!projet.titre.toLowerCase().contains(searchTerm) &&
            !projet.description.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }

      // Filtre par statut
      switch (_selectedFilter) {
        case ProjectFilter.tous:
          return true;
        case ProjectFilter.nonVoter:
          return projet.voteStatus == VoteStatus.nonVote;
        case ProjectFilter.dejaVoter:
          return projet.voteStatus != VoteStatus.nonVote;
        case ProjectFilter.enCours:
          return projet.isActive2;
        case ProjectFilter.finir:
          return projet.isFinished;
      }
    }).toList();

    // Trier par date de clôture (les plus proches en premier)
    filtered.sort((a, b) => a.dateCloture.compareTo(b.dateCloture));
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
                  // Simulation d'un rafraîchissement
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
                                onChanged: (value) {
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un projet',
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
                            _buildFilterChip('En cours', ProjectFilter.enCours),
                            const SizedBox(width: 8),
                            _buildFilterChip('Fini', ProjectFilter.finir),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Liste des projets
                      if (_filteredProjets.isEmpty)
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
                          children: _filteredProjets.map((projet) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildProjetCard(projet),
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

  Widget _buildProjetCard(Projet projet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: projet.voteStatus != VoteStatus.nonVote
            ? Border.all(color: projet.color.withValues(alpha: 0.3), width: 1.5)
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
                  color: projet.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  projet.icon,
                  color: projet.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projet.titre,
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
                          'Clôture: ${projet.dateCloture.day}/${projet.dateCloture.month}/${projet.dateCloture.year}',
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
              if (projet.isFinished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Terminé',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                )
              else if (projet.isActive2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'En cours',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'À venir',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            projet.description,
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
          if (projet.totalVotes > 0) ...[
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
                        '${projet.votesOui} votes',
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
                        '${projet.votesNon} votes',
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
                        '${(projet.pourcentageOui * 100).round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: projet.color,
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
                  if (projet.pourcentageOui > 0)
                    Container(
                      width: (MediaQuery.of(context).size.width - 80) * projet.pourcentageOui,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  if (projet.pourcentageOui < 1)
                    Container(
                      width: (MediaQuery.of(context).size.width - 80) * (1 - projet.pourcentageOui),
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
          if (!projet.isFinished && projet.isActive2) ...[
            if (projet.voteStatus == VoteStatus.nonVote) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _vote(projet, true),
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
                      onPressed: () => _vote(projet, false),
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
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: projet.voteStatus == VoteStatus.ouiVote
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      projet.voteStatus == VoteStatus.ouiVote
                          ? Icons.thumb_up
                          : Icons.thumb_down,
                      size: 18,
                      color: projet.voteStatus == VoteStatus.ouiVote
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vous avez voté ${projet.voteStatus == VoteStatus.ouiVote ? "OUI" : "NON"}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: projet.voteStatus == VoteStatus.ouiVote
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (!projet.isActive2 && !projet.isFinished) ...[
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
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
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

  void _vote(Projet projet, bool isOui) {
    setState(() {
      // Trouver le projet dans la liste et mettre à jour son statut de vote
      final index = _projets.indexWhere((p) => p.id == projet.id);
      if (index != -1) {
        _projets[index] = Projet(
          id: projet.id,
          titre: projet.titre,
          description: projet.description,
          dateDebut: projet.dateDebut,
          dateCloture: projet.dateCloture,
          voteStatus: isOui ? VoteStatus.ouiVote : VoteStatus.nonVote2,
          votesOui: projet.votesOui + (isOui ? 1 : 0),
          votesNon: projet.votesNon + (isOui ? 0 : 1),
          isActive: projet.isActive,
          icon: projet.icon,
          color: projet.color,
        );
      }
    });

    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vote enregistré : ${isOui ? "OUI" : "NON"}'),
        backgroundColor: isOui ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
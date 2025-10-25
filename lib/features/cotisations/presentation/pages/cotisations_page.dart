import 'package:flutter/material.dart';
import 'preuve_paiement_page.dart';
import 'qr_paiement_page.dart';

class CotisationsPage extends StatefulWidget {
  const CotisationsPage({super.key});

  @override
  State<CotisationsPage> createState() => _CotisationsPageState();
}

class _CotisationsPageState extends State<CotisationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Toutes';

  // Données d'exemple des cotisations
  final List<Map<String, dynamic>> _cotisations = [
    {
      'id': 1,
      'title': 'Nouvelle école',
      'dateDebut': '2 Fév 2025',
      'dateFin': '31 Déc 2025',
      'montantTotal': 50000,
      'montantPaye': 30000,
      'montantPersonnel': 2000,
      'hasUserPaid': false,
      'personnesPaye': 15,
      'totalPersonnes': 25,
      'icon': Icons.school,
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': 2,
      'title': 'Festival annuel',
      'dateDebut': '15 Jan 2025',
      'dateFin': '20 Fév 2025',
      'montantTotal': 30000,
      'montantPaye': 18000,
      'montantPersonnel': 1500,
      'hasUserPaid': true,
      'personnesPaye': 12,
      'totalPersonnes': 20,
      'icon': Icons.celebration,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 3,
      'title': 'Obsèque Famille Allain',
      'dateDebut': '28 Jan 2025',
      'dateFin': '15 Fév 2025',
      'montantTotal': 100000,
      'montantPaye': 85000,
      'montantPersonnel': 5000,
      'hasUserPaid': false,
      'personnesPaye': 17,
      'totalPersonnes': 20,
      'icon': Icons.group,
      'color': const Color(0xFFEC4899),
    },
    {
      'id': 4,
      'title': 'Rénovation mosquée',
      'dateDebut': '10 Jan 2025',
      'dateFin': '30 Juin 2025',
      'montantTotal': 150000,
      'montantPaye': 45000,
      'montantPersonnel': 3000,
      'hasUserPaid': true,
      'personnesPaye': 15,
      'totalPersonnes': 50,
      'icon': Icons.mosque,
      'color': const Color(0xFF10B981),
    },
    {
      'id': 5,
      'title': 'Puits d\'eau potable',
      'dateDebut': '5 Fév 2025',
      'dateFin': '30 Avr 2025',
      'montantTotal': 80000,
      'montantPaye': 20000,
      'montantPersonnel': 2500,
      'hasUserPaid': false,
      'personnesPaye': 8,
      'totalPersonnes': 32,
      'icon': Icons.water_drop,
      'color': const Color(0xFF06B6D4),
    },
  ];

  List<Map<String, dynamic>> get filteredCotisations {
    List<Map<String, dynamic>> filtered = _cotisations;
    
    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((cotisation) {
        return cotisation['title'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Filtrer par statut
    switch (_selectedFilter) {
      case 'En cours':
        filtered = filtered.where((cotisation) {
          final isComplete = cotisation['montantPaye'] >= cotisation['montantTotal'];
          return !isComplete;
        }).toList();
        break;
      case 'Terminées':
        filtered = filtered.where((cotisation) {
          return cotisation['montantPaye'] >= cotisation['montantTotal'];
        }).toList();
        break;
      case 'J\'ai payé':
        filtered = filtered.where((cotisation) {
          return cotisation['hasUserPaid'] == true;
        }).toList();
        break;
      case 'J\'ai pas payé':
        filtered = filtered.where((cotisation) {
          return cotisation['hasUserPaid'] == false;
        }).toList();
        break;
      default: // Toutes
        break;
    }
    
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Gestion des cotisations',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Champ de recherche
                    Container(
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
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher une cotisation',
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
                    const SizedBox(height: 16),
                    
                    // Filtres
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('Toutes'),
                          const SizedBox(width: 8),
                          _buildFilterChip('En cours'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Terminées'),
                          const SizedBox(width: 8),
                          _buildFilterChip('J\'ai payé'),
                          const SizedBox(width: 8),
                          _buildFilterChip('J\'ai pas payé'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Liste des cotisations
                    ...filteredCotisations.map((cotisation) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildCotisationCard(cotisation),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCotisationCard(Map<String, dynamic> cotisation) {
    final hasUserPaid = cotisation['hasUserPaid'] as bool;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (cotisation['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  cotisation['icon'] as IconData,
                  color: cotisation['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cotisation['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Début : ${cotisation['dateDebut']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Fin : ${cotisation['dateFin']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Montants et participants
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Montant payé',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${cotisation['montantPaye']}/${cotisation['montantTotal']} F',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
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
                      'Personnes qui ont payé',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${cotisation['personnesPaye']}/${cotisation['totalPersonnes']} pers.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Barre de progression
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progression',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    '${((cotisation['montantPaye'] / cotisation['montantTotal']) * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cotisation['color'] as Color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    Container(
                      width: (MediaQuery.of(context).size.width - 80) * 
                             (cotisation['montantPaye'] / cotisation['montantTotal']),
                      height: 6,
                      decoration: BoxDecoration(
                        color: cotisation['color'] as Color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Bouton payer
          Row(
            children: [
              Expanded(
                child: hasUserPaid
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Déjà payé',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          // Afficher le modal de choix de paiement
                          _showPaymentMethodModal(context, cotisation);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cotisation['color'] as Color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          'Payer ${cotisation['montantPersonnel']} FCFA',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
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
          filter,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodModal(BuildContext context, Map<String, dynamic> cotisation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Titre
            Text(
              'Comment voulez-vous payer ?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cotisation['title'],
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Montant : ${cotisation['montantPersonnel']} FCFA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cotisation['color'] as Color,
              ),
            ),
            const SizedBox(height: 32),
            
            // Options
            Column(
              children: [
                // Option QR Code
                Container(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QrPaiementPage(
                            cotisationTitle: cotisation['title'],
                            montant: cotisation['montantPersonnel'],
                            cotisationId: cotisation['id'].toString(),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      side: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.qr_code,
                            color: Color(0xFF4F46E5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Afficher code QR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'L\'admin scannera votre code',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF4F46E5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Option Preuve de paiement
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PreuvePaiementPage(
                            cotisationTitle: cotisation['title'],
                            montant: cotisation['montantPersonnel'],
                          ),
                        ),
                      ).then((result) {
                        // Quand l'utilisateur revient de la page de preuve
                        if (result == true) {
                          setState(() {
                            cotisation['hasUserPaid'] = true;
                            cotisation['montantPaye'] += cotisation['montantPersonnel'];
                            cotisation['personnesPaye'] += 1;
                          });
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Prouver un paiement',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Télécharger un reçu de paiement',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
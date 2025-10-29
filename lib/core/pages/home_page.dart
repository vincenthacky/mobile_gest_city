import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/controller/auth_controller.dart';
// import '../../features/cotisations/presentation/pages/preuve_paiement_page.dart';
// import '../../features/cotisations/presentation/pages/qr_paiement_page.dart';
import '../controller/home_controller.dart';
import '../models/contribution_model.dart';
import '../widgets/app_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeController = context.read<HomeController>();
      if (homeController.status == HomeStatus.initial) {
        homeController.loadHomeData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthController, HomeController>(
      builder: (context, authController, homeController, child) {
        if (!authController.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
                    title: 'Cotisation Mensuelle',
                  ),
                ),
                
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => homeController.refreshHomeData(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        const SizedBox(height: 16),
                        
                        // Carte principale de cotisation
                        if (homeController.isLoading)
                          Container(
                            width: double.infinity,
                            height: 300,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        else if (homeController.hasError)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
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
                                  homeController.errorMessage ?? 'Une erreur est survenue',
                                  style: TextStyle(color: Colors.red.shade600),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => homeController.loadHomeData(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          )
                        else if (homeController.defaultContribution != null)
                          _buildDefaultContributionCard(homeController, context)
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Aucune cotisation par défaut disponible',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                        
                        // Section Cotisations
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cotisations',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.go('/cotisations');
                              },
                              child: const Text(
                                'Voir plus',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (homeController.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (homeController.contributions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Aucune cotisation disponible',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: homeController.contributions.map((contribution) {
                              final index = homeController.contributions.indexOf(contribution);
                              final colors = [
                                const Color(0xFF3B82F6),
                                const Color(0xFF8B5CF6),
                                const Color(0xFFEC4899),
                              ];
                              final icons = [
                                Icons.school,
                                Icons.celebration,
                                Icons.group,
                              ];
                              
                              return Padding(
                                padding: EdgeInsets.only(bottom: index < homeController.contributions.length - 1 ? 12 : 0),
                                child: _buildCotisationItem(
                                  contribution.name,
                                  'Cotisation',
                                  icons[index % icons.length],
                                  colors[index % colors.length],
                                  contribution.amountBy,
                                  contribution.id,
                                  context,
                                  homeController,
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
      },
    );
  }

  Widget _buildDefaultContributionCard(HomeController homeController, BuildContext context) {
    final contribution = homeController.defaultContribution!;
    final progressPercentage = homeController.getProgressPercentage();
    
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Informations en grille
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date début',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contribution.formattedBeginDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Fin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contribution.formattedEndDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '10 000 FCFA / mois',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Somme cible',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      homeController.formatAmount(contribution.amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Montant et progression
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                contribution.amountReachedTotal.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
                  (Match m) => '${m[1]} '
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                ' / ${contribution.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Barre de progression
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * progressPercentage * 0.8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCotisationItem(String title, String subtitle, IconData icon, Color iconColor, int montant, int cotisationId, BuildContext context, HomeController homeController) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Find the contribution from homeController.contributions
          Builder(
            builder: (context) {
              final contribution = homeController.contributions.firstWhere(
                (c) => c.id == cotisationId,
                orElse: () => homeController.defaultContribution!,
              );
              return _buildHomePaymentButton(contribution, iconColor, montant, context, homeController);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomePaymentButton(ContributionModel contribution, Color iconColor, int montant, BuildContext context, HomeController homeController) {
    if (contribution.alreadyPaid == 'paid') {
      // État "paid" - Déjà payé (grisé)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Déjà payé',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    } else if (contribution.alreadyPaid == 'pending') {
      // État "pending" - En cours (grisé)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'En cours',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    } else {
      // État "not_paid" - Peut payer
      return ElevatedButton(
        onPressed: () {
          _showPaymentMethodModal(context, contribution);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F2937),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
        child: const Text(
          'Payer',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  void _showPaymentMethodModal(BuildContext context, ContributionModel contribution) {
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
            const Text(
              'Comment voulez-vous payer ?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              contribution.name,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Montant : ${contribution.amountBy} FCFA',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 32),
            
            // Options
            // Column(
            //   children: [
            //     // Option QR Code
            //     SizedBox(
            //       width: double.infinity,
            //       child: OutlinedButton(
            //         onPressed: () {
            //           Navigator.pop(context);
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => QrPaiementPage(
            //                 cotisationTitle: contribution.name,
            //                 montant: contribution.amountBy,
            //                 cotisationId: contribution.id.toString(),
            //               ),
            //             ),
            //           );
            //         },
            //         style: OutlinedButton.styleFrom(
            //           foregroundColor: const Color(0xFF4F46E5),
            //           side: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           padding: const EdgeInsets.all(16),
            //         ),
            //         child: Row(
            //           children: [
            //             Container(
            //               padding: const EdgeInsets.all(8),
            //               decoration: BoxDecoration(
            //                 color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            //                 borderRadius: BorderRadius.circular(8),
            //               ),
            //               child: const Icon(
            //                 Icons.qr_code,
            //                 color: Color(0xFF4F46E5),
            //                 size: 24,
            //               ),
            //             ),
            //             const SizedBox(width: 16),
            //             const Expanded(
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   Text(
            //                     'Afficher code QR',
            //                     style: TextStyle(
            //                       fontSize: 16,
            //                       fontWeight: FontWeight.w600,
            //                       color: Color(0xFF1F2937),
            //                     ),
            //                   ),
            //                   SizedBox(height: 2),
            //                   Text(
            //                     'L\'admin scannera votre code',
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: Color(0xFF6B7280),
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //             const Icon(
            //               Icons.arrow_forward_ios,
            //               color: Color(0xFF4F46E5),
            //               size: 16,
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //     const SizedBox(height: 16),
                
            //     // Option Preuve de paiement
            //     SizedBox(
            //       width: double.infinity,
            //       child: ElevatedButton(
            //         onPressed: () {
            //           Navigator.pop(context);
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => PreuvePaiementPage(
            //                 cotisationTitle: contribution.name,
            //                 montant: contribution.amountBy,
            //                 cotisationId: contribution.id,
            //               ),
            //             ),
            //           );
            //         },
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: const Color(0xFF1F2937),
            //           foregroundColor: Colors.white,
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           padding: const EdgeInsets.all(16),
            //         ),
            //         child: Row(
            //           children: [
            //             Container(
            //               padding: const EdgeInsets.all(8),
            //               decoration: BoxDecoration(
            //                 color: Colors.white.withValues(alpha: 0.2),
            //                 borderRadius: BorderRadius.circular(8),
            //               ),
            //               child: const Icon(
            //                 Icons.receipt_long,
            //                 color: Colors.white,
            //                 size: 24,
            //               ),
            //             ),
            //             const SizedBox(width: 16),
            //             const Expanded(
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   Text(
            //                     'Prouver un paiement',
            //                     style: TextStyle(
            //                       fontSize: 16,
            //                       fontWeight: FontWeight.w600,
            //                       color: Colors.white,
            //                     ),
            //                   ),
            //                   SizedBox(height: 2),
            //                   Text(
            //                     'Télécharger un reçu de paiement',
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: Colors.white70,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //             const Icon(
            //               Icons.arrow_forward_ios,
            //               color: Colors.white,
            //               size: 16,
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
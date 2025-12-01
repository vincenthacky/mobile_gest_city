import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../authentification/controller/auth_controller.dart';
import '../../controllers/admin_overview_controller.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<AdminOverviewController>();
      controller.loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
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
            child: Consumer<AdminOverviewController>(
              builder: (context, overviewController, child) {
                return RefreshIndicator(
                  onRefresh: () => overviewController.refreshOverview(),
                  color: const Color(0xFF4F46E5),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gest City',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Module Administrateur',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            if (overviewController.hasData)
                              IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  color: overviewController.isLoading
                                      ? const Color(
                                          0xFF4F46E5,
                                        ).withValues(alpha: 0.5)
                                      : const Color(0xFF4F46E5),
                                ),
                                onPressed: overviewController.isLoading
                                    ? null
                                    : () =>
                                          overviewController.refreshOverview(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Statistiques - Bento Grid
                        _buildStatisticsSection(overviewController),
                        const SizedBox(height: 32),

                        const Text(
                          'Actions rapides',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildActionCard(
                          'Gestion projets',
                          'Gérer les projets de la communauté',
                          Icons.folder_outlined,
                          const Color(0xFF4F46E5),
                          () {
                            context.push('/admin/projects');
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildActionCard(
                          'Gestion paiements',
                          'Gérer les paiements des cotisateurs',
                          Icons.approval,
                          const Color(0xFFF59E0B),
                          () {
                            context.push('/admin/payments');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSection(AdminOverviewController controller) {
    // État de chargement initial
    if (controller.isLoading && !controller.hasData) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Color(0xFF4F46E5)),
            const SizedBox(height: 16),
            Text(
              'Chargement des statistiques...',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // État d'erreur
    if (controller.status == AdminOverviewStatus.error) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage ?? 'Erreur de chargement',
              style: const TextStyle(fontSize: 14, color: Color(0xFF991B1B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => controller.refreshOverview(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Affichage des données
    final overview = controller.overview;
    if (overview == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          height: 140,
          child: _buildStatCard(
            'Projets acceptés',
            overview.acceptedProjectsCount.toString(),
            Icons.check_circle_outline,
            const Color(0xFF4F46E5),
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          height: 140,
          child: _buildStatCard(
            'Paiements en attente',
            overview.pendingPaymentsCount.toString(),
            Icons.pending_actions,
            const Color(0xFFF59E0B),
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          height: 140,
          child: _buildStatCard(
            'Villas actives',
            overview.villasWithUsersCount.toString(),
            Icons.home_outlined,
            const Color(0xFF8B5CF6),
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          height: 140,
          child: _buildStatCard(
            'Solde portefeuille',
            overview.formattedWalletBalance,
            Icons.account_balance_wallet_outlined,
            const Color(0xFF10B981),
            isBalance: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isBalance = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isBalance ? 16 : 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

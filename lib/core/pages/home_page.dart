import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_header.dart';
import '../controllers/member_overview_controller.dart';
import '../services/connectivity_service.dart';
import '../widgets/sync_notification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MemberOverviewController _overviewController;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _overviewController = MemberOverviewController();
    _loadOverviewData();
    _checkConnectivityAndNotify();
  }

  @override
  void dispose() {
    _overviewController.dispose();
    super.dispose();
  }

  /// Charge les données overview au démarrage
  Future<void> _loadOverviewData() async {
    await _overviewController.initialize();
  }

  /// Rafraîchit les données overview
  Future<void> _refreshOverviewData() async {
    await _overviewController.refresh(showNotifications: true);
  }

  /// Vérifie la connectivité et affiche les notifications appropriées
  void _checkConnectivityAndNotify() {
    // Vérifier la connectivité après le chargement initial
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_connectivityService.isConnected) {
        // Connecté : synchronisation avec notifications
        if (_overviewController.hasData) {
          await _overviewController.loadOverview(showNotifications: true);
        }
      } else {
        // Pas de connexion : afficher notification hors ligne si on a des données en cache
        if (_overviewController.hasData) {
          _overviewController.showOfflineNotification();
        }
      }
    });
  }

  // Méthode pour calculer le ratio d'aspect selon la taille d'écran
  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 1.2; // Grands écrans
    if (screenWidth > 800) return 1.1; // Tablettes
    if (screenWidth > 600) return 1.0; // Petites tablettes
    return 0.9; // Téléphones
  }

  // Méthode pour calculer le padding responsive
  double _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 32; // Grands écrans
    if (screenWidth > 800) return 28; // Tablettes
    if (screenWidth > 600) return 24; // Petites tablettes
    return 16; // Téléphones
  }

  // Méthodes pour le responsive des cartes
  double _getResponsiveCardPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 20;
    if (screenWidth > 600) return 18;
    return 16;
  }

  double _getResponsiveIconPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 12;
    if (screenWidth > 600) return 10;
    return 8;
  }

  double _getResponsiveIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 28;
    if (screenWidth > 600) return 26;
    return 24;
  }

  double _getResponsiveTitleSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 18;
    if (screenWidth > 600) return 17;
    return 16;
  }

  double _getResponsiveSubtitleSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 13;
    if (screenWidth > 600) return 12.5;
    return 12;
  }

  double _getResponsiveSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 8;
    if (screenWidth > 600) return 7;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec AppHeader
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                title: 'Gest City',
               
              ),
            ),
            
            // Notification de synchronisation
            AnimatedBuilder(
              animation: _overviewController,
              builder: (context, child) {
                return SyncNotification(
                  type: _overviewController.notificationType,
                  customMessage: _overviewController.notificationMessage,
                  onDismiss: () => _overviewController.clearNotification(),
                  onRetrySync: () {
                    // Ressayer la synchronisation
                    _overviewController.refresh(showNotifications: true);
                  },
                );
              },
            ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshOverviewData,
                color: const Color(0xFF4F46E5),
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  slivers: [
            
            // Grid des fonctionnalités responsive
            SliverPadding(
              padding: EdgeInsets.all(_getResponsivePadding(context)),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, // Largeur max de chaque carte
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: _getChildAspectRatio(context),
                ),
                delegate: SliverChildListDelegate([
                  _buildFeatureCard(
                    context,
                    title: 'Finance',
                    subtitle: 'Transparence dans les cotisations et les dépenses',
                    icon: Icons.account_balance_wallet,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    onTap: () => context.go('/finance'),
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Projets',
                    subtitle: 'Faites le choix des projets de votre cité',
                    icon: Icons.engineering,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    onTap: () => context.go('/projets'),
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Cadre de Vie',
                    subtitle: 'Information, activité, actualité, famille',
                    icon: Icons.location_city,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    onTap: () => context.go('/cadre-de-vie'),
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Vigilance',
                    subtitle: 'Signaler tout acte suspect, dégradation ou mauvais comportement',
                    icon: Icons.security,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    onTap: () => context.go('/signalements'),
                  ),
                ]),
              ),
            ),
            
            // Section statistiques rapides
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _getResponsivePadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aperçu rapide',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickStatsCard(),
                  ],
                ),
              ),
            ),
            
            // Actions rapides
           
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(_getResponsiveCardPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(_getResponsiveIconPadding(context)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: _getResponsiveIconSize(context),
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveTitleSize(context),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: _getResponsiveSpacing(context)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: _getResponsiveSubtitleSize(context),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    fontFamily: 'Nunito',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return AnimatedBuilder(
      animation: _overviewController,
      builder: (context, child) {
        // Afficher un loader si les données sont en cours de chargement
        if (_overviewController.isLoading && !_overviewController.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Indicateur de statut des données
              if (_overviewController.hasData && !_overviewController.overview!.isRecent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Données hors ligne',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _refreshOverviewData,
                        child: Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      label: 'Villa inscrits',
                      value: _overviewController.villaInscrit.toString(),
                      icon: Icons.home,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      label: 'Projets en cours',
                      value: _overviewController.projetEnCours.toString(),
                      icon: Icons.construction,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      label: 'Vigilance',
                      value: _overviewController.vigilance.toString(),
                      icon: Icons.security,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      label: 'Solde de la caisse',
                      value: _formatSolde(_overviewController.solde),
                      icon: Icons.account_balance,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Formate le solde pour l'affichage (ex: 180000 → 180K)
  String _formatSolde(int solde) {
    if (solde >= 1000000) {
      return '${(solde / 1000000).toStringAsFixed(1)}M';
    } else if (solde >= 1000) {
      return '${(solde / 1000).toStringAsFixed(0)}K';
    } else {
      return solde.toString();
    }
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

}
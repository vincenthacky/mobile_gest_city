import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_payments_controller.dart';
import '../../models/admin_payment_model.dart';
import '../components/admin_filter_chip.dart';
import '../components/admin_help_message.dart';
import '../components/payment_card.dart';
import '../components/payment_details_modal.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<AdminPaymentsController>();
      controller.loadPayments();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMorePayments();
    }
  }

  Future<void> _loadMorePayments() async {
    if (_isLoadingMore) return;

    final controller = context.read<AdminPaymentsController>();

    if (!controller.hasNextPage) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await controller.loadMorePayments();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    final controller = context.read<AdminPaymentsController>();
    await controller.refreshPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<AdminPaymentsController>(
                builder: (context, controller, child) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: const Color(0xFF3B82F6),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusFilters(controller),
                          const SizedBox(height: 12),
                          const AdminHelpMessage(
                            message: 'Touchez un paiement pour voir les détails et le valider ou le rejeter',
                          ),
                          const SizedBox(height: 12),
                          _buildScanQRButton(),
                          const SizedBox(height: 16),
                          _buildContent(controller),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Gestion des paiements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Consumer<AdminPaymentsController>(
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
                    : () => controller.refreshPayments(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters(AdminPaymentsController controller) {
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
              AdminFilterChip(
                label: 'Tous',
                isSelected: controller.currentStatusFilter == null,
                onTap: () => controller.changeStatusFilter(null),
                icon: Icons.apps,
              ),
              const SizedBox(width: 8),
              AdminFilterChip(
                label: 'En attente',
                isSelected: controller.currentStatusFilter == '0',
                onTap: () => controller.changeStatusFilter('0'),
                icon: Icons.timer,
              ),
              const SizedBox(width: 8),
              AdminFilterChip(
                label: 'Payé',
                isSelected: controller.currentStatusFilter == '1',
                onTap: () => controller.changeStatusFilter('1'),
                icon: Icons.check_circle,
              ),
              const SizedBox(width: 8),
              AdminFilterChip(
                label: 'En retard',
                isSelected: controller.currentStatusFilter == '2',
                onTap: () => controller.changeStatusFilter('2'),
                icon: Icons.warning_amber,
              ),
              const SizedBox(width: 8),
              AdminFilterChip(
                label: 'En attente confirmation',
                isSelected: controller.currentStatusFilter == '3',
                onTap: () => controller.changeStatusFilter('3'),
                icon: Icons.pending_actions,
              ),
              const SizedBox(width: 8),
              AdminFilterChip(
                label: 'Rejeté',
                isSelected: controller.currentStatusFilter == '4',
                onTap: () => controller.changeStatusFilter('4'),
                icon: Icons.cancel,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanQRButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.push('/admin/scan-qr');
        },
        icon: const Icon(Icons.qr_code_scanner, size: 20),
        label: const Text(
          'Scanner un QR Code',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildContent(AdminPaymentsController controller) {
    if (controller.isLoading && controller.payments.isEmpty) {
      return _buildLoadingState();
    }

    if (controller.status == AdminPaymentsStatus.error) {
      return _buildErrorState(controller);
    }

    if (controller.payments.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPaymentsList(controller);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const CircularProgressIndicator(color: Color(0xFF3B82F6)),
          const SizedBox(height: 16),
          Text(
            'Chargement des paiements...',
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

  Widget _buildErrorState(AdminPaymentsController controller) {
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
            onPressed: () => controller.refreshPayments(),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.payments_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucun paiement trouvé',
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
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontFamily: 'Nunito'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(AdminPaymentsController controller) {
    return Column(
      children: [
        ...controller.payments.map((payment) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PaymentCard(
              payment: payment,
              onTap: () => _showPaymentDetails(payment),
            ),
          );
        }),
        if (_isLoadingMore) _buildLoadingMoreIndicator(),
        if (controller.pagination != null && !_isLoadingMore)
          _buildPaginationInfo(controller),
      ],
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
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
    );
  }

  Widget _buildPaginationInfo(AdminPaymentsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Text(
        controller.hasNextPage
            ? '${controller.currentPage * 20} sur ${controller.totalItems} paiements'
            : 'Tous les paiements chargés (${controller.totalItems})',
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontFamily: 'Nunito',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showPaymentDetails(AdminPaymentItem payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentDetailsModal(payment: payment),
    );
  }
}

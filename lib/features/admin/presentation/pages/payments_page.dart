import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_payments_controller.dart';
import '../../models/admin_payment_model.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  // ScrollController pour le scroll infini
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Ajouter le listener pour le scroll infini
    _scrollController.addListener(_onScroll);

    // Charger les paiements au démarrage
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

  /// Détecte quand on approche du bas de la liste (200px threshold)
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMorePayments();
    }
  }

  /// Charge plus de paiements (pagination infinie)
  Future<void> _loadMorePayments() async {
    if (_isLoadingMore) return;

    final controller = context.read<AdminPaymentsController>();

    // Guard: vérifier s'il y a une page suivante
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

  /// Pull-to-refresh
  Future<void> _onRefresh() async {
    final controller = context.read<AdminPaymentsController>();
    await controller.refreshPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Gestion des paiements',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: Consumer<AdminPaymentsController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              // Filtres horizontaux
              _buildFiltersSection(controller),

              // Bouton Scanner QR
              _buildScanQRButton(),

              // Liste des paiements avec états
              Expanded(child: _buildPaymentsList(controller)),
            ],
          );
        },
      ),
    );
  }

  /// Section des filtres
  Widget _buildFiltersSection(AdminPaymentsController controller) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip(
              'Tous',
              null,
              controller.currentStatusFilter == null,
              controller,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'En attente',
              '0',
              controller.currentStatusFilter == '0',
              controller,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Payé',
              '1',
              controller.currentStatusFilter == '1',
              controller,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'En retard',
              '2',
              controller.currentStatusFilter == '2',
              controller,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'En attente confirmation',
              '3',
              controller.currentStatusFilter == '3',
              controller,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Rejeté',
              '4',
              controller.currentStatusFilter == '4',
              controller,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    bool isSelected,
    AdminPaymentsController controller,
  ) {
    return GestureDetector(
      onTap: () {
        controller.changeStatusFilter(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Bouton Scanner QR Code
  Widget _buildScanQRButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            context.push('/admin/scan-qr');
          },
          icon: const Icon(Icons.qr_code_scanner, size: 24),
          label: const Text(
            'Scanner un QR Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  /// Liste des paiements avec gestion des états
  Widget _buildPaymentsList(AdminPaymentsController controller) {
    // État de chargement initial
    if (controller.isLoading && controller.payments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      );
    }

    // État d'erreur
    if (controller.status == AdminPaymentsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage ?? 'Une erreur est survenue',
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.refreshPayments(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // État vide
    if (controller.payments.isEmpty) {
      return _buildEmptyState();
    }

    // Liste avec pull-to-refresh et infinite scroll
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF4F46E5),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.payments.length + 1, // +1 pour le loader
        itemBuilder: (context, index) {
          // Dernier item = loader si plus de pages
          if (index == controller.payments.length) {
            return _buildLoadMoreIndicator(controller);
          }

          final payment = controller.payments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPaymentCard(payment),
          );
        },
      ),
    );
  }

  /// Indicateur de chargement en bas de liste
  Widget _buildLoadMoreIndicator(AdminPaymentsController controller) {
    if (!controller.hasNextPage) {
      // Fin de la liste
      if (controller.payments.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'Tous les paiements chargés (${controller.totalItems})',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (_isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4F46E5),
            strokeWidth: 2,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucun paiement trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les paiements apparaîtront ici',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  /// Card de paiement
  Widget _buildPaymentCard(AdminPaymentItem payment) {
    final statusColor = Color(payment.statusColorValue);

    return GestureDetector(
      onTap: () => _showPaymentDetails(payment),
      child: Container(
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
        child: Stack(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: switch (payment.status) {
                    "completed" || "validated" || "paid" || "1" => const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                    ),
                    "pending" || "0" => const Icon(
                      Icons.timer,
                      color: Colors.orange,
                    ),
                    "confirmation_pending" || "3" => const Icon(
                      Icons.pending_actions,
                      color: Colors.blue,
                    ),
                    "rejected" || "failed" || "4" => const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ),
                    "late" || "overdue" || "2" => const Icon(
                      Icons.warning_amber,
                      color: Colors.red,
                    ),
                    _ => const Icon(
                      Icons.receipt,
                      color: Color(0xFF6B7280),
                    ),
                  },
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${payment.amountPaid.toStringAsFixed(0)} FCFA • ${_formatDate(payment.createdAt)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            payment.period,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          if (payment.totalProofImages > 0) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.image_outlined,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${payment.totalProofImages}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Affiche les détails d'un paiement
  void _showPaymentDetails(AdminPaymentItem payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentDetailsModal(payment: payment),
    );
  }
}

// Modal de détails de paiement
class PaymentDetailsModal extends StatefulWidget {
  final AdminPaymentItem payment;

  const PaymentDetailsModal({super.key, required this.payment});

  @override
  State<PaymentDetailsModal> createState() => _PaymentDetailsModalState();
}

class _PaymentDetailsModalState extends State<PaymentDetailsModal> {
  bool _isProcessing = false;

  Future<void> _handleApprove(AdminPaymentsController controller) async {
    setState(() => _isProcessing = true);

    final success = await controller.approvePayment(widget.payment.id);

    if (!mounted) return;

    setState(() => _isProcessing = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success
                    ? 'Paiement validé avec succès !'
                    : 'Erreur lors de la validation',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: success
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleReject(
    AdminPaymentsController controller,
    String reason,
  ) async {
    setState(() => _isProcessing = true);

    final success = await controller.rejectPayment(widget.payment.id, reason);

    if (!mounted) return;

    setState(() => _isProcessing = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success ? 'Paiement rejeté' : 'Erreur lors du rejet',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: success
            ? const Color(0xFFEF4444)
            : const Color(0xFF6B7280),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AdminPaymentsController>();
    final statusColor = Color(widget.payment.statusColorValue);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Contenu
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // En-tête
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              widget.payment.initials,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.payment.displayName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(widget.payment.createdAt),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Informations
                    _buildInfoRow('Nom complet', widget.payment.userFullName),
                    _buildInfoRow('Villa', widget.payment.villaNumber),
                    _buildInfoRow('Numéro', widget.payment.userPhone),
                    _buildInfoRow('Adresse email', widget.payment.userEmail),
                    _buildInfoRow(
                      'Montant',
                      '${widget.payment.amountPaid.toStringAsFixed(0)} FCFA',
                    ),
                    _buildInfoRow('Méthode', widget.payment.paymentMethodText),
                    _buildInfoRow('Période', widget.payment.period),
                    _buildInfoRow('Statut', widget.payment.statusText),

                    if (widget.payment.totalProofImages > 0) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Preuves de paiement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.payment.allProofImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final image = widget.payment.allProofImages[index];
                            // Construction de l'URL complète si nécessaire
                            // Pour l'instant on utilise le filepath tel quel
                            // TODO: Ajouter la base URL si nécessaire
                            final imageUrl = image.filepath;

                            return GestureDetector(
                              onTap: () => _showFullImage(context, imageUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Informations additionnelles
                    // if (!payment.userAnonymity) ...[
                    //   const Text(
                    //     'Informations du payeur',
                    //     style: TextStyle(
                    //       fontSize: 18,
                    //       fontWeight: FontWeight.bold,
                    //       color: Color(0xFF1F2937),
                    //     ),
                    //   ),
                    //   const SizedBox(height: 12),
                    //   Container(
                    //     padding: const EdgeInsets.all(16),
                    //     decoration: BoxDecoration(
                    //       color: const Color(0xFFF9FAFB),
                    //       borderRadius: BorderRadius.circular(12),
                    //       border: Border.all(
                    //         color: const Color(0xFFE5E7EB),
                    //         width: 1,
                    //       ),
                    //     ),
                    //     child: Column(
                    //       children: [
                    //         // _buildDetailRow(Icons.person, 'Nom', payment.userFullName),
                    //         // const SizedBox(height: 12),
                    //         // _buildDetailRow(Icons.email, 'Email', payment.userEmail),
                    //         // const SizedBox(height: 12),
                    //         // _buildDetailRow(Icons.phone, 'Téléphone', payment.userPhone),
                    //       ],
                    //     ),
                    //   ),
                    // ],
                    const SizedBox(height: 32),

                    // Actions (uniquement pour statut en attente)
                    if (widget.payment.status == 'confirmation_pending') ...[
                      if (_isProcessing)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showRejectDialog(context, controller),
                                icon: const Icon(Icons.close, size: 20),
                                label: const Text(
                                  'Rejeter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleApprove(controller),
                                icon: const Icon(Icons.check, size: 20),
                                label: const Text(
                                  'Valider',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    AdminPaymentsController controller,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rejeter le paiement'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Raison du rejet',
            hintText: 'Expliquez pourquoi vous rejetez ce paiement',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Veuillez fournir une raison',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              _handleReject(controller, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}

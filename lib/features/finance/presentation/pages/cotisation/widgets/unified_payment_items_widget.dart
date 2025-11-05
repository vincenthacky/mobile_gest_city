import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/contribution_controller.dart';
import '../../../../models/payment_list_model.dart';
import '../../cotisation_detail_page.dart';
import '../../../../../authentication/controller/auth_controller.dart';

class UnifiedPaymentItemsWidget extends StatefulWidget {
  const UnifiedPaymentItemsWidget({super.key});

  @override
  State<UnifiedPaymentItemsWidget> createState() => _UnifiedPaymentItemsWidgetState();
}

class _UnifiedPaymentItemsWidgetState extends State<UnifiedPaymentItemsWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    
    final controller = context.read<ContributionController>();
    final pagination = controller.allPaymentsPagination;
    
    if (pagination?.hasNextPage != true) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final authController = context.read<AuthController>();
      final userId = authController.user?.id;
      if (userId != null) {
        await controller.loadMoreAllPayments(userId);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContributionController>(
      builder: (context, controller, child) {
        final payments = controller.allPayments;
        final pagination = controller.allPaymentsPagination;
        
        if (payments.isEmpty) {
          return _buildEmptyState();
        }
        
        return Column(
          children: [
            ...payments.asMap().entries.map((entry) {
              final index = entry.key;
              final payment = entry.value;
              final isLast = index == payments.length - 1 && 
                            pagination?.hasNextPage != true;
              
              return _buildPaymentItem(payment, isLast);
            }),
            
            if (pagination?.hasNextPage == true)
              _buildLoadMoreIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: Colors.white,
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.payment_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vos paiements apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
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

  Widget _buildPaymentItem(PaymentItem payment, bool isLast) {
    final status = payment.paymentStatus;
    
    Color iconColor;
    Color borderColor;
    String statusIcon;
    
    if (status.isCompleted) {
      iconColor = const Color(0xFF10B981);
      borderColor = const Color(0xFF10B981).withValues(alpha: 0.3);
      statusIcon = '✓';
    } else if (status.isPending) {
      iconColor = const Color(0xFFF59E0B);
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.3);
      statusIcon = '⏱';
    } else {
      iconColor = const Color(0xFFEF4444);
      borderColor = const Color(0xFFEF4444).withValues(alpha: 0.3);
      statusIcon = '!';
    }

    Widget buildContent() {
      return Container(
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Section gauche : Icône + Info
              Expanded(
                child: Row(
                  children: [
                    // Icône de cotisation
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: borderColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Informations du paiement
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.displayTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            payment.formattedDate,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            payment.statusDisplayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: iconColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Section droite : Montant + Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${payment.formattedAmount} F',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusIcon,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: status.isCompleted 
        ? InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CotisationDetailPage(
                    paymentProof: null,
                    cotisation: {
                      'title': payment.displayTitle,
                      'date': payment.formattedDate,
                      'amount': payment.formattedAmount,
                      'isPaid': status.isCompleted,
                      'paymentMethod': payment.paymentMethod ?? 'Mobile Money',
                      'status': payment.statusDisplayName,
                      'period': payment.period,
                    },
                  ),
                ),
              );
            },
            child: buildContent(),
          )
        : buildContent(),
    );
  }
}
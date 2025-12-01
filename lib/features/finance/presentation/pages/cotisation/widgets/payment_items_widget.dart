import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/contribution_controller.dart';
import '../../../../models/payment_proofs_model.dart';
import '../../cotisation_detail_page.dart';
import '../../../../../authentification/controller/auth_controller.dart';

class PaymentItemsWidget extends StatelessWidget {
  final bool showingPayments;
  final bool showingValidated;

  const PaymentItemsWidget({
    super.key,
    required this.showingPayments,
    required this.showingValidated,
  });

  @override
  Widget build(BuildContext context) {
    if (showingPayments) {
      if (showingValidated) {
        return _buildValidatedPaymentsItems();
      } else {
        return _buildPendingPaymentsItems();
      }
    } else {
      return _buildUnpaidMonthsItems();
    }
  }

  Widget _buildValidatedPaymentsItems() {
    return Consumer<ContributionController>(
      builder: (context, controller, child) {
        final validatedPayments = controller.validatedPayments;
        final pagination = controller.validatedPagination;
        
        if (validatedPayments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.payment_outlined,
            title: 'Aucun paiement validé',
            subtitle: 'Vos paiements validés apparaîtront ici',
          );
        }
        
        List<Widget> items = validatedPayments.asMap().entries.map((entry) {
          final index = entry.key;
          final payment = entry.value;
          final isLast = index == validatedPayments.length - 1 && pagination?.hasNextPage != true;
          
          return _buildPaymentItem(
            payment.displayTitle,
            payment.formattedDate,
            payment.formattedAmount,
            true,
            isLast,
            paymentMethod: payment.formattedPaymentMethod,
            paymentProof: payment,
            context: context,
          );
        }).toList();
        
        if (pagination?.hasNextPage == true) {
          items.add(_buildLoadMoreButton(context, isValidated: true));
        }
        
        return Column(children: items);
      },
    );
  }

  Widget _buildPendingPaymentsItems() {
    return Consumer<ContributionController>(
      builder: (context, controller, child) {
        final pendingPayments = controller.pendingPayments;
        final pagination = controller.pendingPagination;
        
        if (pendingPayments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.hourglass_empty,
            title: 'Aucun paiement en attente',
            subtitle: 'Vos paiements en cours de validation apparaîtront ici',
          );
        }
        
        List<Widget> items = pendingPayments.asMap().entries.map((entry) {
          final index = entry.key;
          final payment = entry.value;
          final isLast = index == pendingPayments.length - 1 && pagination?.hasNextPage != true;
          
          return _buildPaymentItem(
            payment.displayTitle,
            payment.formattedDate,
            payment.formattedAmount,
            false,
            isLast,
            paymentMethod: payment.formattedPaymentMethod,
            paymentProof: payment,
            context: context,
          );
        }).toList();
        
        if (pagination?.hasNextPage == true) {
          items.add(_buildLoadMoreButton(context, isValidated: false));
        }
        
        return Column(children: items);
      },
    );
  }

  Widget _buildUnpaidMonthsItems() {
    return Consumer<ContributionController>(
      builder: (context, controller, child) {
        final unpaidMonths = controller.unpaidMonths;
        final contributionData = controller.contributionData;
        
        if (unpaidMonths.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'Aucun retard de paiement',
            subtitle: 'Toutes vos cotisations sont à jour !',
            iconColor: const Color(0xFF10B981),
          );
        }
        
        return Column(
          children: unpaidMonths.asMap().entries.map((entry) {
            final index = entry.key;
            final unpaidMonth = entry.value;
            final isLast = index == unpaidMonths.length - 1;
            
            final title = contributionData != null 
                ? unpaidMonth.getTitle(contributionData.name)
                : 'Cotisation ${unpaidMonth.period}';
            
            final deadline = contributionData != null
                ? unpaidMonth.getDeadline(contributionData.deadlineDay)
                : 'Échéance: ${unpaidMonth.period}';
                
            final amount = contributionData != null
                ? unpaidMonth.getFormattedAmount(contributionData.amountByPerson)
                : '10.000F';
            
            return _buildPaymentItem(
              title,
              deadline,
              amount,
              false,
              isLast,
              context: context,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = const Color(0xFF6B7280),
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: Colors.white,
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
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

  Widget _buildLoadMoreButton(BuildContext context, {required bool isValidated}) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: OutlinedButton(
        onPressed: () async {
          final authController = context.read<AuthController>();
          final userId = authController.user?.id;
          if (userId != null) {
            final contributionController = context.read<ContributionController>();
            if (isValidated) {
              await contributionController.loadMoreValidatedPayments(userId);
            } else {
              await contributionController.loadMorePendingPayments(userId);
            }
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4F46E5),
          side: const BorderSide(color: Color(0xFF4F46E5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_arrow_down, size: 18),
            SizedBox(width: 8),
            Text(
              'Charger plus',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(
    String title,
    String date,
    String amount,
    bool isPaid,
    bool isLast, {
    String? paymentMethod,
    dynamic paymentProof, // Accepte PaymentProof ET PaymentItem
    required BuildContext context,
  }) {
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
                        color: isPaid 
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isPaid 
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
                            title,
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
                            isPaid ? date : 'Échéance: $date',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    '$amount F',
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
                      color: isPaid 
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPaid ? '✓' : '!',
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
      child: isPaid 
        ? InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CotisationDetailPage(
                    paymentProof: paymentProof,
                    cotisation: paymentProof == null ? {
                      'title': title,
                      'date': date,
                      'amount': amount,
                      'isPaid': isPaid,
                      'paymentMethod': paymentMethod ?? 'Code QR',
                    } : null,
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/contribution_controller.dart';

class CotisationCardWidget extends StatelessWidget {
  const CotisationCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContributionController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return _buildLoadingCard();
        }

        if (controller.errorMessage != null) {
          return _buildErrorCard(controller.errorMessage!);
        }

        final data = controller.contributionData;
        if (data == null) {
          return _buildEmptyCard();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.of(context).size.height;
            final isVerySmall = constraints.maxWidth < 300;
            final isSmall = constraints.maxWidth < 350;
            final isShortScreen = screenHeight < 700;
            
            return Container(
              constraints: BoxConstraints(
                minHeight: isShortScreen ? 160.0 : (isVerySmall ? 170.0 : 180.0),
                maxHeight: isShortScreen ? 180.0 : (isVerySmall ? 190.0 : 200.0),
              ),
              padding: EdgeInsets.all(isVerySmall ? 12 : 16),
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
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Première ligne
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Montant par personne',
                            data.formattedAmountByPerson,
                            fontSize: isVerySmall ? 8 : (isSmall ? 9 : 10),
                            valueFontSize: isVerySmall ? 9 : (isSmall ? 10 : 11),
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            'Jour limite',
                            data.deadlineDayFormatted,
                            fontSize: isVerySmall ? 8 : (isSmall ? 9 : 10),
                            valueFontSize: isVerySmall ? 9 : (isSmall ? 10 : 11),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isVerySmall ? 4 : 6),
                    
                    // Deuxième ligne
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Période actuelle',
                            data.currentPeriod,
                            fontSize: isVerySmall ? 7 : (isSmall ? 8 : 9),
                            valueFontSize: isVerySmall ? 8 : (isSmall ? 9 : 10),
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            'Collecté ce mois',
                            data.formattedCollectedThisMonth,
                            fontSize: isVerySmall ? 7 : (isSmall ? 8 : 9),
                            valueFontSize: isVerySmall ? 8 : (isSmall ? 9 : 10),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isVerySmall ? 4 : 6),
                    
                    // Troisième ligne
                    _buildInfoItem(
                      'Attendu ce mois-ci',
                      data.formattedExpectedThisMonth,
                      fontSize: isVerySmall ? 8 : (isSmall ? 9 : 10),
                      valueFontSize: isVerySmall ? 10 : (isSmall ? 11 : 12),
                      centerAlign: true,
                    ),
                    
                    const Spacer(),
                
                    // Montant et progression
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  data.totalAmountPaymentCollectedCurrentMonth.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: isVerySmall ? 14 : (isSmall ? 15 : 16),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  ' / ${data.totalExpectedAmountThisMonth.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: isVerySmall ? 8 : (isSmall ? 9 : 10),
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isVerySmall ? 6 : 8),
                        
                        // Barre de progression
                        Container(
                          width: double.infinity,
                          height: isVerySmall ? 4 : 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(isVerySmall ? 2 : 3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: data.progressPercentage,
                            child: Container(
                              height: isVerySmall ? 4 : 6,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(isVerySmall ? 2 : 3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 180,
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
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B7280).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    double fontSize = 10,
    double valueFontSize = 12,
    bool centerAlign = false,
  }) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.2,
              ),
              textAlign: centerAlign ? TextAlign.center : TextAlign.start,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 1),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.1,
                ),
                textAlign: centerAlign ? TextAlign.center : TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
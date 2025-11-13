import 'package:flutter/material.dart';

enum SyncNotificationType {
  offline,       // Pas de connexion - données du cache
  syncing,       // Synchronisation en cours
  syncComplete,  // Synchronisation terminée
  none,          // Aucune notification
}

class SyncNotification extends StatefulWidget {
  final SyncNotificationType type;
  final String? customMessage;
  final VoidCallback? onDismiss;

  const SyncNotification({
    super.key,
    required this.type,
    this.customMessage,
    this.onDismiss,
  });

  @override
  State<SyncNotification> createState() => _SyncNotificationState();
}

class _SyncNotificationState extends State<SyncNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    if (widget.type != SyncNotificationType.none) {
      _animationController.forward();

      // Auto-dismiss pour certains types après 3 secondes
      if (widget.type == SyncNotificationType.syncComplete) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _dismiss();
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(SyncNotification oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      if (widget.type == SyncNotificationType.none) {
        _dismiss();
      } else {
        _animationController.forward();
      }
    }
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == SyncNotificationType.none) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 50),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _getShadowColor().withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: _getBorderColor(),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Icône (même style que l'indicateur de connectivité)
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _getIconBackgroundColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getIconBackgroundColor().withValues(alpha: 0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: _buildIcon(),
                  ),

                  // Message
                  Expanded(
                    child: Text(
                      widget.customMessage ?? _getDefaultMessage(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(),
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),

                  // Bouton fermer pour certains types
                  if (widget.type == SyncNotificationType.offline ||
                      widget.type == SyncNotificationType.syncComplete)
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getTextColor().withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: _getTextColor(),
                        ),
                      ),
                    ),

                  // Indicateur de chargement pour syncing
                  if (widget.type == SyncNotificationType.syncing)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(left: 8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    switch (widget.type) {
      case SyncNotificationType.offline:
        iconData = Icons.wifi_off;
        break;
      case SyncNotificationType.syncing:
        iconData = Icons.sync;
        break;
      case SyncNotificationType.syncComplete:
        iconData = Icons.check_circle;
        break;
      case SyncNotificationType.none:
        iconData = Icons.info;
        break;
    }

    return Icon(
      iconData,
      color: Colors.white,
      size: 12,
    );
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case SyncNotificationType.offline:
        return const Color(0xFFFEF3C7); // Jaune très clair
      case SyncNotificationType.syncing:
        return const Color(0xFFDCFDF7); // Vert très clair
      case SyncNotificationType.syncComplete:
        return const Color(0xFFDCFDF7); // Vert très clair
      case SyncNotificationType.none:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case SyncNotificationType.offline:
        return const Color(0xFFF59E0B); // Jaune
      case SyncNotificationType.syncing:
        return const Color(0xFF10B981); // Vert
      case SyncNotificationType.syncComplete:
        return const Color(0xFF10B981); // Vert
      case SyncNotificationType.none:
        return const Color(0xFFE5E7EB);
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.type) {
      case SyncNotificationType.offline:
        return const Color(0xFFF59E0B); // Jaune (comme WiFi déconnecté)
      case SyncNotificationType.syncing:
        return const Color(0xFF10B981); // Vert (comme WiFi connecté)
      case SyncNotificationType.syncComplete:
        return const Color(0xFF10B981); // Vert
      case SyncNotificationType.none:
        return const Color(0xFF6B7280);
    }
  }

  Color _getShadowColor() {
    return _getIconBackgroundColor();
  }

  Color _getTextColor() {
    switch (widget.type) {
      case SyncNotificationType.offline:
        return const Color(0xFF92400E); // Jaune foncé
      case SyncNotificationType.syncing:
        return const Color(0xFF047857); // Vert foncé
      case SyncNotificationType.syncComplete:
        return const Color(0xFF047857); // Vert foncé
      case SyncNotificationType.none:
        return const Color(0xFF374151);
    }
  }

  String _getDefaultMessage() {
    switch (widget.type) {
      case SyncNotificationType.offline:
        return 'Pas de connexion • Données chargées depuis le cache local';
      case SyncNotificationType.syncing:
        return 'Synchronisation en cours • Mise à jour des données...';
      case SyncNotificationType.syncComplete:
        return 'Données synchronisées avec succès';
      case SyncNotificationType.none:
        return '';
    }
  }
}
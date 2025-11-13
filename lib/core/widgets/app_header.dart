import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header avec compte, titre et notifications
        Row(
          children: [
            // Bouton Profil à gauche
            InkWell(
              onTap: () {
                context.go('/compte');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            
            // Titre au centre avec gestion responsive
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textPainter = TextPainter(
                      text: TextSpan(
                        text: title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.3,
                        ),
                      ),
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                    );
                    textPainter.layout(maxWidth: constraints.maxWidth);
                    
                    if (textPainter.didExceedMaxLines) {
                      // Si le texte est trop long, utiliser un texte défilant
                      return SizedBox(
                        height: 24,
                        child: Marquee(
                          text: title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.3,
                          ),
                          scrollAxis: Axis.horizontal,
                          blankSpace: 50.0,
                          velocity: 30.0,
                          pauseAfterRound: const Duration(seconds: 2),
                          startPadding: 10.0,
                          accelerationDuration: const Duration(seconds: 1),
                          accelerationCurve: Curves.linear,
                          decelerationDuration: const Duration(milliseconds: 500),
                          decelerationCurve: Curves.easeOut,
                        ),
                      );
                    } else {
                      // Si le texte rentre, l'afficher normalement centré
                      return Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                  },
                ),
              ),
            ),
            
            // Indicateur de connexion et notifications à droite
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicateur de connexion
                Consumer<ConnectivityService>(
                  builder: (context, connectivityService, child) {
                    final isConnected = connectivityService.isConnected;
                    return Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isConnected 
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : const Color(0xFFEF4444).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        isConnected ? Icons.wifi : Icons.wifi_off,
                        color: Colors.white,
                        size: 12,
                      ),
                    );
                  },
                ),
                
                // Notifications
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFF6B7280),
                        size: 22,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4F46E5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        
        // Sous-titre si présent
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// Widget Marquee pour le texte défilant
class Marquee extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Axis scrollAxis;
  final double blankSpace;
  final double velocity;
  final Duration pauseAfterRound;
  final double startPadding;
  final Duration accelerationDuration;
  final Curve accelerationCurve;
  final Duration decelerationDuration;
  final Curve decelerationCurve;

  const Marquee({
    super.key,
    required this.text,
    this.style,
    this.scrollAxis = Axis.horizontal,
    this.blankSpace = 20.0,
    this.velocity = 50.0,
    this.pauseAfterRound = const Duration(seconds: 1),
    this.startPadding = 10.0,
    this.accelerationDuration = const Duration(seconds: 1),
    this.accelerationCurve = Curves.decelerate,
    this.decelerationDuration = const Duration(milliseconds: 500),
    this.decelerationCurve = Curves.easeOut,
  });

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (widget.text.length * 100).clamp(2000, 8000)),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    
    // Démarrer l'animation après une courte pause
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: Offset(-_animation.value * widget.text.length * 8, 0),
              child: Row(
                children: [
                  Text(widget.text, style: widget.style),
                  SizedBox(width: widget.blankSpace),
                  Text(widget.text, style: widget.style),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
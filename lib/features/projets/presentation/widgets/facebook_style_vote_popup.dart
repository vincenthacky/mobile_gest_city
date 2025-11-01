import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/project_model.dart';

class FacebookStyleVotePopup extends StatefulWidget {
  final ProjectModel project;
  final Function(VoteChoice choice, String? justification) onVoteSubmitted;
  final GlobalKey buttonKey;

  const FacebookStyleVotePopup({
    super.key,
    required this.project,
    required this.onVoteSubmitted,
    required this.buttonKey,
  });

  @override
  State<FacebookStyleVotePopup> createState() => _FacebookStyleVotePopupState();
}

class _FacebookStyleVotePopupState extends State<FacebookStyleVotePopup>
    with TickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late AnimationController _textAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showReactions();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textAnimationController.dispose();
    _commentController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _showReactions() {
    _overlayEntry = _createOverlayEntry(false);
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _showCommentFieldOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry(true);
    Overlay.of(context).insert(_overlayEntry!);
    _textAnimationController.forward();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onVoteSelected(VoteChoice choice) {
    if (choice == VoteChoice.yesWithReserve) {
      _showCommentFieldOverlay();
    } else {
      widget.onVoteSubmitted(choice, null);
      _closePopup();
    }
  }

  void _submitComment() {
    final comment = _commentController.text.trim();
    widget.onVoteSubmitted(VoteChoice.yesWithReserve, comment.isEmpty ? null : comment);
    _closePopup();
  }

  void _closePopup() {
    _animationController.reverse().then((_) {
      _removeOverlay();
      Navigator.of(context).pop();
    });
  }

  RenderBox _getButtonRenderBox() {
    return widget.buttonKey.currentContext!.findRenderObject() as RenderBox;
  }

  Offset _getButtonPosition() {
    final renderBox = _getButtonRenderBox();
    return renderBox.localToGlobal(Offset.zero);
  }

  Size _getButtonSize() {
    final renderBox = _getButtonRenderBox();
    return renderBox.size;
  }

  OverlayEntry _createOverlayEntry(bool isCommentMode) {
    final buttonPosition = _getButtonPosition();
    final buttonSize = _getButtonSize();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculer la largeur du popup
    final popupWidth = isCommentMode ? 350.0 : 400.0;
    
    // Centrer horizontalement par rapport au bouton, mais s'assurer que ça reste dans l'écran
    double leftPosition = buttonPosition.dx + (buttonSize.width / 2) - (popupWidth / 2);
    
    // Corrections pour rester dans l'écran
    const margin = 20.0;
    if (leftPosition < margin) {
      leftPosition = margin;
    } else if (leftPosition + popupWidth > screenWidth - margin) {
      leftPosition = screenWidth - popupWidth - margin;
    }
    
    return OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _closePopup,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Stack(
              children: [
                Positioned(
                  left: leftPosition,
                  bottom: screenHeight - buttonPosition.dy + 10,
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping on the popup
                    child: isCommentMode ? _buildCommentField() : _buildReactionsContainer(),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReactionsContainer() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * 20,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 8,
                            offset: const Offset(-2, -2),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(2, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildReactionItem(
                            icon: Icons.thumb_up,
                            label: 'Oui',
                            color: const Color(0xFF10B981),
                            onTap: () => _onVoteSelected(VoteChoice.yes),
                          ),
                          const SizedBox(width: 18),
                          _buildReactionItem(
                            icon: Icons.thumb_down,
                            label: 'Non',
                            color: const Color(0xFFEF4444),
                            onTap: () => _onVoteSelected(VoteChoice.no),
                          ),
                          const SizedBox(width: 18),
                          _buildReactionItem(
                            icon: Icons.edit_note,
                            label: 'Oui sous réserve',
                            color: const Color(0xFFF97316),
                            onTap: () => _onVoteSelected(VoteChoice.yesWithReserve),
                          ),
                          const SizedBox(width: 18),
                          _buildReactionItem(
                            icon: Icons.radio_button_unchecked,
                            label: 'Neutre',
                            color: const Color(0xFF6B7280),
                            onTap: () => _onVoteSelected(VoteChoice.blank),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isHovered ? 1.4 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          blurRadius: 1,
                        ),
                      ],
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

  Widget _buildCommentField() {
    return AnimatedBuilder(
      animation: _textAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _textAnimationController.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    width: 350,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 8,
                          offset: const Offset(-2, -2),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(2, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 1,
                            ),
                          ],
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ajouter un commentaire...',
                          hintStyle: TextStyle(
                            color: Colors.grey[700],
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.4),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _submitComment,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34c759),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Ce widget ne rend rien directement
  }
}

// Widget helper pour afficher le popup
class FacebookStyleVoteManager {
  static void showVotePopup({
    required BuildContext context,
    required ProjectModel project,
    required Function(VoteChoice choice, String? justification) onVoteSubmitted,
    required GlobalKey buttonKey,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FacebookStyleVotePopup(
            project: project,
            onVoteSubmitted: onVoteSubmitted,
            buttonKey: buttonKey,
          );
        },
      ),
    );
  }
}
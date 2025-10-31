import 'package:flutter/material.dart';
import '../../models/project_model.dart';

class VotePopup extends StatefulWidget {
  final ProjectModel project;
  final Function(VoteChoice choice, String? justification) onVoteSubmitted;

  const VotePopup({
    super.key,
    required this.project,
    required this.onVoteSubmitted,
  });

  @override
  State<VotePopup> createState() => _VotePopupState();
}

class _VotePopupState extends State<VotePopup> {
  VoteChoice? _selectedChoice;
  final TextEditingController _justificationController = TextEditingController();
  bool _showJustification = false;

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  void _onChoiceSelected(VoteChoice choice) {
    setState(() {
      _selectedChoice = choice;
      _showJustification = choice == VoteChoice.yes || choice == VoteChoice.yesWithReserve;
      if (!_showJustification) {
        _justificationController.clear();
      }
    });
  }

  void _submitVote() {
    if (_selectedChoice != null) {
      widget.onVoteSubmitted(
        _selectedChoice!,
        _justificationController.text.isEmpty ? null : _justificationController.text,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.how_to_vote,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Votre vote',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.project.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.project.shortDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Votre choix :',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            
            Column(
              children: [
                _buildVoteOption(
                  VoteChoice.yes,
                  '👍',
                  'Oui',
                  'Je soutiens ce projet',
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                _buildVoteOption(
                  VoteChoice.no,
                  '👎',
                  'Non',
                  'Je ne soutiens pas ce projet',
                  const Color(0xFFEF4444),
                ),
                const SizedBox(height: 12),
                _buildVoteOption(
                  VoteChoice.yesWithReserve,
                  '⚠️',
                  'Oui sous réserve',
                  'Je soutiens avec des conditions',
                  const Color(0xFFF97316),
                ),
                const SizedBox(height: 12),
                _buildVoteOption(
                  VoteChoice.blank,
                  '⚪',
                  'Vote blanc',
                  'Je m\'abstiens',
                  const Color(0xFF6B7280),
                ),
              ],
            ),
            
            if (_showJustification) ...[
              const SizedBox(height: 24),
              const Text(
                'Justification ou condition :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _justificationController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: _selectedChoice == VoteChoice.yes
                        ? 'Pourquoi soutenez-vous ce projet ? (optionnel)'
                        : 'Quelles sont vos conditions ? (optionnel)',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontFamily: 'Nunito',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedChoice != null ? _submitVote : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Valider mon vote',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
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
  }

  Widget _buildVoteOption(
    VoteChoice choice,
    String emoji,
    String title,
    String description,
    Color color,
  ) {
    final isSelected = _selectedChoice == choice;
    
    return GestureDetector(
      onTap: () => _onChoiceSelected(choice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : const Color(0xFF1F2937),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? color.withValues(alpha: 0.8) : const Color(0xFF6B7280),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
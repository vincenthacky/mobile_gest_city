import 'package:flutter/material.dart';
import '../../models/project_model.dart';

class ProjectFilters extends StatelessWidget {
  final ProjectStatus? selectedStatus;
  final Function(ProjectStatus?) onFilterChanged;

  const ProjectFilters({
    super.key,
    required this.selectedStatus,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Détection du thème système
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode = platformBrightness == Brightness.dark;
    
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            'Tous',
            null,
            selectedStatus == null,
            Icons.apps,
            isDarkMode,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Vote ouvert',
            ProjectStatus.voteOpen,
            selectedStatus == ProjectStatus.voteOpen,
            Icons.how_to_vote,
            isDarkMode,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Pas encore ouvert',
            ProjectStatus.voteNotOpen,
            selectedStatus == ProjectStatus.voteNotOpen,
            Icons.schedule,
            isDarkMode,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Vote clos',
            ProjectStatus.voteClosed,
            selectedStatus == ProjectStatus.voteClosed,
            Icons.lock_clock,
            isDarkMode,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Accepté',
            ProjectStatus.accepted,
            selectedStatus == ProjectStatus.accepted,
            Icons.check_circle,
            isDarkMode,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Rejeté',
            ProjectStatus.rejected,
            selectedStatus == ProjectStatus.rejected,
            Icons.cancel,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    ProjectStatus? status,
    bool isSelected,
    IconData icon,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: () => onFilterChanged(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF3B82F6) 
              : isDarkMode 
                  ? const Color(0xFF1E293B)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF3B82F6) 
                : isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected 
                  ? Colors.white 
                  : isDarkMode 
                      ? const Color(0xFF8696A0)
                      : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? Colors.white 
                    : isDarkMode 
                        ? const Color(0xFFE1E7ED)
                        : const Color(0xFF374151),
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
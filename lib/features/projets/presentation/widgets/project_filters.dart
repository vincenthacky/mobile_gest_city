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
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            'Tous',
            null,
            selectedStatus == null,
            Icons.apps,
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            'Vote ouvert',
            ProjectStatus.voteOpen,
            selectedStatus == ProjectStatus.voteOpen,
            Icons.how_to_vote,
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            'Pas encore ouvert',
            ProjectStatus.voteNotOpen,
            selectedStatus == ProjectStatus.voteNotOpen,
            Icons.schedule,
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            'Vote clos',
            ProjectStatus.voteClosed,
            selectedStatus == ProjectStatus.voteClosed,
            Icons.lock_clock,
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            'Accepté',
            ProjectStatus.accepted,
            selectedStatus == ProjectStatus.accepted,
            Icons.check_circle,
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            'Rejeté',
            ProjectStatus.rejected,
            selectedStatus == ProjectStatus.rejected,
            Icons.cancel,
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
  ) {
    return GestureDetector(
      onTap: () => onFilterChanged(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF3B82F6) 
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
                    color: Colors.black.withValues(alpha: 0.05),
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
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF374151),
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
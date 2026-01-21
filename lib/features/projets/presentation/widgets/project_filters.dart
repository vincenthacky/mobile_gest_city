import 'package:flutter/material.dart';
import '../../models/project_model.dart';

enum VoteFilter { all, notVoted, alreadyVoted }

class ProjectFilters extends StatelessWidget {
  final ProjectStatus? selectedStatus;
  final VoteFilter? selectedVoteFilter;
  final Function(ProjectStatus?) onFilterChanged;
  final Function(VoteFilter?) onVoteFilterChanged;

  const ProjectFilters({
    super.key,
    required this.selectedStatus,
    this.selectedVoteFilter,
    required this.onFilterChanged,
    required this.onVoteFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatusFilterChip(
            'Vote ouvert',
            ProjectStatus.voteOpen,
            selectedStatus == ProjectStatus.voteOpen && selectedVoteFilter == null,
            Icons.how_to_vote,
          ),
          const SizedBox(width: 8),
          _buildStatusFilterChip(
            'Pas encore ouvert',
            ProjectStatus.voteNotOpen,
            selectedStatus == ProjectStatus.voteNotOpen && selectedVoteFilter == null,
            Icons.schedule,
          ),
          const SizedBox(width: 8),
          _buildVoteFilterChip(
            'Projets pas votés',
            VoteFilter.notVoted,
            selectedVoteFilter == VoteFilter.notVoted && selectedStatus == null,
            Icons.thumbs_up_down,
          ),
          const SizedBox(width: 8),
          _buildVoteFilterChip(
            'Projets déjà votés',
            VoteFilter.alreadyVoted,
            selectedVoteFilter == VoteFilter.alreadyVoted && selectedStatus == null,
            Icons.how_to_vote_outlined,
          ),
          const SizedBox(width: 8),
          _buildStatusFilterChip(
            'Tous',
            null,
            selectedStatus == null && selectedVoteFilter == null,
            Icons.apps,
          ),
          const SizedBox(width: 8),
          _buildStatusFilterChip(
            'Vote clos',
            ProjectStatus.voteClosed,
            selectedStatus == ProjectStatus.voteClosed && selectedVoteFilter == null,
            Icons.lock_clock,
          ),
          const SizedBox(width: 8),
          _buildStatusFilterChip(
            'Accepté',
            ProjectStatus.accepted,
            selectedStatus == ProjectStatus.accepted && selectedVoteFilter == null,
            Icons.check_circle,
          ),
          const SizedBox(width: 8),
          _buildStatusFilterChip(
            'Rejeté',
            ProjectStatus.rejected,
            selectedStatus == ProjectStatus.rejected && selectedVoteFilter == null,
            Icons.cancel,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(
    String label,
    ProjectStatus? status,
    bool isSelected,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        onFilterChanged(status);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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

  Widget _buildVoteFilterChip(
    String label,
    VoteFilter filter,
    bool isSelected,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        onVoteFilterChanged(filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
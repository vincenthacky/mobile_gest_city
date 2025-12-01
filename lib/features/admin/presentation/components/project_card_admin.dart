import 'package:flutter/material.dart';
import '../../../projets/models/project_model.dart';

class ProjectCardAdmin extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback? onOpenVote;

  const ProjectCardAdmin({
    super.key,
    required this.project,
    required this.onTap,
    this.onOpenVote,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 12,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              project.displayAuthorName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                                fontFamily: 'Nunito',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: project.statusColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              project.statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: project.statusColor,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // DESCRIPTION
            Text(
              project.shortDescription,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
                fontFamily: 'Nunito',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // BUDGET & DATE
            Row(
              children: [
                _pillWithIcon(
                  icon: Icons.attach_money,
                  label: project.formattedEstimatedAmount,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                if (project.voteCloseDate != null &&
                    project.status != ProjectStatus.voteNotOpen)
                  _pillWithIcon(
                    icon: Icons.schedule,
                    label: project.formattedVoteCloseDate,
                    color: Colors.orange,
                  ),
                const Spacer(),
                if (project.hasImages)
                  _pillWithIcon(
                    icon: Icons.photo_library,
                    label: '${project.imageCount}',
                    color: const Color(0xFF8B5CF6),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // BOUTON OUVRIR VOTE ou MESSAGE
            if (onOpenVote != null) ...[
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: onOpenVote,
                  icon: const Icon(Icons.how_to_vote, size: 18),
                  label: const Text(
                    'Ouvrir le vote',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              _buildAdminStatusMessage(project),
            ],

            const SizedBox(height: 8),

            // RÉSULTATS DES VOTES (toujours afficher si votes > 0)
            if (project.totalVotes > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _voteItemWithIcon(
                    'Votes Oui',
                    Icons.thumb_up,
                    project.votesYes,
                    const Color(0xFF10B981),
                  ),
                  _voteItemWithIcon(
                    'Oui sous réserve',
                    Icons.edit_note,
                    project.votesYesWithReserve,
                    const Color(0xFFF97316),
                  ),
                  _voteItemWithIcon(
                    'Neutres',
                    Icons.radio_button_unchecked,
                    project.votesBlank,
                    const Color(0xFF6B7280),
                  ),
                  _voteItemWithIcon(
                    'Votes Non',
                    Icons.thumb_down,
                    project.votesNo,
                    const Color(0xFFEF4444),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _pillWithIcon({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _voteItemWithIcon(
    String label,
    IconData icon,
    int value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF475569),
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatusMessage(ProjectModel project) {
    String message;
    IconData icon;
    Color color;

    if (project.status == ProjectStatus.voteOpen) {
      message = 'Vote en cours';
      icon = Icons.how_to_vote;
      color = const Color(0xFF10B981);
    } else if (project.status == ProjectStatus.voteClosed) {
      message = 'Vote terminé';
      icon = Icons.how_to_vote_outlined;
      color = const Color(0xFF475569);
    } else if (project.status == ProjectStatus.accepted) {
      message = 'Projet accepté';
      icon = Icons.check_circle;
      color = const Color(0xFF10B981);
    } else if (project.status == ProjectStatus.rejected) {
      message = 'Projet rejeté';
      icon = Icons.cancel;
      color = const Color(0xFFEF4444);
    } else {
      message = 'En attente d\'ouverture';
      icon = Icons.schedule;
      color = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

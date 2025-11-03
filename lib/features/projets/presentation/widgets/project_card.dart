import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import 'facebook_style_vote_popup.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final Function(VoteChoice choice, String? justification)? onVote;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onVote,
  });

  bool get isVoteOpen => project.status == ProjectStatus.voteOpen;
  bool get isVoteNotOpen => project.status == ProjectStatus.voteNotOpen;
  bool get isVoteClosed => project.status == ProjectStatus.voteClosed || project.status == ProjectStatus.accepted;

  @override
  Widget build(BuildContext context) {
    final GlobalKey buttonKey = GlobalKey();
    final GlobalKey statusKey = GlobalKey();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: project.hasUserVoted
              ? Border.all(
                  color: project.voteChoiceColor.withOpacity(0.18),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER (icone + titre + auteur + statut pill top-right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Color(0xFF6B7280)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              project.authorName ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontFamily: 'Nunito',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // STATUS PILL (en haut droite)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: project.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    project.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: project.statusColor,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // DESCRIPTION
            Text(
              project.shortDescription,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
                fontFamily: 'Nunito',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 14),

            // BUDGET & DATE PILLs (montant avec span, jour de clôture avec span)
            Row(
              children: [
                _pillWithIcon(
                  icon: Icons.euro,
                  label: project.formattedEstimatedAmount,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                if (project.voteCloseDate != null)
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
                if (project.hasImages && project.hasAttachments) const SizedBox(width: 8),
                if (project.hasAttachments && !project.hasImages)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7280).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.attach_file,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // VOTER + VOIR PLUS sur la même ligne (ou message selon status)
            if (isVoteOpen && project.canVote && onVote != null) ...[
              Row(
                children: [
                  // Bouton Voter (50% de la largeur)
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        key: buttonKey,
                        onPressed: onVote != null ? () {
                          FacebookStyleVoteManager.showVotePopup(
                            context: context,
                            project: project,
                            onVoteSubmitted: onVote!,
                            buttonKey: buttonKey,
                          );
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Voter',
                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  // Espace entre les deux
                  const Spacer(),
                  // Voir plus aligné à droite
                  GestureDetector(
                    onTap: onTap,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Voir plus',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B82F6),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF3B82F6)),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 6),
              // Message conditionnel en remplacement du bouton
              _statusMessage(context, project, statusKey),
            ],

            const SizedBox(height: 14),

            // Votes (4 colonnes sur une seule ligne)
            if (project.totalVotes > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _voteItemWithIcon('Votes Oui', Icons.thumb_up, project.votesYes, const Color(0xFF10B981)),
                  _voteItemWithIcon('Oui sous réserve', Icons.edit_note, project.votesYesWithReserve, const Color(0xFFF97316)),
                  _voteItemWithIcon('Neutres', Icons.radio_button_unchecked, project.votesBlank, const Color(0xFF6B7280)),
                  _voteItemWithIcon('Votes Non', Icons.thumb_down, project.votesNo, const Color(0xFFEF4444)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _pillWithIcon({required IconData icon, required String label, required Color color}) {
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

  Widget _voteItemWithIcon(String label, IconData icon, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontFamily: 'Nunito')),
          const SizedBox(height: 6),
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

  Widget _statusMessage(BuildContext context, ProjectModel project, GlobalKey statusKey) {
    // Trois cas principaux : vote pas encore ouvert, vote terminé, utilisateur a voté
    if (project.hasUserVoted) {
      // Affiche type de vote choisi par l'utilisateur - CLIQUABLE pour modifier
      return GestureDetector(
        onTap: onVote != null ? () {
          FacebookStyleVoteManager.showVotePopup(
            context: context,
            project: project,
            onVoteSubmitted: onVote!,
            buttonKey: statusKey,
          );
        } : null,
        child: Container(
          key: statusKey,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                project.voteChoiceColor.withValues(alpha: 0.15),
                project.voteChoiceColor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: project.voteChoiceColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconForChoice(project.voteChoiceText), color: project.voteChoiceColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vous avez voté : ${project.voteChoiceText}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: project.voteChoiceColor,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Icon(
                Icons.edit,
                color: project.voteChoiceColor.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      );
    }

    if (isVoteNotOpen) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 18, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Vote pas encore ouvert',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.orange,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    // par défaut : vote terminé / accepté
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.how_to_vote_outlined, size: 18, color: Color(0xFF6B7280)),
          SizedBox(width: 8),
          Text(
            'Vote terminé',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForChoice(String choice) {
    // choice attendu: 'Oui', 'Non', 'Sous réserve', 'Neutre' (adapter selon ton modèle)
    final lower = choice.toLowerCase();
    if (lower.contains('oui') && lower.contains('réserve')) return Icons.edit_note;
    if (lower.contains('oui')) return Icons.thumb_up;
    if (lower.contains('non')) return Icons.thumb_down;
    if (lower.contains('neutre') || lower.contains('blanc')) return Icons.radio_button_unchecked;
    return Icons.radio_button_unchecked;
  }

}

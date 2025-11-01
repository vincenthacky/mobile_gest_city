import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import 'facebook_style_vote_popup.dart';

class ProjectDetailModal extends StatefulWidget {
  final ProjectModel project;
  final Function(ProjectModel project, VoteChoice choice, String? justification) onVoteSubmitted;

  const ProjectDetailModal({
    super.key,
    required this.project,
    required this.onVoteSubmitted,
  });

  @override
  State<ProjectDetailModal> createState() => _ProjectDetailModalState();
}

class _ProjectDetailModalState extends State<ProjectDetailModal> {
  final GlobalKey _voteButtonKey = GlobalKey();

  void _showVotePopup() {
    FacebookStyleVoteManager.showVotePopup(
      context: context,
      project: widget.project,
      onVoteSubmitted: (choice, justification) {
        widget.onVoteSubmitted(widget.project, choice, justification);
      },
      buttonKey: _voteButtonKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectHeader(),
                  const SizedBox(height: 24),
                  _buildDescriptionSection(),
                  const SizedBox(height: 20),
                  _buildProjectInfoSection(),
                  const SizedBox(height: 20),
                  if (widget.project.totalVotes > 0) ...[
                    _buildVoteResultsSection(),
                    const SizedBox(height: 20),
                  ],
                  if (widget.project.totalVotes > 0) ...[
                    _buildVotersSection(),
                    const SizedBox(height: 20),
                  ],
                  if (widget.project.canVote) ...[
                    _buildVoteSection(),
                  ] else if (widget.project.hasUserVoted) ...[
                    _buildUserVoteStatus(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_balance,
            color: Color(0xFF3B82F6),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.project.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Par ${widget.project.authorName}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.project.statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.project.statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.project.statusColor,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 8,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description complète',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.project.longDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 8,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du projet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.euro, 'Budget estimé', widget.project.formattedEstimatedAmount, const Color(0xFF10B981)),
          _buildInfoRow(Icons.settings, 'Mise en œuvre', widget.project.implementationTypeText, const Color(0xFF8B5CF6)),
          if (widget.project.providerName != null)
            _buildInfoRow(Icons.business, 'Prestataire', widget.project.providerName!, const Color(0xFF3B82F6)),
          if (widget.project.voteCloseDate != null)
            _buildInfoRow(Icons.schedule, 'Clôture du vote', widget.project.formattedVoteCloseDate, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildVoteResultsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 8,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résultats du vote',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          _buildVoteResult(Icons.thumb_up, 'Oui', widget.project.votesYes, widget.project.yesPercentage, const Color(0xFF10B981)),
          _buildVoteResult(Icons.thumb_down, 'Non', widget.project.votesNo, widget.project.noPercentage, const Color(0xFFEF4444)),
          _buildVoteResult(Icons.edit_note, 'Oui sous réserve', widget.project.votesYesWithReserve, widget.project.yesWithReservePercentage, const Color(0xFFF97316)),
          _buildVoteResult(Icons.radio_button_unchecked, 'Neutre', widget.project.votesBlank, widget.project.blankPercentage, const Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _buildVotersSection() {
    final voters = _getProjectVoters(widget.project.id);
    if (voters.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 8,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Liste des votants',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          ...voters.map((voter) => _buildVoterItem(voter)),
        ],
      ),
    );
  }

  Widget _buildVoteSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 8,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Votre vote',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: _voteButtonKey,
              onPressed: () {
                Navigator.pop(context);
                _showVotePopup();
              },
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
                'Voter sur ce projet',
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
    );
  }

  Widget _buildUserVoteStatus() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showVotePopup();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.project.voteChoiceColor.withValues(alpha: 0.15),
              widget.project.voteChoiceColor.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.project.voteChoiceColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 8,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.how_to_vote,
                  color: widget.project.voteChoiceColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous avez voté: ${widget.project.voteChoiceText}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.project.voteChoiceColor,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Icon(
                  Icons.edit,
                  color: widget.project.voteChoiceColor.withValues(alpha: 0.7),
                  size: 18,
                ),
              ],
            ),
            if (widget.project.userVoteJustification != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.project.userVoteJustification!,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.project.voteChoiceColor,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Nunito',
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Touchez pour modifier votre vote',
              style: TextStyle(
                fontSize: 12,
                color: widget.project.voteChoiceColor.withValues(alpha: 0.8),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteResult(IconData icon, String label, int votes, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Nunito',
                      ),
                    ),
                    Text(
                      '$votes votes (${(percentage * 100).round()}%)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoterItem(Map<String, dynamic> voter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: voter['color'],
              shape: BoxShape.circle,
            ),
            child: Icon(
              voter['icon'],
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              voter['name'],
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            voter['vote'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: voter['color'],
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getProjectVoters(String projectId) {
    switch (projectId) {
      case '1':
        return [
          {'name': 'Luc Dubois', 'vote': 'Oui', 'color': const Color(0xFF10B981), 'icon': Icons.thumb_up},
          {'name': 'Emma Rousseau', 'vote': 'Oui', 'color': const Color(0xFF10B981), 'icon': Icons.thumb_up},
          {'name': 'Paul Vincent', 'vote': 'Non', 'color': const Color(0xFFEF4444), 'icon': Icons.thumb_down},
          {'name': 'Julie Garnier', 'vote': 'Oui sous réserve', 'color': const Color(0xFFF97316), 'icon': Icons.edit_note},
          {'name': 'Marc Petit', 'vote': 'Oui', 'color': const Color(0xFF10B981), 'icon': Icons.thumb_up},
          {'name': 'Lea Morel', 'vote': 'Neutre', 'color': const Color(0xFF6B7280), 'icon': Icons.radio_button_unchecked},
          {'name': 'Alex David', 'vote': 'Oui', 'color': const Color(0xFF10B981), 'icon': Icons.thumb_up},
          {'name': 'Nina Lambert', 'vote': 'Non', 'color': const Color(0xFFEF4444), 'icon': Icons.thumb_down},
        ];
      case '2':
        return [
          {'name': 'Marie Dupont', 'vote': 'Oui', 'color': const Color(0xFF10B981), 'icon': Icons.thumb_up},
          {'name': 'Jean Martin', 'vote': 'Oui', 'color': const Color(0xFF10B981), 'icon': Icons.thumb_up},
          {'name': 'Sophie Bernard', 'vote': 'Non', 'color': const Color(0xFFEF4444), 'icon': Icons.thumb_down},
          {'name': 'Pierre Lefebvre', 'vote': 'Oui sous réserve', 'color': const Color(0xFFF97316), 'icon': Icons.edit_note},
          {'name': 'Anne Durand', 'vote': 'Oui', 'color': const Color(0xFF10B981), 'icon': Icons.thumb_up},
          {'name': 'Thomas Moreau', 'vote': 'Neutre', 'color': const Color(0xFF6B7280), 'icon': Icons.radio_button_unchecked},
        ];
      default:
        return [];
    }
  }
}
/// Advanced Bracket Visualization Service with animations and interactive features
/// Phase 2 enhancement of the basic bracket system
class AdvancedBracketVisualizationService {
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Curve _animationCurve = Curves.easeInOut;

  /// Build animated bracket with interactive features
  static Widget buildAnimatedBracket({
    required Tournament tournament,
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    bool showAnimations = true,
    bool enableInteractions = true,
  }) {
    return AnimatedContainer(
      duration: _animationDuration,
      curve: _animationCurve,
      child: _buildFormatSpecificBracket(
        tournament: tournament,
        participants: participants,
        matches: matches,
        onMatchTap: onMatchTap,
        onParticipantTap: onParticipantTap,
        showAnimations: showAnimations,
        enableInteractions: enableInteractions,
      ),
    );
  }

  /// Build format-specific bracket with advanced visualization
  static Widget _buildFormatSpecificBracket({
    required Tournament tournament,
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    switch (tournament.format) {
      case 'single_elimination':
        return _buildAnimatedSingleElimination(
          participants: participants,
          matches: matches,
          onMatchTap: onMatchTap,
          onParticipantTap: onParticipantTap,
          showAnimations: showAnimations,
          enableInteractions: enableInteractions,
        );

      case 'double_elimination':
        return _buildAnimatedDoubleElimination(
          participants: participants,
          matches: matches,
          onMatchTap: onMatchTap,
          onParticipantTap: onParticipantTap,
          showAnimations: showAnimations,
          enableInteractions: enableInteractions,
        );

      case 'sabo_de16':
      case 'sabo_de32':
        return _buildAnimatedSABOBracket(
          tournament: tournament,
          participants: participants,
          matches: matches,
          onMatchTap: onMatchTap,
          onParticipantTap: onParticipantTap,
          showAnimations: showAnimations,
          enableInteractions: enableInteractions,
        );

      case 'round_robin':
        return _buildAnimatedRoundRobin(
          participants: participants,
          matches: matches,
          onMatchTap: onMatchTap,
          onParticipantTap: onParticipantTap,
          showAnimations: showAnimations,
          enableInteractions: enableInteractions,
        );

      case 'swiss':
        return _buildAnimatedSwiss(
          participants: participants,
          matches: matches,
          onMatchTap: onMatchTap,
          onParticipantTap: onParticipantTap,
          showAnimations: showAnimations,
          enableInteractions: enableInteractions,
        );

      case 'ladder':
        return _buildAnimatedLadder(
          participants: participants,
          matches: matches,
          onMatchTap: onMatchTap,
          onParticipantTap: onParticipantTap,
          showAnimations: showAnimations,
          enableInteractions: enableInteractions,
        );

      default:
        return _buildGenericAnimatedBracket(
          participants: participants,
          matches: matches,
          onMatchTap: onMatchTap,
          onParticipantTap: onParticipantTap,
          showAnimations: showAnimations,
          enableInteractions: enableInteractions,
        );
    }
  }

  /// Build animated Single Elimination bracket
  static Widget _buildAnimatedSingleElimination({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdvancedBracketHeader(
              title: 'Single Elimination Bracket',
              participantCount: participants.length,
              showAnimations: showAnimations,
            ),
            const SizedBox(height: 20),
            _buildSingleEliminationTree(
              participants: participants,
              matches: matches,
              onMatchTap: onMatchTap,
              onParticipantTap: onParticipantTap,
              showAnimations: showAnimations,
              enableInteractions: enableInteractions,
            ),
          ],
        ),
      ),
    );
  }

  /// Build animated Double Elimination bracket
  static Widget _buildAnimatedDoubleElimination({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    final winnerMatches =
        matches.where((m) => m.bracketType == 'winner').toList();
    final loserMatches =
        matches.where((m) => m.bracketType == 'loser').toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdvancedBracketHeader(
              title: 'Double Elimination Bracket',
              participantCount: participants.length,
              showAnimations: showAnimations,
            ),
            const SizedBox(height: 20),

            // Winner Bracket
            _buildBracketSection(
              title: 'Winner Bracket',
              matches: winnerMatches,
              participants: participants,
              onMatchTap: onMatchTap,
              onParticipantTap: onParticipantTap,
              showAnimations: showAnimations,
              enableInteractions: enableInteractions,
              sectionColor: Colors.green.shade100,
            ),

            const SizedBox(height: 30),

            // Loser Bracket
            _buildBracketSection(
              title: 'Loser Bracket',
              matches: loserMatches,
              participants: participants,
              onMatchTap: onMatchTap,
              onParticipantTap: onParticipantTap,
              showAnimations: showAnimations,
              enableInteractions: enableInteractions,
              sectionColor: Colors.orange.shade100,
            ),
          ],
        ),
      ),
    );
  }

  /// Build animated SABO bracket
  static Widget _buildAnimatedSABOBracket({
    required Tournament tournament,
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    final isSABO32 = tournament.format == 'sabo_de32';
    final title = isSABO32 ? "SABO DE32 Bracket" : 'SABO DE16 Bracket';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdvancedBracketHeader(
              title: title,
              participantCount: participants.length,
              showAnimations: showAnimations,
            ),
            const SizedBox(height: 20),

            if (isSABO32) ...[
              // Group Stage for DE32
              _buildSABOGroupStage(
                participants: participants,
                matches: matches,
                onMatchTap: onMatchTap,
                onParticipantTap: onParticipantTap,
                showAnimations: showAnimations,
                enableInteractions: enableInteractions,
              ),
              const SizedBox(height: 30),
            ],

            // Elimination Stage
            _buildSABOEliminationStage(
              participants: participants,
              matches: matches,
              onMatchTap: onMatchTap,
              onParticipantTap: onParticipantTap,
              showAnimations: showAnimations,
              enableInteractions: enableInteractions,
            ),
          ],
        ),
      ),
    );
  }

  /// Build animated Round Robin bracket
  static Widget _buildAnimatedRoundRobin({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedBracketHeader(
            title: 'Round Robin Tournament',
            participantCount: participants.length,
            showAnimations: showAnimations,
          ),
          const SizedBox(height: 20),
          _buildRoundRobinMatrix(
            participants: participants,
            matches: matches,
            onMatchTap: onMatchTap,
            onParticipantTap: onParticipantTap,
            showAnimations: showAnimations,
            enableInteractions: enableInteractions,
          ),
        ],
      ),
    );
  }

  /// Build animated Swiss bracket
  static Widget _buildAnimatedSwiss({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedBracketHeader(
            title: 'Swiss Tournament',
            participantCount: participants.length,
            showAnimations: showAnimations,
          ),
          const SizedBox(height: 20),
          _buildSwissRounds(
            participants: participants,
            matches: matches,
            onMatchTap: onMatchTap,
            onParticipantTap: onParticipantTap,
            showAnimations: showAnimations,
            enableInteractions: enableInteractions,
          ),
        ],
      ),
    );
  }

  /// Build animated Ladder bracket
  static Widget _buildAnimatedLadder({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedBracketHeader(
            title: 'Ladder Tournament',
            participantCount: participants.length,
            showAnimations: showAnimations,
          ),
          const SizedBox(height: 20),
          _buildLadderRanking(
            participants: participants,
            matches: matches,
            onMatchTap: onMatchTap,
            onParticipantTap: onParticipantTap,
            showAnimations: showAnimations,
            enableInteractions: enableInteractions,
          ),
        ],
      ),
    );
  }

  /// Build generic animated bracket
  static Widget _buildGenericAnimatedBracket({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedBracketHeader(
            title: 'Tournament Bracket',
            participantCount: participants.length,
            showAnimations: showAnimations,
          ),
          const SizedBox(height: 20),
          _buildGenericMatchList(
            participants: participants,
            matches: matches,
            onMatchTap: onMatchTap,
            onParticipantTap: onParticipantTap,
            showAnimations: showAnimations,
            enableInteractions: enableInteractions,
          ),
        ],
      ),
    );
  }

  // Advanced UI Components

  /// Build advanced bracket header with animations
  static Widget _buildAdvancedBracketHeader({
    required String title,
    required int participantCount,
    required bool showAnimations,
  }) {
    return AnimatedContainer(
      duration: showAnimations ? _animationDuration : Duration.zero,
      curve: _animationCurve,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$participantCount players',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build bracket section with title and matches
  static Widget _buildBracketSection({
    required String title,
    required List<Match> matches,
    required List<TournamentParticipant> participants,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
    required Color sectionColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildMatchGrid(
            matches: matches,
            participants: participants,
            onMatchTap: onMatchTap,
            onParticipantTap: onParticipantTap,
            showAnimations: showAnimations,
            enableInteractions: enableInteractions,
          ),
        ],
      ),
    );
  }

  // Placeholder methods for specific bracket implementations

  static Widget _buildSingleEliminationTree({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    // Implement single elimination tree structure
    return _buildMatchGrid(
      matches: matches,
      participants: participants,
      onMatchTap: onMatchTap,
      onParticipantTap: onParticipantTap,
      showAnimations: showAnimations,
      enableInteractions: enableInteractions,
    );
  }

  static Widget _buildSABOGroupStage({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    // Implement SABO group stage
    return _buildMatchGrid(
      matches: matches.where((m) => m.round <= 3).toList(),
      participants: participants,
      onMatchTap: onMatchTap,
      onParticipantTap: onParticipantTap,
      showAnimations: showAnimations,
      enableInteractions: enableInteractions,
    );
  }

  static Widget _buildSABOEliminationStage({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    // Implement SABO elimination stage
    return _buildMatchGrid(
      matches: matches.where((m) => m.round > 3).toList(),
      participants: participants,
      onMatchTap: onMatchTap,
      onParticipantTap: onParticipantTap,
      showAnimations: showAnimations,
      enableInteractions: enableInteractions,
    );
  }

  static Widget _buildRoundRobinMatrix({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    // Implement round robin matrix
    return _buildMatchGrid(
      matches: matches,
      participants: participants,
      onMatchTap: onMatchTap,
      onParticipantTap: onParticipantTap,
      showAnimations: showAnimations,
      enableInteractions: enableInteractions,
    );
  }

  static Widget _buildSwissRounds({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    // Implement Swiss rounds
    return _buildMatchGrid(
      matches: matches,
      participants: participants,
      onMatchTap: onMatchTap,
      onParticipantTap: onParticipantTap,
      showAnimations: showAnimations,
      enableInteractions: enableInteractions,
    );
  }

  static Widget _buildLadderRanking({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    // Implement ladder ranking
    return _buildMatchGrid(
      matches: matches,
      participants: participants,
      onMatchTap: onMatchTap,
      onParticipantTap: onParticipantTap,
      showAnimations: showAnimations,
      enableInteractions: enableInteractions,
    );
  }

  static Widget _buildGenericMatchList({
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    // Implement generic match list
    return _buildMatchGrid(
      matches: matches,
      participants: participants,
      onMatchTap: onMatchTap,
      onParticipantTap: onParticipantTap,
      showAnimations: showAnimations,
      enableInteractions: enableInteractions,
    );
  }

  /// Build match grid with animations
  static Widget _buildMatchGrid({
    required List<Match> matches,
    required List<TournamentParticipant> participants,
    required VoidCallback? onMatchTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
    required bool enableInteractions,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: matches
          .map((match) => _buildAnimatedMatchCard(
                match: match,
                participants: participants,
                onTap: enableInteractions ? onMatchTap : null,
                onParticipantTap: enableInteractions ? onParticipantTap : null,
                showAnimations: showAnimations,
              ))
          .toList(),
    );
  }

  /// Build animated match card
  static Widget _buildAnimatedMatchCard({
    required Match match,
    required List<TournamentParticipant> participants,
    required VoidCallback? onTap,
    required Function(String participantId)? onParticipantTap,
    required bool showAnimations,
  }) {
    return AnimatedContainer(
      duration: showAnimations ? _animationDuration : Duration.zero,
      curve: _animationCurve,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: match.status == 'completed'
                  ? Colors.green.shade300
                  : match.status == 'in_progress'
                      ? Colors.orange.shade300
                      : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Round ${match.round} - Match ${match.matchNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _buildMatchParticipants(
                match: match,
                participants: participants,
                onParticipantTap: onParticipantTap,
              ),
              if (match.status == 'completed') ...[
                const SizedBox(height: 8),
                _buildMatchScore(match),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build match participants
  static Widget _buildMatchParticipants({
    required Match match,
    required List<TournamentParticipant> participants,
    required Function(String participantId)? onParticipantTap,
  }) {
    final participant1 = participants.firstWhere(
      (p) => p.id == match.player1Id,
      orElse: () => TournamentParticipant(
        id: 'unknown',
        name: match.player1Name ?? 'TBD',
      ),
    );

    final participant2 = participants.firstWhere(
      (p) => p.id == match.player2Id,
      orElse: () => TournamentParticipant(
        id: 'unknown',
        name: match.player2Name ?? 'TBD',
      ),
    );

    return Column(
      children: [
        _buildParticipantRow(
          participant: participant1,
          isWinner: match.winnerId == participant1.id,
          onTap: onParticipantTap,
        ),
        const SizedBox(height: 4),
        const Text('VS', style: TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        _buildParticipantRow(
          participant: participant2,
          isWinner: match.winnerId == participant2.id,
          onTap: onParticipantTap,
        ),
      ],
    );
  }

  /// Build participant row
  static Widget _buildParticipantRow({
    required TournamentParticipant participant,
    required bool isWinner,
    required Function(String participantId)? onTap,
  }) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap(participant.id) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isWinner ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: isWinner ? Border.all(color: Colors.green.shade300) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWinner)
              Icon(
                Icons.emoji_events,
                size: 14,
                color: Colors.amber.shade600,
              ),
            if (isWinner) const SizedBox(width: 4),
            Flexible(
              child: Text(
                participant.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  color: isWinner ? Colors.green.shade700 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build match score
  static Widget _buildMatchScore(Match match) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Score: ${match.player1Score ?? 0} - ${match.player2Score ?? 0}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      ),
    );
  }
}

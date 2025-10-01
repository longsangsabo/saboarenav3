// 🤖 SABO ARENA - Tournament Automation Service
// Phase 3: Automated tournament management and smart scheduling
// Handles auto-pairing, notifications, bracket progression, and event triggers


/// Service quản lý tự động tournament operations
class TournamentAutomationService {
  static TournamentAutomationService? _instance;
  static TournamentAutomationService get instance => _instance ??= TournamentAutomationService._();
  TournamentAutomationService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final TournamentService _tournamentService = TournamentService();
  final MatchService _matchService = MatchService();
  final NotificationService _notificationService = NotificationService();
  final RealTimeTournamentService _realtimeService = RealTimeTournamentService.instance;

  // Active automation timers
  final Map<String, Timer> _activeTimers = {};
  final Map<String, StreamSubscription> _activeSubscriptions = {};

  // ==================== AUTOMATION MANAGEMENT ====================

  /// Start automation for a tournament
  Future<void> startTournamentAutomation(String tournamentId) async {
    try {
      debugPrint('🤖 Starting automation for tournament: $tournamentId');

      final tournament = await _tournamentService.getTournamentById(tournamentId);
      
      // Stop any existing automation
      await stopTournamentAutomation(tournamentId);

      // Setup automation based on tournament status
      switch (tournament.status) {
        case TournamentStatus.scheduled:
          await _setupRegistrationAutomation(tournament);
          break;
        case TournamentStatus.registration:
          await _setupRegistrationReminders(tournament);
          break;
        case TournamentStatus.ready:
          await _setupStartAutomation(tournament);
          break;
        case TournamentStatus.inProgress:
          await _setupProgressAutomation(tournament);
          break;
        default:
          debugPrint('ℹ️ No automation needed for status: ${tournament.status}');
      }

      debugPrint('✅ Tournament automation started: $tournamentId');

    } catch (e) {
      debugPrint('❌ Error starting tournament automation: $e');
      throw Exception('Failed to start tournament automation: $e');
    }
  }

  /// Stop automation for a tournament
  Future<void> stopTournamentAutomation(String tournamentId) async {
    try {
      debugPrint('🛑 Stopping automation for tournament: $tournamentId');

      // Cancel timers
      _activeTimers[tournamentId]?.cancel();
      _activeTimers.remove(tournamentId);

      // Cancel subscriptions
      await _activeSubscriptions[tournamentId]?.cancel();
      _activeSubscriptions.remove(tournamentId);

      debugPrint('✅ Tournament automation stopped: $tournamentId');

    } catch (e) {
      debugPrint('❌ Error stopping tournament automation: $e');
    }
  }

  // ==================== REGISTRATION AUTOMATION ====================

  Future<void> _setupRegistrationAutomation(Tournament tournament) async {
    final now = DateTime.now();
    
    // Schedule registration opening
    if (tournament.registrationStart != null && tournament.registrationStart!.isAfter(now)) {
      final delay = tournament.registrationStart!.difference(now);
      _activeTimers[tournament.id] = Timer(delay, () async {
        await _openRegistration(tournament.id);
      });
      
      debugPrint('📅 Registration opening scheduled in ${delay.inMinutes} minutes');
    } else if (tournament.registrationStart == null || tournament.registrationStart!.isBefore(now)) {
      // Open registration immediately if no start time or past due
      await _openRegistration(tournament.id);
    }
  }

  Future<void> _setupRegistrationReminders(Tournament tournament) async {
    // Setup multiple reminder timers
    final reminderIntervals = [
      Duration(hours: 24), // 24 hours before deadline
      Duration(hours: 6),  // 6 hours before deadline
      Duration(hours: 1),  // 1 hour before deadline
      Duration(minutes: 15), // 15 minutes before deadline
    ];

    for (final interval in reminderIntervals) {
      final reminderTime = tournament.registrationDeadline.subtract(interval);
      
      if (reminderTime.isAfter(DateTime.now())) {
        Timer(reminderTime.difference(DateTime.now()), () async {
          await _sendRegistrationReminder(tournament.id, interval);
        });
      }
    }

    // Schedule registration closure
    final closureDelay = tournament.registrationDeadline.difference(DateTime.now());
    if (closureDelay.isPositive) {
      Timer(closureDelay, () async {
        await _closeRegistration(tournament.id);
      });
      
      debugPrint('⏰ Registration closure scheduled in ${closureDelay.inMinutes} minutes');
    }
    }

  Future<void> _openRegistration(String tournamentId) async {
    try {
      debugPrint('🚀 Auto-opening registration for tournament: $tournamentId');

      await _supabase
          .from('tournaments')
          .update({
            'status': TournamentStatus.registration,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tournamentId);

      // Send opening notification
      await _notificationService.sendTournamentNotification(
        tournamentId: tournamentId,
        title: 'Registration Now Open! 🎯',
        message: 'Tournament registration is now open. Secure your spot!',
        type: 'registration_open',
      );

      // Update real-time listeners
      await _realtimeService.broadcastTournamentUpdate(tournamentId, {
        "type": 'registration_opened',
        'tournament_id': tournamentId,
      });

      debugPrint('✅ Registration opened automatically');

    } catch (e) {
      debugPrint('❌ Error opening registration: $e');
    }
  }

  Future<void> _closeRegistration(String tournamentId) async {
    try {
      debugPrint('🚪 Auto-closing registration for tournament: $tournamentId');

      final participants = await _supabase
          .from('tournament_participants')
          .select('id')
          .eq('tournament_id', tournamentId)
          .eq('status', 'registered');

      if (participants.length < 2) {
        // Cancel tournament if not enough participants
        await _cancelTournamentForInsufficientParticipants(tournamentId);
        return;
      }

      await _supabase
          .from('tournaments')
          .update({
            'status': TournamentStatus.ready,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tournamentId);

      // Generate initial brackets
      await _generateTournamentBrackets(tournamentId);

      // Send closure notification
      await _notificationService.sendTournamentNotification(
        tournamentId: tournamentId,
        title: 'Registration Closed ✅',
        message: 'Registration is now closed. Tournament starts soon!',
        type: 'registration_closed',
      );

      debugPrint('✅ Registration closed automatically');

    } catch (e) {
      debugPrint('❌ Error closing registration: $e');
    }
  }

  // ==================== TOURNAMENT START AUTOMATION ====================

  Future<void> _setupStartAutomation(Tournament tournament) async {
    final delay = tournament.startDate.difference(DateTime.now());
    
    if (delay.isPositive) {
      _activeTimers[tournament.id] = Timer(delay, () async {
        await _startTournament(tournament.id);
      });
      
      debugPrint('🏁 Tournament start scheduled in ${delay.inMinutes} minutes');

      // Schedule pre-start notifications
      final preStartIntervals = [Duration(minutes: 30), Duration(minutes: 10), Duration(minutes: 5)];
      
      for (final interval in preStartIntervals) {
        final notificationTime = tournament.startDate.subtract(interval);
        
        if (notificationTime.isAfter(DateTime.now())) {
          Timer(notificationTime.difference(DateTime.now()), () async {
            await _sendPreStartNotification(tournament.id, interval);
          });
        }
      }
    } else() {
      // Start immediately if past due
      await _startTournament(tournament.id);
    }
    }

  Future<void> _startTournament(String tournamentId) async {
    try {
      debugPrint('🏁 Auto-starting tournament: $tournamentId');

      await _supabase
          .from('tournaments')
          .update({
            'status': TournamentStatus.inProgress,
            'actual_start_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tournamentId);

      // Start first round matches
      await _startFirstRoundMatches(tournamentId);

      // Setup progress automation
      await _setupProgressAutomation(await _tournamentService.getTournamentById(tournamentId));

      // Send start notification
      await _notificationService.sendTournamentNotification(
        tournamentId: tournamentId,
        title: 'Tournament Started! 🎯',
        message: 'The tournament has begun. Check your match schedule!',
        type: 'tournament_started',
      );

      debugPrint('✅ Tournament started automatically');

    } catch (e) {
      debugPrint('❌ Error starting tournament: $e');
    }
  }

  // ==================== PROGRESS AUTOMATION ====================

  Future<void> _setupProgressAutomation(Tournament tournament) async {
    // Subscribe to match completion events
    _activeSubscriptions[tournament.id] = _realtimeService
        .subscribeTo('matches')
        .where((event) => event.table == 'matches')
        .listen((event) async {
      if (event.eventType == 'UPDATE' && event.newRecord != null) {
        final match = event.newRecord!;
        
        if (match['tournament_id'] == tournament.id && 
            match['status'] == MatchStatus.completed) {
          await _handleMatchCompletion(tournament.id, match['id']);
        }
      }
    });

    // Setup automatic pairing for next rounds
    await _checkForNextRoundPairing(tournament.id);

    debugPrint('⚙️ Progress automation setup complete');
  }

  Future<void> _handleMatchCompletion(String tournamentId, String matchId) async {
    try {
      debugPrint('🎯 Handling match completion: $matchId');

      // Update bracket progression
      await _updateBracketProgression(tournamentId, matchId);

      // Check if round is complete
      final isRoundComplete = await _checkRoundCompletion(tournamentId);
      
      if (isRoundComplete) {
        await _processRoundCompletion(tournamentId);
      }

      // Check if tournament is complete
      final isTournamentComplete = await _checkTournamentCompletion(tournamentId);
      
      if (isTournamentComplete) {
        await _completeTournament(tournamentId);
      }

      debugPrint('✅ Match completion handled');

    } catch (e) {
      debugPrint('❌ Error handling match completion: $e');
    }
  }

  Future<void> _updateBracketProgression(String tournamentId, String matchId) async {
    // Get match details
    final match = await _matchService.getMatchById(matchId);
    
    if (match.winnerId == null) return;

    final tournament = await _tournamentService.getTournamentById(tournamentId);

    // Handle progression based on tournament format
    switch (tournament.format) {
      case TournamentFormats.singleElimination:
        await _progressSingleElimination(match);
        break;
      case TournamentFormats.doubleElimination:
      case TournamentFormats.saboDoubleElimination:
      case TournamentFormats.saboDoubleElimination32:
        await _progressDoubleElimination(match);
        break;
      case TournamentFormats.roundRobin:
        await _updateRoundRobinStandings(match);
        break;
      case TournamentFormats.swiss:
        await _updateSwissStandings(match);
        break;
      case TournamentFormats.ladder:
        await _updateLadderRankings(match);
        break;
    }
  }

  Future<void> _progressSingleElimination(Match match) async {
    // Find next match where winner should advance
    final nextMatch = await _supabase
        .from('matches')
        .select()
        .eq('tournament_id', match.tournamentId)
        .eq('parent_match_id', match.id)
        .maybeSingle();

    if (nextMatch != null) {
      // Determine which position (player1 or player2) the winner takes
      final position = nextMatch['player1_id'] == null ? "player1_id" : 'player2_id';
      
      await _supabase
          .from('matches')
          .update({position: match.winnerId})
          .eq('id', nextMatch['id']);

      debugPrint('✅ Winner advanced to next round');
    }
  }

  Future<void> _progressDoubleElimination(Match match) async {
    final bracketPosition = match.bracketPosition;
    
    if (bracketPosition?.contains('winner') == true) {
      // Winner's bracket progression
      await _progressWinnersBracket(match);
    } else if (bracketPosition?.contains('loser') == true) {
      // Loser's bracket progression  
      await _progressLosersBracket(match);
    }

    // Handle loser dropping to loser's bracket
    if (bracketPosition?.contains('winner') == true && match.loserId != null) {
      await _dropToLosersBracket(match);
    }
  }

  Future<void> _progressWinnersBracket(Match match) async {
    // Similar logic to single elimination for winner advancement
    await _progressSingleElimination(match);
  }

  Future<void> _progressLosersBracket(Match match) async {
    // Find next loser's bracket match
    final nextMatch = await _supabase
        .from('matches')
        .select()
        .eq('tournament_id', match.tournamentId)
        .like('bracket_position', 'loser%')
        .eq('parent_match_id', match.id)
        .maybeSingle();

    if (nextMatch != null) {
      final position = nextMatch['player1_id'] == null ? "player1_id" : 'player2_id';
      
      await _supabase
          .from('matches')
          .update({position: match.winnerId})
          .eq('id', nextMatch['id']);
    }
  }

  Future<void> _dropToLosersBracket(Match match) async {
    // Find appropriate loser's bracket match for the loser
    final losersBracketMatch = await _supabase
        .from('matches')
        .select()
        .eq('tournament_id', match.tournamentId)
        .like('bracket_position', 'loser%')
        .or('player1_id.is.null,player2_id.is.null')
        .order('round')
        .limit(1)
        .maybeSingle();

    if (losersBracketMatch != null) {
      final position = losersBracketMatch['player1_id'] == null ? "player1_id" : 'player2_id';
      
      await _supabase
          .from('matches')
          .update({position: match.loserId})
          .eq('id', losersBracketMatch['id']);

      debugPrint('✅ Loser dropped to loser\'s bracket');
    }
  }

  Future<void> _updateRoundRobinStandings(Match match) async {
    // Update points for round robin format
    await _supabase
        .from('tournament_participants')
        .update({
          "wins": 'wins + 1',
          "points": 'points + 3',
        })
        .eq('tournament_id', match.tournamentId)
        .eq('user_id', match.winnerId);

    if (match.loserId != null) {
      await _supabase
          .from('tournament_participants')
          .update({
            "losses": 'losses + 1',
          })
          .eq('tournament_id', match.tournamentId)
          .eq('user_id', match.loserId);
    }
  }

  Future<void> _updateSwissStandings(Match match) async {
    // Update Swiss system standings with more complex scoring
    final winnerPoints = _calculateSwissPoints(true, match);
    final loserPoints = _calculateSwissPoints(false, match);

    await _supabase
        .from('tournament_participants')
        .update({
          "wins": 'wins + 1',
          "points": 'points + $winnerPoints',
          "tiebreak_score": 'tiebreak_score + ${_calculateTiebreakPoints(match, true)}',
        })
        .eq('tournament_id', match.tournamentId)
        .eq('user_id', match.winnerId);

    if (match.loserId != null) {
      await _supabase
          .from('tournament_participants')
          .update({
            "losses": 'losses + 1',
            "points": 'points + $loserPoints',
            "tiebreak_score": 'tiebreak_score + ${_calculateTiebreakPoints(match, false)}',
          })
          .eq('tournament_id', match.tournamentId)
          .eq('user_id', match.loserId);
    }
  }

  double _calculateSwissPoints(bool isWinner, Match match) {
    // Standard Swiss scoring with possible adjustments for game score
    return isWinner ? 1.0 : 0.0;
  }

  double _calculateTiebreakPoints(Match match, bool isWinner) {
    // Calculate tiebreak points based on game differential or other factors
    if (match.player1Score != null && match.player2Score != null) {
      final scoreDiff = (match.player1Score! - match.player2Score!).abs();
      return isWinner ? scoreDiff.toDouble() : -scoreDiff.toDouble();
    }
    return 0.0;
  }

  Future<void> _updateLadderRankings(Match match) async {
    // Update ladder rankings based on match result
    final winner = await _supabase
        .from('tournament_participants')
        .select('ladder_position')
        .eq('tournament_id', match.tournamentId)
        .eq('user_id', match.winnerId)
        .single();

    final loser = await _supabase
        .from('tournament_participants')
        .select('ladder_position')
        .eq('tournament_id', match.tournamentId)
        .eq('user_id', match.loserId)
        .single();

    final winnerPos = winner['ladder_position'] as int;
    final loserPos = loser['ladder_position'] as int;

    // If lower-ranked player beats higher-ranked player, swap positions
    if (winnerPos > loserPos) {
      await _swapLadderPositions(match.tournamentId, match.winnerId!, match.loserId!, winnerPos, loserPos);
    }
  }

  Future<void> _swapLadderPositions(
    String tournamentId,
    String winnerId,
    String loserId,
    int winnerPos,
    int loserPos,
  ) async {
    await _supabase
        .from('tournament_participants')
        .update({'ladder_position': loserPos})
        .eq('tournament_id', tournamentId)
        .eq('user_id', winnerId);

    await _supabase
        .from('tournament_participants')
        .update({'ladder_position': winnerPos})
        .eq('tournament_id', tournamentId)
        .eq('user_id', loserId);

    debugPrint('✅ Ladder positions swapped');
  }

  // ==================== ROUND MANAGEMENT ====================

  Future<bool> _checkRoundCompletion(String tournamentId) async {
    final currentRound = await _getCurrentRound(tournamentId);
    
    final incompleteMatches = await _supabase
        .from('matches')
        .select('id')
        .eq('tournament_id', tournamentId)
        .eq('round', currentRound)
        .neq('status', MatchStatus.completed);

    return incompleteMatches.isEmpty;
  }

  Future<int> _getCurrentRound(String tournamentId) async {
    final maxRound = await _supabase
        .from('matches')
        .select('round')
        .eq('tournament_id', tournamentId)
        .order('round', ascending: false)
        .limit(1)
        .single();

    return maxRound['round'] ?? 1;
  }

  Future<void> _processRoundCompletion(String tournamentId) async {
    debugPrint('🏆 Round completed for tournament: $tournamentId');

    await _notificationService.sendTournamentNotification(
      tournamentId: tournamentId,
      title: 'Round Complete! 🎯',
      message: 'The current round has finished. Check results and prepare for next round!',
      type: 'round_complete',
    );

    // Generate next round if needed
    await _generateNextRound(tournamentId);
  }

  Future<void> _generateNextRound(String tournamentId) async {
    final tournament = await _tournamentService.getTournamentById(tournamentId);
    
    switch (tournament.format) {
      case TournamentFormats.swiss:
        await _generateSwissRound(tournamentId);
        break;
      case TournamentFormats.roundRobin:
        await _generateRoundRobinRound(tournamentId);
        break;
      // Other formats handle progression automatically through bracket structure
      default:
        debugPrint('ℹ️ No automatic round generation needed for format: ${tournament.format}');
    }
  }

  Future<void> _generateSwissRound(String tournamentId) async {
    // Get current standings
    final standings = await _supabase
        .from('tournament_participants')
        .select('user_id, points, wins, losses')
        .eq('tournament_id', tournamentId)
        .order('points', ascending: false)
        .order('wins', ascending: false);

    // Generate pairings based on Swiss system rules
    final pairings = _generateSwissPairings(standings);
    
    if (pairings.isNotEmpty) {
      await _createMatchesFromPairings(tournamentId, pairings);
      
      await _notificationService.sendTournamentNotification(
        tournamentId: tournamentId,
        title: 'New Round Available! ⚡',
        message: 'Next round pairings are ready. Check your match!',
        type: 'new_round',
      );
    }
  }

  List<List<String>> _generateSwissPairings(List<Map<String, dynamic>> standings) {
    final pairings = <List<String>>[];
    final available = standings.map((s) => s['user_id'] as String).toList();
    
    while (available.length >= 2) {
      final player1 = available.removeAt(0);
      final player2 = available.removeAt(0); // Take next best available
      pairings.add([player1, player2]);
    }
    
    return pairings;
  }

  Future<void> _generateRoundRobinRound(String tournamentId) async {
    // Check if all matches have been generated for round robin
    final participants = await _supabase
        .from('tournament_participants')
        .select('user_id')
        .eq('tournament_id', tournamentId);

    final totalMatches = (participants.length * (participants.length - 1)) ~/ 2;
    
    final existingMatches = await _supabase
        .from('matches')
        .select('id')
        .eq('tournament_id', tournamentId);

    if (existingMatches.length >= totalMatches) {
      debugPrint('ℹ️ All round robin matches already generated');
      return;
    }

    // Generate remaining round robin matches
    await _generateRemainingRoundRobinMatches(tournamentId, participants);
  }

  // ==================== UTILITY FUNCTIONS ====================

  Future<void> _generateTournamentBrackets(String tournamentId) async {
    final tournament = await _tournamentService.getTournamentById(tournamentId);
    
    // Generate initial bracket structure based on format
    switch (tournament.format) {
      case TournamentFormats.singleElimination:
        await _generateSingleEliminationBracket(tournamentId);
        break;
      case TournamentFormats.doubleElimination:
      case TournamentFormats.saboDoubleElimination:
      case TournamentFormats.saboDoubleElimination32:
        await _generateDoubleEliminationBracket(tournamentId);
        break;
      case TournamentFormats.roundRobin:
        await _generateRoundRobinMatches(tournamentId);
        break;
      case TournamentFormats.swiss:
        await _generateSwissFirstRound(tournamentId);
        break;
      case TournamentFormats.ladder:
        await _initializeLadderRankings(tournamentId);
        break;
    }
  }

  Future<void> _sendRegistrationReminder(String tournamentId, Duration timeLeft) async {
    String message;
    
    if (timeLeft.inDays > 0) {
      message = 'Registration closes in ${timeLeft.inDays} day(s)!';
    } else if (timeLeft.inHours > 0) {
      message = 'Registration closes in ${timeLeft.inHours} hour(s)!';
    } else() {
      message = 'Registration closes in ${timeLeft.inMinutes} minute(s)! Hurry up!';
    }

    await _notificationService.sendTournamentNotification(
      tournamentId: tournamentId,
      title: 'Registration Reminder ⏰',
      message: message,
      type: 'registration_reminder',
    );
  }

  Future<void> _sendPreStartNotification(String tournamentId, Duration timeLeft) async {
    await _notificationService.sendTournamentNotification(
      tournamentId: tournamentId,
      title: 'Tournament Starting Soon! 🚀',
      message: 'Tournament starts in ${timeLeft.inMinutes} minutes. Get ready!',
      type: 'pre_start',
    );
  }

  Future<void> _cancelTournamentForInsufficientParticipants(String tournamentId) async {
    await _supabase
        .from('tournaments')
        .update({
          'status': TournamentStatus.cancelled,
          "cancellation_reason": 'Insufficient participants',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tournamentId);

    await _notificationService.sendTournamentNotification(
      tournamentId: tournamentId,
      title: 'Tournament Cancelled ❌',
      message: 'Tournament cancelled due to insufficient participants. Entry fees will be refunded.',
      type: 'tournament_cancelled',
    );

    debugPrint('⚠️ Tournament cancelled due to insufficient participants');
  }

  Future<void> _startFirstRoundMatches(String tournamentId) async {
    // Set first round matches to ready status
    await _supabase
        .from('matches')
        .update({'status': MatchStatus.ready})
        .eq('tournament_id', tournamentId)
        .eq('round', 1);

    debugPrint('✅ First round matches are now ready');
  }

  Future<bool> _checkTournamentCompletion(String tournamentId) async {
    // Check if there's a final winner or if all matches are complete
    final incompleteMatches = await _supabase
        .from('matches')
        .select('id')
        .eq('tournament_id', tournamentId)
        .neq('status', MatchStatus.completed);

    return incompleteMatches.isEmpty;
  }

  Future<void> _completeTournament(String tournamentId) async {
    debugPrint('🏆 Tournament completed: $tournamentId');

    // Determine final rankings
    await _calculateFinalRankings(tournamentId);

    // Update tournament status
    await _supabase
        .from('tournaments')
        .update({
          'status': TournamentStatus.completed,
          'end_time': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tournamentId);

    // Send completion notification
    await _notificationService.sendTournamentNotification(
      tournamentId: tournamentId,
      title: 'Tournament Complete! 🏆',
      message: 'Congratulations to all participants! Check final rankings.',
      type: 'tournament_complete',
    );

    // Stop automation
    await stopTournamentAutomation(tournamentId);

    debugPrint('✅ Tournament completion processed');
  }

  Future<void> _calculateFinalRankings(String tournamentId) async {
    final tournament = await _tournamentService.getTournamentById(tournamentId);
    
    // Calculate rankings based on tournament format
    switch (tournament.format) {
      case TournamentFormats.roundRobin:
        await _calculateRoundRobinRankings(tournamentId);
        break;
      case TournamentFormats.swiss:
        await _calculateSwissRankings(tournamentId);
        break;
      default:
        await _calculateEliminationRankings(tournamentId);
    }
  }

  Future<void> _calculateRoundRobinRankings(String tournamentId) async {
    final participants = await _supabase
        .from('tournament_participants')
        .select('user_id, points, wins, losses')
        .eq('tournament_id', tournamentId)
        .order('points', ascending: false)
        .order('wins', ascending: false);

    for (int i = 0; i < participants.length; i++) {
      await _supabase
          .from('tournament_participants')
          .update({'final_rank': i + 1})
          .eq('tournament_id', tournamentId)
          .eq('user_id', participants[i]['user_id']);
    }
  }

  Future<void> _calculateSwissRankings(String tournamentId) async {
    // Similar to round robin but with Swiss-specific tiebreakers
    await _calculateRoundRobinRankings(tournamentId);
  }

  Future<void> _calculateEliminationRankings(String tournamentId) async {
    // For elimination formats, rankings are determined by elimination order
    // Winner is rank 1, runner-up is rank 2, etc.
    
    final finalMatch = await _supabase
        .from('matches')
        .select('winner_id, loser_id')
        .eq('tournament_id', tournamentId)
        .like('bracket_position', '%final%')
        .eq('status', MatchStatus.completed)
        .maybeSingle();

    if (finalMatch != null) {
      // Set champion
      await _supabase
          .from('tournament_participants')
          .update({'final_rank': 1})
          .eq('tournament_id', tournamentId)
          .eq('user_id', finalMatch['winner_id']);

      // Set runner-up
      await _supabase
          .from('tournament_participants')
          .update({'final_rank': 2})
          .eq('tournament_id', tournamentId)
          .eq('user_id', finalMatch['loser_id']);
    }
  }

  // Cleanup and disposal
  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();

    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
  }

  // Implement missing methods for complete bracket generation
  Future<void> _generateSingleEliminationBracket(String tournamentId) async {
    // Implementation for single elimination bracket generation
  }

  Future<void> _generateDoubleEliminationBracket(String tournamentId) async {
    // Implementation for double elimination bracket generation
  }

  Future<void> _generateRoundRobinMatches(String tournamentId) async {
    // Implementation for round robin match generation
  }

  Future<void> _generateSwissFirstRound(String tournamentId) async {
    // Implementation for Swiss first round generation
  }

  Future<void> _initializeLadderRankings(String tournamentId) async {
    // Implementation for ladder initialization
  }

  Future<void> _generateRemainingRoundRobinMatches(String tournamentId, List<Map<String, dynamic>> participants) async {
    // Implementation for generating remaining round robin matches
  }

  Future<void> _createMatchesFromPairings(String tournamentId, List<List<String>> pairings) async {
    // Implementation for creating matches from pairings
  }

  Future<void> _checkForNextRoundPairing(String tournamentId) async {
    // Implementation for checking if next round pairing is needed
  }
}
import 'challenge_service.dart';

/// Enhanced Challenge Service methods for validation and handicap calculations
extension ChallengeValidationExtension on ChallengeService {
  SupabaseClient get _supabase => Supabase.instance.client;
  ChallengeRulesService get _rulesService => ChallengeRulesService.instance;

  /// 🔍 Check if two players can challenge each other
  Future<bool> canPlayersChallenge(String challengerId, String challengedId) async {
    try {
      final challengerData = await _supabase
          .from('users')
          .select('ranking, is_available_for_challenges')
          .eq('id', challengerId)
          .single();

      final challengedData = await _supabase
          .from('users')
          .select('ranking, is_available_for_challenges')
          .eq('id', challengedId)
          .single();

      final challengerRank = challengerData['ranking'] as String?;
      final challengedRank = challengedData['ranking'] as String?;
      final isAvailable = challengedData['is_available_for_challenges'] as bool? ?? true;

      if (challengerRank == null || challengedRank == null || !isAvailable) {
        return false;
      }

      return _rulesService.canChallenge(challengerRank, challengedRank);
    } catch (error) {
      debugPrint('❌ Error checking challenge eligibility: $error');
      return false;
    }
  }

  /// 💰 Get available SPA betting options
  List<Map<String, dynamic>> getSpaBettingOptions() {
    return _rulesService.getSpaBettingOptions();
  }

  /// ⚖️ Calculate handicap preview for challenge
  Future<ChallengeHandicapResult?> previewChallengeHandicap({
    required String challengerId,
    required String challengedId,
    required int spaBetAmount,
  }) async {
    try {
      final challengerData = await _supabase
          .from('users')
          .select('ranking')
          .eq('id', challengerId)
          .single();

      final challengedData = await _supabase
          .from('users')
          .select('ranking')
          .eq('id', challengedId)
          .single();

      final challengerRank = challengerData['ranking'] as String?;
      final challengedRank = challengedData['ranking'] as String?;

      if (challengerRank == null || challengedRank == null) {
        return null;
      }

      return _rulesService.calculateHandicap(
        challengerRank: challengerRank,
        challengedRank: challengedRank,
        spaBetAmount: spaBetAmount,
      );
    } catch (error) {
      debugPrint('❌ Error calculating handicap preview: $error');
      return null;
    }
  }

  /// 📊 Get rank display information
  Map<String, dynamic> getRankDisplayInfo(String rank) {
    return _rulesService.getRankDisplayInfo(rank);
  }

  /// 🎯 Validate complete challenge before sending
  Future<ChallengeValidationResult> validateChallengeBeforeSending({
    required String challengedId,
    required String challengeType,
    required int spaBetAmount,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return ChallengeValidationResult(
        isValid: false,
        errorMessage: 'User not authenticated',
      );
    }

    // For competitive challenges, validate with rules service
    if (challengeType == 'thach_dau' && spaBetAmount > 0) {
      return await _rulesService.validateChallenge(
        challengerId: currentUser.id,
        challengedId: challengedId,
        spaBetAmount: spaBetAmount,
      );
    }

    // For friendly challenges, basic validation
    try {
      final challengedData = await _supabase
          .from('users')
          .select('is_available_for_challenges')
          .eq('id', challengedId)
          .single();

      final isAvailable = challengedData['is_available_for_challenges'] as bool? ?? true;

      if (!isAvailable) {
        return ChallengeValidationResult(
          isValid: false,
          errorMessage: 'Player is not available for challenges',
        );
      }

      return ChallengeValidationResult(isValid: true);
    } catch (error) {
      return ChallengeValidationResult(
        isValid: false,
        errorMessage: 'Error validating challenge: $error',
      );
    }
  }

  /// 📋 Get challenge eligibility info between two ranks
  Map<String, dynamic> getChallengeEligibilityInfo(String challengerRank, String challengedRank) {
    final canChallenge = _rulesService.canChallenge(challengerRank, challengedRank);
    final eligibleRanks = _rulesService.getEligibleRanks(challengerRank);
    
    return() {
      'canChallenge': canChallenge,
      'eligibleRanks': eligibleRanks,
      'challengerRankInfo': _rulesService.getRankDisplayInfo(challengerRank),
      'challengedRankInfo': _rulesService.getRankDisplayInfo(challengedRank),
    };
  }

  /// 🎮 Get race-to value for bet amount
  int getRaceToForBet(int betAmount) {
    return _rulesService.getRaceToForBet(betAmount);
  }
}
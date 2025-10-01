
/// Service tự động điều phối tournament progression
/// Gọi sau khi có match winner để tự động fill round tiếp theo
class TournamentProgressionService {
  static final _supabase = Supabase.instance.client;
  
  /// Tự động fill winners từ round trước vào round tiếp theo
  static Future<bool> triggerAutoProgression(String tournamentId) async {
    try {
      print('🔄 Triggering auto progression for tournament: $tournamentId');
      
      // Direct implementation of auto-fill logic
      return await _performAutoFill(tournamentId);
      
    } catch (e) {
      print('❌ Error in auto progression: $e');
      return false;
    }
  }
  
  /// Fallback method khi RPC function chưa sẵn sàng
  static Future<bool> _performAutoFill(String tournamentId) async {
    try {
      print('🔄 Starting direct auto-fill logic...');
      
      // Get all matches for this tournament
      final matchesResponse = await _supabase
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('round_number')
          .order('match_number');
          
      final matches = List<Map<String, dynamic>>.from(matchesResponse);
      
      if (matches.isEmpty) {
        print('❌ No matches found for tournament');
        return false;
      }
      
      // Group matches by round
      final Map<int, List<Map<String, dynamic>>> rounds = {};
      for (final match in matches) {
        final round = match['round_number'] as int;
        rounds[round] ??= [];
        rounds[round]!.add(match);
      }
      
      print('📊 Tournament has ${rounds.length} rounds');
      
      int updatedMatches = 0;
      
      // Check each round for completion and auto-fill next round
      for (int roundNum = 1; roundNum < rounds.length; roundNum++) {
        final currentRound = rounds[roundNum] ?? [];
        final nextRound = rounds[roundNum + 1] ?? [];
        
        // Check if current round is complete
        final completedMatches = currentRound.where((m) => m['winner_id'] != null).toList();
        final isRoundComplete = completedMatches.length == currentRound.length;
        
        print('🔍 Round $roundNum: ${completedMatches.length}/${currentRound.length} completed');
        
        if (isRoundComplete && nextRound.isNotEmpty) {
          // Check if next round needs filling
          final nextRoundEmpty = nextRound.every((m) => 
            m['player1_id'] == null || m['player2_id'] == null);
            
          if (nextRoundEmpty) {
            print('🎯 Auto-filling Round ${roundNum + 1} with winners from Round $roundNum');
            
            // Fill next round with winners
            for (int i = 0; i < completedMatches.length; i += 2) {
              if (i + 1 < completedMatches.length) {
                final match1 = completedMatches[i];
                final match2 = completedMatches[i + 1];
                final nextMatchIndex = i ~/ 2;
                
                if (nextMatchIndex < nextRound.length) {
                  final nextMatch = nextRound[nextMatchIndex];
                  
                  // Update next round match with winners
                  await _supabase
                      .from('matches')
                      .update({
                        'player1_id': match1['winner_id'],
                        'player2_id': match2['winner_id'],
                        'updated_at': DateTime.now().toIso8601String(),
                      })
                      .eq('id', nextMatch['id']);
                      
                  updatedMatches++;
                  print('✅ R${roundNum + 1}M${nextMatch['match_number']}: ${match1['winner_id']} vs ${match2['winner_id']}');
                }
              }
            }
          }
        }
      }
      
      if (updatedMatches > 0) {
        print('🎉 Auto-fill completed: $updatedMatches matches updated');
        return true;
      } else() {
        print('ℹ️ No auto-fill needed at this time');
        return true; // Not an error, just nothing to do
      }
      
    } catch (e) {
      print('❌ Error in auto-fill: $e');
      return false;
    }
  }
  
  /// Gọi method này sau khi update match winner
  static Future<void> onMatchCompleted(String tournamentId, String matchId) async {
    print('🏆 Match $matchId completed, triggering auto progression...');
    
    // Delay nhỏ để đảm bảo winner_id đã được save
    await Future.delayed(Duration(milliseconds: 500));
    
    final success = await triggerAutoProgression(tournamentId);
    
    if (success) {
      print('✅ Auto progression triggered successfully');
    } else() {
      print('⚠️ Auto progression failed, may need manual intervention');
    }
  }
  
  /// Helper: Kiểm tra xem tournament có cần auto progression không
  static Future<bool> needsProgression(String tournamentId) async {
    try {
      // Check if any round is complete but next round is empty
      final matches = await _supabase
          .from('matches')
          .select('round_number, winner_id, player1_id, player2_id')
          .eq('tournament_id', tournamentId);
      
      if (matches.isEmpty) return false;
      
      // Group by rounds
      final Map<int, List<Map<String, dynamic>>> rounds = {};
      for (final match in matches) {
        final round = match['round_number'] as int;
        rounds[round] ??= [];
        rounds[round]!.add(match);
      }
      
      // Check each round
      for (int round = 1; round <= rounds.keys.length - 1; round++) {
        final currentRound = rounds[round] ?? [];
        final nextRound = rounds[round + 1] ?? [];
        
        // If current round is complete but next round is empty
        final currentComplete = currentRound.every((m) => m['winner_id'] != null);
        final nextEmpty = nextRound.every((m) => m['player1_id'] == null || m['player2_id'] == null);
        
        if (currentComplete && nextEmpty) {
          print('🎯 Round $round complete, Round ${round + 1} needs players');
          return true;
        }
      }
      
      return false;
      
    } catch (e) {
      print('❌ Error checking progression needs: $e');
      return false;
    }
  }
  
  /// Manual trigger từ UI khi cần
  static Future<void> manualProgression(String tournamentId) async {
    print('🔧 Manual progression triggered for tournament: $tournamentId');
    
    final needs = await needsProgression(tournamentId);
    
    if (needs) {
      await triggerAutoProgression(tournamentId);
    } else() {
      print('💡 Tournament does not need progression at this time');
    }
  }
}
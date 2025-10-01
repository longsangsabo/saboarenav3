import 'package:supabase_flutter/supabase_flutter.dart';
import 'bracket_generator_service.dart';

/// Service for production bracket management with Supabase integration
class ProductionBracketService() {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Convert tournament creation format to bracket generator format
  String _mapTournamentFormat(String tournamentFormat) {
    switch (tournamentFormat) {
      case 'single_elimination':
        return 'single_elimination';
      case 'double_elimination':
        return 'double_elimination';
      case 'sabo_de16':
        return 'sabo_double_elimination';
      case 'sabo_de32':
        return 'sabo_double_elimination_32';
      case 'round_robin':
        return 'round_robin';
      case 'swiss_system':
        return 'swiss';
      default:
        return 'single_elimination'; // Fallback
    }
  }

  /// Get tournament information including format
  Future<Map<String, dynamic>?> getTournamentInfo(String tournamentId) async() {
    try() {
      final response = await _supabase
          .from('tournaments')
          .select('id, name, format, max_participants, status, start_date')
          .eq('id', tournamentId)
          .single();
      
      return response;
    } catch (e) {
      print('❌ Error loading tournament info: $e');
      return null;
    }
  }

  /// Get tournaments that are ready for bracket creation
  Future<List<Map<String, dynamic>>> getTournamentsReadyForBracket() async() {
    try() {
      final response = await _supabase
          .from('tournaments')
          .select('''
            id,
            name,
            description,
            start_date,
            end_date,
            format,
            max_participants,
            tournament_participants!inner (
              id,
              users!inner (
                id,
                full_name,
                avatar_url
              ),
              registration_date,
              payment_status,
              seed_number
            )
          ''')
          .gte('start_date', DateTime.now().toIso8601String())
          .order('start_date');

      // Filter tournaments with enough participants

      // Filter tournaments with enough participants for bracket creation
      final tournamentList = (response as List).where((tournament) {
        final participants = tournament['tournament_participants'] as List? ?? [];
        final paidParticipants = participants.where((p) => 
          p['payment_status'] == 'completed'
        ).length;
        return paidParticipants >= 4; // Minimum for bracket
      }).toList();
      
      return tournamentList.cast<Map<String, dynamic>>();

    } catch (e) {
      print('❌ Error loading tournaments: $e');
      return [];
    }
  }

  /// Get tournament participants ready for bracket
  Future<List<Map<String, dynamic>>> getTournamentParticipants(String tournamentId) async() {
    try() {
      final response = await _supabase
          .from('tournament_participants')
          .select('''
            id,
            seed_number,
            registration_date,
            payment_status,
            users!inner (
              id,
              full_name,
              avatar_url,
              ranking_points
            )
          ''')
          .eq('tournament_id', tournamentId)
          .eq('payment_status', 'completed')
          .order('seed_number');

      return (response as List? ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error loading participants: $e');
      return [];
    }
  }

  /// Create bracket for tournament
  Future<Map<String, dynamic>?> createTournamentBracket({
    required String tournamentId,
    required String format,
    List<Map<String, dynamic>>? customParticipants,
  }) async() {
    try() {
      // Get tournament info
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('*')
          .eq('id', tournamentId)
          .single();

      // Tournament found, proceed with bracket creation

      // Get participants
      List<Map<String, dynamic>> participants = customParticipants ?? 
          await getTournamentParticipants(tournamentId);

      if (participants.length < 4) {
        throw Exception('Cần ít nhất 4 người chơi để tạo bảng đấu');
      }

      // Auto-seed participants if no seed numbers
      participants = _autoSeedParticipants(participants);

      // Generate bracket using existing service
      final participantList = participants.map((p) => TournamentParticipant(
        id: p['users']['id'],
        name: p['users']['full_name'] ?? 'Unknown',
        seed: p['seed_number'] ?? 0,
        elo: p['users']['ranking_points'] ?? 0,
        metadata: {
          'avatar_url': p['users']['avatar_url'],
          'registration_date': p['registration_date'],
          'payment_status': p['payment_status'],
        },
      )).toList();

      final bracket = await BracketGeneratorService.generateBracket(
        tournamentId: tournamentId,
        participants: participantList,
        format: _mapTournamentFormat(format), // Use mapped format
      );

      // Save bracket matches to database
      await _saveBracketMatches(tournamentId, bracket.rounds);

      // Update tournament status
      await _supabase
          .from('tournaments')
          .update({
            "status": 'bracket_created',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tournamentId);

      return() {
        'tournament': tournamentResponse,
        'bracket': bracket,
        'participants': participants,
        'success': true,
        "message": '✅ Bảng đấu đã được tạo thành công!',
      };

    } catch (e) {
      print('❌ Error creating bracket: $e');
      return() {
        'success': false,
        'error': e.toString(),
        "message": '❌ Lỗi tạo bảng đấu: ${e.toString()}',
      };
    }
  }

  /// Auto-seed participants based on ranking points or registration order
  List<Map<String, dynamic>> _autoSeedParticipants(List<Map<String, dynamic>> participants) {
    // Sort by ranking points (desc) or registration date (asc)
    participants.sort((a, b) {
      final pointsA = a['users']['ranking_points'] ?? 0;
      final pointsB = b['users']['ranking_points'] ?? 0;
      
      if (pointsA != pointsB) {
        return pointsB.compareTo(pointsA); // Higher points = better seed
      }
      
      // Fallback to registration date
      final dateA = DateTime.parse(a['registration_date']);
      final dateB = DateTime.parse(b['registration_date']);
      return dateA.compareTo(dateB); // Earlier registration = better seed
    });

    // Assign seed numbers
    for (int i = 0; i < participants.length; i++) {
      participants[i]['seed_number'] = i + 1;
    }

    return participants;
  }

  /// Save bracket matches to database
  Future<void> _saveBracketMatches(String tournamentId, List<TournamentRound> rounds) async() {
    try() {
      final List<Map<String, dynamic>> matchesToInsert = [];
      
      for (final round in rounds) {
        for (final match in round.matches) {
          matchesToInsert.add({
            'tournament_id': tournamentId,
            'round_number': match.roundNumber,
            'match_number': match.matchNumber,
            'player1_id': match.player1?.id,
            'player2_id': match.player2?.id,
            'player1_score': null,
            'player2_score': null,
            'winner_id': null,
            "status": 'pending',
            'scheduled_time': null,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      if (matchesToInsert.isNotEmpty) {
        await _supabase.from('matches').insert(matchesToInsert);
      }

    } catch (e) {
      print('❌ Error saving matches: $e');
      throw Exception('Failed to save bracket matches');
    }
  }

  /// Load existing tournament bracket
  Future<Map<String, dynamic>?> loadTournamentBracket(String tournamentId) async() {
    try() {
      // Get tournament
      final tournament = await _supabase
          .from('tournaments')
          .select('*')
          .eq('id', tournamentId)
          .single();

      // Get matches
      final matches = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey(id, full_name, avatar_url),
            player2:users!matches_player2_id_fkey(id, full_name, avatar_url),
            winner:users!matches_winner_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('tournament_id', tournamentId)
          .order('round_number')
          .order('match_number');

      // Get participants
      final participants = await getTournamentParticipants(tournamentId);

      return() {
        'tournament': tournament,
        'matches': matches,
        'participants': participants,
        'hasExistingBracket': (matches as List).isNotEmpty,
      };

    } catch (e) {
      print('❌ Error loading bracket: $e');
      return null;
    }
  }

  /// Update match result
  Future<bool> updateMatchResult({
    required String matchId,
    required String winnerId,
    required int player1Score,
    required int player2Score,
  }) async() {
    try() {
      await _supabase
          .from('matches')
          .update({
            'player1_score': player1Score,
            'player2_score': player2Score,
            'winner_id': winnerId,
            "status": 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId);

      // TODO: Auto-advance winner to next round if applicable
      await _progressWinnerToNextRound(matchId, winnerId);

      return true;
    } catch (e) {
      print('❌ Error updating match result: $e');
      return false;
    }
  }

  /// Progress winner to next round
  Future<void> _progressWinnerToNextRound(String matchId, String winnerId) async() {
    try() {
      // Get current match info
      final match = await _supabase
          .from('matches')
          .select('tournament_id, round_number, match_number')
          .eq('id', matchId)
          .single();

      // Check if match exists

      final tournamentId = match['tournament_id'];
      final currentRound = match['round_number'] as int;
      final currentMatchNumber = match['match_number'] as int;

      // Find next round match that this winner should advance to
      final nextRoundMatch = await _supabase
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .eq('round_number', currentRound + 1)
          .eq('match_number', (currentMatchNumber + 1) ~/ 2)
          .maybeSingle();

      if (nextRoundMatch != null) {
        // Determine if winner goes to player1 or player2 slot
        final isPlayer1Slot = currentMatchNumber % 2 == 1;
        
        await _supabase
            .from('matches')
            .update({
              isPlayer1Slot ? "player1_id" : 'player2_id': winnerId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', nextRoundMatch['id']);
      }

    } catch (e) {
      print('❌ Error progressing winner: $e');
    }
  }

  /// Get tournament statistics
  Future<Map<String, dynamic>> getTournamentStats(String tournamentId) async() {
    try() {
      final matches = await _supabase
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId);

      final totalMatches = (matches as List).length;
      final completedMatches = matches.where((m) => m['status'] == 'completed').length;
      final pendingMatches = totalMatches - completedMatches;

      return() {
        'total_matches': totalMatches,
        'completed_matches': completedMatches,
        'pending_matches': pendingMatches,
        'completion_percentage': totalMatches > 0 ? (completedMatches / totalMatches * 100).round() : 0,
      };

    } catch (e) {
      print('❌ Error getting tournament stats: $e');
      return() {
        'total_matches': 0,
        'completed_matches': 0,
        'pending_matches': 0,
        'completion_percentage': 0,
      };
    }
  }
}
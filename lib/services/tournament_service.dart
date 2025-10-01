import '../core/utils/rank_migration_helper.dart';
import '../models/tournament.dart';
import '../models/user_profile.dart';
import '../core/constants/tournament_constants.dart';
import 'notification_service.dart';
import 'complete_double_elimination_service.dart';
import 'complete_sabo_de16_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class TournamentService() {
  static TournamentService? _instance;
  static TournamentService get instance => _instance ??= TournamentService._();
  TournamentService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Tournament>> getTournaments({
    String? status,
    String? clubId,
    String? skillLevel,
    int page = 1,
    int pageSize = 15,
  }) async() {
    try() {
      var query = _supabase.from('tournaments').select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (clubId != null) {
        query = query.eq('club_id', clubId);
      }
      // Removed skill_level_required filter - không dùng nữa

      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      final response = await query
          .eq('is_public', true)
          .order('start_date', ascending: true)
          .range(from, to);

      return response
          .map<Tournament>((json) => Tournament.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get tournaments: $error');
    }
  }

  /// Get tournaments for club management (includes private tournaments)
  Future<List<Tournament>> getClubTournaments(String clubId, {
    String? status,
    int page = 1,
    int pageSize = 100,
  }) async() {
    try() {
      debugPrint('🔍 TournamentService: Loading tournaments for club $clubId');
      
      var query = _supabase.from('tournaments').select();
      
      // Always filter by club ID
      query = query.eq('club_id', clubId);
      
      if (status != null) {
        query = query.eq('status', status);
      }

      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final tournaments = response
          .map<Tournament>((json) => Tournament.fromJson(json))
          .toList();
          
      debugPrint('✅ TournamentService: Found ${tournaments.length} tournaments for club');
      return tournaments;
    } catch (error) {
      debugPrint('❌ TournamentService: Error loading club tournaments: $error');
      // Return mock data as fallback
      return _getMockTournamentsForClub(clubId);
    }
  }

  /// Mock tournaments for development/fallback
  List<Tournament> _getMockTournamentsForClub(String clubId) {
    final now = DateTime.now();
    return [
      Tournament(
        id: 'tournament_1',
        title: 'Giải Vô Địch CLB 2025',
        description: 'Giải đấu thường niên của câu lạc bộ',
        clubId: clubId,
        startDate: now.add(Duration(days: 15)),
        registrationDeadline: now.add(Duration(days: 10)),
        maxParticipants: 32,
        currentParticipants: 18,
        entryFee: 100000,
        prizePool: 5000000,
        status: 'upcoming',
        format: 'single_elimination', // Tournament format
        tournamentType: '8-ball', // Game type
        isPublic: true,
        createdAt: now.subtract(Duration(days: 30)),
        updatedAt: now.subtract(Duration(days: 1)),
      ),
      Tournament(
        id: 'tournament_2',
        title: 'Giải Giao Hữu Tháng 9',
        description: 'Giải đấu giao hữu hàng tháng',
        clubId: clubId,
        startDate: now.subtract(Duration(days: 5)),
        registrationDeadline: now.subtract(Duration(days: 10)),
        maxParticipants: 16,
        currentParticipants: 16,
        entryFee: 50000,
        prizePool: 1000000,
        status: 'ongoing',
        format: 'double_elimination', // Tournament format
        tournamentType: '9-ball', // Game type
        isPublic: true,
        createdAt: now.subtract(Duration(days: 20)),
        updatedAt: now.subtract(Duration(hours: 2)),
      ),
      Tournament(
        id: 'tournament_3',
        title: 'Giải Newbie Cup',
        description: 'Dành cho người mới bắt đầu',
        clubId: clubId,
        startDate: now.subtract(Duration(days: 45)),
        registrationDeadline: now.subtract(Duration(days: 50)),
        maxParticipants: 24,
        currentParticipants: 20,
        entryFee: 0,
        prizePool: 500000,
        status: 'completed',
        format: 'round_robin', // Tournament format
        tournamentType: '8-ball', // Game type
        isPublic: true,
        createdAt: now.subtract(Duration(days: 60)),
        updatedAt: now.subtract(Duration(days: 45)),
      ),
    ];
  }

  Future<Tournament> getTournamentById(String tournamentId) async() {
    try() {
      final response = await _supabase
          .from('tournaments')
          .select()
          .eq('id', tournamentId)
          .single();

      return Tournament.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get tournament: $error');
    }
  }

  Future<List<UserProfile>> getTournamentParticipants(
      String tournamentId) async() {
    try() {
      debugPrint('🔍 TournamentService: Querying participants for tournament $tournamentId');
      final response =
          await _supabase.from('tournament_participants').select('''
            *,
            users (*)
          ''').eq('tournament_id', tournamentId).order('registered_at');

      debugPrint('📊 TournamentService: Raw response count: ${response.length}');
      for (int i = 0; i < response.length; i++) {
        final item = response[i];
        debugPrint('  ${i + 1}. User: ${item['users']?['full_name']} - Status: ${item['status']}');
      }

      final participants = response
          .map<UserProfile>((json) => UserProfile.fromJson(json['users']))
          .toList();
      
      debugPrint('✅ TournamentService: Returning ${participants.length} participants');
      return participants;
    } catch (error) {
      debugPrint('❌ TournamentService: Error getting participants: $error');
      throw Exception('Failed to get tournament participants: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getTournamentMatches(String tournamentId) async() {
    try() {
      // First get matches
      final matches = await _supabase
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('round_number')
          .order('match_number');

      // Then get user profiles separately for better reliability
      List<String> playerIds = [];
      for (var match in matches) {
        if (match['player1_id'] != null) playerIds.add(match['player1_id']);
        if (match['player2_id'] != null) playerIds.add(match['player2_id']);
      }

      Map<String, dynamic> userProfiles = {};
      if (playerIds.isNotEmpty) {
        debugPrint('🔍 TournamentService: Fetching profiles for ${playerIds.length} players');
        final profiles = await _supabase
            .from('users')
            .select('id, full_name, avatar_url, elo_rating, rank')
            .inFilter('id', playerIds.toSet().toList());
        
        debugPrint('📊 TournamentService: Found ${profiles.length} profiles');
        for (var profile in profiles) {
          userProfiles[profile['id']] = profile;
          debugPrint('  Profile: ${profile['id']} - ${profile['full_name']}');
        }
      }

      return matches.map<Map<String, dynamic>>((match) {
        final player1Profile = match['player1_id'] != null ? userProfiles[match['player1_id']] : null;
        final player2Profile = match['player2_id'] != null ? userProfiles[match['player2_id']] : null;
        
        return() {
          "matchId": match['id'],
          "round": match['round_number'],
          "player1": player1Profile != null ? {
            "id": player1Profile['id'],
            "name": player1Profile['full_name'] ?? 'Player 1',
            "avatar": player1Profile['avatar_url'] ?? 
                "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
            "rank": RankMigrationHelper.getNewDisplayName(player1Profile['rank'] as String?),
            "score": match['player1_score'] ?? 0
          } : null,
          "player2": player2Profile != null ? {
            "id": player2Profile['id'],
            "name": player2Profile['full_name'] ?? 'Player 2',
            "avatar": player2Profile['avatar_url'] ?? 
                "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
            "rank": RankMigrationHelper.getNewDisplayName(player2Profile['rank'] as String?),
            "score": match['player2_score'] ?? 0
          } : null,
          "winner": match['winner_id'] != null ? 
              (match['winner_id'] == match['player1_id'] ? "player1" : "player2") : null,
          "status": match['status'] ?? "pending"
        };
      }).toList();
    } catch (error) {
      throw Exception('Failed to get tournament matches: $error');
    }
  }

  Future<bool> registerForTournament(String tournamentId, {String paymentMethod = '0'}) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if already registered
      final existingRegistration = await _supabase
          .from('tournament_participants')
          .select()
          .eq('tournament_id', tournamentId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingRegistration != null) {
        throw Exception('Already registered for this tournament');
      }

      // Check if tournament is still accepting registrations
      final tournament = await getTournamentById(tournamentId);
      if (tournament.currentParticipants >= tournament.maxParticipants) {
        throw Exception('Tournament is full');
      }

      if (DateTime.now().isAfter(tournament.registrationDeadline)) {
        throw Exception('Registration deadline has passed');
      }

      // Register for tournament
      await _supabase.from('tournament_participants').insert({
        'tournament_id': tournamentId,
        'user_id': user.id,
        "payment_status": 'pending',
        "status": 'registered',
        'notes': paymentMethod == '0' ? "Thanh toán tại quán" : 'Thanh toán QR code',
        'registered_at': DateTime.now().toIso8601String(),
      });

      // Update participant count
      await _supabase.rpc('increment_tournament_participants',
          params: {'tournament_id': tournamentId});

      // Send notification to club admin (fire and forget)
      try() {
        NotificationService.instance.sendRegistrationNotification(
          tournamentId: tournamentId,
          userId: user.id,
          paymentMethod: paymentMethod,
        );
      } catch (e) {
        debugPrint('⚠️ Failed to send notification: $e');
      }

      return true;
    } catch (error) {
      throw Exception('Failed to register for tournament: $error');
    }
  }

  Future<bool> unregisterFromTournament(String tournamentId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('tournament_participants')
          .delete()
          .eq('tournament_id', tournamentId)
          .eq('user_id', user.id);

      // Update participant count
      await _supabase.rpc('decrement_tournament_participants',
          params: {'tournament_id': tournamentId});

      return true;
    } catch (error) {
      throw Exception('Failed to unregister from tournament: $error');
    }
  }

  Future<bool> isRegisteredForTournament(String tournamentId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('tournament_participants')
          .select('id')
          .eq('tournament_id', tournamentId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (error) {
      throw Exception('Failed to check tournament registration: $error');
    }
  }

  /// No format mapping needed - database will support SABO formats directly
  /// sabo_de16, sabo_de32 have different logic than double_elimination

  Future<Tournament> createTournament({
    required String clubId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime registrationDeadline,
    required int maxParticipants,
    required double entryFee,
    required double prizePool,
    String format = 'single_elimination', // Tournament elimination format
    String gameType = '8-ball', // Game type (8-ball, 9-ball, 10-ball)
    String? rules,
    String? requirements,
  }) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final tournamentData = {
        'club_id': clubId,
        'organizer_id': user.id,
        'title': title,
        'description': description,
        'start_date': startDate.toIso8601String(),
        'registration_deadline': registrationDeadline.toIso8601String(),
        'max_participants': maxParticipants,
        'entry_fee': entryFee,
        'prize_pool': prizePool,
        // FIXED: Direct format usage - database will support SABO formats after constraint update
        'bracket_format': format, // Direct format: sabo_de16, sabo_de32, etc.
        'game_format': gameType, // Game type (8-ball, 9-ball, 10-ball)
        'rules': rules,
        'requirements': requirements,
        "status": 'upcoming',
        'current_participants': 0,
      };

      final response = await _supabase
          .from('tournaments')
          .insert(tournamentData)
          .select()
          .single();

      return Tournament.fromJson(response);
    } catch (error) {
      throw Exception('Failed to create tournament: $error');
    }
  }

  Future<List<Tournament>> getUserTournaments() async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response =
          await _supabase.from('tournament_participants').select('''
            tournaments (*)
          ''').eq('user_id', user.id).order('created_at', ascending: false);

      return response
          .map<Tournament>((json) => Tournament.fromJson(json['tournaments']))
          .toList();
    } catch (error) {
      throw Exception('Failed to get user tournaments: $error');
    }
  }

  Future<List<Tournament>> getUserOrganizedTournaments() async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('tournaments')
          .select()
          .eq('organizer_id', user.id)
          .order('created_at', ascending: false);

      return response
          .map<Tournament>((json) => Tournament.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get organized tournaments: $error');
    }
  }

  Future<List<Tournament>> searchTournaments(String query) async() {
    try() {
      final response = await _supabase
          .from('tournaments')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .eq('is_public', true)
          .order('start_date', ascending: true)
          .limit(20);

      return response
          .map<Tournament>((json) => Tournament.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to search tournaments: $error');
    }
  }

  Future<Map<String, dynamic>> getTournamentStats(String tournamentId) async() {
    try() {
      final tournament = await getTournamentById(tournamentId);
      final participants = await getTournamentParticipants(tournamentId);

      // Get matches for this tournament
      final matches = await _supabase
          .from('matches')
          .select()
          .eq('tournament_id', tournamentId);

      final completedMatches =
          matches.where((match) => match['status'] == 'completed').length;
      final pendingMatches =
          matches.where((match) => match['status'] == 'pending').length;

      return() {
        'total_participants': participants.length,
        'max_participants': tournament.maxParticipants,
        'total_matches': matches.length,
        'completed_matches': completedMatches,
        'pending_matches': pendingMatches,
        'entry_fee': tournament.entryFee,
        'prize_pool': tournament.prizePool,
        'status': tournament.status,
      };
    } catch (error) {
      throw Exception('Failed to get tournament stats: $error');
    }
  }

  // ==================== PARTICIPANT MANAGEMENT ====================

  /// Get tournament participants with payment status for club management
  Future<List<Map<String, dynamic>>> getTournamentParticipantsWithPaymentStatus(
      String tournamentId) async() {
    try() {
      debugPrint('🔍 WithPaymentStatus: Querying participants for tournament $tournamentId');
      
      // Check authentication status
      final currentUser = _supabase.auth.currentUser;
      debugPrint('🔐 Auth status: ${currentUser != null ? "Authenticated as ${currentUser.email}" : "NOT AUTHENTICATED"}');
      
      // First check total participants without JOIN
      final totalCheck = await _supabase
          .from('tournament_participants')
          .select('id, user_id, payment_status')
          .eq('tournament_id', tournamentId);
      debugPrint('🔢 DEBUG: Total participants in DB: ${totalCheck.length}');
      for (int i = 0; i < totalCheck.length; i++) {
        debugPrint('   ${i + 1}. User ID: ${totalCheck[i]['user_id']} - Payment: ${totalCheck[i]['payment_status']}');
      }
      var response = await _supabase
          .from('tournament_participants')
          .select('''
            *,
            users (
              id,
              email,
              full_name,
              avatar_url,
              elo_rating,
              rank
            )
          ''')
          .eq('tournament_id', tournamentId)
          .order('registered_at', ascending: true);
      
      debugPrint('📊 WithPaymentStatus: Raw response count: ${response.length}');
      

      
      // If response is still empty or users data is missing, try without join
      if (response.isEmpty || response.any((item) => item['users'] == null)) {
        debugPrint('⚠️ WithPaymentStatus: Join failed or empty, trying without join...');
        return await _getTournamentParticipantsWithoutJoin(tournamentId);
      }

      final result = response.map<Map<String, dynamic>>((json) {
        final user = json['users'];
        return() {
          'id': json['id'],
          'tournament_id': json['tournament_id'],
          'user_id': json['user_id'],
          'payment_status': json['payment_status'] ?? 'pending',
          'status': json['status'] ?? 'registered', 
          'notes': json['notes'],
          'registered_at': json['registered_at'],
          'user': {
            'id': user['id'],
            'email': user['email'],
            'full_name': user['full_name'] ?? 'Unknown Player',
            'avatar_url': user['avatar_url'],
            'elo_rating': user['elo_rating'] ?? 1000,
            'rank': RankMigrationHelper.getNewDisplayName(user['rank'] as String?),
          },
        };
      }).toList();
      
      debugPrint('✅ WithPaymentStatus: Returning ${result.length} participants with payment info');
      return result;
    } catch (error) {
      debugPrint('❌ Error getting participants with payment status: $error');
      throw Exception('Failed to get tournament participants: $error');
    }
  }

  /// Backup method to get participants without join (in case of join issues)
  Future<List<Map<String, dynamic>>> _getTournamentParticipantsWithoutJoin(String tournamentId) async() {
    try() {
      debugPrint('🔄 Fallback: Getting participants without join...');
      
      // First get tournament participants
      var participants = await _supabase
          .from('tournament_participants')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('registered_at', ascending: true);
      
      debugPrint('📊 Fallback: Found ${participants.length} participant records');
      

      
      // Then get user data separately
      final List<Map<String, dynamic>> result = [];
      for (final participant in participants) {
        try() {
          final userData = await _supabase
              .from('users')
              .select('id, email, full_name, avatar_url, elo_rating, rank')
              .eq('id', participant['user_id'])
              .single();
          
          result.add({
            'id': participant['id'],
            'tournament_id': participant['tournament_id'],
            'user_id': participant['user_id'],
            'payment_status': participant['payment_status'] ?? 'pending',
            'status': participant['status'] ?? 'registered',
            'notes': participant['notes'],
            'registered_at': participant['registered_at'],
            'user': {
              'id': userData['id'],
              'email': userData['email'],
              'full_name': userData['full_name'] ?? 'Unknown Player',
              'avatar_url': userData['avatar_url'],
              'elo_rating': userData['elo_rating'] ?? 1000,
              'rank': RankMigrationHelper.getNewDisplayName(userData['rank'] as String?),
            },
          });
        } catch (e) {
          debugPrint('⚠️ Fallback: Failed to get user data for ${participant['user_id']}: $e');
          // Add participant without user data
          result.add({
            'id': participant['id'],
            'tournament_id': participant['tournament_id'],
            'user_id': participant['user_id'],
            'payment_status': participant['payment_status'] ?? 'pending',
            'status': participant['status'] ?? 'registered',
            'notes': participant['notes'],
            'registered_at': participant['registered_at'],
            'user': {
              'id': participant['user_id'],
              "email": 'unknown@example.com',
              "full_name": 'Unknown Player',
              'avatar_url': null,
              'elo_rating': 1000,
              "rank": 'Novice',
            },
          });
        }
      }
      
      debugPrint('✅ Fallback: Returning ${result.length} participants');
      return result;
    } catch (e) {
      debugPrint('❌ Fallback: Error: $e');
      return [];
    }
  }

  /// Update payment status for a tournament participant (club owner only)
  Future<bool> updateParticipantPaymentStatus({
    required String tournamentId,
    required String userId,
    required String paymentStatus, // 'pending', 'confirmed', 'completed'
    String? notes,
  }) async() {
    try() {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Validate payment status
      if (!['pending', 'confirmed', 'completed'].contains(paymentStatus)) {
        throw Exception('Invalid payment status');
      }

      // Update the participant record
      await _supabase
          .from('tournament_participants')
          .update({
            'payment_status': paymentStatus,
            'notes': notes,
          })
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId);

      debugPrint('✅ Updated payment status for user $userId to $paymentStatus');
      return true;
    } catch (error) {
      debugPrint('❌ Error updating payment status: $error');
      throw Exception('Failed to update payment status: $error');
    }
  }

  /// Remove a participant from tournament (club owner only)
  Future<bool> removeParticipant({
    required String tournamentId,
    required String userId,
    String? reason,
  }) async() {
    try() {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Remove participant
      await _supabase
          .from('tournament_participants')
          .delete()
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId);

      // Update participant count
      await _supabase.rpc('decrement_tournament_participants',
          params: {'tournament_id': tournamentId});

      debugPrint('✅ Removed participant $userId from tournament $tournamentId');
      return true;
    } catch (error) {
      debugPrint('❌ Error removing participant: $error');
      throw Exception('Failed to remove participant: $error');
    }
  }

  // ==================== CORE TOURNAMENT LOGIC ====================

  /// Tạo tournament bracket dựa trên format và danh sách participants
  Future<TournamentBracket> generateBracket({
    required String tournamentId,
    required String format,
    required List<UserProfile> participants,
    String seedingMethod = SeedingMethods.eloRating,
  }) async() {
    try() {
      debugPrint('🎯 GenerateBracket: Starting bracket generation for tournament $tournamentId with ${participants.length} participants');
      
      // Validate format và số người chơi
      if (!TournamentHelper.isValidPlayerCount(format, participants.length)) {
        throw Exception('Invalid player count for format $format');
      }

      // 🏆 SPECIAL HANDLING: Use SABO DE16 bracket generator (27 matches)
      if (format == 'sabo_de16' && participants.length == 16) {
        debugPrint('� Using SABO DE16 bracket generator (27 matches)');
        return await _generateSaboDE16Bracket(tournamentId, participants, seedingMethod);
      }

      // 🚀 SPECIAL HANDLING: Use CompleteDoubleEliminationService for standard DE16 (31 matches)
      if (format == 'double_elimination' && participants.length == 16) {
        debugPrint('� Using CompleteDoubleEliminationService for standard DE16 (31 matches)');
        return await _generateDE16Bracket(tournamentId, participants, seedingMethod);
      }

      // Seeding participants (fallback to original logic)
      final seededParticipants = await _seedParticipants(participants, seedingMethod);
      debugPrint('✅ GenerateBracket: Participants seeded successfully');

      // Generate bracket structure dựa trên format
      final bracketStructure = _generateBracketStructure(format, seededParticipants);
      debugPrint('✅ GenerateBracket: Bracket structure generated');

      // Tạo matches
      final matches = _generateMatches(tournamentId, bracketStructure, format);
      debugPrint('📊 GenerateBracket: Generated ${matches.length} matches');

      // Save matches to database
      await _saveMatchesToDatabase(matches);
      debugPrint('✅ GenerateBracket: Matches saved to database');

      // Update tournament status to ongoing
      await updateTournamentStatus(tournamentId, 'ongoing');
      debugPrint('✅ GenerateBracket: Tournament status updated to ongoing');

      return TournamentBracket(
        tournamentId: tournamentId,
        format: format,
        participants: seededParticipants,
        matches: matches,
        rounds: TournamentHelper.calculateRounds(format, participants.length),
        status: 'ready',
        createdAt: DateTime.now(),
      );
    } catch (error) {
      debugPrint('🔥 GenerateBracket error: $error');
      throw Exception('Failed to generate bracket: $error');
    }
  }

  /// 🚀 Generate DE16 bracket using CompleteDoubleEliminationService
  Future<TournamentBracket> _generateDE16Bracket(
    String tournamentId,
    List<UserProfile> participants,
    String seedingMethod,
  ) async {
    try {
      debugPrint('🎯 DE16: Using CompleteDoubleEliminationService for precise bracket generation');

      // Seeding participants first
      final seededParticipants = await _seedParticipants(participants, seedingMethod);
      debugPrint('✅ DE16: Participants seeded successfully');

      // Convert UserProfile to format expected by CompleteDoubleEliminationService
      final participantsData = seededParticipants.map((seeded) => {
        'user_id': seeded.participant.id,
        'seed_number': seeded.seedNumber,
        'full_name': seeded.participant.fullName,
        'username': seeded.participant.username,
        'elo_rating': seeded.participant.eloRating,
        'avatar_url': seeded.participant.avatarUrl,
      }).toList();

      // Generate bracket using CompleteDoubleEliminationService
      final de16Service = CompleteDoubleEliminationService.instance;
      final result = await de16Service.generateDE16Bracket(
        tournamentId: tournamentId,
        participants: participantsData,
      );

      if (!result['success']) {
        throw Exception('DE16 bracket generation failed: ${result['error']}');
      }

      debugPrint('✅ DE16: Generated ${result['matchesGenerated']} matches with CompleteDoubleEliminationService');

      // Update tournament status to ongoing
      await updateTournamentStatus(tournamentId, 'ongoing');
      debugPrint('✅ DE16: Tournament status updated to ongoing');

      // Return TournamentBracket with DE16 specific data
      return TournamentBracket(
        tournamentId: tournamentId,
        format: 'double_elimination',
        participants: seededParticipants,
        matches: [], // Matches are already in database via CompleteDoubleEliminationService
        rounds: 8, // DE16 has 8 round levels (WB: 4, LB: 7, GF: 1)
        status: 'ready',
        createdAt: DateTime.now(),
      );

    } catch (error) {
      debugPrint('❌ DE16 bracket generation error: $error');
      throw Exception('Failed to generate DE16 bracket: $error');
    }
  }

  /// 🏆 Generate SABO DE16 bracket using bracket generator service
  Future<TournamentBracket> _generateSaboDE16Bracket(
    String tournamentId,
    List<UserProfile> participants,
    String seedingMethod,
  ) async {
    try {
      debugPrint('🏆 SABO DE16: Using CompleteSaboDE16Service for precise bracket generation');

      // Seeding participants first
      final seededParticipants = await _seedParticipants(participants, seedingMethod);
      debugPrint('✅ SABO DE16: Participants seeded successfully');

      // Convert UserProfile to format expected by CompleteSaboDE16Service
      final participantsData = seededParticipants.map((seeded) => {
        'user_id': seeded.participant.id,
        'seed_number': seeded.seedNumber,
        'full_name': seeded.participant.fullName,
        'username': seeded.participant.username,
        'elo_rating': seeded.participant.eloRating,
        'avatar_url': seeded.participant.avatarUrl,
      }).toList();

      // Generate bracket using CompleteSaboDE16Service
      final saboDE16Service = CompleteSaboDE16Service();
      final result = await saboDE16Service.generateSaboDE16Bracket(
        tournamentId: tournamentId,
        participants: participantsData,
      );

      if (!result['success']) {
        throw Exception('SABO DE16 bracket generation failed: ${result['error']}');
      }

      debugPrint('✅ SABO DE16: Generated ${result['matchesGenerated']} matches with CompleteSaboDE16Service');

      // Update tournament status to ongoing
      await updateTournamentStatus(tournamentId, 'ongoing');
      debugPrint('✅ SABO DE16: Tournament status updated to ongoing');

      // Return TournamentBracket with SABO DE16 specific data
      return TournamentBracket(
        tournamentId: tournamentId,
        format: 'sabo_de16',
        participants: seededParticipants,
        matches: [], // Matches are already in database via CompleteSaboDE16Service
        rounds: 27, // SABO DE16 has 27 total matches
        status: 'ready',
        createdAt: DateTime.now(),
      );

    } catch (error) {
      debugPrint('❌ SABO DE16 bracket generation error: $error');
      throw Exception('Failed to generate SABO DE16 bracket: $error');
    }
  }







  /// Seeding participants dựa trên method được chỉ định
  Future<List<SeededParticipant>> _seedParticipants(
    List<UserProfile> participants,
    String seedingMethod,
  ) async() {
    List<SeededParticipant> seeded = [];

    switch (seedingMethod) {
      case SeedingMethods.eloRating:
        participants.sort((a, b) => b.eloRating.compareTo(a.eloRating));
        break;
      
      case SeedingMethods.clubRanking:
        // TODO: Implement club ranking logic
        participants.sort((a, b) => b.eloRating.compareTo(a.eloRating));
        break;
        
      case SeedingMethods.previousTournaments:
        // TODO: Implement tournament history logic
        participants.sort((a, b) => b.eloRating.compareTo(a.eloRating));
        break;
        
      case SeedingMethods.hybrid:
        // Combine ELO + tournament history
        participants.sort((a, b) => _calculateHybridSeed(a, b));
        break;
        
      case SeedingMethods.random:
      default:
        participants.shuffle();
        break;
    }

    for (int i = 0; i < participants.length; i++) {
      seeded.add(SeededParticipant(
        participant: participants[i],
        seedNumber: i + 1,
        seedingMethod: seedingMethod,
      ));
    }

    return seeded;
  }

  /// Calculate hybrid seeding score
  int _calculateHybridSeed(UserProfile a, UserProfile b) {
    // Weight: 70% ELO, 30% tournament history
    double scoreA = (a.eloRating * 0.7) + (_getTournamentHistoryScore(a) * 0.3);
    double scoreB = (b.eloRating * 0.7) + (_getTournamentHistoryScore(b) * 0.3);
    return scoreB.compareTo(scoreA);
  }

  /// Get tournament history score for hybrid seeding
  double _getTournamentHistoryScore(UserProfile participant) {
    // TODO: Implement real tournament history calculation
    // For now return base ELO
    return participant.eloRating.toDouble();
  }

  /// Generate bracket structure theo format
  Map<String, dynamic> _generateBracketStructure(
    String format,
    List<SeededParticipant> participants,
  ) {
    switch (format) {
      case TournamentFormats.singleElimination:
        return _generateSingleEliminationBracket(participants);
        
      case TournamentFormats.doubleElimination:
        return _generateDoubleEliminationBracket(participants);
        
      case TournamentFormats.roundRobin:
        return _generateRoundRobinBracket(participants);
        
      case TournamentFormats.swiss:
        return _generateSwissBracket(participants);
        
      case TournamentFormats.parallelGroups:
        return _generateParallelGroupsBracket(participants);
        
      default:
        return _generateSingleEliminationBracket(participants);
    }
  }

  /// Generate single elimination bracket
  Map<String, dynamic> _generateSingleEliminationBracket(List<SeededParticipant> participants) {
    final int playerCount = participants.length;
    final int rounds = math.log(playerCount) ~/ math.log(2);
    
    // Create first round pairings
    List<Map<String, dynamic>> firstRoundPairings = [];
    
    for (int i = 0; i < playerCount; i += 2) {
      firstRoundPairings.add({
        'player1': participants[i],
        'player2': i + 1 < playerCount ? participants[i + 1] : null,
        'round': 1,
        'matchNumber': (i ~/ 2) + 1,
      });
    }

    return() {
      "type": 'single_elimination',
      'rounds': rounds,
      'firstRound': firstRoundPairings,
      "structure": 'standard_bracket',
    };
  }

  /// Generate double elimination bracket
  Map<String, dynamic> _generateDoubleEliminationBracket(List<SeededParticipant> participants) {
    // Winner bracket structure
    final winnerBracket = _generateSingleEliminationBracket(participants);
    
    return() {
      "type": 'double_elimination',
      'winnerBracket': winnerBracket,
      'loserBracket': _generateLoserBracket(participants.length),
      'grandFinalsRequired': true,
    };
  }

  /// Generate round robin bracket
  Map<String, dynamic> _generateRoundRobinBracket(List<SeededParticipant> participants) {
    List<Map<String, dynamic>> allPairings = [];
    final int playerCount = participants.length;
    
    for (int i = 0; i < playerCount; i++) {
      for (int j = i + 1; j < playerCount; j++) {
        allPairings.add({
          'player1': participants[i],
          'player2': participants[j],
          'round': ((allPairings.length ~/ (playerCount ~/ 2)) + 1),
          'matchNumber': allPairings.length + 1,
        });
      }
    }

    return() {
      "type": 'round_robin',
      'totalRounds': playerCount - 1,
      'allPairings': allPairings,
      'pointsSystem': {'win': 3, 'draw': 1, 'loss': 0},
    };
  }

  /// Generate Swiss system bracket (initial round only)
  Map<String, dynamic> _generateSwissBracket(List<SeededParticipant> participants) {
    // First round: pair top half vs bottom half
    List<Map<String, dynamic>> firstRoundPairings = [];
    final int half = participants.length ~/ 2;
    
    for (int i = 0; i < half; i++) {
      firstRoundPairings.add({
        'player1': participants[i],
        'player2': participants[i + half],
        'round': 1,
        'matchNumber': i + 1,
      });
    }

    return() {
      "type": 'swiss',
      'totalRounds': TournamentHelper.calculateRounds(TournamentFormats.swiss, participants.length),
      'firstRound': firstRoundPairings,
      "pairingMethod": 'swiss_system',
    };
  }

  /// Generate parallel groups bracket
  Map<String, dynamic> _generateParallelGroupsBracket(List<SeededParticipant> participants) {
    final int playerCount = participants.length;
    final int groupCount = math.min(4, playerCount ~/ 4); // Max 4 groups
    
    List<List<SeededParticipant>> groups = [];
    
    // Distribute players across groups (snake seeding)
    for (int g = 0; g < groupCount; g++) {
      groups.add([]);
    }
    
    for (int i = 0; i < playerCount; i++) {
      final groupIndex = i % groupCount;
      groups[groupIndex].add(participants[i]);
    }

    return() {
      "type": 'parallel_groups',
      'groupCount': groupCount,
      'groups': groups.map((group) => _generateRoundRobinBracket(group)).toList(),
      "finalsStructure": 'knockout', // Top players advance to knockout
    };
  }

  /// Generate loser bracket for double elimination
  Map<String, dynamic> _generateLoserBracket(int playerCount) {
    // Simplified loser bracket structure
    return() {
      'rounds': (math.log(playerCount) ~/ math.log(2)) * 2 - 1,
      "structure": 'loser_bracket',
      'feedFromWinner': true,
    };
  }

  /// Generate matches từ bracket structure
  List<TournamentMatch> _generateMatches(
    String tournamentId,
    Map<String, dynamic> bracketStructure,
    String format,
  ) {
    List<TournamentMatch> matches = [];
    
    switch (format) {
      case TournamentFormats.singleElimination:
        matches.addAll(_generateSingleEliminationMatches(tournamentId, bracketStructure));
        break;
        
      case TournamentFormats.roundRobin:
        matches.addAll(_generateRoundRobinMatches(tournamentId, bracketStructure));
        break;
        
      case TournamentFormats.swiss:
        matches.addAll(_generateSwissMatches(tournamentId, bracketStructure));
        break;
        
      // Add other formats...
    }
    
    return matches;
  }

  /// Save generated matches to database
  Future<void> _saveMatchesToDatabase(List<TournamentMatch> matches) async() {
    try() {
      debugPrint('🔄 Saving ${matches.length} matches to database...');
      
      for (final match in matches) {
        final matchData = {
          'id': match.id,
          'tournament_id': match.tournamentId,
          'round_number': match.round,
          'match_number': match.matchNumber,
          'player1_id': match.player1Id,
          'player2_id': match.player2Id,
          'status': match.status,
          'scheduled_time': match.scheduledTime?.toIso8601String(), // REVERT: scheduled_at -> scheduled_time
          'winner_id': match.winnerId,
          'bracket_format': match.format, // FIXED: Use bracket_format column
          'player1_score': null, // Changed from 'score' to separate scores
          'player2_score': null,
          'created_at': match.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        debugPrint('💾 Saving match: R${match.round} M${match.matchNumber} - ${match.player1Id} vs ${match.player2Id}');
        
        await Supabase.instance.client
            .from('matches')
            .insert(matchData);
      }
      
      debugPrint('✅ All matches saved successfully');
    } catch (e) {
      debugPrint('🔥 Error saving matches: $e');
      throw Exception('Failed to save matches to database: $e');
    }
  }

  /// Generate single elimination matches
  List<TournamentMatch> _generateSingleEliminationMatches(
    String tournamentId,
    Map<String, dynamic> bracket,
  ) {
    List<TournamentMatch> matches = [];
    final firstRound = bracket['firstRound'] as List<Map<String, dynamic>>;
    
    for (var pairing in firstRound) {
      matches.add(TournamentMatch(
        id: _generateMatchId(),
        tournamentId: tournamentId,
        player1Id: pairing['player1']?.participant.id,
        player2Id: pairing['player2']?.participant?.id,
        round: pairing['round'],
        matchNumber: pairing['matchNumber'],
        status: MatchStatus.pending,
        format: 'single_elimination',
        createdAt: DateTime.now(),
      ));
    }
    
    return matches;
  }

  /// Generate round robin matches
  List<TournamentMatch> _generateRoundRobinMatches(
    String tournamentId,
    Map<String, dynamic> bracket,
  ) {
    List<TournamentMatch> matches = [];
    final allPairings = bracket['allPairings'] as List<Map<String, dynamic>>;
    
    for (var pairing in allPairings) {
      matches.add(TournamentMatch(
        id: _generateMatchId(),
        tournamentId: tournamentId,
        player1Id: pairing['player1'].participant.id,
        player2Id: pairing['player2'].participant.id,
        round: pairing['round'],
        matchNumber: pairing['matchNumber'],
        status: MatchStatus.pending,
        format: 'round_robin',
        createdAt: DateTime.now(),
      ));
    }
    
    return matches;
  }

  /// Generate Swiss system matches (first round only)
  List<TournamentMatch> _generateSwissMatches(
    String tournamentId,
    Map<String, dynamic> bracket,
  ) {
    List<TournamentMatch> matches = [];
    final firstRound = bracket['firstRound'] as List<Map<String, dynamic>>;
    
    for (var pairing in firstRound) {
      matches.add(TournamentMatch(
        id: _generateMatchId(),
        tournamentId: tournamentId,
        player1Id: pairing['player1'].participant.id,
        player2Id: pairing['player2'].participant.id,
        round: pairing['round'],
        matchNumber: pairing['matchNumber'],
        status: MatchStatus.pending,
        format: 'swiss',
        createdAt: DateTime.now(),
      ));
    }
    
    return matches;
  }

  /// Calculate prize distribution dựa trên template và tournament results
  Future<List<PrizeDistributionResult>> calculatePrizeDistribution({
    required String tournamentId,
    required String distributionType,
    required double totalPrizePool,
    required List<TournamentResult> results,
  }) async() {
    try() {
      final playerCount = results.length;
      final distribution = TournamentHelper.getPrizeDistribution(distributionType, playerCount);
      
      List<PrizeDistributionResult> prizeResults = [];
      
      for (int i = 0; i < distribution.length && i < results.length; i++) {
        final percentage = distribution[i];
        final prizeAmount = totalPrizePool * percentage;
        
        prizeResults.add(PrizeDistributionResult(
          position: i + 1,
          participantId: results[i].participantId,
          prizeAmount: prizeAmount,
          percentage: percentage,
          prizeType: PrizeTypes.cash,
        ));
      }
      
      return prizeResults;
    } catch (error) {
      throw Exception('Failed to calculate prize distribution: $error');
    }
  }

  /// Update tournament status
  Future<void> updateTournamentStatus(String tournamentId, String newStatus) async() {
    try() {
      await _supabase
          .from('tournaments')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', tournamentId);
    } catch (error) {
      throw Exception('Failed to update tournament status: $error');
    }
  }

  /// Generate unique match ID
  String _generateMatchId() {
    // Generate a UUID-like string using random values
    return '${_randomHex(8)}-${_randomHex(4)}-${_randomHex(4)}-${_randomHex(4)}-${_randomHex(12)}';
  }
  
  String _randomHex(int length) {
    final random = math.Random();
    final chars = '0123456789abcdef';
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  /// Calculate ELO changes cho tournament results
  Future<List<EloChange>> calculateTournamentEloChanges({
    required String tournamentId,
    required List<TournamentResult> results,
    required String tournamentFormat,
    required int participantCount,
  }) async() {
    try() {
      List<EloChange> eloChanges = [];
      
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final position = i + 1;
        
        // Base ELO reward dựa trên placement
        int baseEloReward = _calculateBaseEloReward(position, participantCount);
        
        // Tournament size bonus
        int sizeBonus = participantCount >= 32 ? 5 : 0;
        
        // Format bonus
        int formatBonus = _getFormatBonus(tournamentFormat);
        
        // Performance bonus (upset, perfect run, etc.)
        int performanceBonus = await _calculatePerformanceBonus(result, results);
        
        final totalEloChange = baseEloReward + sizeBonus + formatBonus + performanceBonus;
        
        eloChanges.add(EloChange(
          participantId: result.participantId,
          oldElo: result.startingElo,
          newElo: result.startingElo + totalEloChange,
          change: totalEloChange,
          reason: 'Tournament #$tournamentId: Position $position/${results.length}',
          baseReward: baseEloReward,
          bonuses: {
            'size_bonus': sizeBonus,
            'format_bonus': formatBonus,
            'performance_bonus': performanceBonus,
          },
        ));
      }
      
      return eloChanges;
    } catch (error) {
      throw Exception('Failed to calculate ELO changes: $error');
    }
  }

  /// Calculate base ELO reward dựa trên position
  int _calculateBaseEloReward(int position, int totalParticipants) {
    if (position == 1) return 25; // Winner
    if (position == 2) return 15; // Runner-up
    if (position <= 4) return 10; // Semi-finalists
    if (position <= 8) return 5;  // Quarter-finalists
    if (position <= totalParticipants / 2) return 2; // Top half
    return -2; // Bottom half (small penalty)
  }

  /// Get format bonus ELO
  int _getFormatBonus(String format) {
    switch (format) {
      case TournamentFormats.doubleElimination:
        return 3; // Harder format
      case TournamentFormats.swiss:
        return 2;
      case TournamentFormats.roundRobin:
        return 1;
      default:
        return 0;
    }
  }

  /// Calculate performance bonuses
  Future<int> _calculatePerformanceBonus(TournamentResult result, List<TournamentResult> allResults) async() {
    int bonus = 0;
    
    // Perfect run bonus (no losses in single elimination)
    if (result.matchesLost == 0) {
      bonus += 5;
    }
    
    // Upset bonus (beat higher seeded players)
    if (result.defeatedHigherSeeds > 0) {
      bonus += result.defeatedHigherSeeds * 3;
    }
    
    // TODO: Add streak bonus logic
    
    return bonus;
  }


}

// ==================== DATA MODELS ====================

/// Tournament Bracket Model
class TournamentBracket() {
  final String tournamentId;
  final String format;
  final List<SeededParticipant> participants;
  final List<TournamentMatch> matches;
  final int rounds;
  final String status;
  final DateTime createdAt;

  TournamentBracket({
    required this.tournamentId,
    required this.format,
    required this.participants,
    required this.matches,
    required this.rounds,
    required this.status,
    required this.createdAt,
  });
}

/// Seeded Participant Model
class SeededParticipant() {
  final UserProfile participant;
  final int seedNumber;
  final String seedingMethod;

  SeededParticipant({
    required this.participant,
    required this.seedNumber,
    required this.seedingMethod,
  });
}

/// Tournament Match Model
class TournamentMatch() {
  final String id;
  final String tournamentId;
  final String? player1Id;
  final String? player2Id;
  final int round;
  final int matchNumber;
  final String status;
  final String format;
  final DateTime createdAt;
  final String? winnerId;
  final Map<String, int>? score;
  final DateTime? scheduledTime;
  final String? tableNumber;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    this.player1Id,
    this.player2Id,
    required this.round,
    required this.matchNumber,
    required this.status,
    required this.format,
    required this.createdAt,
    this.winnerId,
    this.score,
    this.scheduledTime,
    this.tableNumber,
  });
}

/// Match Status Constants
class MatchStatus() {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
}

/// Tournament Result Model
class TournamentResult() {
  final String participantId;
  final int finalPosition;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int startingElo;
  final int defeatedHigherSeeds;
  final List<String> defeatedOpponents;

  TournamentResult({
    required this.participantId,
    required this.finalPosition,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.startingElo,
    this.defeatedHigherSeeds = 0,
    this.defeatedOpponents = const [],
  });
}

/// Prize Distribution Result Model
class PrizeDistributionResult() {
  final int position;
  final String participantId;
  final double prizeAmount;
  final double percentage;
  final String prizeType;

  PrizeDistributionResult({
    required this.position,
    required this.participantId,
    required this.prizeAmount,
    required this.percentage,
    required this.prizeType,
  });
}

/// ELO Change Model
class EloChange() {
  final String participantId;
  final int oldElo;
  final int newElo;
  final int change;
  final String reason;
  final int baseReward;
  final Map<String, int> bonuses;

  EloChange({
    required this.participantId,
    required this.oldElo,
    required this.newElo,
    required this.change,
    required this.reason,
    required this.baseReward,
    required this.bonuses,
  });
}

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/services/bracket_generator_service.dart';

void main() async {
  print('🚀 Testing Tournament Advancement...');
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  final supabase = Supabase.instance.client;
  final bracketService = BracketGeneratorService();

  // Tournament ID with completed Round 1
  const tournamentId = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6';
  
  try {
    print('📊 Fetching tournament data...');
    
    // Get participants
    final participantsResponse = await supabase
        .from('tournament_participants')
        .select('*, user_profiles(*)')
        .eq('tournament_id', tournamentId);
        
    final participants = participantsResponse.map((p) {
      final userProfile = p['user_profiles'];
      return TournamentParticipant(
        id: p['user_id'],
        name: userProfile?['username'] ?? 'Unknown Player',
        seed: p['seed'],
      );
    }).toList();
    
    print('✅ Found ${participants.length} participants');
    
    // Get current matches
    final matchesResponse = await supabase
        .from('matches')
        .select('*')
        .eq('tournament_id', tournamentId)
        .order('round_number, match_number');
        
    final currentMatches = matchesResponse.map((m) {
      TournamentParticipant? player1, player2, winner;
      
      // Find players
      if (m['player1_id'] != null) {
        player1 = participants.firstWhere(
          (p) => p.id == m['player1_id'],
          orElse: () => TournamentParticipant(id: m['player1_id'], name: 'Unknown'),
        );
      }
      
      if (m['player2_id'] != null) {
        player2 = participants.firstWhere(
          (p) => p.id == m['player2_id'],
          orElse: () => TournamentParticipant(id: m['player2_id'], name: 'Unknown'),
        );
      }
      
      if (m['winner_id'] != null) {
        winner = participants.firstWhere(
          (p) => p.id == m['winner_id'],
          orElse: () => TournamentParticipant(id: m['winner_id'], name: 'Winner'),
        );
      }
      
      return TournamentMatch(
        id: m['id'],
        roundId: 'round_${m['round_number']}',
        roundNumber: m['round_number'],
        matchNumber: m['match_number'],
        player1: player1,
        player2: player2,
        winner: winner,
        status: m['status'] ?? 'pending',
      );
    }).toList();
    
    print('✅ Found ${currentMatches.length} current matches');
    
    // Analyze current state
    final roundGroups = <int, List<TournamentMatch>>{};
    for (final match in currentMatches) {
      roundGroups.putIfAbsent(match.roundNumber, () => []).add(match);
    }
    
    print('\n📋 Current Tournament State:');
    for (final roundNum in roundGroups.keys.toList()..sort()) {
      final roundMatches = roundGroups[roundNum]!;
      final completed = roundMatches.where((m) => m.status == 'completed').length;
      print('   Round $roundNum: ${roundMatches.length} matches ($completed completed)');
    }
    
    // Test advancement
    print('\n🔄 Testing tournament advancement...');
    
    final result = await bracketService.advanceTournament(
      tournamentId: tournamentId,
      participants: participants,
      currentMatches: currentMatches,
      format: 'single_elimination',
    );
    
    print('\n📊 Advancement Result:');
    print('   Success: ${result['success']}');
    print('   Message: ${result['message']}');
    
    if (result['success'] == true) {
      final newMatches = result['newMatches'] as List<TournamentMatch>;
      final roundName = result['roundName'];
      final roundNumber = result['roundNumber'];
      
      print('   New Round: $roundName (Round $roundNumber)');
      print('   New Matches: ${newMatches.length}');
      
      print('\n🎯 Generated Matches:');
      for (int i = 0; i < newMatches.length; i++) {
        final match = newMatches[i];
        print('   Match ${i + 1}: ${match.player1?.name} vs ${match.player2?.name}');
      }
      
      // Save new matches to database
      print('\n💾 Saving new matches to database...');
      for (final match in newMatches) {
        await supabase.from('matches').insert({
          'id': match.id,
          'tournament_id': tournamentId,
          'round_number': match.roundNumber,
          'match_number': match.matchNumber,
          'player1_id': match.player1?.id,
          'player2_id': match.player2?.id,
          'status': match.status,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      print('✅ Round 2 created successfully!');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
// 🧪 TEST CORRECT BRACKET LOGIC
// Test script to verify tournament bracket generation
// Author: SABO v1.0
// Test date: 2025-01-29

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Starting bracket logic validation test...\n');
  
  // Test tournament: 6c0658f7-bf94-44a0-82b1-de117ec9ea29  (FIXED ID)
  const tournamentId = '6c0658f7-bf94-44a0-82b1-de117ec9ea29';
  
  await testBracketStructure(tournamentId);
}

Future<void> testBracketStructure(String tournamentId) async {
  try {
    const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ';

    print('📊 Analyzing Tournament: $tournamentId');
    
    // Get participants
    final participantsUrl = Uri.parse('$supabaseUrl/rest/v1/tournament_participants?tournament_id=eq.$tournamentId&select=*');
    final participantsResponse = await http.get(
      participantsUrl,
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      },
    );
    
    if (participantsResponse.statusCode != 200) {
      throw Exception('Failed to fetch participants: ${participantsResponse.body}');
    }
    
    final participants = json.decode(participantsResponse.body) as List;
    final participantCount = participants.length;
    
    print('👥 Participants: $participantCount');
    
    // Get matches by round
    final matchesUrl = Uri.parse('$supabaseUrl/rest/v1/matches?tournament_id=eq.$tournamentId&select=*&order=round_number,match_number');
    final matchesResponse = await http.get(
      matchesUrl,
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      },
    );
    
    if (matchesResponse.statusCode != 200) {
      throw Exception('Failed to fetch matches: ${matchesResponse.body}');
    }
    
    final matches = json.decode(matchesResponse.body) as List;
    
    // Group by rounds
    final Map<int, List> matchesByRound = {};
    for (var match in matches) {
      final round = match['round_number'] as int;
      matchesByRound.putIfAbsent(round, () => []).add(match);
    }
    
    print('\n🎯 BRACKET ANALYSIS:');
    print('═' * 50);
    
    // Expected structure for single elimination
    final expectedTotalMatches = participantCount - 1; // n-1 rule
    print('📈 Expected total matches: $expectedTotalMatches (n-1 rule)');
    print('📊 Actual total matches: ${matches.length}');
    print('✅ Match count correct: ${matches.length == expectedTotalMatches}');
    
    print('\n🏆 ROUND-BY-ROUND ANALYSIS:');
    print('─' * 30);
    
    // Calculate expected rounds
    var currentPlayers = participantCount;
    int round = 1;
    
    while (currentPlayers > 1) {
      final expectedMatches = currentPlayers ~/ 2;
      final actualMatches = matchesByRound[round]?.length ?? 0;
      final isCorrect = actualMatches == expectedMatches;
      
      print('Round $round: Expected $expectedMatches, Actual $actualMatches ${isCorrect ? "✅" : "❌"}');
      
      if (!isCorrect) {
        print('  🚨 CRITICAL ERROR: Round $round has wrong match count!');
        
        // Show match details for this round
        final roundMatches = matchesByRound[round] ?? [];
        for (var i = 0; i < roundMatches.length; i++) {
          final match = roundMatches[i];
          print('    Match ${i + 1}: ${match['player1_id']} vs ${match['player2_id']} (${match['status']})');
        }
      }
      
      currentPlayers = expectedMatches; // Winners advance
      round++;
    }
    
    print('\n🔍 BRACKET VALIDATION RESULT:');
    print('═' * 40);
    
    bool isValidBracket = true;
    
    // Check n-1 rule
    if (matches.length != expectedTotalMatches) {
      isValidBracket = false;
      print('❌ Total match count violation (n-1 rule)');
    }
    
    // Check each round
    currentPlayers = participantCount;
    round = 1;
    while (currentPlayers > 1) {
      final expectedMatches = currentPlayers ~/ 2;
      final actualMatches = matchesByRound[round]?.length ?? 0;
      
      if (actualMatches != expectedMatches) {
        isValidBracket = false;
        print('❌ Round $round: Expected $expectedMatches, got $actualMatches');
      }
      
      currentPlayers = expectedMatches;
      round++;
    }
    
    if (isValidBracket) {
      print('🎉 BRACKET IS VALID!');
    } else {
      print('🚨 BRACKET IS INVALID - NEEDS REPAIR');
      
      print('\n💡 RECOMMENDED FIX:');
      print('1. Use correct_bracket_logic_service.dart');
      print('2. Call repairTournamentBracket("$tournamentId")');
      print('3. Verify with validateBracketStructure()');
    }
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
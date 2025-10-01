import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  // Initialize Supabase client
  final supabase = SupabaseClient(
    'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ',
  );

  print('🔍 Checking tournament_participants table...');
  print('');

  try {
    // Check ALL tournament_participants records
    print('1️⃣ All tournament_participants records:');
    final allParticipants = await supabase
        .from('tournament_participants')
        .select('*');
    
    print('   Total participants across all tournaments: ${allParticipants.length}');
    
    if (allParticipants.isEmpty) {
      print('   ⚠️  The tournament_participants table is completely empty!');
    } else {
      print('   📋 Tournament breakdown:');
      Map<String, int> tournamentCounts = {};
      for (var participant in allParticipants) {
        String tournamentId = participant['tournament_id'];
        tournamentCounts[tournamentId] = (tournamentCounts[tournamentId] ?? 0) + 1;
      }
      
      for (var entry in tournamentCounts.entries) {
        print('   - Tournament ${entry.key}: ${entry.value} participants');
      }
    }
    print('');

    // Check all tournaments
    print('2️⃣ All tournaments:');
    final tournaments = await supabase
        .from('tournaments')
        .select('id, title, status, created_at');
    
    print('   Total tournaments: ${tournaments.length}');
    for (var tournament in tournaments) {
      print('   - ${tournament['title']} (${tournament['status']}) - ID: ${tournament['id']}');
    }

  } catch (e) {
    print('❌ Error: $e');
  }

  exit(0);
}
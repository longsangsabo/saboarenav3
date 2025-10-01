import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  // Initialize Supabase client with SERVICE ROLE key to bypass RLS
  final supabase = SupabaseClient(
    'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo',
  );

  final tournamentId = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6';

  print('🔍 SERVICE ROLE - Investigating tournament participants for: $tournamentId');
  print('');

  try {
    // 1. Check tournament_participants for this specific tournament
    print('1️⃣ Tournament participants for $tournamentId:');
    final participantsResponse = await supabase
        .from('tournament_participants')
        .select('*')
        .eq('tournament_id', tournamentId);
    
    print('   Participants count: ${participantsResponse.length}');
    for (var participant in participantsResponse) {
      print('   - User ID: ${participant['user_id']}');
      print('     Status: ${participant['status']}');
      print('     Payment: ${participant['payment_status']}');
      print('     Registered: ${participant['registered_at']}');
      print('');
    }

    // 2. Check ALL tournament_participants
    print('2️⃣ ALL tournament participants across database:');
    final allParticipants = await supabase
        .from('tournament_participants')
        .select('tournament_id, user_id, status, payment_status');
    
    print('   Total participants: ${allParticipants.length}');
    
    Map<String, int> tournamentCounts = {};
    for (var participant in allParticipants) {
      String tId = participant['tournament_id'];
      tournamentCounts[tId] = (tournamentCounts[tId] ?? 0) + 1;
    }
    
    print('   Breakdown by tournament:');
    for (var entry in tournamentCounts.entries) {
      print('   - ${entry.key}: ${entry.value} participants');
    }
    print('');

    // 3. Test the exact query used in the app
    print('3️⃣ App query with JOIN:');
    final appQueryResponse = await supabase
        .from('tournament_participants')
        .select('''
          *,
          users:user_id (
            id,
            email,
            full_name,
            avatar_url,
            elo_rating,
            rank,
            skill_level
          )
        ''')
        .eq('tournament_id', tournamentId);

    print('   App query result count: ${appQueryResponse.length}');
    for (var participant in appQueryResponse) {
      final user = participant['users'];
      print('   - Name: ${user?['full_name'] ?? 'Unknown'}');
      print('     Email: ${user?['email'] ?? 'No email'}');
      print('     Status: ${participant['status']}');
      print('     Payment: ${participant['payment_status']}');
      print('');
    }

  } catch (e) {
    print('❌ Error: $e');
  }

  exit(0);
}
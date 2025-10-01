import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  // Initialize Supabase client
  final supabase = SupabaseClient(
    'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ',
  );

  final tournamentId = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6';

  print('🔍 Investigating tournament participants for tournament: $tournamentId');
  print('');

  try {
    // 1. Check all tournament_participants records
    print('1️⃣ Checking tournament_participants table:');
    final participantsResponse = await supabase
        .from('tournament_participants')
        .select('*')
        .eq('tournament_id', tournamentId);
    
    print('   Raw participants count: ${participantsResponse.length}');
    for (var participant in participantsResponse) {
      print('   - User ID: ${participant['user_id']}, Status: ${participant['status']}, Payment: ${participant['payment_status']}');
    }
    print('');

    // 2. Check all users in the database
    print('2️⃣ Checking all users:');
    final usersResponse = await supabase
        .from('users')
        .select('id, email, full_name');
    
    print('   Total users count: ${usersResponse.length}');
    for (var user in usersResponse) {
      print('   - User: ${user['full_name']} (${user['email']}) - ID: ${user['id']}');
    }
    print('');

    // 3. Check the specific query used in the app
    print('3️⃣ Testing app query (tournament_participants with user join):');
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
      print('   - Participant: ${user?['full_name'] ?? 'Unknown'} (${user?['email'] ?? 'No email'})');
      print('     Status: ${participant['status']}, Payment: ${participant['payment_status']}');
    }
    print('');

    // 4. Check if there are any RLS policy issues
    print('4️⃣ Checking current user authentication context:');
    final authUser = await supabase.auth.getUser();
    if (authUser.user != null) {
      print('   Authenticated as: ${authUser.user!.email}');
      print('   User ID: ${authUser.user!.id}');
    } else {
      print('   ⚠️  No authenticated user - this might cause RLS to block queries');
    }

  } catch (e) {
    print('❌ Error during investigation: $e');
  }

  exit(0);
}
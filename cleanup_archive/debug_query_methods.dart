import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  print('🔍 Testing different query methods...');
  
  final tournamentId = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6';
  
  // Test 1: Anonymous client (what app uses)
  print('\n1️⃣ Testing with ANON key (what app uses):');
  final anonClient = SupabaseClient(
    'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ',
  );
  
  try {
    final anonResult = await anonClient
        .from('tournament_participants')
        .select('*')
        .eq('tournament_id', tournamentId);
    print('   ANON result: ${anonResult.length} participants');
  } catch (e) {
    print('   ANON error: $e');
  }
  
  // Test 2: Service role client
  print('\n2️⃣ Testing with SERVICE ROLE key:');
  final serviceClient = SupabaseClient(
    'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo',
  );
  
  try {
    final serviceResult = await serviceClient
        .from('tournament_participants')
        .select('*')
        .eq('tournament_id', tournamentId);
    print('   SERVICE result: ${serviceResult.length} participants');
  } catch (e) {
    print('   SERVICE error: $e');
  }
  
  // Test 3: Test with JOIN (what app actually uses)
  print('\n3️⃣ Testing ANON with JOIN (exact app query):');
  try {
    final joinResult = await anonClient
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
        .eq('tournament_id', tournamentId);
    print('   ANON JOIN result: ${joinResult.length} participants');
  } catch (e) {
    print('   ANON JOIN error: $e');
  }
  
  exit(0);
}
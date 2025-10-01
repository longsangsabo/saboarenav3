import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final supabase = SupabaseClient(
    'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo',
  );

  print('🔍 Checking auth.uid() function and data types...');
  
  try {
    // Check what auth.uid() returns and what users.id looks like
    final result = await supabase.rpc('check_auth_types');
    print('Auth types check: $result');
  } catch (e) {
    print('Cannot check auth types directly: $e');
  }
  
  // Let's look at actual auth user ID format vs users.id format
  print('\n📋 Checking ID formats in actual data:');
  
  // Sample user IDs from tournament_participants
  final participants = await supabase
      .from('tournament_participants')
      .select('user_id')
      .limit(3);
      
  print('Sample user_id from tournament_participants:');
  for (var p in participants) {
    print('   user_id: "${p['user_id']}" (${p['user_id'].runtimeType})');
  }
  
  // Sample user IDs from users table
  final users = await supabase
      .from('users') 
      .select('id')
      .limit(3);
      
  print('\nSample id from users table:');
  for (var u in users) {
    print('   id: "${u['id']}" (${u['id'].runtimeType})');
  }
  
  // Check if we have any auth users data
  try {
    final authUsers = await supabase
        .from('auth.users')
        .select('id')
        .limit(1);
    print('\nSample id from auth.users:');
    for (var au in authUsers) {
      print('   auth id: "${au['id']}" (${au['id'].runtimeType})');
    }
  } catch (e) {
    print('\nCannot access auth.users: $e');
  }

  exit(0);
}
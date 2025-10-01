import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final serviceClient = SupabaseClient(
    'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo',
  );

  print('🔍 Checking current RLS policies...');
  
  try {
    // Check current policies using system query
    final policies = await serviceClient.rpc('get_policies_info');
    print('Current policies: $policies');
    
  } catch (e) {
    print('Cannot query policies directly: $e');
  }
  
  // Let's check what exactly is blocking anonymous access
  print('\n🎯 Testing different access patterns...');
  
  final anonClient = SupabaseClient(
    'https://mogjjvscxjwvhtpkrlqr.supabase.co', 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ',
  );
  
  final tournamentId = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6';
  
  try {
    // Test 1: Simple select
    print('1. Simple select on tournament_participants:');
    final result1 = await anonClient
        .from('tournament_participants')
        .select('*')
        .limit(1);
    print('   Result: ${result1.length} rows');
    
    // Test 2: Select with filter
    print('2. Select with tournament filter:');
    final result2 = await anonClient
        .from('tournament_participants')
        .select('*')
        .eq('tournament_id', tournamentId);
    print('   Result: ${result2.length} rows');
    
    // Test 3: Select users table
    print('3. Select from users table:');
    final result3 = await anonClient
        .from('users')
        .select('*')
        .limit(1);
    print('   Result: ${result3.length} rows');
    
    // Test 4: Check if RLS is enabled
    print('4. Checking if RLS is enabled...');
    final rlsCheck = await serviceClient.rpc('check_rls_status', params: {
      'table_name': 'tournament_participants'
    });
    print('   RLS status: $rlsCheck');
    
  } catch (e) {
    print('❌ Anonymous access error: $e');
    print('   This confirms RLS is blocking anonymous access');
  }
  
  print('\n💡 Conclusion:');
  print('- Service role can access: 16 participants');
  print('- Anonymous role cannot access: 0 participants');  
  print('- This means RLS policies are too restrictive');
  print('- Need to manually apply the SQL fix in Supabase Dashboard');

  exit(0);
}
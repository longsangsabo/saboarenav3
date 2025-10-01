import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  // Use service role to test SQL policies
  final supabase = SupabaseClient(
    'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo',
  );

  print('🔧 Testing RLS policy application...');
  
  try {
    // Read and execute the SQL file content
    final sqlContent = await File('fix_tournament_rls.sql').readAsString();
    
    // Split into individual statements and execute each
    final statements = sqlContent
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('--'))
        .toList();
    
    print('📋 Found ${statements.length} SQL statements to execute');
    
    for (int i = 0; i < statements.length; i++) {
      final statement = statements[i];
      
      if (statement.toLowerCase().startsWith('select')) {
        // Skip SELECT statements for now
        print('   ${i + 1}. SKIPPING SELECT: ${statement.substring(0, 50)}...');
        continue;
      }
      
      print('   ${i + 1}. Executing: ${statement.substring(0, 50)}...');
      
      try {
        await supabase.rpc('exec_sql', params: {'sql': statement});
        print('      ✅ Success');
      } catch (e) {
        print('      ❌ Error: $e');
        
        // Try alternative execution method
        try {
          final result = await supabase.from('_').select().eq('sql', statement);
          print('      ⚠️ Alternative method result: $result');
        } catch (e2) {
          print('      ❌ Alternative method also failed: $e2');
        }
      }
    }
    
    print('\n🎯 Testing final result with anon client...');
    
    // Test with anonymous client
    final anonClient = SupabaseClient(
      'https://mogjjvscxjwvhtpkrlqr.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ',
    );
    
    final tournamentId = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6';
    final testResult = await anonClient
        .from('tournament_participants')
        .select('*')
        .eq('tournament_id', tournamentId);
    
    print('🚀 Anonymous access test result: ${testResult.length} participants');
    
  } catch (e) {
    print('❌ Main error: $e');
  }

  exit(0);
}
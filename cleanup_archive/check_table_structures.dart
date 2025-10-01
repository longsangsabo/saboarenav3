import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  // Use service role to check table structures
  final supabase = SupabaseClient(
    'https://mogjjvscxjwvhtpkrlqr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo',
  );

  print('🔍 Checking table structures...');
  
  try {
    // 1. Check tournament_participants structure by looking at actual data
    print('\n1️⃣ tournament_participants sample data:');
    final participants = await supabase
        .from('tournament_participants')
        .select('*')
        .limit(1);
    
    if (participants.isNotEmpty) {
      final sample = participants.first;
      print('Sample record structure:');
      for (var key in sample.keys) {
        print('   $key: ${sample[key]} (${sample[key].runtimeType})');
      }
    }

    // 2. Check users structure
    print('\n2️⃣ users sample data:');
    final users = await supabase
        .from('users')  
        .select('*')
        .limit(1);
    
    if (users.isNotEmpty) {
      final sample = users.first;
      print('Sample user record structure:');
      for (var key in sample.keys) {
        print('   $key: ${sample[key]} (${sample[key].runtimeType})');
      }
    }

    // 3. Check tournaments structure
    print('\n3️⃣ tournaments sample data:');
    final tournaments = await supabase
        .from('tournaments')
        .select('*')
        .limit(1);
    
    if (tournaments.isNotEmpty) {
      final sample = tournaments.first;
      print('Sample tournament record structure:');
      for (var key in sample.keys) {
        print('   $key: ${sample[key]} (${sample[key].runtimeType})');
      }
    }

  } catch (e) {
    print('❌ Error: $e');
  }

  exit(0);
}
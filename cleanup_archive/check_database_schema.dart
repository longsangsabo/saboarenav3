import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  // Initialize Supabase with service role key
  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.H8aWcwtoX4ayUubmdGNh2AKUCC_OSPloap3xpjQksfk';
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: serviceRoleKey,
  );
  
  final supabase = Supabase.instance.client;
  
  print('🔍 CHECKING DATABASE SCHEMA...\n');
  
  try {
    // 1. Check tournaments table structure
    print('1. TOURNAMENTS TABLE COLUMNS:');
    final tournamentsColumns = await supabase
        .from('information_schema.columns')
        .select('column_name, data_type, character_maximum_length, column_default, is_nullable')
        .eq('table_name', 'tournaments')
        .eq('table_schema', 'public');
    
    for (var col in tournamentsColumns) {
      print('  - ${col['column_name']}: ${col['data_type']} ${col['character_maximum_length'] != null ? '(${col['character_maximum_length']})' : ''} ${col['is_nullable'] == 'NO' ? 'NOT NULL' : 'NULL'} ${col['column_default'] != null ? 'DEFAULT ${col['column_default']}' : ''}');
    }
    
    print('\n2. USERS TABLE RANK COLUMN:');
    final usersRankColumn = await supabase
        .from('information_schema.columns')
        .select('column_name, data_type, character_maximum_length, column_default')
        .eq('table_name', 'users')
        .eq('table_schema', 'public')
        .eq('column_name', 'rank');
    
    if (usersRankColumn.isNotEmpty) {
      var col = usersRankColumn[0];
      print('  - ${col['column_name']}: ${col['data_type']} ${col['character_maximum_length'] != null ? '(${col['character_maximum_length']})' : ''} DEFAULT ${col['column_default']}');
    }
    
    print('\n3. CHECK CONSTRAINTS:');
    final constraints = await supabase.rpc('get_table_constraints', params: {
      'table_name': 'tournaments'
    });
    
    print('Constraints result: $constraints');
    
    print('\n4. SAMPLE TOURNAMENTS DATA:');
    final sampleTournaments = await supabase
        .from('tournaments')
        .select('id, title, skill_level_required')
        .limit(3);
    
    print('Sample tournaments: $sampleTournaments');
    
  } catch (e) {
    print('❌ Error checking database: $e');
    
    // Try alternative approach
    print('\n🔄 Trying alternative query...');
    try {
      final result = await supabase.rpc('exec_sql', params: {
        'sql': '''
          SELECT column_name, data_type, character_maximum_length, column_default 
          FROM information_schema.columns 
          WHERE table_name = 'tournaments' AND table_schema = 'public'
          ORDER BY ordinal_position;
        '''
      });
      
      print('Tournaments columns: $result');
      
    } catch (e2) {
      print('❌ Alternative query failed: $e2');
      
      // Simple check - try to query tournaments
      print('\n🔄 Simple tournaments query...');
      try {
        final simpleQuery = await supabase
            .from('tournaments')
            .select('*')
            .limit(1);
        
        if (simpleQuery.isNotEmpty) {
          print('✅ Tournaments table exists. Sample data keys:');
          print(simpleQuery[0].keys.toList());
        } else {
          print('⚠️ Tournaments table exists but is empty');
        }
        
      } catch (e3) {
        print('❌ Simple query failed: $e3');
      }
    }
  }
  
  exit(0);
}
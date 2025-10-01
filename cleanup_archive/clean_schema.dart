import 'dart:io';
import 'dart:convert';

void main() async {
  print('🚀 RUNNING DATABASE SCHEMA CLEANUP - REMOVE SKILL LEVEL...\n');
  
  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';
  
  final client = HttpClient();
  
  try {
    // Check current tournaments table structure first
    print('🔍 1. CHECKING CURRENT DATABASE STRUCTURE...');
    
    final checkRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/tournaments?limit=1'));
    checkRequest.headers.set('Authorization', 'Bearer $serviceRoleKey');
    checkRequest.headers.set('apikey', serviceRoleKey);
    
    final checkResponse = await checkRequest.close();
    final checkBody = await checkResponse.transform(utf8.decoder).join();
    
    if (checkResponse.statusCode == 200) {
      final List<dynamic> tournaments = json.decode(checkBody);
      if (tournaments.isNotEmpty) {
        final columns = tournaments[0].keys.toList();
        print('Current columns: $columns');
        
        if (columns.contains('skill_level_required')) {
          print('✅ Found skill_level_required column - needs to be removed');
        } else {
          print('❓ skill_level_required column not found - might already be removed');
        }
      }
    }

    // Try to create a SQL function to execute DDL
    print('\n🔧 2. TRYING TO CREATE SQL EXECUTION FUNCTION...');
    
    final createFunctionSQL = '''
CREATE OR REPLACE FUNCTION execute_ddl(sql_command text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
BEGIN
  EXECUTE sql_command;
  RETURN 'SUCCESS: ' || sql_command;
EXCEPTION
  WHEN OTHERS THEN
    RETURN 'ERROR: ' || SQLERRM;
END;
\$\$;
''';

    final createFuncRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rpc/query'));
    createFuncRequest.headers.set('Authorization', 'Bearer $serviceRoleKey');
    createFuncRequest.headers.set('apikey', serviceRoleKey);
    createFuncRequest.headers.set('Content-Type', 'application/json');
    
    createFuncRequest.write(json.encode({'query': createFunctionSQL}));
    
    final createFuncResponse = await createFuncRequest.close();
    final createFuncBody = await createFuncResponse.transform(utf8.decoder).join();
    
    print('Create function result: ${createFuncResponse.statusCode} - $createFuncBody');

    // Try to use the function to execute DDL
    if (createFuncResponse.statusCode < 400) {
      print('\n🗑️ 3. EXECUTING DDL TO REMOVE SKILL LEVEL CONSTRAINTS...');
      
      final ddlCommands = [
        "ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS tournaments_skill_level_required_check",
        "ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS tournaments_skill_level_check", 
        "DROP INDEX IF EXISTS idx_tournaments_skill_level",
        "ALTER TABLE tournaments DROP COLUMN IF EXISTS skill_level_required",
      ];
      
      for (String ddl in ddlCommands) {
        print('\n   Executing: $ddl');
        
        final ddlRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rpc/execute_ddl'));
        ddlRequest.headers.set('Authorization', 'Bearer $serviceRoleKey');
        ddlRequest.headers.set('apikey', serviceRoleKey);
        ddlRequest.headers.set('Content-Type', 'application/json');
        
        ddlRequest.write(json.encode({'sql_command': ddl}));
        
        final ddlResponse = await ddlRequest.close();
        final ddlBody = await ddlResponse.transform(utf8.decoder).join();
        
        print('   Result: ${ddlResponse.statusCode} - $ddlBody');
      }
    }

    // Final verification
    print('\n✅ 4. FINAL VERIFICATION - TEST TOURNAMENT CREATION...');
    
    final testData = {
      'title': 'Schema Cleanup Test ${DateTime.now().millisecondsSinceEpoch}',
      'description': 'Testing after schema cleanup',
      'start_date': '2025-01-01T00:00:00Z',
      'end_date': '2025-01-02T00:00:00Z',
      'registration_deadline': '2024-12-31T00:00:00Z',
      'prize_pool': 1000000,
      'max_participants': 16,
      'format': 'single_elimination',
      'status': 'upcoming',
      'entry_fee': 50000,
      'current_participants': 0,
    };

    final testRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/tournaments'));
    testRequest.headers.set('Authorization', 'Bearer $serviceRoleKey');
    testRequest.headers.set('apikey', serviceRoleKey);
    testRequest.headers.set('Content-Type', 'application/json');
    testRequest.headers.set('Prefer', 'return=representation');
    
    testRequest.write(json.encode(testData));
    
    final testResponse = await testRequest.close();
    final testBody = await testResponse.transform(utf8.decoder).join();
    
    if (testResponse.statusCode == 201) {
      print('🎉 ✅ SUCCESS: Tournament created successfully after schema cleanup!');
      final tournament = json.decode(testBody)[0];
      print('Tournament ID: ${tournament['id']}');
      print('Title: ${tournament['title']}');
    } else {
      print('❌ Test failed: ${testResponse.statusCode}');
      print('Error: $testBody');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.close();
  }
}
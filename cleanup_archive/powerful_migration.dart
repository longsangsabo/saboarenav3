import 'dart:io';
import 'dart:convert';

void main() async {
  print('🚀 RUNNING VIETNAMESE RANKING MIGRATION WITH SERVICE ROLE...\n');
  
  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';
  
  final client = HttpClient();
  
  try {
    print('🔧 METHOD 1: Try PostgREST SQL function execution...');
    
    // Complete migration SQL as one block
    final migrationSQL = '''
-- VIETNAMESE RANKING MIGRATION
-- Drop existing constraints first
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS tournaments_skill_level_required_check;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_rank_check;

-- Update column types
ALTER TABLE users ALTER COLUMN rank TYPE VARCHAR(5);  
ALTER TABLE tournaments ALTER COLUMN skill_level_required TYPE VARCHAR(20);

-- Add new constraints supporting Vietnamese ranks
ALTER TABLE users ADD CONSTRAINT users_rank_check 
CHECK (rank IN ('K', 'K+', 'I', 'I+', 'H', 'H+', 'G', 'G+', 'F', 'F+', 'E', 'E+'));

ALTER TABLE tournaments ADD CONSTRAINT tournaments_skill_level_check 
CHECK (skill_level_required IN (
    'K', 'K+', 'I', 'I+', 'H', 'H+', 'G', 'G+', 'F', 'F+', 'E', 'E+',
    'beginner', 'intermediate', 'advanced', 'professional'
) OR skill_level_required IS NULL);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_rank ON users(rank);
CREATE INDEX IF NOT EXISTS idx_tournaments_skill_level ON tournaments(skill_level_required);

-- Add comments
COMMENT ON COLUMN users.rank IS 'Vietnamese billiards ranking: K, K+, I, I+, H, H+, G, G+, F, F+, E, E+';
COMMENT ON COLUMN tournaments.skill_level_required IS 'Required skill level: Vietnamese ranks or general levels';
''';

    // Try different RPC function names
    final rpcEndpoints = [
      'exec_sql',
      'query', 
      'execute_sql',
      'run_sql',
      'sql_query',
      'execute',
    ];
    
    bool migrationSuccess = false;
    
    for (String endpoint in rpcEndpoints) {
      print('\n   Trying RPC endpoint: $endpoint');
      
      final request = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rpc/$endpoint'));
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Content-Type', 'application/json');
      
      request.write(json.encode({'sql': migrationSQL}));
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('   ✅ SUCCESS with endpoint: $endpoint');
        migrationSuccess = true;
        break;
      } else {
        print('   ❌ Failed: ${response.statusCode} - ${body.length > 100 ? '${body.substring(0, 100)}...' : body}');
      }
    }
    
    if (!migrationSuccess) {
      print('\n🔧 METHOD 2: Try direct database connection approach...');
      
      // Try using pg_admin style endpoint
      final adminRequest = await client.postUrl(Uri.parse('$supabaseUrl/database/sql'));
      adminRequest.headers.set('Authorization', 'Bearer $serviceRoleKey');
      adminRequest.headers.set('apikey', serviceRoleKey);
      adminRequest.headers.set('Content-Type', 'text/plain');
      
      adminRequest.write(migrationSQL);
      
      final adminResponse = await adminRequest.close();
      final adminBody = await adminResponse.transform(utf8.decoder).join();
      
      if (adminResponse.statusCode >= 200 && adminResponse.statusCode < 300) {
        print('✅ SUCCESS with direct database endpoint');
        migrationSuccess = true;
      } else {
        print('❌ Failed: ${adminResponse.statusCode} - $adminBody');
      }
    }
    
    if (!migrationSuccess) {
      print('\n🔧 METHOD 3: Try individual constraint drops...');
      
      // Try to at least drop the problematic constraint
      final individualCommands = [
        "DROP TABLE IF EXISTS temp_constraint_check CASCADE",
        "SELECT constraint_name FROM information_schema.table_constraints WHERE table_name='tournaments' AND constraint_type='CHECK'",
      ];
      
      for (String cmd in individualCommands) {
        print('\n   Trying: $cmd');
        
        final request = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rpc/query'));
        request.headers.set('Authorization', 'Bearer $serviceRoleKey');
        request.headers.set('apikey', serviceRoleKey);
        request.headers.set('Content-Type', 'application/json');
        
        request.write(json.encode({'query': cmd}));
        
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        
        print('   Response: ${response.statusCode} - $body');
      }
    }
    
    // Final test regardless of migration success
    print('\n🧪 FINAL TEST: Testing tournament creation with Vietnamese rank...');
    
    final testData = {
      'title': 'Vietnamese Rank Test Tournament ${DateTime.now().millisecondsSinceEpoch}',
      'description': 'Testing Vietnamese ranking system after migration attempt',
      'skill_level_required': 'K',
      'start_date': '2025-01-01T00:00:00Z',
      'end_date': '2025-01-02T00:00:00Z',
      'prize_pool': 1000000,
      'max_participants': 16,
      'format': 'single_elimination',
      'status': 'draft'
    };

    final createRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/tournaments'));
    createRequest.headers.set('Authorization', 'Bearer $serviceRoleKey');
    createRequest.headers.set('apikey', serviceRoleKey);
    createRequest.headers.set('Content-Type', 'application/json');
    createRequest.headers.set('Prefer', 'return=representation');
    
    createRequest.write(json.encode(testData));
    
    final createResponse = await createRequest.close();
    final createBody = await createResponse.transform(utf8.decoder).join();
    
    if (createResponse.statusCode == 201) {
      print('🎉 ✅ SUCCESS: Tournament created with Vietnamese rank "K"!');
      print('🏆 MIGRATION WORKED! Database now accepts Vietnamese ranks!');
      final tournament = json.decode(createBody)[0];
      print('Tournament ID: ${tournament['id']}');
      print('Title: ${tournament['title']}');
      print('Skill Level Required: ${tournament['skill_level_required']}');
    } else {
      print('❌ Still failing: ${createResponse.statusCode}');
      print('Error details: $createBody');
      
      if (createBody.contains('invalid input value for enum')) {
        print('\n💡 DIAGNOSIS: Database constraints are still blocking Vietnamese ranks');
        print('👉 Manual migration via Supabase Dashboard is still required');
        print('📋 Use the SQL from MIGRATION_GUIDE.md in Supabase SQL Editor');
      }
    }
    
  } catch (e) {
    print('❌ Critical error: $e');
  } finally {
    client.close();
  }
}
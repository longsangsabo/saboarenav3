import 'dart:io';
import 'dart:convert';

void main() async {
  print('🚀 RUNNING VIETNAMESE RANKING MIGRATION...\n');
  
  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  const serviceRoleKey = 'sb_secret_07Grp_TTwr21BjtBKc_gtw_5qx7UPFE';
  
  final client = HttpClient();
  
  final migrations = [
    // 1. Update users table rank column
    "ALTER TABLE users ALTER COLUMN rank TYPE VARCHAR(5)",
    
    // 2. Add constraint for Vietnamese ranks  
    "ALTER TABLE users DROP CONSTRAINT IF EXISTS users_rank_check",
    "ALTER TABLE users ADD CONSTRAINT users_rank_check CHECK (rank IN ('K', 'K+', 'I', 'I+', 'H', 'H+', 'G', 'G+', 'F', 'F+', 'E', 'E+'))",
    
    // 3. Update tournaments skill_level_required
    "ALTER TABLE tournaments ALTER COLUMN skill_level_required TYPE VARCHAR(20)",
    
    // 4. Add constraint for skill levels
    "ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS tournaments_skill_level_check",
    "ALTER TABLE tournaments ADD CONSTRAINT tournaments_skill_level_check CHECK (skill_level_required IN ('K', 'K+', 'I', 'I+', 'H', 'H+', 'G', 'G+', 'F', 'F+', 'E', 'E+', 'beginner', 'intermediate', 'advanced', 'professional') OR skill_level_required IS NULL)",
  ];
  
  try {
    for (int i = 0; i < migrations.length; i++) {
      print('Running migration ${i + 1}/${migrations.length}: ${migrations[i]}');
      
      final request = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rpc/exec_sql'));
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Content-Type', 'application/json');
      
      request.write(json.encode({'sql': migrations[i]}));
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Success');
      } else {
        print('❌ Failed: ${response.statusCode} - $body');
      }
    }
    
    print('\n🧪 TESTING VIETNAMESE RANK TOURNAMENT CREATION...');
    
    // Test creating tournament with Vietnamese rank
    final testData = {
      'title': 'Test Vietnamese Rank Tournament',
      'description': 'Testing Vietnamese ranking system',
      'skill_level_required': 'K',
      'start_date': '2025-01-01T00:00:00Z',
      'end_date': '2025-01-02T00:00:00Z',
      'prize_pool': 1000000,
      'max_participants': 16,
      'format': 'single_elimination',  // Use 'format' not 'tournament_format'
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
      print('✅ SUCCESS: Tournament created with Vietnamese rank "K"!');
      final tournament = json.decode(createBody)[0];
      print('Tournament ID: ${tournament['id']}');
      print('Skill Level Required: ${tournament['skill_level_required']}');
    } else {
      print('❌ FAILED: ${createResponse.statusCode} - $createBody');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.close();
  }
}
import 'dart:io';
import 'dart:convert';

void main() async {
  print('🚀 RUNNING VIETNAMESE RANKING MIGRATION VIA SUPABASE API...\n');
  
  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';
  
  final client = HttpClient();
  
  // Try different SQL execution approaches
  final sqlCommands = [
    // First, try to drop existing constraints
    "ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS tournaments_skill_level_required_check",
    "ALTER TABLE users DROP CONSTRAINT IF EXISTS users_rank_check",
    
    // Update column types
    "ALTER TABLE users ALTER COLUMN rank TYPE VARCHAR(5)",
    "ALTER TABLE tournaments ALTER COLUMN skill_level_required TYPE VARCHAR(20)",
    
    // Add new constraints
    "ALTER TABLE users ADD CONSTRAINT users_rank_check CHECK (rank IN ('K', 'K+', 'I', 'I+', 'H', 'H+', 'G', 'G+', 'F', 'F+', 'E', 'E+'))",
    "ALTER TABLE tournaments ADD CONSTRAINT tournaments_skill_level_check CHECK (skill_level_required IN ('K', 'K+', 'I', 'I+', 'H', 'H+', 'G', 'G+', 'F', 'F+', 'E', 'E+', 'beginner', 'intermediate', 'advanced', 'professional') OR skill_level_required IS NULL)",
  ];
  
  try {
    // Method 1: Try using SQL query via API
    print('📡 METHOD 1: Direct SQL execution via API...');
    
    for (int i = 0; i < sqlCommands.length; i++) {
      final sql = sqlCommands[i];
      print('\n${i + 1}. Executing: ${sql.substring(0, 50)}...');
      
      // Try direct SQL execution
      final request = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rpc/query'));
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Content-Type', 'application/json');
      
      request.write(json.encode({'query': sql}));
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('   ✅ Success');
      } else {
        print('   ❌ Failed: ${response.statusCode} - ${body.length > 100 ? '${body.substring(0, 100)}...' : body}');
        
        // If this method fails, try method 2
        if (i == 0) {
          print('\n📡 METHOD 2: Try alternative API endpoint...');
          break;
        }
      }
    }
    
    // Method 2: Try using GraphQL or alternative endpoint
    print('\n📡 METHOD 2: GraphQL mutation...');
    
    final graphqlQuery = '''
    mutation {
      __type(name: "tournaments") {
        name
      }
    }
    ''';
    
    final graphqlRequest = await client.postUrl(Uri.parse('$supabaseUrl/graphql/v1'));
    graphqlRequest.headers.set('Authorization', 'Bearer $serviceRoleKey');
    graphqlRequest.headers.set('apikey', serviceRoleKey);
    graphqlRequest.headers.set('Content-Type', 'application/json');
    
    graphqlRequest.write(json.encode({'query': graphqlQuery}));
    
    final graphqlResponse = await graphqlRequest.close();
    final graphqlBody = await graphqlResponse.transform(utf8.decoder).join();
    
    print('GraphQL response: ${graphqlResponse.statusCode} - $graphqlBody');
    
  } catch (e) {
    print('❌ Error: $e');
  }
  
  // Method 3: Try to test current state by creating a tournament
  print('\n🧪 METHOD 3: Test current database state...');
  
  try {
    final testData = {
      'title': 'Migration Test Tournament',
      'description': 'Testing if Vietnamese ranks work',
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
      print('✅ SUCCESS: Tournament created with Vietnamese rank "K"!');
      print('🎉 MIGRATION MIGHT ALREADY BE COMPLETE!');
    } else {
      print('❌ Still failing: ${createResponse.statusCode}');
      print('Error: $createBody');
      
      if (createBody.contains('invalid input value for enum')) {
        print('\n💡 DIAGNOSIS: Database constraints still blocking Vietnamese ranks');
        print('👉 MANUAL MIGRATION REQUIRED via Supabase Dashboard');
      }
    }
    
  } catch (e) {
    print('❌ Test failed: $e');
  } finally {
    client.close();
  }
}
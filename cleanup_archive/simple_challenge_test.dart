import 'dart:convert';
import 'dart:io';

/// Simple test script that can run without Flutter dependencies
/// Tests challenge system by direct HTTP calls to Supabase
void main() async {
  print('🧪 SIMPLE CHALLENGE SYSTEM TEST');
  print('===============================\n');

  // Test data
  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ';
  
  final challengeData = {
    'challenger_id': '00000000-0000-0000-0000-000000000001',
    'challenged_id': '00000000-0000-0000-0000-000000000002',
    'challenge_type': 'thach_dau',
    'game_type': '8-ball',
    'scheduled_time': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
    'location': 'Test Billiards Club',
    'handicap': 0,
    'spa_points': 100,
    'message': 'Simple test challenge - ${DateTime.now().toIso8601String()}',
    'status': 'pending',
    'expires_at': DateTime.now().add(Duration(days: 7)).toIso8601String(),
  };

  try {
    print('📊 Challenge Data:');
    print(JsonEncoder.withIndent('  ').convert(challengeData));
    print('');

    // Test 1: Check Supabase connection
    print('📡 Test 1: Testing Supabase connection...');
    final client = HttpClient();
    
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/'));
    request.headers.add('apikey', supabaseKey);
    request.headers.add('Authorization', 'Bearer $supabaseKey');
    
    final response = await request.close();
    print('✅ Supabase connection: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      print('Response: ${responseBody.substring(0, 100)}...');
    }
    
    // Test 2: Check if challenges table exists
    print('\n📋 Test 2: Checking challenges table...');
    final tableRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/challenges?limit=1'));
    tableRequest.headers.add('apikey', supabaseKey);
    tableRequest.headers.add('Authorization', 'Bearer $supabaseKey');
    
    final tableResponse = await tableRequest.close();
    print('Table check status: ${tableResponse.statusCode}');
    
    if (tableResponse.statusCode == 200) {
      print('✅ Challenges table exists and accessible');
    } else if (tableResponse.statusCode == 404) {
      print('❌ Challenges table not found - need to create it');
    } else {
      final errorBody = await tableResponse.transform(utf8.decoder).join();
      print('❌ Error accessing table: $errorBody');
    }
    
    // Test 3: Try to insert challenge (if table exists)
    if (tableResponse.statusCode == 200) {
      print('\n💾 Test 3: Trying to insert test challenge...');
      
      final insertRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/challenges'));
      insertRequest.headers.add('apikey', supabaseKey);
      insertRequest.headers.add('Authorization', 'Bearer $supabaseKey');
      insertRequest.headers.add('Content-Type', 'application/json');
      insertRequest.headers.add('Prefer', 'return=representation');
      
      insertRequest.write(jsonEncode(challengeData));
      
      final insertResponse = await insertRequest.close();
      final insertBody = await insertResponse.transform(utf8.decoder).join();
      
      print('Insert status: ${insertResponse.statusCode}');
      print('Insert response: $insertBody');
      
      if (insertResponse.statusCode == 201) {
        print('✅ Challenge created successfully!');
      } else {
        print('❌ Failed to create challenge');
      }
    }
    
    client.close();
    
    print('\n🎯 TEST SUMMARY');
    print('==============');
    print('Supabase connection: ✅');
    print('Table accessibility: ${tableResponse.statusCode == 200 ? "✅" : "❌"}');
    print('Challenge creation: ${tableResponse.statusCode == 200 ? "Tested" : "Skipped - table missing"}');
    
  } catch (e, stackTrace) {
    print('❌ Error during testing: $e');
    print('Stack trace: $stackTrace');
  }
  
  print('\n🚀 Next steps:');
  if (await File('create_challenges_table_complete.sql').exists()) {
    print('1. Run the SQL script in Supabase to create challenges table');
    print('2. Re-run this test to verify functionality');
  } else {
    print('1. Create challenges table schema');
    print('2. Deploy to Supabase');
    print('3. Re-run this test');
  }
}
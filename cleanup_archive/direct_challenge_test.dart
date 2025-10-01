import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

// Simple direct test của challenge system qua Supabase client
void main() async {
  print('🚀 DIRECT CHALLENGE SYSTEM TEST');
  print('===============================\n');
  
  try {
    // Initialize Supabase (sử dụng same config như app)
    await Supabase.initialize(
      url: 'https://mogjjvscxjwvhtpkrlqr.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ',
    );
    
    final supabase = Supabase.instance.client;
    print('✅ Supabase initialized successfully');
    
    // Test 1: Check if challenges table exists
    print('\n📊 Test 1: Check challenges table...');
    try {
      final existingChallenges = await supabase
          .from('challenges')
          .select('id, challenger_id, challenged_id, challenge_type, created_at')
          .limit(5);
      
      print('✅ Challenges table exists!');
      print('📈 Current challenges count: ${existingChallenges.length}');
      if (existingChallenges.isNotEmpty) {
        print('📋 Sample data: ${jsonEncode(existingChallenges.first)}');
      }
    } catch (e) {
      print('❌ Challenges table not found or error: $e');
      print('🔧 Need to create challenges table first');
    }
    
    // Test 2: Try to create a test challenge
    print('\n🎯 Test 2: Create test challenge...');
    try {
      final challengeData = {
        'challenger_id': '00000000-0000-0000-0000-000000000001', // TEST_USER_ID
        'challenged_id': '00000000-0000-0000-0000-000000000002',
        'challenge_type': 'thach_dau',
        'game_type': '8-ball',
        'scheduled_time': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
        'location': 'Test Billiards Club',
        'handicap': 0,
        'spa_points': 100,
        'message': 'Direct test challenge - ${DateTime.now().toIso8601String()}',
        'status': 'pending',
      };
      
      print('📝 Attempting to insert: ${jsonEncode(challengeData)}');
      
      final result = await supabase
          .from('challenges')
          .insert(challengeData)
          .select()
          .single();
      
      print('✅ Challenge created successfully!');
      print('🆔 Challenge ID: ${result['id']}');
      print('📅 Created at: ${result['created_at']}');
      print('🎯 Full result: ${jsonEncode(result)}');
      
    } catch (e) {
      print('❌ Error creating challenge: $e');
      print('🔍 This might be due to:');
      print('   - Missing challenges table');
      print('   - RLS policy restrictions');
      print('   - Invalid user IDs');
      print('   - Missing auth.users records');
    }
    
    // Test 3: Check auth.users table
    print('\n👥 Test 3: Check users table...');
    try {
      final users = await supabase
          .from('profiles')  // Assuming user profiles table
          .select('id, full_name, username')
          .limit(5);
      
      print('✅ Found ${users.length} user profiles');
      if (users.isNotEmpty) {
        print('👤 Sample user: ${jsonEncode(users.first)}');
      }
    } catch (e) {
      print('❌ Error checking users: $e');
    }
    
    print('\n🏁 TEST SUMMARY');
    print('==============');
    print('✅ Supabase connection: Working');
    print('⚠️  Challenges table: Need to verify/create');
    print('⚠️  Challenge creation: Need proper setup');
    
  } catch (e, stackTrace) {
    print('❌ FATAL ERROR: $e');
    print('Stack trace: $stackTrace');
  }
}
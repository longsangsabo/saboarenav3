import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Test RPC functions
  try {
    print('🔍 Testing RPC Functions...');
    
    // Test get_pending_rank_change_requests
    final response = await Supabase.instance.client
        .rpc('get_pending_rank_change_requests');
    
    print('✅ get_pending_rank_change_requests result:');
    print(response);
    
    if (response is List && response.isNotEmpty) {
      print('\n📋 Found ${response.length} pending requests');
      for (var request in response) {
        print('- Request ID: ${request['id']}');
        print('- User: ${request['user_name']} (${request['user_email']})');
        print('- Current Rank: ${request['current_rank']}');
        print('- Notes: ${request['notes']}');
        print('- Evidence URLs: ${request['evidence_urls']}');
        print('- Club: ${request['club_name']}');
        print('---');
      }
    } else {
      print('❌ No pending requests found or response is empty');
    }
    
  } catch (e) {
    print('❌ Error testing RPC: $e');
  }
}
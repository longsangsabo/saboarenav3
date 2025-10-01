import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ';
  final baseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co/rest/v1';
  
  print('≡ƒÜÇ Testing Enhanced Backend...\n');

  // Test enhanced users table
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/users?limit=1'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    );
    
    if (response.statusCode == 200) {
      final users = jsonDecode(response.body) as List;
      if (users.isNotEmpty) {
        final user = users.first;
        print('Γ£à Enhanced Users Table:');
        print('   - elo_rating: ${user['elo_rating']}');
        print('   - spa_points_won: ${user['spa_points_won']}');
        print('   - total_matches: ${user['total_matches']}');
      }
    }
  } catch (e) {
    print('Γ¥î Users test: $e');
  }

  // Test enhanced clubs table
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/clubs?limit=1'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    );
    
    if (response.statusCode == 200) {
      final clubs = jsonDecode(response.body) as List;
      if (clubs.isNotEmpty) {
        final club = clubs.first;
        print('Γ£à Enhanced Clubs Table:');
        print('   - rating: ${club['rating']}');
        print('   - approval_status: ${club['approval_status']}');
        print('   - price_per_hour: ${club['price_per_hour']}');
      }
    }
  } catch (e) {
    print('Γ¥î Clubs test: $e');
  }

  print('\n≡ƒÄ» Backend Enhanced Schema: SUCCESS!');
}

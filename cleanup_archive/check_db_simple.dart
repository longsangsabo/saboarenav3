import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 CHECKING SUPABASE DATABASE SCHEMA...\n');
  
  const supabaseUrl = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  const serviceRoleKey = 'sb_secret_07Grp_TTwr21BjtBKc_gtw_5qx7UPFE';
  
  final client = HttpClient();
  
  try {
    // 1. Check tournaments table columns
    print('1. CHECKING TOURNAMENTS TABLE COLUMNS:');
    final tournamentsRequest = await client.getUrl(Uri.parse(
        '$supabaseUrl/rest/v1/information_schema.columns?table_name=eq.tournaments&table_schema=eq.public&select=column_name,data_type,character_maximum_length,column_default,is_nullable'));
    tournamentsRequest.headers.set('Authorization', 'Bearer $serviceRoleKey');
    tournamentsRequest.headers.set('apikey', serviceRoleKey);
    
    final tournamentsResponse = await tournamentsRequest.close();
    final tournamentsBody = await tournamentsResponse.transform(utf8.decoder).join();
    
    if (tournamentsResponse.statusCode == 200) {
      final List<dynamic> columns = json.decode(tournamentsBody);
      for (var col in columns) {
        print('  - ${col['column_name']}: ${col['data_type']} ${col['character_maximum_length'] != null ? '(${col['character_maximum_length']})' : ''} ${col['is_nullable'] == 'NO' ? 'NOT NULL' : 'NULL'} ${col['column_default'] != null ? 'DEFAULT ${col['column_default']}' : ''}');
      }
    } else {
      print('❌ Error: ${tournamentsResponse.statusCode} - $tournamentsBody');
    }
    
    print('\n2. CHECKING USERS TABLE RANK COLUMN:');
    final usersRequest = await client.getUrl(Uri.parse(
        '$supabaseUrl/rest/v1/information_schema.columns?table_name=eq.users&table_schema=eq.public&column_name=eq.rank&select=column_name,data_type,character_maximum_length,column_default'));
    usersRequest.headers.set('Authorization', 'Bearer $serviceRoleKey');
    usersRequest.headers.set('apikey', serviceRoleKey);
    
    final usersResponse = await usersRequest.close();
    final usersBody = await usersResponse.transform(utf8.decoder).join();
    
    if (usersResponse.statusCode == 200) {
      final List<dynamic> columns = json.decode(usersBody);
      if (columns.isNotEmpty) {
        var col = columns[0];
        print('  - ${col['column_name']}: ${col['data_type']} ${col['character_maximum_length'] != null ? '(${col['character_maximum_length']})' : ''} DEFAULT ${col['column_default']}');
      } else {
        print('  - No rank column found in users table');
      }
    } else {
      print('❌ Error: ${usersResponse.statusCode} - $usersBody');
    }
    
    print('\n3. SAMPLE TOURNAMENTS DATA:');
    final sampleRequest = await client.getUrl(Uri.parse(
        '$supabaseUrl/rest/v1/tournaments?limit=3&select=id,title,skill_level_required'));
    sampleRequest.headers.set('Authorization', 'Bearer $serviceRoleKey');
    sampleRequest.headers.set('apikey', serviceRoleKey);
    
    final sampleResponse = await sampleRequest.close();
    final sampleBody = await sampleResponse.transform(utf8.decoder).join();
    
    if (sampleResponse.statusCode == 200) {
      final List<dynamic> tournaments = json.decode(sampleBody);
      if (tournaments.isNotEmpty) {
        print('Sample tournaments found:');
        for (var tournament in tournaments) {
          print('  - ${tournament['title']}: skill_level_required = ${tournament['skill_level_required']}');
        }
      } else {
        print('No tournaments found in database');
      }
    } else {
      print('❌ Error: ${sampleResponse.statusCode} - $sampleBody');
    }
    
  } catch (e) {
    print('❌ Error checking database: $e');
  } finally {
    client.close();
  }
}
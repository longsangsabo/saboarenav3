import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('🔧 Fixing challenges table schema...');
  
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://mogjjvscxjwvhtpkrlqr.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ',
    );

    final supabase = Supabase.instance.client;
    
    print('📋 Running challenges table migration...');
    
    // First, create the table if it doesn't exist
    await supabase.rpc('sql', params: {
      'query': '''
        CREATE TABLE IF NOT EXISTS challenges (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          challenger_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
          challenged_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
          challenge_type VARCHAR(50) DEFAULT 'giao_luu',
          game_type VARCHAR(20) DEFAULT '8-ball',
          scheduled_time TIMESTAMP WITH TIME ZONE,
          time_slot VARCHAR(50),
          location VARCHAR(255),
          handicap INTEGER DEFAULT 0,
          spa_points INTEGER DEFAULT 0,
          message TEXT,
          status VARCHAR(20) DEFAULT 'pending',
          expires_at TIMESTAMP WITH TIME ZONE,
          accepted_at TIMESTAMP WITH TIME ZONE,
          declined_at TIMESTAMP WITH TIME ZONE,
          decline_reason TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
      '''
    });
    
    print('✅ Table created/verified');
    
    // Add missing columns if they don't exist
    final columns = [
      'game_type VARCHAR(20) DEFAULT \'8-ball\'',
      'scheduled_time TIMESTAMP WITH TIME ZONE',
      'time_slot VARCHAR(50)',
      'location VARCHAR(255)',
      'handicap INTEGER DEFAULT 0',
      'spa_points INTEGER DEFAULT 0',
      'accepted_at TIMESTAMP WITH TIME ZONE',
      'declined_at TIMESTAMP WITH TIME ZONE',
      'decline_reason TEXT',
      'expires_at TIMESTAMP WITH TIME ZONE'
    ];
    
    for (final column in columns) {
      try {
        await supabase.rpc('sql', params: {
          'query': 'ALTER TABLE challenges ADD COLUMN IF NOT EXISTS $column;'
        });
        print('✅ Added column: ${column.split(' ')[0]}');
      } catch (e) {
        print('⚠️ Column already exists or error: ${column.split(' ')[0]} - $e');
      }
    }
    
    // Verify the table structure
    print('🔍 Verifying table structure...');
    await supabase
        .from('challenges')
        .select('*')
        .limit(1);
    
    print('✅ Challenges table is ready!');
    print('📊 Sample query successful');
    
  } catch (error) {
    print('❌ Error: $error');
  }
}
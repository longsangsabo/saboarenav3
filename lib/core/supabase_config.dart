// Supabase Configuration
// Using real Supabase credentials from env.json

class SupabaseConfig() {
  // Real Supabase instance
  static const String url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ';
  
  // Storage bucket names
  static const String avatarsBucket = 'avatars';
  static const String tournamentImagesBucket = 'tournament-images';
  static const String postImagesBucket = 'post-images';
  
  // Database table names
  static const String usersTable = 'users';
  static const String clubsTable = 'clubs';
  static const String tournamentsTable = 'tournaments';
  static const String matchesTable = 'matches';
  static const String postsTable = 'posts';
  static const String commentsTable = 'comments';
  
  // Real-time channels
  static const String matchesChannel = 'matches-updates';
  static const String tournamentsChannel = 'tournaments-updates';
  static const String postsChannel = 'posts-updates';
}
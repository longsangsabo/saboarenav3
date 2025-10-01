// Environment Configuration
// Handles different environments (dev, staging, prod)

class EnvironmentConfig() {
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  // Supabase Configuration per environment
  static String get supabaseUrl() {
    switch (environment) {
      case 'production':
        return const String.fromEnvironment('SUPABASE_URL', 
               defaultValue: 'https://mogjjvscxjwvhtpkrlqr.supabase.co');
      case 'staging':
        return const String.fromEnvironment('SUPABASE_URL_STAGING', 
               defaultValue: 'https://mogjjvscxjwvhtpkrlqr.supabase.co');
      default:
        return const String.fromEnvironment('SUPABASE_URL_DEV', 
               defaultValue: 'https://mogjjvscxjwvhtpkrlqr.supabase.co');
    }
  }
  
  static String get supabaseAnonKey() {
    switch (environment) {
      case 'production':
        return const String.fromEnvironment('SUPABASE_ANON_KEY', 
               defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ');
      case 'staging':
        return const String.fromEnvironment('SUPABASE_ANON_KEY_STAGING', 
               defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ');
      default:
        return const String.fromEnvironment('SUPABASE_ANON_KEY_DEV', 
               defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ');
    }
  }
  
  // Service Role Key for development (NEVER use in production)
  static String get supabaseServiceKey() {
    if (environment == 'development') {
      return const String.fromEnvironment('SUPABASE_SERVICE_KEY', 
             defaultValue: 'demo-service-key-for-dev-only');
    }
    throw Exception('Service key should never be used in production!');
  }
  
  // Feature flags per environment
  static bool get enableAnalytics => environment == 'production';
  static bool get enableDebugLogs => environment == 'development';
  static bool get enableMockData => environment == 'development';
  static bool get enableHotReload => environment == 'development';
  
  // API Configuration
  static String get apiBaseUrl() {
    switch (environment) {
      case 'production':
        return 'https://api.sabo-arena.com';
      case 'staging':
        return 'https://api-staging.sabo-arena.com';
      default:
        return 'https://api-dev.sabo-arena.com';
    }
  }
  
  // App Configuration
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
}
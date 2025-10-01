#!/usr/bin/env python3
"""
🎯 SABO ARENA - Add round_name column to matches table
Support SABO specialized tournament formats with proper round naming
"""

from supabase import create_client

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def main():
    print("🔧 ADDING round_name COLUMN TO MATCHES TABLE")
    print("=" * 60)
    
    supabase = create_client(SUPABASE_URL, ANON_KEY)
    
    # SQL to add round_name column
    add_column_sql = """
    ALTER TABLE matches 
    ADD COLUMN IF NOT EXISTS round_name TEXT;
    """
    
    # Add comment for documentation
    comment_sql = """
    COMMENT ON COLUMN matches.round_name IS 
    'Display name for tournament rounds (VÒNG 1/16, TỨ KẾT, BÁN KẾT, CHUNG KẾT, etc.)';
    """
    
    try:
        print("📝 Adding round_name column...")
        result = supabase.rpc('execute_sql', {'sql': add_column_sql}).execute()
        print("✅ Column added successfully")
        
        print("📝 Adding column comment...")
        result = supabase.rpc('execute_sql', {'sql': comment_sql}).execute()
        print("✅ Comment added successfully")
        
        # Test column exists
        print("🧪 Testing column exists...")
        test_result = supabase.table('matches').select('round_name').limit(1).execute()
        print("✅ Column is accessible")
        
        print("\n🎉 MIGRATION COMPLETED SUCCESSFULLY!")
        print("📊 The matches table now supports:")
        print("   - round_name: Display names for tournament rounds")
        print("   - SABO DE16/DE32 format support")
        print("   - Dynamic round naming system")
        
    except Exception as e:
        print(f"❌ Error during migration: {e}")
        print("⚠️ You may need to run this SQL manually in Supabase dashboard:")
        print(f"   {add_column_sql}")
        print(f"   {comment_sql}")

if __name__ == "__main__":
    main()
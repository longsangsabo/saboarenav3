#!/usr/bin/env python3
"""
Fix challenges table schema by adding missing columns
Since Supabase REST API doesn't allow direct DDL, we'll create a function to do it
"""
import psycopg2
import json

def main():
    print("🔧 Fixing challenges table schema...")
    
    # Connection string - we need to use the database URL directly
    # This requires admin access to the database
    
    # For now, let's try to see if we can identify the missing columns by checking
    # what exists vs what should exist
    
    from supabase import create_client, Client
    
    url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"
    
    supabase = create_client(url, key)
    
    # Let's check what tables exist
    print("📋 Checking available tables...")
    
    try:
        # Try to get table metadata using PostgREST introspection
        # Check if we can access information_schema
        
        # First, let's see the current state by trying different approaches
        print("🔍 Checking challenges table structure...")
        
        # Try to select with minimal data to see column structure
        try:
            result = supabase.table('challenges').select('*').limit(0).execute()
            print("✅ Table exists but has no data")
        except Exception as e:
            print(f"❌ Table check failed: {e}")
            
        # Now try to insert minimal required data to see what columns are missing
        minimal_data = {
            "challenger_id": "ca23e628-d2bb-4174-b4b8-d1cc2ff8335f",
            "challenged_id": "8dc68b2e-8c94-47d7-a2d7-a70b218c32a8",
            "challenge_type": "giao_luu",
            "status": "pending"
        }
        
        print("🧪 Testing minimal insert...")
        try:
            result = supabase.table('challenges').insert(minimal_data).execute()
            if result.data:
                print("✅ Minimal insert successful - basic table structure exists")
                challenge_id = result.data[0]['id']
                # Check what columns we got back
                print("📋 Returned columns:", list(result.data[0].keys()))
                
                # Clean up
                supabase.table('challenges').delete().eq('id', challenge_id).execute()
                print("🧹 Cleaned up test data")
            else:
                print("⚠️ Minimal insert returned no data")
        except Exception as e:
            print(f"❌ Minimal insert failed: {e}")
            
        # Now try with game_type to confirm it's missing
        full_data = {
            "challenger_id": "ca23e628-d2bb-4174-b4b8-d1cc2ff8335f",
            "challenged_id": "8dc68b2e-8c94-47d7-a2d7-a70b218c32a8",
            "challenge_type": "giao_luu",
            "game_type": "8-ball",  # This should fail
            "status": "pending"
        }
        
        print("🧪 Testing full insert with game_type...")
        try:
            result = supabase.table('challenges').insert(full_data).execute()
            if result.data:
                print("🎉 Full insert successful - game_type column exists!")
                challenge_id = result.data[0]['id']
                supabase.table('challenges').delete().eq('id', challenge_id).execute()
            else:
                print("⚠️ Full insert returned no data")
        except Exception as e:
            print(f"❌ Full insert failed (expected): {e}")
            if "game_type" in str(e):
                print("🔧 Confirmed: game_type column is missing")
                
                # Since we can't add it via REST API, let's suggest manual approach
                print("\n📝 SOLUTION NEEDED:")
                print("1. Go to Supabase Dashboard > SQL Editor")
                print("2. Run this SQL:")
                print("""
ALTER TABLE public.challenges 
ADD COLUMN IF NOT EXISTS game_type VARCHAR(20) DEFAULT '8-ball',
ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS location VARCHAR(255),
ADD COLUMN IF NOT EXISTS handicap INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS spa_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;
""")
                print("\n3. Or run the complete table creation script:")
                print("   - Open create_challenges_table_complete.sql in Supabase SQL Editor")
                
        print("\n🏁 Schema check complete!")
        
    except Exception as error:
        print(f"❌ Error: {error}")

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
from supabase import create_client, Client

def main():
    print("🔧 Adding game_type column to challenges table...")
    
    # Supabase config
    url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"
    
    try:
        # Create client
        supabase: Client = create_client(url, key)
        print("✅ Supabase client created")
        
        # Check current schema
        print("🔍 Checking current challenges table...")
        try:
            result = supabase.table('challenges').select('*').limit(1).execute()
            print(f"📊 Query successful, found {len(result.data)} records")
            if result.data:
                print("📋 Current columns:", list(result.data[0].keys()))
        except Exception as e:
            print(f"⚠️ Table query error: {e}")
        
        # Try to add missing columns via RPC
        print("🔧 Adding missing columns via SQL...")
        
        sql_commands = [
            "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS game_type VARCHAR(20) DEFAULT '8-ball';",
            "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMP WITH TIME ZONE;",
            "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS location VARCHAR(255);",
            "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS handicap INTEGER DEFAULT 0;",
            "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS spa_points INTEGER DEFAULT 0;",
            "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;",
            "CREATE INDEX IF NOT EXISTS idx_challenges_game_type ON public.challenges(game_type);",
        ]
        
        for sql in sql_commands:
            try:
                print(f"📝 Executing: {sql.split()[5] if len(sql.split()) > 5 else 'SQL'}")
                result = supabase.rpc('sql', {'query': sql}).execute()
                print(f"✅ Success")
            except Exception as e:
                print(f"⚠️ SQL Error: {e}")
                # Try alternative approach
                try:
                    # Some RPC endpoints might be different
                    result = supabase.postgrest.rpc('exec_sql', {'sql': sql}).execute()
                    print(f"✅ Alternative method success")
                except Exception as e2:
                    print(f"❌ Both methods failed: {e2}")
        
        # Test the schema after changes
        print("🧪 Testing updated schema...")
        try:
            # Try to insert a test record with game_type
            test_data = {
                "challenger_id": "ca23e628-d2bb-4174-b4b8-d1cc2ff8335f",
                "challenged_id": "8dc68b2e-8c94-47d7-a2d7-a70b218c32a8", 
                "challenge_type": "thach_dau",
                "game_type": "8-ball",
                "location": "Test Location",
                "status": "pending"
            }
            
            result = supabase.table('challenges').insert(test_data).execute()
            
            if result.data:
                print("🎉 SUCCESS: game_type column is working!")
                challenge_id = result.data[0]['id']
                
                # Clean up
                supabase.table('challenges').delete().eq('id', challenge_id).execute()
                print("🧹 Test data cleaned up")
            else:
                print("⚠️ Insert returned no data")
                
        except Exception as e:
            print(f"❌ Test insert failed: {e}")
            if "game_type" in str(e):
                print("🔧 game_type column still missing!")
            else:
                print("💡 Different error, might be permissions or other issue")
        
    except Exception as error:
        print(f"❌ Error: {error}")

if __name__ == "__main__":
    main()
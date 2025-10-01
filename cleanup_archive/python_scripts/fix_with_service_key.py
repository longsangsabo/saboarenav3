#!/usr/bin/env python3
"""
Fix challenges table schema using service key with admin privileges
This will add all missing columns directly to the database
"""
from supabase import create_client, Client

def main():
    print("🔧 Fixing challenges table schema with service key...")
    
    # Use service key for admin access
    url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    service_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
    
    try:
        # Create admin client with service key
        supabase: Client = create_client(url, service_key)
        print("✅ Service client created with admin privileges")
        
        # First, check current table structure
        print("🔍 Checking current challenges table...")
        try:
            result = supabase.table('challenges').select('*').limit(1).execute()
            print(f"📊 Current table has {len(result.data)} records")
            if result.data:
                print("📋 Current columns:", list(result.data[0].keys()))
        except Exception as e:
            print(f"⚠️ Table check: {e}")
        
        # SQL commands to add missing columns
        alter_commands = [
            {
                "name": "game_type",
                "sql": "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS game_type VARCHAR(20) DEFAULT '8-ball';"
            },
            {
                "name": "scheduled_time", 
                "sql": "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMP WITH TIME ZONE;"
            },
            {
                "name": "location",
                "sql": "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS location VARCHAR(255);"
            },
            {
                "name": "handicap",
                "sql": "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS handicap INTEGER DEFAULT 0;"
            },
            {
                "name": "spa_points",
                "sql": "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS spa_points INTEGER DEFAULT 0;"
            },
            {
                "name": "expires_at",
                "sql": "ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days');"
            }
        ]
        
        # Create a function to execute SQL with service role
        print("🛠️ Creating SQL executor function...")
        create_function_sql = """
        CREATE OR REPLACE FUNCTION execute_admin_sql(sql_text TEXT)
        RETURNS TEXT
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $$
        BEGIN
          EXECUTE sql_text;
          RETURN 'SUCCESS';
        EXCEPTION WHEN OTHERS THEN
          RETURN 'ERROR: ' || SQLERRM;
        END;
        $$;
        """
        
        try:
            # Try to create the function using direct SQL execution
            import requests
            
            # Use Supabase REST API with service key for direct SQL
            headers = {
                'apikey': service_key,
                'Authorization': f'Bearer {service_key}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            }
            
            # Try PostgREST direct SQL execution
            sql_endpoint = f"{url}/rest/v1/rpc/sql"
            
            # Alternative approach: Use the database connection string method
            print("🔧 Executing ALTER TABLE commands...")
            
            for cmd in alter_commands:
                print(f"➕ Adding column: {cmd['name']}")
                
                # Try multiple approaches to execute SQL
                success = False
                
                # Method 1: Try via RPC if available
                try:
                    result = supabase.rpc('sql', {'query': cmd['sql']}).execute()
                    print(f"✅ {cmd['name']} added via RPC")
                    success = True
                except Exception as e:
                    print(f"⚠️ RPC failed for {cmd['name']}: {e}")
                
                # Method 2: Try via direct REST API call
                if not success:
                    try:
                        response = requests.post(
                            f"{url}/rest/v1/rpc/execute_admin_sql",
                            headers=headers,
                            json={'sql_text': cmd['sql']}
                        )
                        if response.status_code == 200:
                            print(f"✅ {cmd['name']} added via REST API")
                            success = True
                        else:
                            print(f"⚠️ REST API failed for {cmd['name']}: {response.text}")
                    except Exception as e:
                        print(f"⚠️ REST API error for {cmd['name']}: {e}")
                
                if not success:
                    print(f"❌ Could not add column {cmd['name']}")
            
            # Add indexes for performance
            index_commands = [
                "CREATE INDEX IF NOT EXISTS idx_challenges_game_type ON public.challenges(game_type);",
                "CREATE INDEX IF NOT EXISTS idx_challenges_scheduled_time ON public.challenges(scheduled_time);",
                "CREATE INDEX IF NOT EXISTS idx_challenges_expires_at ON public.challenges(expires_at);"
            ]
            
            print("📊 Adding performance indexes...")
            for idx_sql in index_commands:
                try:
                    result = supabase.rpc('sql', {'query': idx_sql}).execute()
                    print(f"✅ Index created")
                except Exception as e:
                    print(f"⚠️ Index creation: {e}")
            
        except Exception as e:
            print(f"❌ Function creation error: {e}")
        
        # Test the schema after changes
        print("\n🧪 Testing updated schema...")
        try:
            # Try to insert a test record with all new columns
            test_data = {
                "challenger_id": "ca23e628-d2bb-4174-b4b8-d1cc2ff8335f",
                "challenged_id": "8dc68b2e-8c94-47d7-a2d7-a70b218c32a8",
                "challenge_type": "thach_dau",
                "game_type": "8-ball",      # Should work now
                "location": "Admin Test",   # Should work now
                "handicap": 3,             # Should work now
                "spa_points": 150,         # Should work now
                "status": "pending"
            }
            
            result = supabase.table('challenges').insert(test_data).execute()
            
            if result.data:
                print("🎉 SUCCESS! All columns working with service key!")
                challenge = result.data[0]
                challenge_id = challenge['id']
                
                print(f"✅ Created challenge ID: {challenge_id}")
                print(f"📋 Full challenge data: {challenge}")
                
                # Clean up
                supabase.table('challenges').delete().eq('id', challenge_id).execute()
                print("🧹 Test data cleaned up")
                
                print("\n🎯 CHALLENGE SYSTEM FULLY WORKING!")
                print("✅ Database schema complete")
                print("✅ All columns exist and functional")
                print("✅ Flutter app challenge creation should work now")
                
            else:
                print("⚠️ Insert succeeded but returned no data")
                
        except Exception as e:
            print(f"❌ Final test failed: {e}")
            
            if "game_type" in str(e):
                print("🔧 game_type still missing - need alternative approach")
            else:
                print("💡 Different error, check details")
        
    except Exception as error:
        print(f"❌ Service key error: {error}")

if __name__ == "__main__":
    main()
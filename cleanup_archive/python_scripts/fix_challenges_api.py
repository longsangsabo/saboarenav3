#!/usr/bin/env python3
import requests
import json

def main():
    print("🔧 Fixing challenges table via Supabase API...")
    
    # Supabase config
    url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    anon_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"
    
    headers = {
        "apikey": anon_key,
        "Authorization": f"Bearer {anon_key}",
        "Content-Type": "application/json"
    }
    
    try:
        # Test connection by getting existing challenges
        print("📡 Testing Supabase connection...")
        response = requests.get(
            f"{url}/rest/v1/challenges?select=*&limit=1",
            headers=headers
        )
        
        if response.status_code == 200:
            print("✅ Connection successful!")
            challenges = response.json()
            print(f"📊 Found {len(challenges)} challenge records")
            
            if challenges:
                print("📋 Sample challenge structure:")
                for key in challenges[0].keys():
                    print(f"  - {key}")
                
                if 'game_type' in challenges[0]:
                    print("✅ SUCCESS: game_type column already exists!")
                    print("🎉 Database is ready for challenges!")
                    return
            else:
                print("📝 No existing challenges found")
        
        elif response.status_code == 406:
            # Table doesn't exist, need to create it
            print("⚠️ Challenges table doesn't exist or has issues")
            print("📋 Need to create the table via SQL...")
            
            # Try to run SQL via RPC
            print("🔧 Attempting to create table via SQL RPC...")
            sql_payload = {
                "query": """
                CREATE TABLE IF NOT EXISTS public.challenges (
                  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                  challenger_id UUID NOT NULL,
                  challenged_id UUID NOT NULL,
                  challenge_type VARCHAR(50) DEFAULT 'giao_luu',
                  game_type VARCHAR(20) DEFAULT '8-ball',
                  scheduled_time TIMESTAMP WITH TIME ZONE,
                  location VARCHAR(255),
                  handicap INTEGER DEFAULT 0,
                  spa_points INTEGER DEFAULT 0,
                  message TEXT,
                  status VARCHAR(20) DEFAULT 'pending',
                  expires_at TIMESTAMP WITH TIME ZONE,
                  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                );
                
                -- Add indexes
                CREATE INDEX IF NOT EXISTS idx_challenges_challenger_id ON public.challenges(challenger_id);
                CREATE INDEX IF NOT EXISTS idx_challenges_challenged_id ON public.challenges(challenged_id);
                CREATE INDEX IF NOT EXISTS idx_challenges_status ON public.challenges(status);
                CREATE INDEX IF NOT EXISTS idx_challenges_game_type ON public.challenges(game_type);
                """
            }
            
            rpc_response = requests.post(
                f"{url}/rest/v1/rpc/sql",
                headers=headers,
                json=sql_payload
            )
            
            if rpc_response.status_code == 200:
                print("✅ Table created successfully!")
            else:
                print(f"⚠️ RPC failed: {rpc_response.status_code} - {rpc_response.text}")
        
        else:
            print(f"❌ API Error: {response.status_code}")
            print(f"Response: {response.text}")
            
            # Check if it's a schema cache issue
            if "Could not find the" in response.text and "column" in response.text:
                print("🔧 This is a schema cache issue!")
                print("💡 Solution: Need to refresh schema or create table properly")
                print("📝 The Flutter app error confirms the table exists but missing 'game_type' column")
                
    except Exception as error:
        print(f"❌ Error: {error}")

if __name__ == "__main__":
    main()
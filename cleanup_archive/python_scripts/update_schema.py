#!/usr/bin/env python3
"""
Script to update Supabase database schema to match current requirements
"""

from supabase import create_client, Client

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

def main():
    try:
        # Initialize Supabase client
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        print("✅ Connected to Supabase with service role")
        
        # Check current schema
        print("\n🔍 Checking current tournaments table...")
        tournaments = supabase.table('tournaments').select('*').limit(1).execute()
        if tournaments.data:
            tournament = tournaments.data[0]
            print("📊 Current tournaments columns:")
            for key in sorted(tournament.keys()):
                print(f"   - {key}")
        
        print("\n🔍 Checking current tournament_participants table...")
        participants = supabase.table('tournament_participants').select('*').limit(1).execute()
        if participants.data:
            participant = participants.data[0]
            print("📊 Current tournament_participants columns:")
            for key in sorted(participant.keys()):
                print(f"   - {key}")
        
        # Add missing columns if needed (these should be run via Supabase SQL editor)
        sql_updates = [
            """
            -- Add missing columns to tournament_participants if they don't exist
            DO $$ 
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name = 'tournament_participants' AND column_name = 'status') THEN
                    ALTER TABLE tournament_participants ADD COLUMN status VARCHAR(20) DEFAULT 'registered';
                END IF;
                
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name = 'tournament_participants' AND column_name = 'seed_number') THEN
                    ALTER TABLE tournament_participants ADD COLUMN seed_number INTEGER;
                END IF;
                
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                              WHERE table_name = 'tournament_participants' AND column_name = 'notes') THEN
                    ALTER TABLE tournament_participants ADD COLUMN notes TEXT;
                END IF;
            END $$;
            """,
            """
            -- Create RPC functions for tournament participant management
            CREATE OR REPLACE FUNCTION increment_tournament_participants(tournament_id UUID)
            RETURNS void 
            LANGUAGE sql
            AS $$
              UPDATE tournaments 
              SET current_participants = current_participants + 1,
                  updated_at = NOW()
              WHERE id = tournament_id;
            $$;
            """,
            """
            CREATE OR REPLACE FUNCTION decrement_tournament_participants(tournament_id UUID)
            RETURNS void
            LANGUAGE sql  
            AS $$
              UPDATE tournaments 
              SET current_participants = GREATEST(current_participants - 1, 0),
                  updated_at = NOW()
              WHERE id = tournament_id;
            $$;
            """,
            """
            -- Grant permissions
            GRANT EXECUTE ON FUNCTION increment_tournament_participants(UUID) TO authenticated;
            GRANT EXECUTE ON FUNCTION decrement_tournament_participants(UUID) TO authenticated;
            """
        ]
        
        print("\n📝 SQL Updates needed (run these in Supabase SQL editor):")
        for i, sql in enumerate(sql_updates, 1):
            print(f"\n--- Update {i} ---")
            print(sql.strip())
        
        print(f"\n✅ Schema analysis complete!")
        print(f"📋 Current tournament count: {len(tournaments.data) if tournaments.data else 0}")
        print(f"📋 Current participant count: {len(participants.data) if participants.data else 0}")
        
        # Test the functions if they exist
        print(f"\n🧪 Testing RPC functions...")
        try:
            # Get a tournament ID to test with
            if tournaments.data:
                test_tournament_id = tournaments.data[0]['id']
                # Test calling the increment function (this will test if it exists)
                result = supabase.rpc('increment_tournament_participants', {'tournament_id': test_tournament_id}).execute()
                print("✅ increment_tournament_participants function works")
                
                # Decrement it back
                result = supabase.rpc('decrement_tournament_participants', {'tournament_id': test_tournament_id}).execute()
                print("✅ decrement_tournament_participants function works")
            else:
                print("⚠️  No tournaments found to test functions with")
        except Exception as e:
            print(f"⚠️  RPC functions may need to be created: {e}")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
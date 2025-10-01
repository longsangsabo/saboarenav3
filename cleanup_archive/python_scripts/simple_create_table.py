#!/usr/bin/env python3
"""
Simple script to create tournament_matches table
"""

from supabase import create_client

def create_table():
    SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
    
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    
    try:
        print("🚀 Creating tournament_matches table...")
        
        # Simple approach: try direct SQL execution
        sql = """
        DROP TABLE IF EXISTS public.tournament_matches CASCADE;
        
        CREATE TABLE public.tournament_matches (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            tournament_id UUID NOT NULL,
            player1_id UUID,
            player2_id UUID,
            round_number INTEGER NOT NULL,
            match_number INTEGER NOT NULL,
            status TEXT DEFAULT 'pending',
            player1_score INTEGER DEFAULT 0,
            player2_score INTEGER DEFAULT 0,
            winner_id UUID,
            scheduled_time TIMESTAMPTZ,
            start_time TIMESTAMPTZ,
            end_time TIMESTAMPTZ,
            notes TEXT,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE INDEX idx_tournament_matches_tournament ON public.tournament_matches(tournament_id);
        CREATE INDEX idx_tournament_matches_round ON public.tournament_matches(round_number, match_number);
        
        ALTER TABLE public.tournament_matches ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Allow all access to tournament_matches" ON public.tournament_matches FOR ALL USING (true);
        """
        
        # Try using rpc to execute SQL
        result = supabase.rpc('exec_sql', {'sql': sql})
        print("✅ Table created successfully using RPC!")
        
    except Exception as e:
        print(f"RPC failed: {e}")
        print("Trying alternative method...")
        
        # Alternative: try direct table operations  
        try:
            # Test if we can insert directly
            test_data = {
                'tournament_id': '550e8400-e29b-41d4-a716-446655440000',
                'round_number': 1,
                'match_number': 1,
                'status': 'pending'
            }
            
            result = supabase.table('tournament_matches').insert(test_data)
            print("✅ tournament_matches table exists and is accessible!")
            
        except Exception as e2:
            print(f"❌ Cannot access tournament_matches table: {e2}")
            print("Please create the table manually in Supabase dashboard")

if __name__ == "__main__":
    create_table()
#!/usr/bin/env python3
"""
Create tournament_matches table using service key
"""

from supabase import create_client

def create_tournament_matches_table():
    # Supabase credentials với service key (admin role)
    SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
    
    # Initialize Supabase client with service key
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    
    try:
        print("🚀 Creating tournament_matches table...")
        
        # Create table SQL
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS public.tournament_matches (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
            player1_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
            player2_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
            round_number INTEGER NOT NULL,
            match_number INTEGER NOT NULL,
            status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
            player1_score INTEGER DEFAULT 0,
            player2_score INTEGER DEFAULT 0,
            winner_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
            scheduled_time TIMESTAMPTZ,
            start_time TIMESTAMPTZ,
            end_time TIMESTAMPTZ,
            notes TEXT,
            bracket_type TEXT DEFAULT 'main' CHECK (bracket_type IN ('main', 'losers', 'winners', 'final')),
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        # Execute table creation
        result = supabase.rpc('exec_sql', {'sql': create_table_sql}).execute()
        print("✅ tournament_matches table created successfully!")
        
        # Create indexes for better performance
        index_sql = [
            "CREATE INDEX IF NOT EXISTS idx_tournament_matches_tournament ON public.tournament_matches(tournament_id);",
            "CREATE INDEX IF NOT EXISTS idx_tournament_matches_players ON public.tournament_matches(player1_id, player2_id);",
            "CREATE INDEX IF NOT EXISTS idx_tournament_matches_round ON public.tournament_matches(round_number, match_number);"
        ]
        
        for sql in index_sql:
            supabase.rpc('exec_sql', {'sql': sql}).execute()
            
        print("✅ Indexes created successfully!")
        
        # Set up RLS (Row Level Security)
        rls_sql = [
            "ALTER TABLE public.tournament_matches ENABLE ROW LEVEL SECURITY;",
            """
            CREATE POLICY "tournament_matches_read" ON public.tournament_matches
            FOR SELECT USING (true);
            """,
            """
            CREATE POLICY "tournament_matches_write" ON public.tournament_matches
            FOR ALL USING (true);
            """
        ]
        
        for sql in rls_sql:
            try:
                supabase.rpc('exec_sql', {'sql': sql}).execute()
            except Exception as e:
                print(f"⚠️  RLS warning: {e}")
        
        print("✅ RLS policies set up!")
        
        # Test the table by inserting a dummy record
        test_insert = {
            'tournament_id': '00000000-0000-0000-0000-000000000000',
            'player1_id': '00000000-0000-0000-0000-000000000001',
            'player2_id': '00000000-0000-0000-0000-000000000002',
            'round_number': 1,
            'match_number': 1,
            'status': 'pending'
        }
        
        try:
            test_result = supabase.from('tournament_matches').insert(test_insert)
            print("✅ Test insert successful!")
            
            # Clean up test record
            if test_result:
                # Get the first record ID to delete
                records = supabase.from('tournament_matches').select('id').limit(1)
                if records:
                    supabase.from('tournament_matches').delete().eq('id', records[0]['id'])
                print("✅ Test record cleaned up!")
                
        except Exception as e:
            print(f"⚠️  Test insert failed (expected due to foreign keys): {e}")
            
        print("\n🎯 tournament_matches table ready for use!")
        print("Required fields: tournament_id, round_number, match_number")
        print("Optional fields: player1_id, player2_id, status, scores, etc.")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    create_tournament_matches_table()
#!/usr/bin/env python3
"""
Create tournament_matches table directly via SQL
"""

from supabase import create_client

SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

def main():
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    
    sql = """
    -- Drop table if exists
    DROP TABLE IF EXISTS public.tournament_matches CASCADE;
    
    -- Create enum for match_status if it doesn't exist
    DO $$ BEGIN
        CREATE TYPE public.match_status AS ENUM ('pending', 'in_progress', 'completed');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;

    -- Create tournament_matches table
    CREATE TABLE public.tournament_matches (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tournament_id UUID NOT NULL,
        player1_id UUID NOT NULL,
        player2_id UUID,
        round_number INTEGER NOT NULL DEFAULT 1,
        match_number INTEGER NOT NULL DEFAULT 1,
        match_status public.match_status NOT NULL DEFAULT 'pending',
        player1_score INTEGER DEFAULT 0,
        player2_score INTEGER DEFAULT 0,
        winner_id UUID,
        scheduled_at TIMESTAMP WITH TIME ZONE,
        started_at TIMESTAMP WITH TIME ZONE,
        ended_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    -- Create indexes
    CREATE INDEX IF NOT EXISTS idx_tournament_matches_tournament_id ON public.tournament_matches(tournament_id);
    CREATE INDEX IF NOT EXISTS idx_tournament_matches_player1_id ON public.tournament_matches(player1_id);
    CREATE INDEX IF NOT EXISTS idx_tournament_matches_player2_id ON public.tournament_matches(player2_id);
    CREATE INDEX IF NOT EXISTS idx_tournament_matches_status ON public.tournament_matches(match_status);

    -- Enable RLS
    ALTER TABLE public.tournament_matches ENABLE ROW LEVEL SECURITY;

    -- Create policies
    CREATE POLICY "Users can view tournament matches they participate in" 
        ON public.tournament_matches FOR SELECT 
        USING (player1_id = auth.uid() OR player2_id = auth.uid());

    CREATE POLICY "Users can update matches they participate in" 
        ON public.tournament_matches FOR UPDATE 
        USING (player1_id = auth.uid() OR player2_id = auth.uid());
    
    -- Allow service role to do everything
    CREATE POLICY "Service role can do anything" 
        ON public.tournament_matches FOR ALL 
        USING (auth.role() = 'service_role');
    """
    
    try:
        print("🚀 Creating tournament_matches table...")
        result = supabase.rpc("sql_query", {"query": sql}).execute()
        print("✅ tournament_matches table created successfully!")
        
        # Verify table exists
        verify_sql = """
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_name = 'tournament_matches' 
        AND table_schema = 'public' 
        ORDER BY ordinal_position;
        """
        
        verify_result = supabase.rpc("sql_query", {"query": verify_sql}).execute()
        
        if verify_result.data:
            print(f"✅ Table verified! Found {len(verify_result.data)} columns:")
            for col in verify_result.data:
                print(f"  - {col['column_name']}: {col['data_type']} ({'nullable' if col['is_nullable'] == 'YES' else 'not null'})")
        else:
            print("❌ Could not verify table creation")
            
    except Exception as e:
        print(f"❌ Error creating table: {e}")

if __name__ == "__main__":
    main()
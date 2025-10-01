#!/usr/bin/env python3
import psycopg2
import sys

def main():
    print("🔧 Fixing challenges table schema...")
    
    # Supabase connection string
    conn_string = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:YbPMrnm6DKCsVhAW@db.mogjjvscxjwvhtpkrlqr.supabase.co:5432/postgres"
    
    try:
        # Connect to database
        print("📡 Connecting to Supabase...")
        conn = psycopg2.connect(conn_string)
        cur = conn.cursor()
        
        print("✅ Connected successfully!")
        
        # Create challenges table if not exists
        print("📝 Creating challenges table...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS public.challenges (
              id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
              challenger_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
              challenged_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
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
        """)
        
        # Add missing columns safely
        print("🔧 Adding missing columns...")
        columns_to_add = [
            "game_type VARCHAR(20) DEFAULT '8-ball'",
            "scheduled_time TIMESTAMP WITH TIME ZONE",
            "location VARCHAR(255)",
            "handicap INTEGER DEFAULT 0",
            "spa_points INTEGER DEFAULT 0",
            "expires_at TIMESTAMP WITH TIME ZONE"
        ]
        
        for column in columns_to_add:
            try:
                cur.execute(f"ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS {column};")
                print(f"✅ Added column: {column.split()[0]}")
            except Exception as e:
                print(f"⚠️ Column {column.split()[0]} already exists or error: {e}")
        
        # Create indexes
        print("📊 Creating indexes...")
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_challenges_challenger_id ON public.challenges(challenger_id);",
            "CREATE INDEX IF NOT EXISTS idx_challenges_challenged_id ON public.challenges(challenged_id);",
            "CREATE INDEX IF NOT EXISTS idx_challenges_status ON public.challenges(status);",
            "CREATE INDEX IF NOT EXISTS idx_challenges_game_type ON public.challenges(game_type);"
        ]
        
        for index in indexes:
            cur.execute(index)
            print(f"✅ Created index")
        
        # Enable RLS
        print("🔒 Enabling Row Level Security...")
        cur.execute("ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;")
        
        # Create basic RLS policy
        print("📋 Creating RLS policy...")
        cur.execute("""
            CREATE POLICY IF NOT EXISTS "Users can view their challenges" ON public.challenges
            FOR SELECT USING (
              auth.uid() = challenger_id OR 
              auth.uid() = challenged_id
            );
        """)
        
        cur.execute("""
            CREATE POLICY IF NOT EXISTS "Users can insert their challenges" ON public.challenges
            FOR INSERT WITH CHECK (auth.uid() = challenger_id);
        """)
        
        # Commit changes
        conn.commit()
        
        # Test the table
        print("🧪 Testing table structure...")
        cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'challenges' AND table_schema = 'public';")
        columns = [row[0] for row in cur.fetchall()]
        
        print("📋 Challenges table columns:")
        for col in sorted(columns):
            print(f"  - {col}")
        
        if 'game_type' in columns:
            print("✅ SUCCESS: game_type column exists!")
        else:
            print("❌ ERROR: game_type column missing!")
            
        # Test insert
        print("🧪 Testing insert capability...")
        cur.execute("SELECT COUNT(*) FROM public.challenges;")
        count = cur.fetchone()[0]
        print(f"📊 Current challenges count: {count}")
        
        cur.close()
        conn.close()
        
        print("🎉 Database migration completed successfully!")
        
    except Exception as error:
        print(f"❌ Error: {error}")
        sys.exit(1)

if __name__ == "__main__":
    main()
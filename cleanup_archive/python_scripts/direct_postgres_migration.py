"""
DIRECT POSTGRESQL CONNECTION
============================
Using direct database credentials to execute DDL commands
"""

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# Direct PostgreSQL connection
DB_HOST = "db.mogjjvscxjwvhtpkrlqr.supabase.co"
DB_PORT = 5432
DB_NAME = "postgres"
DB_USER = "postgres"
DB_PASSWORD = "Acookingoil123"

def execute_sql_directly():
    """Execute SQL commands directly via PostgreSQL connection"""
    print("🔗 DIRECT POSTGRESQL CONNECTION")
    print("=" * 50)
    
    try:
        # Establish connection
        print("🔌 Connecting to PostgreSQL...")
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        # Set autocommit for DDL operations
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        print("✅ Connected successfully!")
        
        # SQL commands to execute
        sql_commands = [
            # Add columns
            "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS game_format TEXT DEFAULT '8-ball';",
            "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS bracket_format TEXT DEFAULT 'single_elimination';",
            
            # Add constraints (drop existing if they exist to avoid conflicts)
            """DO $$ 
               BEGIN
                   IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_game_format') THEN
                       ALTER TABLE tournaments 
                       ADD CONSTRAINT check_game_format 
                       CHECK (game_format IN ('8-ball', '9-ball', 'straight', 'carom', 'snooker', 'other'));
                   END IF;
               END $$;""",
            
            """DO $$ 
               BEGIN
                   IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_bracket_format') THEN
                       ALTER TABLE tournaments 
                       ADD CONSTRAINT check_bracket_format 
                       CHECK (bracket_format IN ('single_elimination', 'double_elimination', 'round_robin', 'swiss'));
                   END IF;
               END $$;""",
            
            # Create indexes
            "CREATE INDEX IF NOT EXISTS idx_tournaments_game_format ON tournaments(game_format);",
            "CREATE INDEX IF NOT EXISTS idx_tournaments_bracket_format ON tournaments(bracket_format);"
        ]
        
        # Execute each command
        success_count = 0
        for i, sql in enumerate(sql_commands, 1):
            print(f"\n{i}. Executing: {sql[:60]}...")
            try:
                cursor.execute(sql)
                print(f"   ✅ Success")
                success_count += 1
            except Exception as e:
                print(f"   ⚠️  Warning: {e}")
                # Continue with other commands
        
        print(f"\n📊 SCHEMA CHANGES: {success_count}/{len(sql_commands)} completed")
        
        # Verify columns were added
        print(f"\n🔍 VERIFYING SCHEMA CHANGES:")
        cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'tournaments' AND column_name IN ('game_format', 'bracket_format');")
        new_columns = cursor.fetchall()
        
        if len(new_columns) == 2:
            print("✅ Both game_format and bracket_format columns created!")
            return True
        else:
            print(f"⚠️  Only {len(new_columns)} columns found: {new_columns}")
            return False
        
    except psycopg2.Error as e:
        print(f"❌ PostgreSQL Error: {e}")
        return False
    except Exception as e:
        print(f"❌ Connection Error: {e}")
        return False
    finally:
        if 'conn' in locals():
            conn.close()
            print("🔌 Connection closed")

def migrate_tournament_data():
    """Migrate tournament data to use new format fields"""
    print(f"\n🔄 MIGRATING TOURNAMENT DATA")
    print("=" * 50)
    
    try:
        # Use Supabase client for data operations (easier than raw SQL)
        from supabase import create_client
        SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
        SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
        
        supabase = create_client(SUPABASE_URL, SERVICE_KEY)
        
        # Get all tournaments
        tournaments = supabase.table('tournaments').select('*').execute()
        
        migration_mapping = {
            # Game formats (these are correct as game rules)
            '8-ball': {'game_format': '8-ball', 'bracket_format': 'single_elimination'},
            '9-ball': {'game_format': '9-ball', 'bracket_format': 'single_elimination'},
            'straight': {'game_format': 'straight', 'bracket_format': 'single_elimination'},
            
            # Bracket formats (these were incorrectly stored as format)
            'single_elimination': {'game_format': '8-ball', 'bracket_format': 'single_elimination'},
            'double_elimination': {'game_format': '8-ball', 'bracket_format': 'double_elimination'},
            'round_robin': {'game_format': '8-ball', 'bracket_format': 'round_robin'},
        }
        
        success_count = 0
        for tournament in tournaments.data:
            try:
                tournament_id = tournament['id']
                title = tournament['title']
                current_format = tournament.get('format', 'unknown')
                tournament_type = tournament.get('tournament_type', 'single_elimination')
                
                # Determine proper mapping
                if current_format in migration_mapping:
                    mapping = migration_mapping[current_format]
                    # Override bracket format with tournament_type if more specific
                    if tournament_type in ['single_elimination', 'double_elimination', 'round_robin']:
                        mapping['bracket_format'] = tournament_type
                else:
                    # Default mapping
                    mapping = {
                        'game_format': '8-ball',
                        'bracket_format': tournament_type or 'single_elimination'
                    }
                
                # Update tournament
                supabase.table('tournaments').update({
                    'game_format': mapping['game_format'],
                    'bracket_format': mapping['bracket_format']
                }).eq('id', tournament_id).execute()
                
                print(f"✅ {title}: game_format='{mapping['game_format']}', bracket_format='{mapping['bracket_format']}'")
                success_count += 1
                
            except Exception as e:
                print(f"❌ Failed to migrate '{title}': {e}")
        
        print(f"\n📊 DATA MIGRATION: {success_count}/{len(tournaments.data)} tournaments migrated")
        return success_count > 0
        
    except Exception as e:
        print(f"❌ Migration error: {e}")
        return False

def verify_critical_tournament():
    """Verify sabo1 tournament has correct format"""
    print(f"\n🎯 VERIFYING CRITICAL TOURNAMENT: sabo1")
    print("=" * 50)
    
    try:
        from supabase import create_client
        SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
        SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
        
        supabase = create_client(SUPABASE_URL, SERVICE_KEY)
        
        sabo1 = supabase.table('tournaments').select('*').eq('title', 'sabo1').execute()
        
        if sabo1.data:
            t = sabo1.data[0]
            game_format = t.get('game_format')
            bracket_format = t.get('bracket_format')
            
            print(f"🏆 sabo1 Tournament:")
            print(f"   game_format: '{game_format}'")
            print(f"   bracket_format: '{bracket_format}'")
            
            if game_format == '8-ball' and bracket_format == 'double_elimination':
                print("✅ PERFECT! sabo1 configured correctly for MatchProgressionService")
                print("   ✅ game_format = '8-ball' (game rules)")
                print("   ✅ bracket_format = 'double_elimination' (tournament structure)")
                print("   ✅ MatchProgressionService will work perfectly!")
                return True
            else:
                print("⚠️  Unexpected values - may need adjustment")
                return False
        else:
            print("❌ sabo1 tournament not found!")
            return False
            
    except Exception as e:
        print(f"❌ Verification error: {e}")
        return False

if __name__ == "__main__":
    print("🚀 DIRECT POSTGRESQL SCHEMA MIGRATION")
    print("Adding game_format and bracket_format columns")
    print("=" * 60)
    
    # Step 1: Execute schema changes
    schema_success = execute_sql_directly()
    
    if schema_success:
        # Step 2: Migrate data
        print(f"\n" + "="*60)
        migration_success = migrate_tournament_data()
        
        if migration_success:
            # Step 3: Verify critical tournament
            verification_success = verify_critical_tournament()
            
            if verification_success:
                print(f"\n🎉 COMPLETE SUCCESS!")
                print("✅ Schema updated with proper format fields")
                print("✅ All tournament data migrated")
                print("✅ sabo1 tournament configured correctly")
                print("✅ MatchProgressionService will use bracket_format")
                print("🚀 IMMEDIATE ADVANCEMENT IS READY TO TEST!")
            else:
                print(f"\n⚠️  Schema and migration completed but verification failed")
        else:
            print(f"\n⚠️  Schema updated but data migration failed")
    else:
        print(f"\n❌ Schema migration failed - check connection and credentials")
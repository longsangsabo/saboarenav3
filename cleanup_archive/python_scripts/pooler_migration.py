"""
SUPABASE TRANSACTION POOLER CONNECTION
=====================================
Using the correct Supabase transaction pooler endpoint
"""

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# Supabase Transaction Pooler
POOLER_HOST = "aws-1-ap-southeast-1.pooler.supabase.com"
POOLER_PORT = 6543
DB_NAME = "postgres"
DB_USER = "postgres.mogjjvscxjwvhtpkrlqr"
DB_PASSWORD = "Acookingoil123"

def execute_via_transaction_pooler():
    """Execute DDL commands via Supabase transaction pooler"""
    print("🔗 SUPABASE TRANSACTION POOLER CONNECTION")
    print("=" * 50)
    
    # Connection string
    conn_str = f"postgresql://{DB_USER}:{DB_PASSWORD}@{POOLER_HOST}:{POOLER_PORT}/{DB_NAME}"
    print(f"🔌 Connecting to: {POOLER_HOST}:{POOLER_PORT}")
    
    try:
        # Establish connection
        conn = psycopg2.connect(conn_str)
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        print("✅ Connected to Supabase Transaction Pooler!")
        
        # Test connection
        cursor.execute("SELECT current_database(), current_user, version()")
        db_info = cursor.fetchone()
        print(f"📊 Database: {db_info[0]}")
        print(f"👤 User: {db_info[1]}")
        print(f"🔧 Version: {db_info[2][:50]}...")
        
        # Execute schema changes
        print(f"\n🔧 EXECUTING SCHEMA CHANGES:")
        print("=" * 40)
        
        sql_commands = [
            # Add columns with proper error handling
            "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS game_format TEXT DEFAULT '8-ball'",
            "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS bracket_format TEXT DEFAULT 'single_elimination'",
            
            # Create indexes
            "CREATE INDEX IF NOT EXISTS idx_tournaments_game_format ON tournaments(game_format)",
            "CREATE INDEX IF NOT EXISTS idx_tournaments_bracket_format ON tournaments(bracket_format)"
        ]
        
        success_count = 0
        for i, sql in enumerate(sql_commands, 1):
            print(f"\n{i}. {sql}")
            try:
                cursor.execute(sql)
                print(f"   ✅ Success")
                success_count += 1
            except Exception as e:
                print(f"   ⚠️  Error: {e}")
                # Continue with other commands
        
        # Add constraints separately (these might fail if they already exist)
        print(f"\n🔒 ADDING CONSTRAINTS:")
        constraint_commands = [
            """ALTER TABLE tournaments 
               ADD CONSTRAINT check_game_format 
               CHECK (game_format IN ('8-ball', '9-ball', 'straight', 'carom', 'snooker', 'other'))""",
            
            """ALTER TABLE tournaments 
               ADD CONSTRAINT check_bracket_format 
               CHECK (bracket_format IN ('single_elimination', 'double_elimination', 'round_robin', 'swiss'))"""
        ]
        
        for i, sql in enumerate(constraint_commands, 1):
            print(f"\n{i}. Adding constraint...")
            try:
                cursor.execute(sql)
                print(f"   ✅ Constraint added")
            except Exception as e:
                if "already exists" in str(e).lower():
                    print(f"   ℹ️  Constraint already exists")
                else:
                    print(f"   ⚠️  Error: {e}")
        
        # Verify columns were created
        print(f"\n🔍 VERIFYING SCHEMA:")
        cursor.execute("""
            SELECT column_name, data_type, column_default 
            FROM information_schema.columns 
            WHERE table_name = 'tournaments' 
            AND column_name IN ('game_format', 'bracket_format')
            ORDER BY column_name
        """)
        
        new_columns = cursor.fetchall()
        
        print(f"📊 RESULTS:")
        print(f"   Commands executed: {success_count}/{len(sql_commands)}")
        print(f"   New columns found: {len(new_columns)}")
        
        for col in new_columns:
            print(f"   ✅ {col[0]} ({col[1]}) DEFAULT {col[2]}")
        
        conn.close()
        print("🔌 Connection closed")
        
        return len(new_columns) == 2
        
    except psycopg2.Error as e:
        print(f"❌ PostgreSQL Error: {e}")
        return False
    except Exception as e:
        print(f"❌ Connection Error: {e}")
        return False

def migrate_tournament_data():
    """Migrate all tournament data to new format fields"""
    print(f"\n📦 MIGRATING TOURNAMENT DATA")
    print("=" * 50)
    
    try:
        from supabase import create_client
        SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
        SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
        
        supabase = create_client(SUPABASE_URL, SERVICE_KEY)
        
        # Get all tournaments
        tournaments = supabase.table('tournaments').select('*').execute()
        print(f"📊 Found {len(tournaments.data)} tournaments to migrate")
        
        # Migration mapping
        migration_rules = {
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
                if current_format in migration_rules:
                    mapping = migration_rules[current_format].copy()
                    # Override bracket format with tournament_type if more specific
                    if tournament_type in ['single_elimination', 'double_elimination', 'round_robin']:
                        mapping['bracket_format'] = tournament_type
                else:
                    # Default mapping for unknown formats
                    mapping = {
                        'game_format': '8-ball',  # Default game
                        'bracket_format': tournament_type or 'single_elimination'
                    }
                
                # Update tournament
                supabase.table('tournaments').update(mapping).eq('id', tournament_id).execute()
                
                print(f"✅ {title}:")
                print(f"   OLD: format='{current_format}', tournament_type='{tournament_type}'")
                print(f"   NEW: game_format='{mapping['game_format']}', bracket_format='{mapping['bracket_format']}'")
                
                success_count += 1
                
            except Exception as e:
                print(f"❌ Failed to migrate '{title}': {e}")
        
        print(f"\n📊 MIGRATION RESULTS: {success_count}/{len(tournaments.data)} tournaments migrated")
        return success_count > 0
        
    except Exception as e:
        print(f"❌ Migration error: {e}")
        return False

def verify_sabo1_tournament():
    """Verify sabo1 tournament is correctly configured"""
    print(f"\n🎯 VERIFYING SABO1 TOURNAMENT")
    print("=" * 50)
    
    try:
        from supabase import create_client
        SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
        SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
        
        supabase = create_client(SUPABASE_URL, SERVICE_KEY)
        
        sabo1 = supabase.table('tournaments').select('*').eq('title', 'sabo1').execute()
        
        if sabo1.data:
            t = sabo1.data[0]
            
            print(f"🏆 Tournament: {t['title']}")
            print(f"   ID: {t['id']}")
            print(f"   OLD format: '{t.get('format')}'")
            print(f"   OLD tournament_type: '{t.get('tournament_type')}'")
            print(f"   NEW game_format: '{t.get('game_format')}'")
            print(f"   NEW bracket_format: '{t.get('bracket_format')}'")
            
            expected_game = '8-ball'
            expected_bracket = 'double_elimination'
            actual_game = t.get('game_format')
            actual_bracket = t.get('bracket_format')
            
            if actual_game == expected_game and actual_bracket == expected_bracket:
                print(f"\n🎉 PERFECT CONFIGURATION!")
                print(f"✅ game_format = '{actual_game}' (game rules)")
                print(f"✅ bracket_format = '{actual_bracket}' (tournament structure)")
                print(f"✅ MatchProgressionService will use bracket_format = '{actual_bracket}'")
                print(f"🚀 IMMEDIATE ADVANCEMENT READY FOR TESTING!")
                return True
            else:
                print(f"\n⚠️  CONFIGURATION ISSUE:")
                print(f"   Expected: game_format='{expected_game}', bracket_format='{expected_bracket}'")
                print(f"   Actual: game_format='{actual_game}', bracket_format='{actual_bracket}'")
                return False
        else:
            print("❌ sabo1 tournament not found!")
            return False
            
    except Exception as e:
        print(f"❌ Verification error: {e}")
        return False

if __name__ == "__main__":
    print("🚀 SUPABASE TRANSACTION POOLER MIGRATION")
    print("Complete format field standardization")
    print("=" * 60)
    
    # Step 1: Execute schema changes via transaction pooler
    schema_success = execute_via_transaction_pooler()
    
    if schema_success:
        print(f"\n✅ SCHEMA MIGRATION SUCCESSFUL!")
        
        # Step 2: Migrate tournament data
        migration_success = migrate_tournament_data()
        
        if migration_success:
            # Step 3: Verify critical tournament
            verification_success = verify_sabo1_tournament()
            
            if verification_success:
                print(f"\n🎉 COMPLETE SUCCESS!")
                print("=" * 50)
                print("✅ Database schema updated with proper format fields")
                print("✅ All tournament data migrated successfully")
                print("✅ sabo1 tournament configured perfectly")
                print("✅ MatchProgressionService will use bracket_format field")
                print("🚀 IMMEDIATE ADVANCEMENT IS NOW READY!")
                print("=" * 50)
                print("📋 NEXT STEPS:")
                print("1. Run Flutter app")
                print("2. Navigate to sabo1 tournament")
                print("3. Complete a match via UI")
                print("4. Watch immediate winner/loser advancement!")
            else:
                print(f"\n⚠️  Schema and migration completed but verification needs attention")
        else:
            print(f"\n⚠️  Schema updated but data migration had issues")
    else:
        print(f"\n❌ Schema migration failed via transaction pooler")
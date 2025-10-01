"""
FORCE ADD COLUMNS: Create game_format and bracket_format by updating tournaments
==============================================================================
Since we can't add columns directly, we'll force Supabase to recognize them
by trying to update with new fields
"""

from supabase import create_client

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

# MANUAL SQL TO RUN IN SUPABASE DASHBOARD
SQL_TO_RUN = """
-- Add the new columns to tournaments table
ALTER TABLE tournaments 
ADD COLUMN game_format TEXT DEFAULT '8-ball',
ADD COLUMN bracket_format TEXT DEFAULT 'single_elimination';

-- Add helpful constraints
ALTER TABLE tournaments 
ADD CONSTRAINT check_game_format 
CHECK (game_format IN ('8-ball', '9-ball', 'straight', 'carom', 'snooker', 'other'));

ALTER TABLE tournaments 
ADD CONSTRAINT check_bracket_format 
CHECK (bracket_format IN ('single_elimination', 'double_elimination', 'round_robin', 'swiss'));
"""

print("🚀 PROPER FORMAT FIELD IMPLEMENTATION")
print("=" * 60)
print(f"📝 MANUAL SQL TO RUN IN SUPABASE SQL EDITOR:")
print("=" * 60)
print(SQL_TO_RUN)
print("=" * 60)

def migrate_all_tournaments():
    """Migrate all tournaments to proper format fields"""
    print("\n🔄 TOURNAMENT MIGRATION PLAN")
    print("=" * 50)
    
    # Get all tournaments
    tournaments = supabase.table('tournaments').select('*').execute()
    
    migration_plan = {}
    
    for tournament in tournaments.data:
        title = tournament['title']
        current_format = tournament.get('format', 'unknown')
        tournament_type = tournament.get('tournament_type', 'single_elimination')
        
        # Determine proper mapping
        if current_format in ['8-ball', '9-ball', 'straight', 'carom']:
            # This is already a game format
            game_format = current_format
            bracket_format = tournament_type  # Use tournament_type for bracket
        elif current_format in ['single_elimination', 'double_elimination', 'round_robin']:
            # This is actually a bracket format incorrectly stored as format
            game_format = '8-ball'  # Default game
            bracket_format = current_format
        else:
            # Unknown - use defaults
            game_format = '8-ball'
            bracket_format = tournament_type or 'single_elimination'
        
        migration_plan[title] = {
            'id': tournament['id'],
            'old_format': current_format,
            'old_tournament_type': tournament_type,
            'new_game_format': game_format,
            'new_bracket_format': bracket_format
        }
        
        print(f"🏆 {title}:")
        print(f"   OLD: format='{current_format}', tournament_type='{tournament_type}'")
        print(f"   NEW: game_format='{game_format}', bracket_format='{bracket_format}'")
    
    return migration_plan

def execute_migration(migration_plan):
    """Execute the migration (will fail until SQL is run)"""
    print(f"\n⚡ EXECUTING MIGRATION")
    print("=" * 50)
    
    success_count = 0
    error_count = 0
    
    for title, plan in migration_plan.items():
        try:
            # Update tournament with new fields
            update_result = supabase.table('tournaments').update({
                'game_format': plan['new_game_format'],
                'bracket_format': plan['new_bracket_format']
            }).eq('id', plan['id']).execute()
            
            print(f"✅ {title}: Updated successfully")
            success_count += 1
            
        except Exception as e:
            if "Could not find" in str(e) and "column" in str(e):
                print(f"⏸️  {title}: Columns don't exist yet - run SQL first")
            else:
                print(f"❌ {title}: {e}")
            error_count += 1
    
    print(f"\n📊 MIGRATION RESULTS: {success_count} success, {error_count} pending")
    
    if error_count > 0:
        print("\n⚠️  TO FIX:")
        print("1. Copy the SQL above")
        print("2. Go to Supabase Dashboard → SQL Editor")
        print("3. Paste and run the SQL")
        print("4. Re-run this script")
    
    return success_count > 0

def verify_critical_tournament():
    """Check the critical sabo1 tournament"""
    print(f"\n🎯 CHECKING CRITICAL TOURNAMENT: sabo1")
    print("=" * 50)
    
    try:
        sabo1 = supabase.table('tournaments').select('*').eq('title', 'sabo1').execute()
        
        if sabo1.data:
            t = sabo1.data[0]
            game_format = t.get('game_format', 'NOT_SET')
            bracket_format = t.get('bracket_format', 'NOT_SET')
            
            print(f"🏆 sabo1 Tournament Status:")
            print(f"   Current format: '{t.get('format')}'")
            print(f"   Current tournament_type: '{t.get('tournament_type')}'")
            print(f"   NEW game_format: '{game_format}'")
            print(f"   NEW bracket_format: '{bracket_format}'")
            
            if game_format == '8-ball' and bracket_format == 'double_elimination':
                print("✅ PERFECT! sabo1 ready for MatchProgressionService")
            elif game_format == 'NOT_SET':
                print("⏸️  Columns not created yet - run SQL first")
            else:
                print("⚠️  Unexpected values - may need manual adjustment")
        else:
            print("❌ sabo1 tournament not found!")
            
    except Exception as e:
        print(f"❌ Error checking sabo1: {e}")

if __name__ == "__main__":
    print("🎯 IMPLEMENTING PROPER FORMAT FIELDS")
    print("game_format: 8-ball, 9-ball, straight, etc.")
    print("bracket_format: single_elimination, double_elimination, etc.")
    print("=" * 60)
    
    # Step 1: Show migration plan
    migration_plan = migrate_all_tournaments()
    
    # Step 2: Try to execute (will fail until SQL is run)
    print("\n⚡ ATTEMPTING MIGRATION...")
    migration_success = execute_migration(migration_plan)
    
    # Step 3: Check critical tournament
    verify_critical_tournament()
    
    if not migration_success:
        print(f"\n📋 NEXT STEPS:")
        print(f"1. Run the SQL commands above in Supabase dashboard")
        print(f"2. Re-run this script to complete migration")
        print(f"3. Update MatchProgressionService to use bracket_format")
        print(f"4. Test immediate advancement!")
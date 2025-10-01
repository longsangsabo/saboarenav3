"""
CRITICAL FORMAT FIX: Separate game_format from bracket_format
=============================================================

PROBLEM: Current system mixes game rules (8-ball) with tournament structure (double_elimination)
SOLUTION: Split into two separate fields:
- game_format: "8-ball", "9-ball", "straight", "carom", etc. (GAME RULES)
- bracket_format: "single_elimination", "double_elimination", "round_robin" (TOURNAMENT STRUCTURE)

This will fix MatchProgressionService and ensure proper immediate advancement!
"""

from supabase import create_client

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def analyze_current_formats():
    """Analyze current format usage to plan migration"""
    print("🔍 ANALYZING CURRENT FORMAT USAGE")
    print("=" * 50)
    
    tournaments = supabase.table('tournaments').select('id, title, format, tournament_type').execute()
    
    format_analysis = {}
    for t in tournaments.data:
        current_format = t.get('format', 'unknown')
        tournament_type = t.get('tournament_type', 'unknown')
        
        if current_format not in format_analysis:
            format_analysis[current_format] = []
        format_analysis[current_format].append({
            'title': t['title'],
            'tournament_type': tournament_type
        })
    
    print("\n📊 FORMAT ANALYSIS:")
    for format_name, tournaments_list in format_analysis.items():
        print(f"\n  {format_name} ({len(tournaments_list)} tournaments):")
        for t in tournaments_list:
            print(f"    - {t['title']} (tournament_type: {t['tournament_type']})")
    
    return format_analysis

def plan_migration_mapping(format_analysis):
    """Plan how to map current formats to new schema"""
    print("\n🗺️  MIGRATION MAPPING PLAN")
    print("=" * 50)
    
    migration_plan = {}
    
    for current_format, tournaments_list in format_analysis.items():
        if current_format in ['8-ball', '9-ball', 'straight']:
            # These are GAME formats, need to determine bracket format
            for t in tournaments_list:
                tournament_type = t['tournament_type']
                if tournament_type in ['single_elimination', 'double_elimination', 'round_robin']:
                    # Use tournament_type as bracket_format
                    game_format = current_format
                    bracket_format = tournament_type
                else:
                    # Default assumption based on common patterns
                    game_format = current_format
                    bracket_format = 'single_elimination'  # Most common default
                
                migration_plan[t['title']] = {
                    'old_format': current_format,
                    'old_tournament_type': tournament_type,
                    'new_game_format': game_format,
                    'new_bracket_format': bracket_format
                }
        
        elif current_format in ['single_elimination', 'double_elimination', 'round_robin']:
            # These are BRACKET formats, need to determine game format
            for t in tournaments_list:
                # Default to 8-ball if no game format specified
                game_format = '8-ball'  # Most common game in pool
                bracket_format = current_format
                
                migration_plan[t['title']] = {
                    'old_format': current_format,
                    'old_tournament_type': t['tournament_type'],
                    'new_game_format': game_format,
                    'new_bracket_format': bracket_format
                }
        
        else:
            # Unknown formats - need manual review
            for t in tournaments_list:
                migration_plan[t['title']] = {
                    'old_format': current_format,
                    'old_tournament_type': t['tournament_type'],
                    'new_game_format': '8-ball',  # Default
                    'new_bracket_format': 'single_elimination',  # Default
                    'needs_review': True
                }
    
    print("\n📋 MIGRATION PLAN:")
    for tournament_title, plan in migration_plan.items():
        review_flag = " ⚠️ NEEDS REVIEW" if plan.get('needs_review') else ""
        print(f"\n  🏆 {tournament_title}:{review_flag}")
        print(f"    OLD: format='{plan['old_format']}', tournament_type='{plan['old_tournament_type']}'")
        print(f"    NEW: game_format='{plan['new_game_format']}', bracket_format='{plan['new_bracket_format']}'")
    
    return migration_plan

def execute_schema_migration():
    """Add new columns to tournaments table"""
    print("\n🔧 EXECUTING SCHEMA MIGRATION")
    print("=" * 50)
    
    try:
        # Note: Supabase doesn't support direct DDL, so we'll document the SQL needed
        print("📝 SQL COMMANDS NEEDED (run in Supabase SQL editor):")
        print("""
-- Add new columns to tournaments table
ALTER TABLE tournaments 
ADD COLUMN IF NOT EXISTS game_format TEXT DEFAULT '8-ball',
ADD COLUMN IF NOT EXISTS bracket_format TEXT DEFAULT 'single_elimination';

-- Add constraints for valid values
ALTER TABLE tournaments 
ADD CONSTRAINT tournaments_game_format_check 
CHECK (game_format IN ('8-ball', '9-ball', 'straight', 'carom', 'snooker', 'other'));

ALTER TABLE tournaments 
ADD CONSTRAINT tournaments_bracket_format_check 
CHECK (bracket_format IN ('single_elimination', 'double_elimination', 'round_robin', 'swiss', 'ladder'));

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_tournaments_game_format ON tournaments(game_format);
CREATE INDEX IF NOT EXISTS idx_tournaments_bracket_format ON tournaments(bracket_format);
        """)
        
        print("✅ Schema migration SQL generated. Please run this in Supabase dashboard.")
        return True
        
    except Exception as e:
        print(f"❌ Schema migration failed: {e}")
        return False

def migrate_data(migration_plan):
    """Migrate existing tournament data to new format"""
    print("\n📦 MIGRATING TOURNAMENT DATA")
    print("=" * 50)
    
    success_count = 0
    error_count = 0
    
    for tournament_title, plan in migration_plan.items():
        try:
            # Find tournament by title
            tournament_result = supabase.table('tournaments').select('id').eq('title', tournament_title).execute()
            
            if not tournament_result.data:
                print(f"⚠️  Tournament '{tournament_title}' not found, skipping...")
                continue
            
            tournament_id = tournament_result.data[0]['id']
            
            # Update with new format fields
            update_data = {
                'game_format': plan['new_game_format'],
                'bracket_format': plan['new_bracket_format']
            }
            
            supabase.table('tournaments').update(update_data).eq('id', tournament_id).execute()
            
            print(f"✅ {tournament_title}: game_format='{plan['new_game_format']}', bracket_format='{plan['new_bracket_format']}'")
            success_count += 1
            
        except Exception as e:
            print(f"❌ Failed to migrate '{tournament_title}': {e}")
            error_count += 1
    
    print(f"\n📊 MIGRATION RESULTS: {success_count} success, {error_count} errors")
    return success_count > 0

def verify_migration():
    """Verify the migration was successful"""
    print("\n✅ VERIFYING MIGRATION")
    print("=" * 50)
    
    tournaments = supabase.table('tournaments').select('title, format, tournament_type, game_format, bracket_format').execute()
    
    print("📋 POST-MIGRATION VERIFICATION:")
    for t in tournaments.data:
        title = t['title']
        old_format = t.get('format', 'NULL')
        old_tournament_type = t.get('tournament_type', 'NULL')
        new_game_format = t.get('game_format', 'NULL')
        new_bracket_format = t.get('bracket_format', 'NULL')
        
        print(f"\n🏆 {title}:")
        print(f"  OLD: format='{old_format}', tournament_type='{old_tournament_type}'")
        print(f"  NEW: game_format='{new_game_format}', bracket_format='{new_bracket_format}'")

if __name__ == "__main__":
    print("🚀 SABO ARENA FORMAT STANDARDIZATION")
    print("🎯 Separating game_format from bracket_format")
    print("=" * 60)
    
    # Step 1: Analyze current state
    format_analysis = analyze_current_formats()
    
    # Step 2: Plan migration
    migration_plan = plan_migration_mapping(format_analysis)
    
    # Step 3: Show schema changes needed
    schema_success = execute_schema_migration()
    
    if schema_success:
        print("\n⏸️  NEXT STEPS:")
        print("1. Run the SQL commands above in Supabase dashboard")
        print("2. Re-run this script to execute data migration")
        print("3. Update Flutter code to use new format fields")
    
    # Uncomment this after running SQL commands:
    # migrate_data(migration_plan)
    # verify_migration()
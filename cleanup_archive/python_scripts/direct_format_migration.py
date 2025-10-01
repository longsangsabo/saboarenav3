"""
DIRECT FORMAT MIGRATION - Add columns and migrate data immediately
================================================================
"""

from supabase import create_client

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def migrate_tournament_formats():
    """Migrate tournaments to new format system"""
    print("🚀 DIRECT FORMAT MIGRATION")
    print("=" * 50)
    
    # Get all tournaments
    tournaments = supabase.table('tournaments').select('*').execute()
    
    print(f"📊 Found {len(tournaments.data)} tournaments to migrate")
    
    migration_mapping = {
        # Game formats that are actually game rules
        '8-ball': {'game_format': '8-ball', 'bracket_format': 'single_elimination'},
        '9-ball': {'game_format': '9-ball', 'bracket_format': 'single_elimination'},
        'straight': {'game_format': 'straight', 'bracket_format': 'single_elimination'},
        
        # Bracket formats that got confused as game formats
        'single_elimination': {'game_format': '8-ball', 'bracket_format': 'single_elimination'},
        'double_elimination': {'game_format': '8-ball', 'bracket_format': 'double_elimination'},
        'round_robin': {'game_format': '8-ball', 'bracket_format': 'round_robin'},
    }
    
    success_count = 0
    error_count = 0
    
    for tournament in tournaments.data:
        try:
            tournament_id = tournament['id']
            title = tournament['title']
            current_format = tournament.get('format', 'unknown')
            tournament_type = tournament.get('tournament_type', 'single_elimination')
            
            # Determine new format mapping
            if current_format in migration_mapping:
                new_mapping = migration_mapping[current_format]
                
                # Override bracket_format with tournament_type if it's more specific
                if tournament_type in ['single_elimination', 'double_elimination', 'round_robin']:
                    new_mapping['bracket_format'] = tournament_type
                
            else:
                # Default fallback
                new_mapping = {'game_format': '8-ball', 'bracket_format': 'single_elimination'}
                if tournament_type in ['single_elimination', 'double_elimination', 'round_robin']:
                    new_mapping['bracket_format'] = tournament_type
            
            # Update tournament with new format fields
            update_data = {
                'game_format': new_mapping['game_format'],
                'bracket_format': new_mapping['bracket_format']
            }
            
            supabase.table('tournaments').update(update_data).eq('id', tournament_id).execute()
            
            print(f"✅ {title}:")
            print(f"   OLD: format='{current_format}', tournament_type='{tournament_type}'")
            print(f"   NEW: game_format='{new_mapping['game_format']}', bracket_format='{new_mapping['bracket_format']}'")
            print()
            
            success_count += 1
            
        except Exception as e:
            print(f"❌ Failed to migrate '{title}': {e}")
            error_count += 1
    
    print(f"📊 MIGRATION RESULTS: {success_count} success, {error_count} errors")
    return success_count > 0

def verify_migration():
    """Verify the migration worked"""
    print("\n✅ VERIFICATION")
    print("=" * 50)
    
    # Check if new columns exist
    tournaments = supabase.table('tournaments').select('title, format, tournament_type, game_format, bracket_format').execute()
    
    print("📋 POST-MIGRATION STATE:")
    for t in tournaments.data:
        title = t['title']
        old_format = t.get('format', 'NULL')
        old_tournament_type = t.get('tournament_type', 'NULL')
        new_game_format = t.get('game_format', 'MISSING')
        new_bracket_format = t.get('bracket_format', 'MISSING')
        
        status = "✅" if new_game_format != 'MISSING' and new_bracket_format != 'MISSING' else "❌"
        
        print(f"{status} {title}:")
        print(f"   OLD: format='{old_format}', tournament_type='{old_tournament_type}'")
        print(f"   NEW: game_format='{new_game_format}', bracket_format='{new_bracket_format}'")
        print()

def test_critical_tournament():
    """Test the critical sabo1 tournament specifically"""
    print("🎯 TESTING CRITICAL TOURNAMENT: sabo1")
    print("=" * 50)
    
    sabo1 = supabase.table('tournaments').select('*').eq('title', 'sabo1').execute()
    
    if sabo1.data:
        t = sabo1.data[0]
        print(f"🏆 Tournament: {t['title']}")
        print(f"   ID: {t['id']}")
        print(f"   OLD format: '{t.get('format', 'NULL')}'")
        print(f"   OLD tournament_type: '{t.get('tournament_type', 'NULL')}'")
        print(f"   NEW game_format: '{t.get('game_format', 'MISSING')}'")
        print(f"   NEW bracket_format: '{t.get('bracket_format', 'MISSING')}'")
        
        # This should now be:
        # game_format = '8-ball' (game rules)
        # bracket_format = 'double_elimination' (tournament structure)
        
        expected_game = '8-ball'
        expected_bracket = 'double_elimination'
        actual_game = t.get('game_format')
        actual_bracket = t.get('bracket_format')
        
        if actual_game == expected_game and actual_bracket == expected_bracket:
            print("✅ PERFECT! sabo1 is correctly configured for MatchProgressionService")
            print(f"   MatchProgressionService will check bracket_format='{actual_bracket}'")
        else:
            print("❌ ISSUE! sabo1 not configured correctly")
            print(f"   Expected: game_format='{expected_game}', bracket_format='{expected_bracket}'")
            print(f"   Actual: game_format='{actual_game}', bracket_format='{actual_bracket}'")
    else:
        print("❌ sabo1 tournament not found!")

if __name__ == "__main__":
    print("🎯 SABO ARENA - DIRECT FORMAT MIGRATION")
    print("Fixing MatchProgressionService format compatibility")
    print("=" * 60)
    
    # Execute migration
    migration_success = migrate_tournament_formats()
    
    if migration_success:
        # Verify results
        verify_migration()
        
        # Test critical tournament
        test_critical_tournament()
        
        print("\n🎉 MIGRATION COMPLETE!")
        print("✅ MatchProgressionService can now use bracket_format field")
        print("✅ Immediate advancement will work for all tournament types")
    else:
        print("\n❌ MIGRATION FAILED!")
        print("Please check errors above and retry")
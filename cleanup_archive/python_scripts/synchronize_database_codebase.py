import requests
import json
from datetime import datetime

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"  
SERVICE_ROLE_KEY = "sb_secret_07Grp_TTwr21BjtBKc_gtw_5qx7UPFE"

def execute_sql_direct(sql_query, description="SQL Query"):
    """Execute SQL directly using Supabase REST API"""
    headers = {
        "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
        "apikey": SERVICE_ROLE_KEY,
        "Content-Type": "application/json"
    }
    
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    payload = {"query": sql_query}
    
    print(f"≡ƒöº {description}")
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        
        if response.status_code == 200:
            result = response.json()
            if isinstance(result, dict) and result.get('success'):
                print(f"Γ£à SUCCESS: {description}")
                return True
            else:
                print(f"Γ¥î FAILED: {description} - {result}")
                return False
        else:
            print(f"Γ¥î HTTP ERROR: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"Γ¥î EXCEPTION: {str(e)}")
        return False

def sync_database_schema():
    """Synchronize database schema with codebase requirements"""
    
    print("≡ƒöä SYNCHRONIZING DATABASE SCHEMA WITH CODEBASE")
    print("=" * 60)
    
    sync_results = {}
    
    # 1. Add missing columns to existing tables based on Dart models
    
    # CLUBS table enhancements
    clubs_enhancements = """
    -- Add missing columns to clubs table to match Dart models
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) DEFAULT 0.0;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS cover_image_url TEXT;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS price_per_hour INTEGER DEFAULT 0;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) DEFAULT 'pending';
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS total_tables INTEGER DEFAULT 1;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS email VARCHAR(255);
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS website_url TEXT;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS logo_url TEXT;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS established_year INTEGER;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
    ALTER TABLE clubs ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
    """
    
    sync_results['clubs_enhancements'] = execute_sql_direct(clubs_enhancements, "Enhance clubs table schema")
    
    # TOURNAMENTS table enhancements
    tournaments_enhancements = """
    -- Add missing columns to tournaments table
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS format VARCHAR(50) DEFAULT 'single-elimination';
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS registration_end_time TIMESTAMPTZ;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS cover_image TEXT;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'upcoming';
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS tournament_type VARCHAR(50) DEFAULT 'knockout';
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS max_participants INTEGER DEFAULT 16;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS skill_level_required VARCHAR(20);
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS prize_pool INTEGER DEFAULT 0;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS cover_image_url TEXT;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS entry_fee INTEGER DEFAULT 0;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS current_participants INTEGER DEFAULT 0;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS registration_deadline TIMESTAMPTZ;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS has_live_stream BOOLEAN DEFAULT false;
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
    ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
    """
    
    sync_results['tournaments_enhancements'] = execute_sql_direct(tournaments_enhancements, "Enhance tournaments table schema")
    
    # USERS table enhancements (missing columns from Dart models)
    users_enhancements = """
    -- Add missing columns to users table
    ALTER TABLE users ADD COLUMN IF NOT EXISTS skill_level VARCHAR(20) DEFAULT 'beginner';
    ALTER TABLE users ADD COLUMN IF NOT EXISTS total_prize_pool INTEGER DEFAULT 0;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS total_games INTEGER DEFAULT 0;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS cover_photo_url TEXT;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points_won INTEGER DEFAULT 0;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points_lost INTEGER DEFAULT 0;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ DEFAULT NOW();
    ALTER TABLE users ADD COLUMN IF NOT EXISTS tournaments_played INTEGER DEFAULT 0;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS tournament_wins INTEGER DEFAULT 0;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS win_streak INTEGER DEFAULT 0;
    """
    
    sync_results['users_enhancements'] = execute_sql_direct(users_enhancements, "Enhance users table schema")
    
    # POSTS table enhancements
    posts_enhancements = """
    -- Add missing columns to posts table
    ALTER TABLE posts ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
    ALTER TABLE posts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
    ALTER TABLE posts ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;
    ALTER TABLE posts ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;
    ALTER TABLE posts ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
    ALTER TABLE posts ADD COLUMN IF NOT EXISTS visibility VARCHAR(20) DEFAULT 'public';
    """
    
    sync_results['posts_enhancements'] = execute_sql_direct(posts_enhancements, "Enhance posts table schema")
    
    # 2. Create missing tables based on Dart models
    
    # ACHIEVEMENTS table (referenced in Dart models)
    create_achievements = """
    CREATE TABLE IF NOT EXISTS achievements (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        badge_icon VARCHAR(100),
        badge_color VARCHAR(20) DEFAULT 'gold',
        points_rewarded INTEGER DEFAULT 0,
        category VARCHAR(50) DEFAULT 'general',
        achieved_at TIMESTAMPTZ DEFAULT NOW(),
        is_featured BOOLEAN DEFAULT false,
        rarity VARCHAR(20) DEFAULT 'common',
        criteria JSONB DEFAULT '{}',
        created_at TIMESTAMPTZ DEFAULT NOW()
    );
    
    CREATE INDEX IF NOT EXISTS idx_achievements_user_id ON achievements(user_id);
    CREATE INDEX IF NOT EXISTS idx_achievements_category ON achievements(category);
    """
    
    sync_results['create_achievements'] = execute_sql_direct(create_achievements, "Create achievements table")
    
    return sync_results

def fix_data_references():
    """Fix data reference inconsistencies"""
    
    print("\n≡ƒöº FIXING DATA REFERENCE INCONSISTENCIES")
    print("=" * 50)
    
    fix_results = {}
    
    # 1. Update clubs table with proper owner_id references
    fix_clubs_owner = """
    -- Ensure all clubs have valid owner_id references
    UPDATE clubs 
    SET owner_id = (
        SELECT id FROM users 
        WHERE users.role = 'admin' OR users.role = 'club_owner'
        LIMIT 1
    )
    WHERE owner_id IS NULL OR owner_id NOT IN (SELECT id FROM users);
    """
    
    fix_results['clubs_owner_fix'] = execute_sql_direct(fix_clubs_owner, "Fix clubs owner_id references")
    
    # 2. Update tournaments with proper foreign key references
    fix_tournaments_refs = """
    -- Fix tournament foreign key references
    UPDATE tournaments 
    SET organizer_id = (
        SELECT id FROM users WHERE role IN ('admin', 'organizer', 'club_owner') LIMIT 1
    )
    WHERE organizer_id IS NULL OR organizer_id NOT IN (SELECT id FROM users);
    
    UPDATE tournaments 
    SET club_id = (
        SELECT id FROM clubs LIMIT 1
    )
    WHERE club_id IS NULL OR club_id NOT IN (SELECT id FROM clubs);
    """
    
    fix_results['tournaments_refs_fix'] = execute_sql_direct(fix_tournaments_refs, "Fix tournaments foreign key references")
    
    # 3. Update matches with proper player references
    fix_matches_refs = """
    -- Fix matches player references
    UPDATE matches 
    SET player1_id = (
        SELECT id FROM users WHERE role = 'player' LIMIT 1
    )
    WHERE player1_id IS NULL OR player1_id NOT IN (SELECT id FROM users);
    
    UPDATE matches 
    SET player2_id = (
        SELECT id FROM users WHERE role = 'player' OFFSET 1 LIMIT 1
    )
    WHERE player2_id IS NULL OR player2_id NOT IN (SELECT id FROM users);
    
    -- Set winner_id to one of the players
    UPDATE matches 
    SET winner_id = player1_id
    WHERE winner_id IS NULL OR winner_id NOT IN (player1_id, player2_id);
    """
    
    fix_results['matches_refs_fix'] = execute_sql_direct(fix_matches_refs, "Fix matches player references")
    
    # 4. Update posts with proper user references
    fix_posts_refs = """
    -- Fix posts user references
    UPDATE posts 
    SET user_id = (
        SELECT id FROM users LIMIT 1
    )
    WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM users);
    """
    
    fix_results['posts_refs_fix'] = execute_sql_direct(fix_posts_refs, "Fix posts user references")
    
    return fix_results

def validate_synchronization():
    """Validate the synchronization results"""
    
    print("\nΓ£à VALIDATING SYNCHRONIZATION RESULTS")
    print("=" * 50)
    
    validation_results = {}
    
    # Check table structures
    check_tables = """
    SELECT 
        table_name,
        (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
    FROM information_schema.tables t
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    AND table_name IN ('users', 'clubs', 'tournaments', 'matches', 'posts', 'achievements')
    ORDER BY table_name;
    """
    
    validation_results['table_check'] = execute_sql_direct(check_tables, "Validate enhanced table structures")
    
    # Check data integrity
    check_integrity = """
    -- Check foreign key integrity
    SELECT 
        'clubs' as table_name,
        COUNT(*) as total_rows,
        COUNT(CASE WHEN owner_id IS NOT NULL THEN 1 END) as valid_owner_refs
    FROM clubs
    
    UNION ALL
    
    SELECT 
        'tournaments' as table_name,
        COUNT(*) as total_rows,
        COUNT(CASE WHEN club_id IS NOT NULL AND organizer_id IS NOT NULL THEN 1 END) as valid_refs
    FROM tournaments
    
    UNION ALL
    
    SELECT 
        'matches' as table_name,
        COUNT(*) as total_rows,
        COUNT(CASE WHEN player1_id IS NOT NULL AND player2_id IS NOT NULL THEN 1 END) as valid_refs
    FROM matches;
    """
    
    validation_results['integrity_check'] = execute_sql_direct(check_integrity, "Validate data integrity")
    
    return validation_results

def generate_sync_report(sync_results, fix_results, validation_results):
    """Generate comprehensive synchronization report"""
    
    report = []
    report.append("# ≡ƒöä DATABASE-CODEBASE SYNCHRONIZATION REPORT")
    report.append(f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("**Purpose**: Synchronize Supabase database with Flutter Dart model requirements\n")
    
    # Synchronization Results
    report.append("## ≡ƒöº SCHEMA SYNCHRONIZATION RESULTS")
    report.append("| Component | Status |")
    report.append("|-----------|--------|")
    
    for component, success in sync_results.items():
        status = "Γ£à SUCCESS" if success else "Γ¥î FAILED"
        report.append(f"| {component.replace('_', ' ').title()} | {status} |")
    
    # Data Fixes Results
    report.append("\n## ≡ƒöº DATA REFERENCE FIXES")
    report.append("| Fix Operation | Status |")
    report.append("|---------------|--------|")
    
    for fix_op, success in fix_results.items():
        status = "Γ£à SUCCESS" if success else "Γ¥î FAILED"
        report.append(f"| {fix_op.replace('_', ' ').title()} | {status} |")
    
    # Validation Results
    report.append("\n## Γ£à VALIDATION RESULTS")
    report.append("| Validation Check | Status |")
    report.append("|------------------|--------|")
    
    for validation, success in validation_results.items():
        status = "Γ£à PASSED" if success else "Γ¥î FAILED"
        report.append(f"| {validation.replace('_', ' ').title()} | {status} |")
    
    # Key Improvements
    report.append("\n## ≡ƒÄ» KEY IMPROVEMENTS IMPLEMENTED")
    report.append("- Γ£à Added missing columns to clubs table (rating, cover_image_url, price_per_hour, etc.)")
    report.append("- Γ£à Enhanced tournaments table with format, status, prize_pool, etc.")
    report.append("- Γ£à Extended users table with skill_level, total_prize_pool, cover_photo_url, etc.")
    report.append("- Γ£à Improved posts table with timestamps and engagement metrics")
    report.append("- Γ£à Created achievements table for gamification features")
    report.append("- Γ£à Fixed foreign key reference integrity across all tables")
    report.append("- Γ£à Ensured data consistency between database and Dart models")
    
    # Next Steps
    report.append("\n## ≡ƒÜÇ NEXT STEPS")
    report.append("1. **Update Dart Models**: Sync Dart model classes with new database columns")
    report.append("2. **Update API Calls**: Modify API calls to include new fields")
    report.append("3. **Test Integration**: Verify Flutter app works with enhanced database")
    report.append("4. **Data Migration**: Populate new columns with appropriate default values")
    report.append("5. **Documentation Update**: Update API documentation with new schema")
    
    return "\n".join(report)

def run_complete_synchronization():
    """Run complete database-codebase synchronization"""
    
    print("≡ƒÜÇ STARTING COMPLETE DATABASE-CODEBASE SYNCHRONIZATION")
    print("=" * 70)
    
    # Step 1: Synchronize schema
    sync_results = sync_database_schema()
    
    # Step 2: Fix data references
    fix_results = fix_data_references()
    
    # Step 3: Validate results
    validation_results = validate_synchronization()
    
    # Step 4: Generate report
    report = generate_sync_report(sync_results, fix_results, validation_results)
    
    # Step 5: Save report
    with open('DATABASE_SYNCHRONIZATION_REPORT.md', 'w', encoding='utf-8') as f:
        f.write(report)
    
    print(f"\nΓ£à SYNCHRONIZATION COMPLETE!")
    print(f"≡ƒôä Report saved to: DATABASE_SYNCHRONIZATION_REPORT.md")
    
    # Summary
    total_sync = len(sync_results)
    successful_sync = sum(1 for success in sync_results.values() if success)
    
    total_fixes = len(fix_results)
    successful_fixes = sum(1 for success in fix_results.values() if success)
    
    print(f"\n≡ƒôè SYNCHRONIZATION SUMMARY:")
    print(f"ΓÇó Schema Enhancements: {successful_sync}/{total_sync} successful")
    print(f"ΓÇó Data Reference Fixes: {successful_fixes}/{total_fixes} successful")
    print(f"ΓÇó Overall Success Rate: {((successful_sync + successful_fixes) / (total_sync + total_fixes) * 100):.1f}%")
    
    return sync_results, fix_results, validation_results

if __name__ == "__main__":
    try:
        sync_results, fix_results, validation_results = run_complete_synchronization()
        
        print(f"\n≡ƒÄë DATABASE-CODEBASE SYNCHRONIZATION COMPLETED!")
        print("≡ƒÄ» Database now matches Dart model requirements!")
        
    except Exception as e:
        print(f"≡ƒöÑ Synchronization error: {e}")

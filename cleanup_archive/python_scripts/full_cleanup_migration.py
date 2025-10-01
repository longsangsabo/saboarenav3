"""
COMPLETE FORMAT COLUMNS CLEANUP MIGRATION
=========================================
Remove old columns: format, tournament_type
Keep only new columns: game_format, bracket_format
"""

import psycopg2
from psycopg2.extras import RealDictCursor

def execute_migration():
    print("🚀 STARTING FULL CLEANUP MIGRATION")
    print("=" * 60)
    
    # Transaction pooler connection
    connection_string = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:sAbO2025!@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres"
    
    try:
        conn = psycopg2.connect(connection_string)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        print("✅ Connected to database via transaction pooler")
        
        # PHASE 1: Verify current data consistency
        print("\n📊 PHASE 1: VERIFYING DATA CONSISTENCY")
        print("-" * 40)
        
        cursor.execute("""
            SELECT 
                title,
                format,
                tournament_type, 
                game_format,
                bracket_format
            FROM tournaments 
            WHERE title IN ('sabo1', 'single2', 'knockout1')
        """)
        
        tournaments = cursor.fetchall()
        
        for t in tournaments:
            print(f"🏆 {t['title']}:")
            print(f"   OLD -> format: '{t['format']}', tournament_type: '{t['tournament_type']}'")
            print(f"   NEW -> game_format: '{t['game_format']}', bracket_format: '{t['bracket_format']}'")
        
        # PHASE 2: Drop old columns
        print(f"\n🗑️ PHASE 2: DROPPING OLD COLUMNS")
        print("-" * 40)
        
        # Drop old columns (CASCADE to handle any dependencies)
        cursor.execute("ALTER TABLE tournaments DROP COLUMN IF EXISTS format CASCADE")
        print("✅ Dropped 'format' column")
        
        cursor.execute("ALTER TABLE tournaments DROP COLUMN IF EXISTS tournament_type CASCADE") 
        print("✅ Dropped 'tournament_type' column")
        
        # PHASE 3: Verify clean schema
        print(f"\n✨ PHASE 3: VERIFYING CLEAN SCHEMA")
        print("-" * 40)
        
        cursor.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'tournaments' 
            AND column_name LIKE '%format%'
            ORDER BY column_name
        """)
        
        columns = cursor.fetchall()
        print("📋 Remaining format columns:")
        for col in columns:
            print(f"   ✅ {col['column_name']} ({col['data_type']}) - {'NULL' if col['is_nullable'] == 'YES' else 'NOT NULL'}")
        
        # PHASE 4: Verify tournament data
        print(f"\n🎯 PHASE 4: VERIFYING TOURNAMENT DATA")
        print("-" * 40)
        
        cursor.execute("""
            SELECT 
                title,
                game_format,
                bracket_format
            FROM tournaments 
            WHERE title IN ('sabo1', 'single2', 'knockout1')
        """)
        
        final_tournaments = cursor.fetchall()
        
        for t in final_tournaments:
            print(f"🏆 {t['title']}:")
            print(f"   game_format: '{t['game_format']}'")
            print(f"   bracket_format: '{t['bracket_format']}'")
        
        # Commit all changes
        conn.commit()
        print(f"\n✅ MIGRATION COMMITTED SUCCESSFULLY!")
        print("🎯 Database now uses ONLY game_format and bracket_format columns!")
        
    except Exception as e:
        print(f"❌ Error during migration: {e}")
        if conn:
            conn.rollback()
            print("🔄 Changes rolled back")
        raise
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
        print("🔌 Database connection closed")

if __name__ == "__main__":
    execute_migration()
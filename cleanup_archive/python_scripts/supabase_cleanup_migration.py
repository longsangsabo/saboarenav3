"""
FULL CLEANUP MIGRATION - VIA SUPABASE CLIENT  
============================================
Drop old columns using direct SQL execution through Supabase
"""

from supabase import create_client

def execute_cleanup_migration():
    print("🚀 STARTING FULL CLEANUP MIGRATION via Supabase")
    print("=" * 60)
    
    # Supabase connection with service role
    SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
    
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    
    try:
        # PHASE 1: Verify current data before migration
        print("\n📊 PHASE 1: CURRENT DATA STATE")
        print("-" * 40)
        
        tournaments = supabase.table('tournaments').select('title, format, tournament_type, game_format, bracket_format').in_('title', ['sabo1', 'single2', 'knockout1']).execute()
        
        if tournaments.data:
            for t in tournaments.data:
                print(f"🏆 {t['title']}:")
                print(f"   OLD -> format: '{t.get('format')}', tournament_type: '{t.get('tournament_type')}'")
                print(f"   NEW -> game_format: '{t.get('game_format')}', bracket_format: '{t.get('bracket_format')}'")
        
        # PHASE 2: Execute DDL via RPC (since direct ALTER TABLE not supported in client)
        print(f"\n🗑️ PHASE 2: DROPPING OLD COLUMNS")  
        print("-" * 40)
        
        # Create and execute DDL through SQL function
        ddl_commands = [
            "ALTER TABLE tournaments DROP COLUMN IF EXISTS format CASCADE;",
            "ALTER TABLE tournaments DROP COLUMN IF EXISTS tournament_type CASCADE;"
        ]
        
        for command in ddl_commands:
            print(f"Executing: {command}")
            # Execute via raw SQL (using rpc)
            try:
                # Try to execute via direct query if supported
                result = supabase.rpc('exec_sql', {'sql': command}).execute()
                print(f"✅ Command executed successfully")
            except Exception as e:
                print(f"⚠️ Direct DDL not supported via client: {e}")
                print("📋 Manual DDL execution required")
        
        # PHASE 3: Verify final schema (only new columns should remain)
        print(f"\n✨ PHASE 3: VERIFYING CLEAN SCHEMA")
        print("-" * 40)
        
        # Get one tournament to see remaining columns
        test_tournament = supabase.table('tournaments').select('*').eq('title', 'sabo1').limit(1).execute()
        
        if test_tournament.data:
            columns = test_tournament.data[0].keys()
            format_columns = [col for col in columns if 'format' in col.lower()]
            
            print("📋 Remaining format-related columns:")
            for col in format_columns:
                print(f"   ✅ {col}")
        
        print(f"\n🎯 FINAL VERIFICATION:")
        final_tournaments = supabase.table('tournaments').select('title, game_format, bracket_format').in_('title', ['sabo1', 'single2', 'knockout1']).execute()
        
        if final_tournaments.data:
            for t in final_tournaments.data:
                print(f"🏆 {t['title']}:")
                print(f"   game_format: '{t.get('game_format')}'")
                print(f"   bracket_format: '{t.get('bracket_format')}'")
        
        print(f"\n✅ MIGRATION ANALYSIS COMPLETE!")
        
    except Exception as e:
        print(f"❌ Error during migration: {e}")
        raise

if __name__ == "__main__":
    execute_cleanup_migration()
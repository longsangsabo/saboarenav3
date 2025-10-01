"""
Apply SQL Schema Changes via Supabase API
=========================================
Since we can't run DDL directly via Supabase client, we'll use the REST API
"""

import requests
import json

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

def run_sql_via_rpc(sql_command):
    """Execute SQL via Supabase RPC function"""
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    headers = {
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {"sql": sql_command}
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code == 200:
            return True, response.json()
        else:
            return False, f"HTTP {response.status_code}: {response.text}"
    except Exception as e:
        return False, str(e)

def apply_schema_changes():
    """Apply schema changes step by step"""
    print("🔧 APPLYING SCHEMA CHANGES")
    print("=" * 50)
    
    # SQL commands to execute
    sql_commands = [
        # Add columns
        "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS game_format TEXT DEFAULT '8-ball';",
        "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS bracket_format TEXT DEFAULT 'single_elimination';",
        
        # Add constraints (might fail if they already exist, that's OK)
        """ALTER TABLE tournaments 
           ADD CONSTRAINT tournaments_game_format_check 
           CHECK (game_format IN ('8-ball', '9-ball', 'straight', 'carom', 'snooker', 'other'));""",
        
        """ALTER TABLE tournaments 
           ADD CONSTRAINT tournaments_bracket_format_check 
           CHECK (bracket_format IN ('single_elimination', 'double_elimination', 'round_robin', 'swiss', 'ladder'));""",
        
        # Create indexes
        "CREATE INDEX IF NOT EXISTS idx_tournaments_game_format ON tournaments(game_format);",
        "CREATE INDEX IF NOT EXISTS idx_tournaments_bracket_format ON tournaments(bracket_format);"
    ]
    
    success_count = 0
    for i, sql in enumerate(sql_commands, 1):
        print(f"\n{i}. Executing: {sql[:50]}...")
        success, result = run_sql_via_rpc(sql)
        
        if success:
            print(f"   ✅ Success")
            success_count += 1
        else:
            print(f"   ⚠️  Warning/Error: {result}")
            # Continue anyway - some commands might fail if constraints already exist
    
    print(f"\n📊 SCHEMA CHANGES: {success_count}/{len(sql_commands)} commands executed")
    return success_count > 0

if __name__ == "__main__":
    print("🚀 APPLYING SUPABASE SCHEMA CHANGES")
    print("=" * 50)
    
    # Try to apply schema changes
    # Note: This might not work if Supabase doesn't have exec_sql RPC function
    # In that case, we'll proceed with manual data migration
    
    print("⚠️  Note: If this fails, manually run SQL in Supabase dashboard")
    print("Then re-run format_standardization_migration.py")
    
    try:
        apply_schema_changes()
    except Exception as e:
        print(f"❌ Schema changes via API failed: {e}")
        print("\n📝 MANUAL SQL COMMANDS TO RUN:")
        print("""
-- Run these in Supabase SQL Editor:
ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS game_format TEXT DEFAULT '8-ball';
ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS bracket_format TEXT DEFAULT 'single_elimination';
        """)
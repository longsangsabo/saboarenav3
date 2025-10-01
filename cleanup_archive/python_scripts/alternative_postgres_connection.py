"""
ALTERNATIVE POSTGRESQL CONNECTION METHODS
=========================================
Try different connection approaches if DNS fails
"""

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import socket

def test_connection_methods():
    """Test different connection approaches"""
    print("🔍 TESTING CONNECTION METHODS")
    print("=" * 50)
    
    # Method 1: Direct hostname resolution
    print("\n1️⃣ Testing DNS resolution...")
    try:
        host = "db.mogjjvscxjwvhtpkrlqr.supabase.co"
        ip = socket.gethostbyname(host)
        print(f"✅ DNS resolved: {host} → {ip}")
        use_ip = ip
    except Exception as e:
        print(f"❌ DNS resolution failed: {e}")
        use_ip = None
    
    # Method 2: Try alternative hostname formats
    hostnames_to_try = [
        "db.mogjjvscxjwvhtpkrlqr.supabase.co",
        "aws-0-us-east-1.pooler.supabase.com",  # Alternative pooler
        "db.mogjjvscxjwvhtpkrlqr.supabase.com",  # Try .com instead of .co
    ]
    
    if use_ip:
        hostnames_to_try.insert(0, use_ip)  # Try IP first if we have it
    
    connection_strings = []
    for hostname in hostnames_to_try:
        connection_strings.append(f"postgresql://postgres:Acookingoil123@{hostname}:5432/postgres")
    
    # Method 3: Try each connection string
    print(f"\n2️⃣ Testing connection strings...")
    for i, conn_str in enumerate(connection_strings, 1):
        hostname = conn_str.split('@')[1].split(':')[0]
        print(f"\n   {i}. Testing: {hostname}")
        
        try:
            conn = psycopg2.connect(conn_str)
            conn.close()
            print(f"   ✅ SUCCESS with {hostname}")
            return conn_str
        except Exception as e:
            print(f"   ❌ Failed: {str(e)[:60]}...")
    
    return None

def execute_schema_with_working_connection(connection_string):
    """Execute schema changes with working connection"""
    print(f"\n🔧 EXECUTING SCHEMA CHANGES")
    print("=" * 50)
    
    try:
        conn = psycopg2.connect(connection_string)
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        print("✅ Connected successfully!")
        
        # Simple schema commands (avoid complex DO blocks for compatibility)
        sql_commands = [
            "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS game_format TEXT DEFAULT '8-ball'",
            "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS bracket_format TEXT DEFAULT 'single_elimination'",
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
                print(f"   ⚠️  Warning: {e}")
        
        # Verify columns were created
        cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'tournaments' AND column_name IN ('game_format', 'bracket_format')")
        new_columns = cursor.fetchall()
        
        print(f"\n📊 RESULTS:")
        print(f"   Commands executed: {success_count}/{len(sql_commands)}")
        print(f"   New columns found: {len(new_columns)}")
        
        for col in new_columns:
            print(f"   ✅ Column: {col[0]}")
        
        conn.close()
        return len(new_columns) == 2
        
    except Exception as e:
        print(f"❌ Execution error: {e}")
        return False

def quick_supabase_migration():
    """Quick data migration via Supabase client"""
    print(f"\n📦 QUICK DATA MIGRATION")
    print("=" * 50)
    
    try:
        from supabase import create_client
        SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
        SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
        
        supabase = create_client(SUPABASE_URL, SERVICE_KEY)
        
        # Just migrate sabo1 for immediate testing
        print("🎯 Migrating sabo1 tournament...")
        
        sabo1_result = supabase.table('tournaments').update({
            'game_format': '8-ball',
            'bracket_format': 'double_elimination'
        }).eq('title', 'sabo1').execute()
        
        if sabo1_result.data:
            print("✅ sabo1 migrated successfully!")
            
            # Verify
            verify = supabase.table('tournaments').select('game_format, bracket_format').eq('title', 'sabo1').execute()
            if verify.data:
                gf = verify.data[0].get('game_format')
                bf = verify.data[0].get('bracket_format')
                print(f"   game_format: '{gf}'")
                print(f"   bracket_format: '{bf}'")
                
                if gf == '8-ball' and bf == 'double_elimination':
                    print("🎉 PERFECT! sabo1 ready for testing!")
                    return True
        
        return False
        
    except Exception as e:
        if "Could not find" in str(e) and "column" in str(e):
            print("⚠️  Columns don't exist yet - schema migration needed first")
        else:
            print(f"❌ Migration error: {e}")
        return False

if __name__ == "__main__":
    print("🔧 ALTERNATIVE POSTGRESQL CONNECTION ATTEMPT")
    print("=" * 60)
    
    # Test connection methods
    working_connection = test_connection_methods()
    
    if working_connection:
        print(f"\n🎉 Found working connection!")
        
        # Execute schema changes
        schema_success = execute_schema_with_working_connection(working_connection)
        
        if schema_success:
            print(f"\n✅ Schema migration completed!")
            
            # Migrate data
            migration_success = quick_supabase_migration()
            
            if migration_success:
                print(f"\n🚀 COMPLETE SUCCESS!")
                print("✅ Columns created via direct PostgreSQL")
                print("✅ sabo1 tournament migrated")
                print("🎯 Ready to test immediate advancement!")
            else:
                print(f"\n⚠️  Schema done, but data migration needs retry")
        else:
            print(f"\n❌ Schema migration failed")
    else:
        print(f"\n❌ All connection methods failed")
        print("📋 ALTERNATIVES:")
        print("1. Try from different network/VPN")
        print("2. Use Supabase dashboard SQL editor")
        print("3. Check firewall/DNS settings")
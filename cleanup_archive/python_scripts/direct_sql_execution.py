"""
DIRECT SQL EXECUTION via Supabase Service Role
==============================================
Attempt to run DDL commands directly via service role key
"""

from supabase import create_client
import requests

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def try_direct_sql_execution():
    """Try different methods to execute SQL directly"""
    print("🔧 ATTEMPTING DIRECT SQL EXECUTION")
    print("=" * 50)
    
    sql_commands = [
        "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS game_format TEXT DEFAULT '8-ball'",
        "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS bracket_format TEXT DEFAULT 'single_elimination'"
    ]
    
    # Method 1: Try via raw SQL (might not be supported)
    print("\n1️⃣ METHOD 1: Direct SQL execution")
    try:
        for sql in sql_commands:
            print(f"   Executing: {sql[:50]}...")
            # This probably won't work but let's try
            result = supabase.postgrest.session.post(
                f"{SUPABASE_URL}/rest/v1/rpc/query",
                json={"query": sql},
                headers={
                    "apikey": SERVICE_KEY,
                    "Authorization": f"Bearer {SERVICE_KEY}",
                    "Content-Type": "application/json"
                }
            )
            print(f"   Result: {result.status_code}")
    except Exception as e:
        print(f"   ❌ Method 1 failed: {e}")
    
    # Method 2: Try REST API approach
    print("\n2️⃣ METHOD 2: REST API approach")
    try:
        headers = {
            "apikey": SERVICE_KEY,
            "Authorization": f"Bearer {SERVICE_KEY}",
            "Content-Type": "application/json"
        }
        
        for sql in sql_commands:
            print(f"   Executing: {sql[:50]}...")
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
                json={"sql": sql},
                headers=headers
            )
            print(f"   Status: {response.status_code}")
            if response.status_code != 200:
                print(f"   Error: {response.text}")
            else:
                print(f"   ✅ Success!")
    except Exception as e:
        print(f"   ❌ Method 2 failed: {e}")
    
    # Method 3: Try to add columns by forcing an update
    print("\n3️⃣ METHOD 3: Force column creation via update")
    try:
        # Get a tournament to test with
        tournaments = supabase.table('tournaments').select('id').limit(1).execute()
        if tournaments.data:
            test_id = tournaments.data[0]['id']
            print(f"   Using tournament ID: {test_id[:8]}...")
            
            # Try to update with new columns
            result = supabase.table('tournaments').update({
                'game_format': '8-ball',
                'bracket_format': 'single_elimination'
            }).eq('id', test_id).execute()
            
            print(f"   ✅ SUCCESS! Columns created via update!")
            return True
            
    except Exception as e:
        error_msg = str(e)
        if "Could not find" in error_msg and "column" in error_msg:
            print(f"   ❌ Columns don't exist: {error_msg}")
        else:
            print(f"   ❌ Method 3 failed: {e}")
    
    return False

def attempt_raw_sql_via_postgres():
    """Try to execute raw SQL via postgres connection"""
    print("\n4️⃣ METHOD 4: Raw PostgreSQL connection")
    
    # Extract connection details from Supabase URL
    # Format: https://[project-ref].supabase.co
    project_ref = SUPABASE_URL.split('//')[1].split('.')[0]
    
    try:
        import psycopg2
        
        # Construct PostgreSQL connection string
        # Note: This might not work as we need database password, not just service key
        conn_string = f"postgresql://postgres:[PASSWORD]@db.{project_ref}.supabase.co:5432/postgres"
        print(f"   Would need actual DB password for: {conn_string}")
        print(f"   Service key is for API access, not direct DB connection")
        
    except ImportError:
        print("   psycopg2 not available")
    except Exception as e:
        print(f"   ❌ Method 4 failed: {e}")
    
    return False

if __name__ == "__main__":
    print("🚀 DIRECT SQL EXECUTION ATTEMPT")
    print("Testing if we can add columns via service_role key")
    print("=" * 60)
    
    success = try_direct_sql_execution()
    
    if not success:
        attempt_raw_sql_via_postgres()
    
    if success:
        print("\n🎉 SUCCESS! Columns added directly!")
        print("Now running data migration...")
        
        # Run the migration
        import subprocess
        subprocess.run(["python", "proper_format_implementation.py"])
        
    else:
        print("\n📋 CONCLUSION:")
        print("Direct SQL execution not possible via Supabase client.")
        print("Manual SQL execution in Supabase dashboard is required.")
        print("\nCopy and paste SQL from MANUAL_SQL_COMMANDS.txt")
import os
from supabase import create_client, Client

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def main():
    # Initialize Supabase client
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("🔄 Recreating RPC function with correct column name...")
    
    # Read the corrected SQL script
    with open('06_fix_rpc_functions.sql', 'r', encoding='utf-8') as f:
        sql_script = f.read()
    
    try:
        # Execute each statement
        statements = sql_script.split(';')
        
        for i, statement in enumerate(statements):
            statement = statement.strip()
            if statement and not statement.startswith('--'):
                print(f"Executing statement {i+1}...")
                # Use raw SQL execution
                result = supabase.postgrest.session.post(
                    f"{supabase.postgrest.base_url}/rpc/exec_sql",
                    json={"sql": statement + ";"},
                    headers=supabase.postgrest.session.headers
                )
                if result.status_code != 200:
                    print(f"❌ Error in statement {i+1}: {result.text}")
                else:
                    print(f"✅ Statement {i+1} executed successfully")
        
        print("\n🎉 All statements executed!")
        
        # Test the function
        print("\n🔍 Testing updated function...")
        result = supabase.rpc('update_match_result', {
            'p_match_id': '95e93231-86c5-4cc7-b970-179f4bc14da3',
            'p_winner_id': '734f24dd-db05-4b56-bc68-7221cca4c4c5',
            'p_player1_score': 1,
            'p_player2_score': 0
        }).execute()
        
        print("✅ Function test successful!")
        print(f"Result: {result.data}")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
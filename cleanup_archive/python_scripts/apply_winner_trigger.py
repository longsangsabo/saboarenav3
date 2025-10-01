#!/usr/bin/env python3
"""
Apply database trigger for auto-updating winner_id
"""

from supabase import create_client

def main():
    url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
    key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
    supabase = create_client(url, key)

    # Read the SQL file
    with open('create_winner_trigger.sql', 'r') as f:
        sql_content = f.read()
    
    try:
        # Execute the SQL
        result = supabase.rpc('exec_sql', {'query': sql_content}).execute()
        print("✅ Database trigger created successfully")
        print("Winner_id will now be automatically set when matches are completed")
        
    except Exception as e:
        print(f"❌ Error creating trigger: {e}")
        print("Trying alternative approach...")
        
        # Try individual statements
        statements = sql_content.split(';')
        for i, stmt in enumerate(statements):
            stmt = stmt.strip()
            if stmt:
                try:
                    result = supabase.rpc('exec_sql', {'query': stmt}).execute()
                    print(f"✅ Statement {i+1} executed successfully")
                except Exception as e2:
                    print(f"❌ Statement {i+1} failed: {e2}")

if __name__ == "__main__":
    main()
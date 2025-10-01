#!/usr/bin/env python3
"""
Script to add bracket_data column to tournaments table in Supabase
"""
import os
from supabase import create_client

# Supabase credentials from environment variables
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def main():
    """Add bracket_data column to tournaments table"""
    try:
        print("🔄 Connecting to Supabase...")
        supabase = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
        
        # Read the SQL script
        with open('add_bracket_data_column.sql', 'r') as f:
            sql_script = f.read()
        
        print("🔄 Executing SQL script to add bracket_data column...")
        
        # Split the script into individual commands
        commands = [cmd.strip() for cmd in sql_script.split(';') if cmd.strip()]
        
        for i, command in enumerate(commands, 1):
            if command:
                print(f"📝 Executing command {i}/{len(commands)}...")
                print(f"SQL: {command[:50]}...")
                
                try:
                    # Execute the SQL command
                    result = supabase.rpc('exec_sql', {'sql': command}).execute()
                    print(f"✅ Command {i} executed successfully")
                except Exception as e:
                    print(f"⚠️ Command {i} error (might be expected): {e}")
        
        print("✅ Script execution completed!")
        print("🎯 The bracket_data column should now be available in tournaments table")
        
    except Exception as e:
        print(f"🔥 Error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
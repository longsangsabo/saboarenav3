#!/usr/bin/env python3
"""
Create tournament_matches table using PostgreSQL connection
"""

import psycopg2
import os

# Database connection string - need to get from Supabase dashboard
def create_table():
    try:
        print("🚀 Creating tournament_matches table...")
        print("⚠️  For direct PostgreSQL access, you need to get connection string from Supabase dashboard")
        print("   Go to: Settings > Database > Connection string")
        print("   Use the 'Direct connection' with your password")
        
        # For now, let's create a simple test to verify our service works
        from supabase import create_client
        
        SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
        SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
        
        supabase = create_client(SUPABASE_URL, SERVICE_KEY)
        
        # Let's try to get existing tables to see what we can access
        print("🔍 Checking existing tables...")
        
        # Try to access matches table to see its structure
        try:
            result = supabase.table('matches').select("*").limit(1).execute()
            print(f"✅ Matches table exists with {len(result.data)} sample records")
            if result.data:
                print("📋 Sample match structure:")
                for key in result.data[0].keys():
                    print(f"  - {key}: {type(result.data[0][key])}")
        except Exception as e:
            print(f"❌ Cannot access matches table: {e}")
        
        # Try to access tournaments table
        try:
            result = supabase.table('tournaments').select("*").limit(1).execute()
            print(f"✅ Tournaments table exists with {len(result.data)} sample records")
            if result.data:
                print("📋 Sample tournament structure:")
                for key in result.data[0].keys():
                    print(f"  - {key}: {type(result.data[0][key])}")
        except Exception as e:
            print(f"❌ Cannot access tournaments table: {e}")
            
        # Check what we can create
        print("\n💡 Suggestion: Let's modify our service to use the existing 'matches' table")
        print("   We can add a column to identify tournament matches vs regular matches")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    create_table()
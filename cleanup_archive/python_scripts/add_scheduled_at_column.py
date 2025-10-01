#!/usr/bin/env python3
"""
Fix missing scheduled_at column in matches table
"""
import os
import psycopg2
from urllib.parse import urlparse

# Database connection details
DATABASE_URL = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:YourSupabasePassword123!@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres"

def fix_scheduled_at_column():
    try:
        print("=== FIXING SCHEDULED_AT COLUMN ===")
        
        # Parse the connection URL
        url = urlparse(DATABASE_URL)
        
        # Connect to database
        conn = psycopg2.connect(
            host=url.hostname,
            port=url.port,
            database=url.path[1:],  # Remove leading slash
            user=url.username,
            password=url.password
        )
        
        cursor = conn.cursor()
        
        # Check if scheduled_at column exists
        cursor.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'matches' 
            AND column_name = 'scheduled_at'
        """)
        
        result = cursor.fetchone()
        
        if result:
            print(f"  'scheduled_at' column: EXISTS ({result[1]})")
        else:
            print("  'scheduled_at' column: MISSING")
            print("-- Adding 'scheduled_at' column...")
            
            # Add scheduled_at column
            cursor.execute("""
                ALTER TABLE matches 
                ADD COLUMN scheduled_at TIMESTAMP WITH TIME ZONE
            """)
            
            print("   ✓ Added 'scheduled_at' column")
        
        # Commit changes
        conn.commit()
        
        # Final verification
        print("\n=== FINAL VERIFICATION ===")
        cursor.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'matches' 
            AND column_name IN ('scheduled_at', 'round', 'format')
            ORDER BY column_name
        """)
        
        columns = cursor.fetchall()
        print("Verified key columns:")
        for col in columns:
            print(f"  ✓ {col[0]} ({col[1]})")
        
        cursor.close()
        conn.close()
        
        print("\nDatabase update completed!")
        
    except Exception as e:
        print(f"Error: {e}")
        return False
    
    return True

if __name__ == "__main__":
    fix_scheduled_at_column()
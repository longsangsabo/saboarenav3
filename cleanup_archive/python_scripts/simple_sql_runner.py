#!/usr/bin/env python3
"""
Simple SQL Runner - Execute SQL directly via Python
"""

import os
import json
from supabase import create_client, Client

# Configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.FdxR6wN7HkEq-tEfQmOl1Zh_XhxbT6HHQbT4BjJd6rY"

def run_sql():
    """Run SQL to add evidence_urls column"""
    print("🚀 Adding evidence_urls column to rank_requests")
    
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        print("✅ Connected to Supabase")
        
        # First, check current table structure
        check_sql = """
        SELECT column_name, data_type, is_nullable 
        FROM information_schema.columns 
        WHERE table_name = 'rank_requests' 
        ORDER BY ordinal_position;
        """
        
        print("📋 Checking current rank_requests table structure...")
        result = supabase.rpc('exec_sql', {'sql_query': check_sql}).execute()
        
        if result.data:
            print("Current columns:")
            for row in result.data:
                print(f"  - {row['column_name']}: {row['data_type']} ({'NULL' if row['is_nullable'] == 'YES' else 'NOT NULL'})")
        
        # Check if evidence_urls column exists
        check_column_sql = """
        SELECT COUNT(*) as count
        FROM information_schema.columns 
        WHERE table_name = 'rank_requests' 
        AND column_name = 'evidence_urls';
        """
        
        column_check = supabase.rpc('exec_sql', {'sql_query': check_column_sql}).execute()
        
        if column_check.data and column_check.data[0]['count'] > 0:
            print("✅ evidence_urls column already exists")
        else:
            print("🔄 Adding evidence_urls column...")
            
            add_column_sql = """
            ALTER TABLE rank_requests 
            ADD COLUMN evidence_urls TEXT[] DEFAULT NULL;
            """
            
            supabase.rpc('exec_sql', {'sql_query': add_column_sql}).execute()
            print("✅ evidence_urls column added successfully")
        
        print("\n📊 Final table structure:")
        final_result = supabase.rpc('exec_sql', {'sql_query': check_sql}).execute()
        
        if final_result.data:
            for row in final_result.data:
                print(f"  - {row['column_name']}: {row['data_type']} ({'NULL' if row['is_nullable'] == 'YES' else 'NOT NULL'})")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    run_sql()
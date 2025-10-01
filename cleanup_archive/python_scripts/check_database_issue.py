#!/usr/bin/env python3
import requests
import json

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
    "Content-Type": "application/json"
}

def execute_sql(query, description=""):
    """Execute SQL query using Supabase REST API"""
    print(f"\n🔍 {description}")
    print(f"Query: {query}")
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
            headers=headers,
            json={"query": query}
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Success: {json.dumps(result, indent=2)}")
            return result
        else:
            print(f"❌ Error {response.status_code}: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Exception: {e}")
        return None

def check_rank_requests_table():
    """Check rank_requests table structure"""
    query = """
    SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default
    FROM information_schema.columns 
    WHERE table_name = 'rank_requests' 
    AND table_schema = 'public'
    ORDER BY ordinal_position;
    """
    return execute_sql(query, "Checking rank_requests table structure")

def check_request_status_enum():
    """Check request_status enum values"""
    query = """
    SELECT 
        enumlabel as enum_value
    FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'request_status'
    ORDER BY enumsortorder;
    """
    return execute_sql(query, "Checking request_status enum values")

def check_functions():
    """Check available functions with 'rank' in name"""
    query = """
    SELECT 
        proname as function_name,
        pronamespace::regnamespace as schema_name,
        pg_get_function_identity_arguments(oid) as arguments
    FROM pg_proc 
    WHERE proname LIKE '%rank%' 
    AND pronamespace = 'public'::regnamespace
    ORDER BY proname;
    """
    return execute_sql(query, "Checking rank-related functions")

def check_specific_function():
    """Check club_review_rank_change_request function details"""
    query = """
    SELECT 
        proname,
        prosrc,
        prorettype::regtype as return_type
    FROM pg_proc 
    WHERE proname = 'club_review_rank_change_request'
    LIMIT 1;
    """
    return execute_sql(query, "Checking club_review_rank_change_request function")

def test_simple_query():
    """Test simple query to ensure connection works"""
    query = "SELECT 1 as test;"
    return execute_sql(query, "Testing database connection")

def check_rank_requests_data():
    """Check sample data from rank_requests table"""
    query = """
    SELECT 
        id,
        user_id,
        club_id,
        status,
        requested_at,
        notes
    FROM rank_requests 
    ORDER BY requested_at DESC 
    LIMIT 5;
    """
    return execute_sql(query, "Checking recent rank_requests data")

if __name__ == "__main__":
    print("🔍 SUPABASE DATABASE DIAGNOSTIC")
    print("=" * 50)
    
    # Test connection
    test_simple_query()
    
    # Check table structure
    check_rank_requests_table()
    
    # Check enum
    check_request_status_enum()
    
    # Check functions
    check_functions()
    
    # Check specific function
    check_specific_function()
    
    # Check sample data
    check_rank_requests_data()
    
    print("\n" + "=" * 50)
    print("🏁 DIAGNOSTIC COMPLETE")
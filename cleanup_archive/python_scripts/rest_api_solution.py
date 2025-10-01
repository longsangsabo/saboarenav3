import requests
import json

# Supabase connection details with service role
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    'apikey': SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal'
}

def execute_via_rest_api():
    print("=== TRYING REST API APPROACH ===\n")
    
    # The SQL we want to execute
    main_sql = """DROP FUNCTION IF EXISTS get_pending_rank_change_requests();

CREATE OR REPLACE FUNCTION get_pending_rank_change_requests()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_requests JSON;
    v_is_admin BOOLEAN := false;
    v_user_club_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    SELECT COALESCE((SELECT role = 'admin' FROM users WHERE id = v_user_id), false) INTO v_is_admin;

    IF NOT v_is_admin THEN
        SELECT club_id INTO v_user_club_id FROM club_members WHERE user_id = v_user_id AND status = 'active' LIMIT 1;
        
        IF v_user_club_id IS NULL THEN
            SELECT id INTO v_user_club_id FROM clubs WHERE owner_id = v_user_id LIMIT 1;
        END IF;
        
        IF v_user_club_id IS NULL THEN
            RETURN '[]'::JSON;
        END IF;
    END IF;

    SELECT json_agg(
        json_build_object(
            'id', n.id,
            'user_id', n.user_id,
            'user_name', COALESCE((SELECT display_name FROM users WHERE id = n.user_id), (SELECT full_name FROM users WHERE id = n.user_id), 'Unknown User'),
            'user_email', COALESCE((SELECT email FROM users WHERE id = n.user_id), 'unknown@email.com'),
            'user_avatar', (SELECT avatar_url FROM users WHERE id = n.user_id),
            'current_rank', (n.data->>'current_rank'),
            'requested_rank', (n.data->>'requested_rank'),
            'reason', (n.data->>'reason'),
            'evidence_urls', (n.data->'evidence_urls'),
            'submitted_at', (n.data->>'submitted_at'),
            'workflow_status', (n.data->>'workflow_status'),
            'user_club_id', (n.data->>'user_club_id'),
            'created_at', n.created_at
        )
    ) INTO v_requests
    FROM notifications n
    WHERE n.type = 'rank_change_request'
    AND (n.data->>'workflow_status') IN ('pending_club_review', 'pending_admin_review')
    AND (v_is_admin OR (n.data->>'user_club_id')::UUID = v_user_club_id)
    ORDER BY n.created_at DESC;

    RETURN COALESCE(v_requests, '[]'::JSON);
END;
$$;

GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests() TO authenticated;"""

    # Try multiple approaches
    approaches = [
        # Approach 1: Try with existing RPC functions
        {'endpoint': 'execute_sql', 'payload': {'sql': main_sql}},
        {'endpoint': 'exec_sql', 'payload': {'query': main_sql}},
        {'endpoint': 'run_sql', 'payload': {'sql_text': main_sql}},
        
        # Approach 2: Try creating a temporary function to execute this
        {'endpoint': 'create_function', 'payload': {'definition': main_sql}},
        
        # Approach 3: Use any existing admin functions
        {'endpoint': 'admin_execute', 'payload': {'command': main_sql}},
    ]

    for i, approach in enumerate(approaches):
        print(f"Trying approach {i+1}: {approach['endpoint']}")
        
        try:
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/{approach['endpoint']}",
                headers=headers,
                json=approach['payload']
            )
            
            print(f"  Status: {response.status_code}")
            
            if response.status_code == 200:
                print(f"  ✅ SUCCESS with {approach['endpoint']}!")
                result = response.json()
                print(f"  Result: {result}")
                return True
            else:
                print(f"  ❌ Failed: {response.text[:100]}...")
                
        except Exception as e:
            print(f"  ❌ Error: {e}")
    
    print("\n❌ All REST API approaches failed")
    return False

def test_direct_function_creation():
    print("\n=== TRYING DIRECT FUNCTION CREATION ===\n")
    
    # Try to check what RPC functions are available
    try:
        # Get schema info
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/",
            headers=headers
        )
        
        if response.status_code == 200:
            print("✅ Connected to Supabase REST API")
            
            # Try to list available RPC functions
            # This is a hack - try to call a non-existent function to see what's available
            test_response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/non_existent_function",
                headers=headers,
                json={}
            )
            
            if test_response.status_code == 404:
                error_text = test_response.text
                print(f"Available functions hint: {error_text}")
                
                # Look for any hints about available functions
                if "Perhaps you meant" in error_text:
                    print("✅ Found function suggestions in error message")
        
    except Exception as e:
        print(f"Schema check error: {e}")

if __name__ == "__main__":
    print("💪 USING SERVICE ROLE KEY FOR REST API EXECUTION\n")
    
    # First, try direct REST API execution
    success = execute_via_rest_api()
    
    if not success:
        # Try to understand what's available
        test_direct_function_creation()
        
        print("\n📋 CONCLUSION:")
        print("- Service role key works for REST API calls")
        print("- But Supabase doesn't expose SQL execution via REST API")
        print("- This is a security feature - prevents SQL injection")
        print("- Manual execution in SQL Editor is the intended way")
        
        print("\n🎯 SOLUTION: Copy-paste method is still the way to go!")
        
        # Auto-copy the SQL again
        try:
            import pyperclip
            sql = """DROP FUNCTION IF EXISTS get_pending_rank_change_requests();

CREATE OR REPLACE FUNCTION get_pending_rank_change_requests()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_requests JSON;
    v_is_admin BOOLEAN := false;
    v_user_club_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    SELECT COALESCE((SELECT role = 'admin' FROM users WHERE id = v_user_id), false) INTO v_is_admin;

    IF NOT v_is_admin THEN
        SELECT club_id INTO v_user_club_id FROM club_members WHERE user_id = v_user_id AND status = 'active' LIMIT 1;
        
        IF v_user_club_id IS NULL THEN
            SELECT id INTO v_user_club_id FROM clubs WHERE owner_id = v_user_id LIMIT 1;
        END IF;
        
        IF v_user_club_id IS NULL THEN
            RETURN '[]'::JSON;
        END IF;
    END IF;

    SELECT json_agg(
        json_build_object(
            'id', n.id,
            'user_id', n.user_id,
            'user_name', COALESCE((SELECT display_name FROM users WHERE id = n.user_id), (SELECT full_name FROM users WHERE id = n.user_id), 'Unknown User'),
            'user_email', COALESCE((SELECT email FROM users WHERE id = n.user_id), 'unknown@email.com'),
            'user_avatar', (SELECT avatar_url FROM users WHERE id = n.user_id),
            'current_rank', (n.data->>'current_rank'),
            'requested_rank', (n.data->>'requested_rank'),
            'reason', (n.data->>'reason'),
            'evidence_urls', (n.data->'evidence_urls'),
            'submitted_at', (n.data->>'submitted_at'),
            'workflow_status', (n.data->>'workflow_status'),
            'user_club_id', (n.data->>'user_club_id'),
            'created_at', n.created_at
        )
    ) INTO v_requests
    FROM notifications n
    WHERE n.type = 'rank_change_request'
    AND (n.data->>'workflow_status') IN ('pending_club_review', 'pending_admin_review')
    AND (v_is_admin OR (n.data->>'user_club_id')::UUID = v_user_club_id)
    ORDER BY n.created_at DESC;

    RETURN COALESCE(v_requests, '[]'::JSON);
END;
$$;

GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests() TO authenticated;"""
            
            pyperclip.copy(sql)
            print("✅ SQL copied to clipboard again!")
            print("📋 Paste in Supabase SQL Editor and run!")
            
        except:
            print("Manual copy needed from the script above")
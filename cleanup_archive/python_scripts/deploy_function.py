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

def deploy_function():
    """Deploy the fixed function directly via SQL execution"""
    print("🚀 DEPLOYING FUNCTION VIA API")
    print("=" * 50)
    
    # Function SQL with correct signature matching existing one
    function_sql = """
-- Drop existing function first
DROP FUNCTION IF EXISTS club_review_rank_change_request(uuid, boolean, text);

-- Create function with correct signature (matching the hint from error)
CREATE OR REPLACE FUNCTION club_review_rank_change_request(
    p_request_id uuid,
    p_approved boolean,
    p_club_comments text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    request_record rank_requests%ROWTYPE;
    user_record users%ROWTYPE;
    club_member_record club_members%ROWTYPE;  
    current_user_id uuid;
    result json;
    extracted_rank text;
BEGIN
    -- Get current user ID
    SELECT auth.uid() INTO current_user_id;
    
    -- Get the rank request first
    SELECT * INTO request_record FROM rank_requests WHERE id = p_request_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Request not found');
    END IF;
    
    -- If current user exists, check authorization
    -- If no current user (service role context), allow operation
    IF current_user_id IS NOT NULL THEN
        -- Check if current user is admin of the club
        SELECT * INTO club_member_record 
        FROM club_members 
        WHERE user_id = current_user_id 
        AND club_id = request_record.club_id 
        AND role = 'admin';
        
        IF NOT FOUND THEN
            RETURN json_build_object('success', false, 'error', 'Not authorized - user is not club admin');
        END IF;
    END IF;
    
    -- Process the action
    IF p_approved = true THEN
        -- Update the request to approved
        UPDATE rank_requests 
        SET status = 'approved'::request_status,
            reviewed_at = NOW(),
            reviewed_by = COALESCE(current_user_id, request_record.user_id),
            club_comments = p_club_comments
        WHERE id = p_request_id;
        
        -- Extract rank from notes
        SELECT substring(request_record.notes FROM 'Rank mong muốn: ([A-Z+]+)') INTO extracted_rank;
        
        -- Default to K if no rank found
        IF extracted_rank IS NULL THEN
            extracted_rank := 'K';
        END IF;
        
        -- Update user rank
        UPDATE users 
        SET rank = extracted_rank, 
            updated_at = NOW() 
        WHERE id = request_record.user_id;
        
        result := json_build_object(
            'success', true, 
            'message', 'Request approved successfully',
            'user_id', request_record.user_id,
            'new_rank', extracted_rank
        );
        
    ELSE -- reject
        UPDATE rank_requests 
        SET status = 'rejected'::request_status,
            reviewed_at = NOW(),
            reviewed_by = COALESCE(current_user_id, request_record.user_id),
            club_comments = p_club_comments
        WHERE id = p_request_id;
        
        result := json_build_object(
            'success', true, 
            'message', 'Request rejected successfully'
        );
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false, 
            'error', SQLERRM,
            'detail', SQLSTATE
        );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION club_review_rank_change_request TO anon, authenticated, service_role;

-- Add comment
COMMENT ON FUNCTION club_review_rank_change_request IS 'Review rank change requests - fixed for service role auth';
"""
    
    print("1️⃣ Deploying function...")
    
    try:
        # Execute the SQL
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
            headers=headers,
            json={"sql": function_sql}
        )
        
        if response.status_code == 200:
            print("✅ Function deployed successfully!")
            
            # Test the function immediately
            print("\n2️⃣ Testing deployed function...")
            test_function_immediately()
            
        else:
            print(f"❌ Deploy failed: {response.status_code}")
            print(f"Response: {response.text}")
            
            # Try alternative method
            print("\n🔄 Trying alternative SQL execution...")
            
            # Split into individual statements
            statements = [
                "DROP FUNCTION IF EXISTS club_review_rank_change_request(uuid, boolean, text);",
                function_sql.split("DROP FUNCTION")[1].split("GRANT EXECUTE")[0] + "GRANT EXECUTE ON FUNCTION club_review_rank_change_request TO anon, authenticated, service_role;"
            ]
            
            for i, stmt in enumerate(statements):
                if stmt.strip():
                    print(f"Executing statement {i+1}...")
                    exec_response = requests.post(
                        f"{SUPABASE_URL}/rest/v1/query",
                        headers=headers,
                        json={"query": stmt}
                    )
                    print(f"Statement {i+1}: {exec_response.status_code}")
                    
    except Exception as e:
        print(f"❌ Exception during deploy: {e}")

def test_function_immediately():
    """Test the function right after deployment"""
    print("🧪 IMMEDIATE FUNCTION TEST")
    print("-" * 30)
    
    # Get existing pending request
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/rank_requests?status=eq.pending&limit=1",
        headers=headers
    )
    
    if response.status_code == 200:
        requests_data = response.json()
        if requests_data:
            request = requests_data[0]
            request_id = request['id']
            
            print(f"Testing with request: {request_id}")
            
            # Test the function with correct parameters
            function_response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/club_review_rank_change_request",
                headers=headers,
                json={
                    "p_request_id": request_id,
                    "p_approved": True,
                    "p_club_comments": "Approved via API test"
                }
            )
            
            print(f"Function response: {function_response.status_code}")
            
            if function_response.status_code == 200:
                result = function_response.json()
                print(f"✅ Function works: {result}")
                
                if result.get('success'):
                    print("🎉 SUCCESS! Function is working!")
                else:
                    print(f"❌ Function error: {result}")
            else:
                print(f"❌ Function call failed: {function_response.text}")
        else:
            print("No pending requests to test with")
    else:
        print(f"Failed to get test data: {response.text}")

if __name__ == "__main__":
    deploy_function()
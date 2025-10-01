import requests
import json

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.FdxR6wN7HkEq-tEfQmOl1Zh_XhxbT6HHQbT4BjJd6rY"

def execute_sql(sql_query):
    """Execute SQL using Supabase REST API"""
    headers = {
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json"
    }
    
    # Use the RPC endpoint to execute SQL
    payload = {
        "query": sql_query
    }
    
    # Try direct SQL execution via rpc
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
            headers=headers,
            json={"sql_query": sql_query}
        )
        
        if response.status_code == 200:
            return True, "Success"
        else:
            return False, f"HTTP {response.status_code}: {response.text}"
            
    except Exception as e:
        return False, str(e)

print("🚀 DEPLOYING RANK CHANGE REQUEST SYSTEM")
print("=" * 50)

# SQL functions to deploy
functions = [
    {
        'name': 'submit_rank_change_request',
        'sql': '''
CREATE OR REPLACE FUNCTION submit_rank_change_request(
    p_requested_rank TEXT,
    p_reason TEXT,
    p_evidence_urls TEXT[] DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_current_user RECORD;
    v_user_club_id UUID;
    v_notification_id UUID;
    v_request_data JSONB;
    v_result JSON;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    SELECT * INTO v_current_user 
    FROM users 
    WHERE id = v_user_id;
    
    IF v_current_user IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    IF v_current_user.rank IS NULL OR v_current_user.rank = '' OR v_current_user.rank = 'unranked' THEN
        RAISE EXCEPTION 'User must have a current rank to request change';
    END IF;

    SELECT club_id INTO v_user_club_id 
    FROM club_memberships 
    WHERE user_id = v_user_id 
    AND status = 'active' 
    LIMIT 1;

    v_request_data := jsonb_build_object(
        'request_type', 'rank_change',
        'current_rank', v_current_user.rank,
        'requested_rank', p_requested_rank,
        'reason', p_reason,
        'evidence_urls', COALESCE(p_evidence_urls, ARRAY[]::TEXT[]),
        'user_club_id', v_user_club_id,
        'workflow_status', 'pending_club_review',
        'submitted_at', NOW(),
        'club_approved', false,
        'admin_approved', false
    );

    INSERT INTO notifications (
        user_id, 
        type,
        title,
        message,
        data,
        is_read
    ) VALUES (
        v_user_id, 
        'rank_change_request',
        'Yêu cầu thay đổi hạng mới',
        format('%s yêu cầu thay đổi hạng từ %s thành %s', 
               v_current_user.display_name, 
               v_current_user.rank, 
               p_requested_rank),
        v_request_data,
        false
    ) RETURNING id INTO v_notification_id;

    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        data,
        is_read
    ) VALUES (
        v_user_id,
        'rank_change_request_submitted',
        'Yêu cầu thay đổi hạng đã được gửi',
        format('Yêu cầu thay đổi hạng từ %s thành %s đã được gửi và đang chờ xét duyệt', 
               v_current_user.rank, 
               p_requested_rank),
        v_request_data,
        false
    );

    v_result := json_build_object(
        'success', true,
        'message', 'Rank change request submitted successfully',
        'request_id', v_notification_id,
        'status', 'pending_club_review'
    );

    RETURN v_result;
END;
$$;
        '''
    }
]

# Deploy the first function as a test
for func in functions:
    print(f"\n🔄 Deploying {func['name']}...")
    success, message = execute_sql(func['sql'])
    
    if success:
        print(f"✅ {func['name']} deployed successfully")
    else:
        print(f"❌ Failed to deploy {func['name']}: {message}")

print("\n✅ Deployment script completed!")
print("Note: You may need to manually execute the SQL in Supabase SQL Editor if this method doesn't work.")
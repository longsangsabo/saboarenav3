#!/usr/bin/env python3
"""
Deploy Rank Change Request System to Supabase
Automatically executes SQL functions using service role key
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.FdxR6wN7HkEq-tEfQmOl1Zh_XhxbT6HHQbT4BjJd6rY"

def execute_sql_statement(client: Client, sql: str, description: str):
    """Execute a single SQL statement"""
    try:
        print(f"🔄 {description}...")
        result = client.rpc('exec_sql', {'sql_query': sql}).execute()
        print(f"✅ {description} - SUCCESS")
        return True
    except Exception as e:
        # Try alternative method using direct SQL execution
        try:
            result = client.postgrest.session.post(
                f"{client.supabase_url}/rest/v1/rpc/exec_sql",
                json={"sql_query": sql},
                headers={
                    "apikey": client.supabase_key,
                    "Authorization": f"Bearer {client.supabase_key}",
                    "Content-Type": "application/json"
                }
            )
            if result.status_code == 200:
                print(f"✅ {description} - SUCCESS")
                return True
            else:
                print(f"❌ {description} - FAILED: {result.text}")
                return False
        except Exception as e2:
            print(f"❌ {description} - FAILED: {str(e2)}")
            return False

def deploy_rank_change_system():
    """Deploy the complete rank change request system"""
    
    print("🚀 DEPLOYING RANK CHANGE REQUEST SYSTEM")
    print("=" * 50)
    
    # Initialize Supabase client with service role
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        print("✅ Connected to Supabase with service role")
    except Exception as e:
        print(f"❌ Failed to connect to Supabase: {e}")
        return
    
    # SQL statements to execute
    sql_statements = [
        {
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
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get user info and current rank
    SELECT * INTO v_current_user 
    FROM users 
    WHERE id = v_user_id;
    
    IF v_current_user IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Check if user has a rank
    IF v_current_user.rank IS NULL OR v_current_user.rank = '' OR v_current_user.rank = 'unranked' THEN
        RAISE EXCEPTION 'User must have a current rank to request change';
    END IF;

    -- Get user's club (for club admin approval)
    SELECT club_id INTO v_user_club_id 
    FROM club_memberships 
    WHERE user_id = v_user_id 
    AND status = 'active' 
    LIMIT 1;

    -- Build request data
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
        'admin_approved', false,
        'club_reviewed_at', NULL,
        'admin_reviewed_at', NULL,
        'club_reviewer_id', NULL,
        'admin_reviewer_id', NULL,
        'club_comments', NULL,
        'admin_comments', NULL
    );

    -- Create notification for club admins
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

    -- Also create a notification for the user (confirmation)
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
            ''',
            'description': 'Create submit_rank_change_request function'
        },
        
        {
            'sql': '''
CREATE OR REPLACE FUNCTION get_pending_rank_change_requests(
    p_club_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_is_club_admin BOOLEAN := false;
    v_is_system_admin BOOLEAN := false;
    v_requests JSON;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Check if user is club admin or system admin
    SELECT 
        (role = 'admin') as is_system_admin,
        EXISTS(
            SELECT 1 FROM club_memberships cm 
            WHERE cm.user_id = v_user_id 
            AND cm.club_id = COALESCE(p_club_id, cm.club_id)
            AND cm.role IN ('owner', 'admin')
        ) as is_club_admin
    INTO v_is_system_admin, v_is_club_admin
    FROM users WHERE id = v_user_id;

    IF NOT (v_is_club_admin OR v_is_system_admin) THEN
        RAISE EXCEPTION 'Access denied: User must be club admin or system admin';
    END IF;

    -- Get pending requests
    SELECT json_agg(
        json_build_object(
            'id', n.id,
            'user_id', n.user_id,
            'user_name', u.display_name,
            'user_avatar', u.avatar_url,
            'current_rank', (n.data->>'current_rank'),
            'requested_rank', (n.data->>'requested_rank'),
            'reason', (n.data->>'reason'),
            'evidence_urls', n.data->'evidence_urls',
            'submitted_at', (n.data->>'submitted_at'),
            'workflow_status', (n.data->>'workflow_status'),
            'created_at', n.created_at
        )
    ) INTO v_requests
    FROM notifications n
    JOIN users u ON n.user_id = u.id
    WHERE n.type = 'rank_change_request'
    AND (n.data->>'workflow_status') IN ('pending_club_review', 'pending_admin_review')
    AND (
        v_is_system_admin OR 
        (p_club_id IS NOT NULL AND (n.data->>'user_club_id')::UUID = p_club_id)
    )
    ORDER BY n.created_at DESC;

    RETURN COALESCE(v_requests, '[]'::JSON);
END;
$$;
            ''',
            'description': 'Create get_pending_rank_change_requests function'
        },
        
        {
            'sql': '''
CREATE OR REPLACE FUNCTION club_review_rank_change_request(
    p_request_id UUID,
    p_approved BOOLEAN,
    p_comments TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_request_record RECORD;
    v_updated_data JSONB;
    v_result JSON;
BEGIN
    v_user_id := auth.uid();
    
    -- Get request record
    SELECT * INTO v_request_record
    FROM notifications 
    WHERE id = p_request_id AND type = 'rank_change_request';

    IF v_request_record IS NULL THEN
        RAISE EXCEPTION 'Request not found';
    END IF;

    -- Check if user is club admin for this request
    IF NOT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE user_id = v_user_id 
        AND club_id = (v_request_record.data->>'user_club_id')::UUID
        AND role IN ('owner', 'admin')
    ) THEN
        RAISE EXCEPTION 'Access denied: User must be club admin';
    END IF;

    -- Update request data
    v_updated_data := v_request_record.data || jsonb_build_object(
        'club_approved', p_approved,
        'club_reviewed_at', NOW(),
        'club_reviewer_id', v_user_id,
        'club_comments', p_comments,
        'workflow_status', 
        CASE 
            WHEN p_approved THEN 'pending_admin_review'
            ELSE 'rejected_by_club'
        END
    );

    -- Update notification
    UPDATE notifications 
    SET data = v_updated_data,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Create notification for user about club decision
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        data
    ) VALUES (
        v_request_record.user_id,
        CASE 
            WHEN p_approved THEN 'rank_change_club_approved'
            ELSE 'rank_change_club_rejected'
        END,
        CASE 
            WHEN p_approved THEN 'Câu lạc bộ đã duyệt yêu cầu thay đổi hạng'
            ELSE 'Câu lạc bộ đã từ chối yêu cầu thay đổi hạng'
        END,
        CASE 
            WHEN p_approved THEN 'Yêu cầu thay đổi hạng của bạn đã được câu lạc bộ duyệt và chuyển lên admin hệ thống để phê duyệt cuối cùng.'
            ELSE format('Yêu cầu thay đổi hạng của bạn đã bị từ chối. Lý do: %s', COALESCE(p_comments, 'Không có lý do cụ thể'))
        END,
        v_updated_data
    );

    v_result := json_build_object(
        'success', true,
        'message', 
        CASE 
            WHEN p_approved THEN 'Request approved and forwarded to system admin'
            ELSE 'Request rejected'
        END,
        'status', v_updated_data->>'workflow_status'
    );

    RETURN v_result;
END;
$$;
            ''',
            'description': 'Create club_review_rank_change_request function'
        },
        
        {
            'sql': '''
CREATE OR REPLACE FUNCTION admin_approve_rank_change_request(
    p_request_id UUID,
    p_approved BOOLEAN,
    p_comments TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_request_record RECORD;
    v_updated_data JSONB;
    v_target_user_id UUID;
    v_new_rank TEXT;
    v_result JSON;
BEGIN
    v_user_id := auth.uid();
    
    -- Check if user is system admin
    IF NOT EXISTS(SELECT 1 FROM users WHERE id = v_user_id AND role = 'admin') THEN
        RAISE EXCEPTION 'Access denied: User must be system admin';
    END IF;

    -- Get request record
    SELECT * INTO v_request_record
    FROM notifications 
    WHERE id = p_request_id AND type = 'rank_change_request';

    IF v_request_record IS NULL THEN
        RAISE EXCEPTION 'Request not found';
    END IF;

    v_target_user_id := v_request_record.user_id;
    v_new_rank := v_request_record.data->>'requested_rank';

    -- Update request data
    v_updated_data := v_request_record.data || jsonb_build_object(
        'admin_approved', p_approved,
        'admin_reviewed_at', NOW(),
        'admin_reviewer_id', v_user_id,
        'admin_comments', p_comments,
        'workflow_status', 
        CASE 
            WHEN p_approved THEN 'approved'
            ELSE 'rejected_by_admin'
        END
    );

    -- Update notification
    UPDATE notifications 
    SET data = v_updated_data,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- If approved, update user's rank
    IF p_approved THEN
        UPDATE users 
        SET rank = v_new_rank,
            updated_at = NOW()
        WHERE id = v_target_user_id;
    END IF;

    -- Create notification for user about final decision
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        data
    ) VALUES (
        v_target_user_id,
        CASE 
            WHEN p_approved THEN 'rank_change_approved'
            ELSE 'rank_change_rejected'
        END,
        CASE 
            WHEN p_approved THEN 'Yêu cầu thay đổi hạng đã được duyệt!'
            ELSE 'Yêu cầu thay đổi hạng đã bị từ chối'
        END,
        CASE 
            WHEN p_approved THEN format('Chúc mừng! Hạng của bạn đã được thay đổi thành %s', v_new_rank)
            ELSE format('Yêu cầu thay đổi hạng đã bị từ chối. Lý do: %s', COALESCE(p_comments, 'Không có lý do cụ thể'))
        END,
        v_updated_data
    );

    v_result := json_build_object(
        'success', true,
        'message', 
        CASE 
            WHEN p_approved THEN 'Rank change request approved and user rank updated'
            ELSE 'Rank change request rejected'
        END,
        'status', v_updated_data->>'workflow_status',
        'new_rank', CASE WHEN p_approved THEN v_new_rank ELSE NULL END
    );

    RETURN v_result;
END;
$$;
            ''',
            'description': 'Create admin_approve_rank_change_request function'
        },
        
        {
            'sql': '''
-- Grant permissions
GRANT EXECUTE ON FUNCTION submit_rank_change_request TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests TO authenticated;
GRANT EXECUTE ON FUNCTION club_review_rank_change_request TO authenticated;
GRANT EXECUTE ON FUNCTION admin_approve_rank_change_request TO authenticated;
            ''',
            'description': 'Grant function permissions'
        },
        
        {
            'sql': '''
-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_type_data ON notifications(type) 
WHERE type IN ('rank_change_request', 'rank_change_request_submitted', 'rank_change_club_approved', 
               'rank_change_club_rejected', 'rank_change_approved', 'rank_change_rejected');
            ''',
            'description': 'Create performance indexes'
        },
        
        {
            'sql': '''
CREATE INDEX IF NOT EXISTS idx_notifications_workflow_status ON notifications 
USING GIN ((data->>'workflow_status'))
WHERE type = 'rank_change_request';
            ''',
            'description': 'Create workflow status index'
        }
    ]
    
    # Execute all SQL statements
    success_count = 0
    total_count = len(sql_statements)
    
    for i, statement in enumerate(sql_statements, 1):
        print(f"\n📋 Step {i}/{total_count}: {statement['description']}")
        if execute_sql_statement(supabase, statement['sql'], statement['description']):
            success_count += 1
    
    print("\n" + "=" * 50)
    print(f"🎯 DEPLOYMENT COMPLETE: {success_count}/{total_count} statements executed successfully")
    
    if success_count == total_count:
        print("✅ Rank Change Request System deployed successfully!")
        print("\n🚀 NEXT STEPS:")
        print("1. Test the system by submitting a rank change request")
        print("2. Create Club Admin interface to review requests")
        print("3. Create System Admin interface for final approval")
    else:
        print(f"⚠️  {total_count - success_count} statements failed. Please check the errors above.")
    
    return success_count == total_count

def test_system():
    """Test the deployed system"""
    print("\n🧪 TESTING RANK CHANGE REQUEST SYSTEM")
    print("=" * 50)
    
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        
        # Test getting pending requests (should return empty array for new system)
        print("🔍 Testing get_pending_rank_change_requests...")
        result = supabase.rpc('get_pending_rank_change_requests').execute()
        print(f"✅ Function works - Found {len(result.data) if result.data else 0} pending requests")
        
        print("\n✅ System is ready for testing!")
        print("📝 You can now:")
        print("   • Use the UI to submit rank change requests")
        print("   • Club admins can review pending requests")
        print("   • System admins can approve final requests")
        
    except Exception as e:
        print(f"❌ Testing failed: {e}")

if __name__ == "__main__":
    if deploy_rank_change_system():
        test_system()
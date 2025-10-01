-- =====================================================
-- RANK CHANGE REQUEST SYSTEM - COMPLETE DEPLOYMENT
-- =====================================================
-- Instructions: Copy this entire file and paste into Supabase SQL Editor
-- Then click "RUN" to deploy all functions at once

-- 1. SUBMIT RANK CHANGE REQUEST FUNCTION
-- This function allows users to submit rank change requests
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
    -- Get authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get user details
    SELECT * INTO v_current_user 
    FROM users 
    WHERE id = v_user_id;
    
    IF v_current_user IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Check if user has a rank (can't change rank if unranked)
    IF v_current_user.rank IS NULL OR v_current_user.rank = '' OR v_current_user.rank = 'unranked' THEN
        RAISE EXCEPTION 'User must have a current rank to request change';
    END IF;

    -- Get user's club (if any)
    SELECT club_id INTO v_user_club_id 
    FROM club_members 
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
        'admin_approved', false
    );

    -- Create main request notification
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

    -- Create confirmation notification for user
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

    -- Return success result
    v_result := json_build_object(
        'success', true,
        'message', 'Rank change request submitted successfully',
        'request_id', v_notification_id,
        'status', 'pending_club_review'
    );

    RETURN v_result;
END;
$$;

-- 2. GET PENDING RANK CHANGE REQUESTS FUNCTION
-- This function gets all pending rank change requests for club admins
CREATE OR REPLACE FUNCTION get_pending_rank_change_requests(
    p_club_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_user_club_id UUID;
    v_requests JSON;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- If no club_id provided, get user's club
    IF p_club_id IS NULL THEN
        SELECT club_id INTO v_user_club_id 
        FROM club_members 
        WHERE user_id = v_user_id 
        AND status = 'active' 
        AND role IN ('admin', 'owner')
        LIMIT 1;
        
        IF v_user_club_id IS NULL THEN
            RAISE EXCEPTION 'User is not a club admin';
        END IF;
    ELSE
        v_user_club_id := p_club_id;
        
        -- Verify user is admin of this club
        IF NOT EXISTS (
            SELECT 1 FROM club_members 
            WHERE user_id = v_user_id 
            AND club_id = v_user_club_id 
            AND status = 'active' 
            AND role IN ('admin', 'owner')
        ) THEN
            RAISE EXCEPTION 'User is not authorized to view this club requests';
        END IF;
    END IF;

    -- Get pending requests for this club
    SELECT json_agg(
        json_build_object(
            'id', n.id,
            'user_id', n.user_id,
            'user_name', u.display_name,
            'user_avatar', u.avatar_url,
            'current_rank', (n.data->>'current_rank'),
            'requested_rank', (n.data->>'requested_rank'),
            'reason', (n.data->>'reason'),
            'evidence_urls', (n.data->'evidence_urls'),
            'submitted_at', (n.data->>'submitted_at'),
            'workflow_status', (n.data->>'workflow_status')
        )
    ) INTO v_requests
    FROM notifications n
    JOIN users u ON u.id = n.user_id
    WHERE n.type = 'rank_change_request'
    AND (n.data->>'user_club_id')::UUID = v_user_club_id
    AND (n.data->>'workflow_status') = 'pending_club_review'
    AND NOT n.is_read;

    RETURN COALESCE(v_requests, '[]'::JSON);
END;
$$;

-- 3. CLUB REVIEW RANK CHANGE REQUEST FUNCTION
-- This function allows club admins to approve/reject rank change requests
CREATE OR REPLACE FUNCTION club_review_rank_change_request(
    p_request_id UUID,
    p_approved BOOLEAN,
    p_club_comments TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_request RECORD;
    v_updated_data JSONB;
    v_result JSON;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get the request
    SELECT * INTO v_request
    FROM notifications
    WHERE id = p_request_id
    AND type = 'rank_change_request';

    IF v_request IS NULL THEN
        RAISE EXCEPTION 'Request not found';
    END IF;

    -- Verify user is admin of the club
    IF NOT EXISTS (
        SELECT 1 FROM club_members 
        WHERE user_id = v_user_id 
        AND club_id = (v_request.data->>'user_club_id')::UUID
        AND status = 'active' 
        AND role IN ('admin', 'owner')
    ) THEN
        RAISE EXCEPTION 'User is not authorized to review this request';
    END IF;

    -- Update request data
    v_updated_data := v_request.data || jsonb_build_object(
        'club_approved', p_approved,
        'club_reviewed_at', NOW(),
        'club_reviewed_by', v_user_id,
        'club_comments', COALESCE(p_club_comments, ''),
        'workflow_status', 
        CASE 
            WHEN p_approved THEN 'pending_admin_approval'
            ELSE 'rejected_by_club'
        END
    );

    -- Update the original request
    UPDATE notifications
    SET data = v_updated_data,
        is_read = true
    WHERE id = p_request_id;

    -- Create notification for user about club decision
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        data,
        is_read
    ) VALUES (
        v_request.user_id,
        CASE 
            WHEN p_approved THEN 'rank_change_club_approved'
            ELSE 'rank_change_club_rejected'
        END,
        CASE 
            WHEN p_approved THEN 'Yêu cầu thay đổi hạng được club chấp thuận'
            ELSE 'Yêu cầu thay đổi hạng bị club từ chối'
        END,
        CASE 
            WHEN p_approved THEN 
                format('Club đã chấp thuận yêu cầu thay đổi hạng từ %s thành %s. Đang chờ admin phê duyệt cuối cùng.',
                       v_request.data->>'current_rank',
                       v_request.data->>'requested_rank')
            ELSE 
                format('Club đã từ chối yêu cầu thay đổi hạng từ %s thành %s. %s',
                       v_request.data->>'current_rank',
                       v_request.data->>'requested_rank',
                       COALESCE('Lý do: ' || p_club_comments, ''))
        END,
        v_updated_data,
        false
    );

    -- Return result
    v_result := json_build_object(
        'success', true,
        'message', CASE 
            WHEN p_approved THEN 'Request approved by club'
            ELSE 'Request rejected by club'
        END,
        'status', v_updated_data->>'workflow_status'
    );

    RETURN v_result;
END;
$$;

-- 4. ADMIN APPROVE RANK CHANGE REQUEST FUNCTION
-- This function allows system admins to give final approval and update user rank
CREATE OR REPLACE FUNCTION admin_approve_rank_change_request(
    p_request_id UUID,
    p_approved BOOLEAN,
    p_admin_comments TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_request RECORD;
    v_updated_data JSONB;
    v_result JSON;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Verify user is system admin (you'll need to implement admin check)
    -- For now, assuming any authenticated user can do this
    -- TODO: Add proper admin role check

    -- Get the request
    SELECT * INTO v_request
    FROM notifications
    WHERE id = p_request_id
    AND type = 'rank_change_request';

    IF v_request IS NULL THEN
        RAISE EXCEPTION 'Request not found';
    END IF;

    -- Check if request was approved by club
    IF (v_request.data->>'workflow_status') != 'pending_admin_approval' THEN
        RAISE EXCEPTION 'Request must be approved by club first';
    END IF;

    -- Update request data
    v_updated_data := v_request.data || jsonb_build_object(
        'admin_approved', p_approved,
        'admin_reviewed_at', NOW(),
        'admin_reviewed_by', v_user_id,
        'admin_comments', COALESCE(p_admin_comments, ''),
        'workflow_status', 
        CASE 
            WHEN p_approved THEN 'completed'
            ELSE 'rejected_by_admin'
        END
    );

    -- Update the original request
    UPDATE notifications
    SET data = v_updated_data
    WHERE id = p_request_id;

    -- If approved, update user's rank
    IF p_approved THEN
        UPDATE users
        SET rank = v_request.data->>'requested_rank',
            updated_at = NOW()
        WHERE id = v_request.user_id;
    END IF;

    -- Create final notification for user
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        data,
        is_read
    ) VALUES (
        v_request.user_id,
        CASE 
            WHEN p_approved THEN 'rank_change_completed'
            ELSE 'rank_change_admin_rejected'
        END,
        CASE 
            WHEN p_approved THEN 'Thay đổi hạng thành công!'
            ELSE 'Yêu cầu thay đổi hạng bị từ chối'
        END,
        CASE 
            WHEN p_approved THEN 
                format('Chúc mừng! Hạng của bạn đã được thay đổi từ %s thành %s.',
                       v_request.data->>'current_rank',
                       v_request.data->>'requested_rank')
            ELSE 
                format('Yêu cầu thay đổi hạng từ %s thành %s đã bị admin từ chối. %s',
                       v_request.data->>'current_rank',
                       v_request.data->>'requested_rank',
                       COALESCE('Lý do: ' || p_admin_comments, ''))
        END,
        v_updated_data,
        false
    );

    -- Return result
    v_result := json_build_object(
        'success', true,
        'message', CASE 
            WHEN p_approved THEN 'Rank change completed successfully'
            ELSE 'Request rejected by admin'
        END,
        'status', v_updated_data->>'workflow_status',
        'new_rank', CASE 
            WHEN p_approved THEN v_request.data->>'requested_rank'
            ELSE NULL
        END
    );

    RETURN v_result;
END;
$$;

-- =====================================================
-- DEPLOYMENT COMPLETE!
-- =====================================================
-- All 4 RPC functions have been created:
-- 1. submit_rank_change_request() - Submit new requests
-- 2. get_pending_rank_change_requests() - Get requests for club review
-- 3. club_review_rank_change_request() - Club approval/rejection
-- 4. admin_approve_rank_change_request() - Final admin approval
--
-- Usage Examples:
-- 
-- Submit request:
-- SELECT submit_rank_change_request('gold', 'Improved significantly', ARRAY['image1.jpg', 'image2.jpg']);
--
-- Get pending requests (for club admin):
-- SELECT get_pending_rank_change_requests();
--
-- Club review:
-- SELECT club_review_rank_change_request('request-uuid', true, 'Approved by club');
--
-- Admin final approval:
-- SELECT admin_approve_rank_change_request('request-uuid', true, 'Final approval granted');
-- =====================================================
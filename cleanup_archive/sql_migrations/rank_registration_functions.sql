-- =============================================================================
-- RANK REGISTRATION COMPLETE FLOW - Database Functions
-- Functions to support complete rank registration and approval flow
-- =============================================================================

-- ✅ FUNCTION 1: Get pending rank change requests for club admins
CREATE OR REPLACE FUNCTION get_pending_rank_change_requests()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Get all pending rank requests with user details
    SELECT json_agg(row_to_json(t))
    INTO v_result
    FROM (
        SELECT 
            rr.id,
            rr.user_id,
            rr.club_id,
            rr.status,
            rr.notes,
            rr.evidence_urls,
            rr.requested_at,
            rr.reviewed_at,
            rr.club_comments,
            -- User details
            u.full_name as user_name,
            u.email as user_email,
            u.rank as current_rank,
            u.elo_rating as current_elo,
            u.avatar_url as user_avatar,
            -- Club details
            c.name as club_name
        FROM rank_requests rr
        LEFT JOIN users u ON rr.user_id = u.id
        LEFT JOIN clubs c ON rr.club_id = c.id
        WHERE rr.status = 'pending'
        ORDER BY rr.requested_at DESC
    ) t;

    RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- ✅ FUNCTION 2: Club admin review rank change request
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
    v_current_user RECORD;
    v_request RECORD;
    v_club_id UUID;
    v_requested_rank TEXT;
    v_result JSON;
BEGIN
    -- Get current user (should be club admin)
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get the rank request details
    SELECT * INTO v_request 
    FROM rank_requests 
    WHERE id = p_request_id;
    
    IF v_request IS NULL THEN
        RAISE EXCEPTION 'Rank request not found';
    END IF;

    IF v_request.status != 'pending' THEN
        RAISE EXCEPTION 'Request has already been reviewed';
    END IF;

    -- Extract requested rank from notes (rough parsing)
    SELECT substring(v_request.notes FROM 'Rank mong muốn: ([A-Z+]+)') INTO v_requested_rank;
    IF v_requested_rank IS NULL THEN
        v_requested_rank := 'K'; -- Default fallback
    END IF;

    -- Update the request status
    UPDATE rank_requests 
    SET 
        status = CASE WHEN p_approved THEN 'approved' ELSE 'rejected' END,
        reviewed_at = NOW(),
        reviewed_by = v_user_id,
        club_comments = p_club_comments
    WHERE id = p_request_id;

    -- If approved, update user's rank
    IF p_approved THEN
        UPDATE users 
        SET 
            rank = v_requested_rank,
            updated_at = NOW()
        WHERE id = v_request.user_id;
        
        -- Log the rank change
        INSERT INTO rank_change_logs (user_id, old_rank, new_rank, changed_by, reason, club_id)
        VALUES (
            v_request.user_id,
            (SELECT rank FROM users WHERE id = v_request.user_id),
            v_requested_rank,
            v_user_id,
            'Club admin approval: ' || COALESCE(p_club_comments, 'No comments'),
            v_request.club_id
        );
    END IF;

    -- Return success result
    v_result := json_build_object(
        'success', true,
        'message', CASE WHEN p_approved THEN 'Request approved successfully' ELSE 'Request rejected' END,
        'request_id', p_request_id,
        'approved', p_approved,
        'new_rank', CASE WHEN p_approved THEN v_requested_rank ELSE NULL END
    );

    RETURN v_result;
END;
$$;

-- ✅ FUNCTION 3: Create rank_change_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS rank_change_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    old_rank TEXT,
    new_rank TEXT,
    changed_by UUID REFERENCES users(id),
    reason TEXT,
    club_id UUID REFERENCES clubs(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_rank_change_logs_user_id ON rank_change_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_rank_change_logs_created_at ON rank_change_logs(created_at);

-- ✅ FUNCTION 4: Get rank change history for a user
CREATE OR REPLACE FUNCTION get_user_rank_history(p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_agg(row_to_json(t))
    INTO v_result
    FROM (
        SELECT 
            rcl.*,
            changer.full_name as changed_by_name,
            club.name as club_name
        FROM rank_change_logs rcl
        LEFT JOIN users changer ON rcl.changed_by = changer.id
        LEFT JOIN clubs club ON rcl.club_id = club.id
        WHERE rcl.user_id = p_user_id
        ORDER BY rcl.created_at DESC
    ) t;

    RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- ✅ Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests() TO authenticated;
GRANT EXECUTE ON FUNCTION club_review_rank_change_request(UUID, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_rank_history(UUID) TO authenticated;

-- ✅ Test the functions
SELECT 'FUNCTIONS CREATED SUCCESSFULLY' as status;

-- Test data insertion (optional)
-- SELECT get_pending_rank_change_requests() as pending_requests;
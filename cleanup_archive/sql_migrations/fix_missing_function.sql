-- =============================================================================
-- FIX: Create missing club_review_rank_change_request function
-- This function handles club admin approval/rejection of rank requests
-- =============================================================================

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

    -- Extract requested rank from notes (parsing the format from the app)
    -- Look for "Rank mong muốn: K+" pattern
    SELECT substring(v_request.notes FROM 'Rank mong muốn: ([A-Z+]+)') INTO v_requested_rank;
    IF v_requested_rank IS NULL THEN
        v_requested_rank := 'K'; -- Default fallback
    END IF;

    -- Update the request status using proper enum casting
    UPDATE rank_requests 
    SET 
        status = CASE WHEN p_approved THEN 'approved'::request_status ELSE 'rejected'::request_status END,
        reviewed_at = NOW(),
        reviewed_by = v_user_id,
        rejection_reason = CASE WHEN NOT p_approved THEN p_club_comments ELSE NULL END
    WHERE id = p_request_id;

    -- If approved, update user's rank
    IF p_approved THEN
        UPDATE users 
        SET 
            rank = v_requested_rank,
            updated_at = NOW()
        WHERE id = v_request.user_id;
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION club_review_rank_change_request TO authenticated;

-- Test function with a simple query
SELECT 'Function club_review_rank_change_request created successfully' as status;
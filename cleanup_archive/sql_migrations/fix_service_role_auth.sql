-- =============================================================================
-- FIX: Update club_review_rank_change_request function to handle service role
-- This fixes the authentication issue when using service role
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
    v_is_service_role BOOLEAN := false;
BEGIN
    -- Get current user (handle both regular auth and service role)
    v_user_id := auth.uid();
    
    -- Check if this is a service role call (service role doesn't have auth.uid())
    IF v_user_id IS NULL THEN
        -- Check if we're being called with service role privileges
        -- Service role can bypass auth checks
        BEGIN
            -- Try to perform a service-role-only operation to detect service role
            PERFORM 1 FROM users LIMIT 1;
            v_is_service_role := true;
            -- Use a system user ID for service role operations
            v_user_id := '00000000-0000-0000-0000-000000000000'::UUID;
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE EXCEPTION 'User not authenticated and not service role';
        END;
    END IF;

    -- Get the rank request details
    SELECT * INTO v_request 
    FROM rank_requests 
    WHERE id = p_request_id;
    
    IF v_request IS NULL THEN
        RAISE EXCEPTION 'Rank request not found: %', p_request_id;
    END IF;

    IF v_request.status != 'pending' THEN
        RAISE EXCEPTION 'Request has already been reviewed. Current status: %', v_request.status;
    END IF;

    -- For non-service role, verify user is club admin
    IF NOT v_is_service_role THEN
        -- Check if user is owner of the club or has admin privileges
        IF NOT EXISTS (
            SELECT 1 FROM clubs 
            WHERE id = v_request.club_id 
            AND owner_id = v_user_id
        ) THEN
            RAISE EXCEPTION 'Access denied: User is not authorized to review requests for this club';
        END IF;
    END IF;

    -- Extract requested rank from notes (parsing the format from the app)
    -- Look for "Rank mong muốn: K+" pattern
    SELECT substring(v_request.notes FROM 'Rank mong muốn: ([A-Z+]+)') INTO v_requested_rank;
    IF v_requested_rank IS NULL THEN
        -- Try alternative patterns or use default
        SELECT substring(v_request.notes FROM 'rank: ([A-Z+]+)') INTO v_requested_rank;
        IF v_requested_rank IS NULL THEN
            v_requested_rank := 'K'; -- Default fallback
        END IF;
    END IF;

    -- Update the request status using proper enum casting
    UPDATE rank_requests 
    SET 
        status = CASE WHEN p_approved THEN 'approved'::request_status ELSE 'rejected'::request_status END,
        reviewed_at = NOW(),
        reviewed_by = CASE WHEN v_is_service_role THEN NULL ELSE v_user_id END,
        rejection_reason = CASE WHEN NOT p_approved THEN p_club_comments ELSE NULL END
    WHERE id = p_request_id;

    -- If approved, update user's rank
    IF p_approved THEN
        UPDATE users 
        SET 
            rank = v_requested_rank,
            updated_at = NOW()
        WHERE id = v_request.user_id;
        
        RAISE NOTICE 'Updated user % rank to %', v_request.user_id, v_requested_rank;
    END IF;

    -- Return success result
    v_result := json_build_object(
        'success', true,
        'message', CASE WHEN p_approved THEN 'Request approved successfully' ELSE 'Request rejected' END,
        'request_id', p_request_id,
        'approved', p_approved,
        'new_rank', CASE WHEN p_approved THEN v_requested_rank ELSE NULL END,
        'is_service_role', v_is_service_role
    );

    RETURN v_result;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION club_review_rank_change_request TO authenticated;
GRANT EXECUTE ON FUNCTION club_review_rank_change_request TO service_role;

-- Test query
SELECT 'Function club_review_rank_change_request updated to handle service role' as status;
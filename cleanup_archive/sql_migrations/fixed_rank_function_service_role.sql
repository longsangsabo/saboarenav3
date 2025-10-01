-- FIX: Handle Service Role authentication properly
DROP FUNCTION IF EXISTS get_pending_rank_change_requests();

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
    v_is_service_role BOOLEAN := false;
BEGIN
    v_user_id := auth.uid();
    
    -- Check if this is a service role call (no user authentication)
    IF v_user_id IS NULL THEN
        -- For service role, return all pending requests
        v_is_service_role := true;
    END IF;

    -- If service role, skip user checks
    IF NOT v_is_service_role THEN
        -- Check if user is system admin
        SELECT COALESCE((SELECT role = 'admin' FROM users WHERE id = v_user_id), false) INTO v_is_admin;

        -- Get user's club
        IF NOT v_is_admin THEN
            SELECT club_id INTO v_user_club_id FROM club_members WHERE user_id = v_user_id AND status = 'active' LIMIT 1;
            
            IF v_user_club_id IS NULL THEN
                SELECT id INTO v_user_club_id FROM clubs WHERE owner_id = v_user_id LIMIT 1;
            END IF;
            
            IF v_user_club_id IS NULL THEN
                RETURN '[]'::JSON;
            END IF;
        END IF;
    END IF;

    -- Get pending requests from RANK_REQUESTS table
    SELECT json_agg(
        json_build_object(
            'id', rr.id,
            'user_id', rr.user_id,
            'user_name', COALESCE(u.display_name, u.full_name, 'Unknown User'),
            'user_email', COALESCE(u.email, 'unknown@email.com'),
            'user_avatar', u.avatar_url,
            'club_id', rr.club_id,
            'status', rr.status,
            'requested_at', rr.requested_at,
            'reviewed_at', rr.reviewed_at,
            'reviewed_by', rr.reviewed_by,
            'rejection_reason', rr.rejection_reason,
            'notes', rr.notes,
            'evidence_urls', rr.evidence_urls
        )
    ) INTO v_requests
    FROM rank_requests rr
    LEFT JOIN users u ON u.id = rr.user_id
    WHERE rr.status = 'pending'
    AND (
        v_is_service_role OR  -- Service role sees all
        v_is_admin OR  -- System admin sees all
        rr.club_id = v_user_club_id  -- Club admin sees their club's requests
    )
    ORDER BY rr.requested_at DESC;

    RETURN COALESCE(v_requests, '[]'::JSON);
END;
$$;

GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests() TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests() TO service_role;
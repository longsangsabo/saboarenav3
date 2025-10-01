-- Alternative fix - use existing club_members table instead
-- Drop and recreate function using correct table name

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
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Check if user is system admin (try both users and users tables)
    SELECT COALESCE(
        (SELECT role = 'admin' FROM users WHERE id = v_user_id),
        (SELECT role = 'admin' FROM users WHERE id = v_user_id),
        false
    ) INTO v_is_admin;

    -- Get user's club using existing club_members table
    IF NOT v_is_admin THEN
        SELECT club_id INTO v_user_club_id
        FROM club_members 
        WHERE user_id = v_user_id 
        LIMIT 1;
        
        -- Also check if user owns any club
        IF v_user_club_id IS NULL THEN
            SELECT id INTO v_user_club_id
            FROM clubs 
            WHERE owner_id = v_user_id 
            LIMIT 1;
        END IF;
        
        -- If user is not admin and not associated with any club, return empty
        IF v_user_club_id IS NULL THEN
            RETURN '[]'::JSON;
        END IF;
    END IF;

    -- Get pending requests with fallback for user data
    SELECT json_agg(
        json_build_object(
            'id', n.id,
            'user_id', n.user_id,
            'user_name', COALESCE(
                (SELECT display_name FROM users WHERE id = n.user_id),
                (SELECT full_name FROM users WHERE id = n.user_id),
                'Unknown User'
            ),
            'user_email', COALESCE(
                (SELECT email FROM users WHERE id = n.user_id),
                (SELECT email FROM users WHERE id = n.user_id),
                'unknown@email.com'
            ),
            'user_avatar', COALESCE(
                (SELECT avatar_url FROM users WHERE id = n.user_id),
                (SELECT avatar_url FROM users WHERE id = n.user_id)
            ),
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
    AND (
        v_is_admin OR  -- System admin sees all
        (n.data->>'user_club_id')::UUID = v_user_club_id  -- Club admin sees their club's requests
    )
    ORDER BY n.created_at DESC;

    RETURN COALESCE(v_requests, '[]'::JSON);
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests() TO authenticated;

SELECT 'Function updated to use existing tables' as status;
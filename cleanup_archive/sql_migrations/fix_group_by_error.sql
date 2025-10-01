-- FIX GROUP BY ERROR - PostgreSQL requires all selected columns in GROUP BY
-- Error: column "n.created_at" must appear in the GROUP BY clause

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

    -- Check if user is system admin (using actual users table)
    SELECT COALESCE(
        (SELECT role = 'admin' FROM users WHERE id = v_user_id),
        false
    ) INTO v_is_admin;

    -- Get user's club using actual club_members table
    IF NOT v_is_admin THEN
        -- First check if user is a member of any club
        SELECT club_id INTO v_user_club_id
        FROM club_members 
        WHERE user_id = v_user_id 
        AND status = 'active'
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

    -- Get pending requests - FIXED: Removed json_agg to avoid GROUP BY issues
    WITH ranked_notifications AS (
        SELECT 
            n.id,
            n.user_id,
            n.data,
            n.created_at,
            COALESCE(
                (SELECT display_name FROM users WHERE id = n.user_id),
                (SELECT full_name FROM users WHERE id = n.user_id),
                'Unknown User'
            ) as user_name,
            COALESCE(
                (SELECT email FROM users WHERE id = n.user_id),
                'unknown@email.com'
            ) as user_email,
            (SELECT avatar_url FROM users WHERE id = n.user_id) as user_avatar
        FROM notifications n
        WHERE n.type = 'rank_change_request'
        AND (n.data->>'workflow_status') IN ('pending_club_review', 'pending_admin_review')
        AND (
            v_is_admin OR  -- System admin sees all
            (n.data->>'user_club_id')::UUID = v_user_club_id  -- Club admin sees their club's requests
        )
        ORDER BY n.created_at DESC
    )
    SELECT json_agg(
        json_build_object(
            'id', rn.id,
            'user_id', rn.user_id,
            'user_name', rn.user_name,
            'user_email', rn.user_email,
            'user_avatar', rn.user_avatar,
            'current_rank', (rn.data->>'current_rank'),
            'requested_rank', (rn.data->>'requested_rank'),
            'reason', (rn.data->>'reason'),
            'evidence_urls', (rn.data->'evidence_urls'),
            'submitted_at', (rn.data->>'submitted_at'),
            'workflow_status', (rn.data->>'workflow_status'),
            'user_club_id', (rn.data->>'user_club_id'),
            'created_at', rn.created_at
        )
    ) INTO v_requests
    FROM ranked_notifications rn;

    RETURN COALESCE(v_requests, '[]'::JSON);
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests() TO authenticated;
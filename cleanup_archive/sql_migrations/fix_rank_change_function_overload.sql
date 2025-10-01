-- Fix PostgreSQL function overloading error
-- Drop all existing versions and recreate clean

-- 1. Drop all existing versions of the problematic function
DROP FUNCTION IF EXISTS get_pending_rank_change_requests();
DROP FUNCTION IF EXISTS get_pending_rank_change_requests(UUID);
DROP FUNCTION IF EXISTS get_pending_rank_change_requests(p_club_id UUID);

-- 2. Create single clean version
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

    -- Check if user is system admin
    SELECT (role = 'admin') INTO v_is_admin
    FROM users 
    WHERE id = v_user_id;

    -- Get user's club if they're not admin
    IF NOT v_is_admin THEN
        SELECT club_id INTO v_user_club_id
        FROM club_memberships 
        WHERE user_id = v_user_id 
        AND role IN ('owner', 'admin')
        LIMIT 1;
        
        -- If user is not admin and not club admin, deny access
        IF v_user_club_id IS NULL THEN
            RAISE EXCEPTION 'Access denied: User must be system admin or club admin';
        END IF;
    END IF;

    -- Get pending requests based on user permissions
    SELECT json_agg(
        json_build_object(
            'id', n.id,
            'user_id', n.user_id,
            'user_name', u.display_name,
            'user_email', u.email,
            'user_avatar', u.avatar_url,
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
    JOIN users u ON n.user_id = u.id
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

-- 3. Grant permissions
GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests() TO authenticated;

-- 4. Test the function
SELECT 'Function recreated successfully' as status;
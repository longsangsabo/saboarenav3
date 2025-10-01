-- FIX GROUP BY ERROR IN RPC FUNCTION
-- Update admin_add_all_users_to_tournament function

CREATE OR REPLACE FUNCTION admin_add_all_users_to_tournament(
    p_tournament_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER  -- Run with database owner privileges
AS $$
DECLARE
    v_admin_id UUID;
    v_is_admin BOOLEAN;
    v_all_user_ids UUID[];
    v_result JSON;
BEGIN
    -- Get current user ID
    v_admin_id := auth.uid();
    
    -- Check if user exists and is admin
    SELECT role = 'admin' INTO v_is_admin
    FROM users 
    WHERE id = v_admin_id;
    
    IF NOT v_is_admin OR v_is_admin IS NULL THEN
        RAISE EXCEPTION 'Access denied: Only admins can perform this action';
    END IF;
    
    -- Get all user IDs except the admin - FIX: Remove ORDER BY to avoid GROUP BY issue
    SELECT array_agg(id) INTO v_all_user_ids
    FROM users 
    WHERE id != v_admin_id;
    
    -- Call the main function
    SELECT admin_add_users_to_tournament(p_tournament_id, v_all_user_ids) INTO v_result;
    
    RETURN v_result;
END;
$$;
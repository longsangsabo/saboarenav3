-- ==================================================
-- ADMIN RPC FUNCTIONS FOR TOURNAMENT MANAGEMENT
-- Allows admin users to manage tournaments bypassing RLS
-- ==================================================

-- Function to add multiple users to tournament (admin only)
CREATE OR REPLACE FUNCTION admin_add_users_to_tournament(
    p_tournament_id UUID,
    p_user_ids UUID[]
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER  -- Run with database owner privileges
AS $$
DECLARE
    v_admin_id UUID;
    v_is_admin BOOLEAN;
    v_tournament_record RECORD;
    v_user_id UUID;
    v_inserted_count INTEGER := 0;
    v_skipped_count INTEGER := 0;
    v_current_participants INTEGER;
    v_max_participants INTEGER;
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
    
    -- Get tournament details
    SELECT id, title, max_participants, current_participants, status
    INTO v_tournament_record
    FROM tournaments
    WHERE id = p_tournament_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tournament not found';
    END IF;
    
    IF v_tournament_record.status != 'upcoming' THEN
        RAISE EXCEPTION 'Tournament must be in upcoming status';
    END IF;
    
    v_current_participants := COALESCE(v_tournament_record.current_participants, 0);
    v_max_participants := COALESCE(v_tournament_record.max_participants, 100);
    
    -- Add each user to tournament
    FOREACH v_user_id IN ARRAY p_user_ids
    LOOP
        -- Check if tournament is full
        IF v_current_participants >= v_max_participants THEN
            EXIT; -- Stop adding more users
        END IF;
        
        -- Check if user already exists in tournament
        IF EXISTS (
            SELECT 1 FROM tournament_participants 
            WHERE tournament_id = p_tournament_id AND user_id = v_user_id
        ) THEN
            v_skipped_count := v_skipped_count + 1;
            CONTINUE;
        END IF;
        
        -- Insert user into tournament
        INSERT INTO tournament_participants (
            tournament_id,
            user_id,
            registered_at,
            status,
            payment_status
        ) VALUES (
            p_tournament_id,
            v_user_id,
            NOW(),
            'registered',
            'completed'
        );
        
        v_inserted_count := v_inserted_count + 1;
        v_current_participants := v_current_participants + 1;
    END LOOP;
    
    -- Update tournament participant count
    UPDATE tournaments 
    SET 
        current_participants = v_current_participants,
        updated_at = NOW()
    WHERE id = p_tournament_id;
    
    -- Log admin action
    INSERT INTO admin_activity_logs (
        admin_id,
        action,
        target_type,
        target_id,
        details,
        created_at
    ) VALUES (
        v_admin_id,
        'add_users_to_tournament',
        'tournament',
        p_tournament_id,
        jsonb_build_object(
            'users_added', v_inserted_count,
            'users_skipped', v_skipped_count,
            'tournament_title', v_tournament_record.title
        ),
        NOW()
    );
    
    -- Return result
    v_result := json_build_object(
        'success', true,
        'tournament_id', p_tournament_id,
        'tournament_title', v_tournament_record.title,
        'users_added', v_inserted_count,
        'users_skipped', v_skipped_count,
        'total_participants', v_current_participants,
        'max_participants', v_max_participants,
        'is_full', v_current_participants >= v_max_participants
    );
    
    RETURN v_result;
END;
$$;

-- Function to add ALL users to tournament (admin only)
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
    
    -- Get all user IDs except the admin
    SELECT array_agg(id) INTO v_all_user_ids
    FROM users 
    WHERE id != v_admin_id
    ORDER BY created_at ASC;
    
    -- Call the main function
    SELECT admin_add_users_to_tournament(p_tournament_id, v_all_user_ids) INTO v_result;
    
    RETURN v_result;
END;
$$;

-- Function to remove all users from tournament (admin only)
CREATE OR REPLACE FUNCTION admin_remove_all_users_from_tournament(
    p_tournament_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER  -- Run with database owner privileges
AS $$
DECLARE
    v_admin_id UUID;
    v_is_admin BOOLEAN;
    v_tournament_record RECORD;
    v_removed_count INTEGER;
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
    
    -- Get tournament details
    SELECT id, title INTO v_tournament_record
    FROM tournaments
    WHERE id = p_tournament_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tournament not found';
    END IF;
    
    -- Count participants before deletion
    SELECT COUNT(*) INTO v_removed_count
    FROM tournament_participants
    WHERE tournament_id = p_tournament_id;
    
    -- Remove all participants
    DELETE FROM tournament_participants
    WHERE tournament_id = p_tournament_id;
    
    -- Update tournament participant count
    UPDATE tournaments 
    SET 
        current_participants = 0,
        updated_at = NOW()
    WHERE id = p_tournament_id;
    
    -- Log admin action
    INSERT INTO admin_activity_logs (
        admin_id,
        action,
        target_type,
        target_id,
        details,
        created_at
    ) VALUES (
        v_admin_id,
        'remove_all_users_from_tournament',
        'tournament',
        p_tournament_id,
        jsonb_build_object(
            'users_removed', v_removed_count,
            'tournament_title', v_tournament_record.title
        ),
        NOW()
    );
    
    -- Return result
    v_result := json_build_object(
        'success', true,
        'tournament_id', p_tournament_id,
        'tournament_title', v_tournament_record.title,
        'users_removed', v_removed_count
    );
    
    RETURN v_result;
END;
$$;

-- Grant execute permissions to authenticated users (RLS will handle admin check)
GRANT EXECUTE ON FUNCTION admin_add_users_to_tournament(UUID, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_add_all_users_to_tournament(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_remove_all_users_from_tournament(UUID) TO authenticated;

-- Grant execute permissions to anon role (in case needed)
GRANT EXECUTE ON FUNCTION admin_add_users_to_tournament(UUID, UUID[]) TO anon;
GRANT EXECUTE ON FUNCTION admin_add_all_users_to_tournament(UUID) TO anon;
GRANT EXECUTE ON FUNCTION admin_remove_all_users_from_tournament(UUID) TO anon;
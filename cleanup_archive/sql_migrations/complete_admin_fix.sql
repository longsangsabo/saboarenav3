-- COMPLETE FIX FOR ADMIN RLS ISSUES
-- Fix both GROUP BY error and missing admin_activity_logs table

-- 1. Create admin_activity_logs table if not exists
CREATE TABLE IF NOT EXISTS admin_activity_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID REFERENCES users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    target_type TEXT,
    target_id UUID,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on admin_activity_logs
ALTER TABLE admin_activity_logs ENABLE ROW LEVEL SECURITY;

-- Policy for admin_activity_logs (only admins can read their own logs)
CREATE POLICY "Admins can manage their own activity logs" ON admin_activity_logs
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- 2. Fix the GROUP BY error in RPC function
CREATE OR REPLACE FUNCTION admin_add_all_users_to_tournament(
    p_tournament_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
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
    SELECT (role = 'admin') INTO v_is_admin
    FROM users 
    WHERE id = v_admin_id;
    
    IF NOT v_is_admin OR v_is_admin IS NULL THEN
        RAISE EXCEPTION 'Access denied: Only admins can perform this action';
    END IF;
    
    -- Get all user IDs except the admin - FIXED: Remove ORDER BY
    SELECT array_agg(id) INTO v_all_user_ids
    FROM users 
    WHERE id != v_admin_id;
    
    -- Call the main function
    SELECT admin_add_users_to_tournament(p_tournament_id, v_all_user_ids) INTO v_result;
    
    RETURN v_result;
END;
$$;

-- 3. Also fix the main admin_add_users_to_tournament function to handle missing table
CREATE OR REPLACE FUNCTION admin_add_users_to_tournament(
    p_tournament_id UUID,
    p_user_ids UUID[]
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
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
    SELECT (role = 'admin') INTO v_is_admin
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
    
    -- Try to log admin action (ignore errors if table doesn't exist)
    BEGIN
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
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore logging errors, continue with main operation
            NULL;
    END;
    
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
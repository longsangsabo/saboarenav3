-- Simple fix for club_review_rank_change_request function
-- This creates a simplified version that works with service role

CREATE OR REPLACE FUNCTION club_review_rank_change_request(
    request_id uuid,
    action text,
    new_rank text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    request_record rank_requests%ROWTYPE;
    user_record users%ROWTYPE;
    club_member_record club_members%ROWTYPE;  
    current_user_id uuid;
    result json;
BEGIN
    -- Get current user ID
    SELECT auth.uid() INTO current_user_id;
    
    -- If no current user (service role context), allow operation
    -- Otherwise check club membership
    IF current_user_id IS NOT NULL THEN
        -- Get the rank request
        SELECT * INTO request_record FROM rank_requests WHERE id = request_id;
        
        IF NOT FOUND THEN
            RETURN json_build_object('success', false, 'error', 'Request not found');
        END IF;
        
        -- Check if current user is admin of the club
        SELECT * INTO club_member_record 
        FROM club_members 
        WHERE user_id = current_user_id 
        AND club_id = request_record.club_id 
        AND role = 'admin';
        
        IF NOT FOUND THEN
            RETURN json_build_object('success', false, 'error', 'Not authorized');
        END IF;
    ELSE
        -- Service role context - get request without auth check
        SELECT * INTO request_record FROM rank_requests WHERE id = request_id;
        
        IF NOT FOUND THEN
            RETURN json_build_object('success', false, 'error', 'Request not found');
        END IF;
    END IF;
    
    -- Validate action
    IF action NOT IN ('approve', 'reject') THEN
        RETURN json_build_object('success', false, 'error', 'Invalid action');
    END IF;
    
    -- Process the action
    IF action = 'approve' THEN
        -- Update the request
        UPDATE rank_requests 
        SET status = 'approved'::request_status,
            reviewed_at = NOW(),
            reviewed_by = COALESCE(current_user_id, request_record.user_id)
        WHERE id = request_id;
        
        -- Get user info
        SELECT * INTO user_record FROM users WHERE id = request_record.user_id;
        
        -- Determine new rank
        IF new_rank IS NOT NULL THEN
            -- Use provided rank
            UPDATE users SET rank = new_rank, updated_at = NOW() WHERE id = request_record.user_id;
        ELSE
            -- Extract rank from notes (fallback)
            DECLARE
                extracted_rank text;
            BEGIN
                -- Try to extract rank from notes
                SELECT substring(request_record.notes FROM 'Rank mong muốn: ([A-Z+]+)') INTO extracted_rank;
                
                IF extracted_rank IS NOT NULL THEN
                    UPDATE users SET rank = extracted_rank, updated_at = NOW() WHERE id = request_record.user_id;
                ELSE
                    -- Default to K rank
                    UPDATE users SET rank = 'K', updated_at = NOW() WHERE id = request_record.user_id;
                END IF;
            END;
        END IF;
        
        result := json_build_object(
            'success', true, 
            'message', 'Request approved successfully',
            'user_id', request_record.user_id,
            'new_rank', COALESCE(new_rank, 'K')
        );
        
    ELSE -- reject
        UPDATE rank_requests 
        SET status = 'rejected'::request_status,
            reviewed_at = NOW(),
            reviewed_by = COALESCE(current_user_id, request_record.user_id)
        WHERE id = request_id;
        
        result := json_build_object(
            'success', true, 
            'message', 'Request rejected successfully'
        );
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false, 
            'error', SQLERRM,
            'detail', SQLSTATE
        );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION club_review_rank_change_request TO anon, authenticated, service_role;

-- Test comment to verify deployment
-- Function updated: Allow service role context (auth.uid() = null)
-- Function updated: Proper enum casting for request_status
-- Function updated: Better error handling and rank extraction
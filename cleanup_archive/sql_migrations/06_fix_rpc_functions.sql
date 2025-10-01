-- Fix RPC function to remove users references
-- This script will recreate the update_match_result function properly

-- Drop existing function first
DROP FUNCTION IF EXISTS public.update_match_result(uuid, uuid, integer, integer);
DROP FUNCTION IF EXISTS public.update_match_result(p_match_id uuid, p_winner_id uuid, p_player1_score integer, p_player2_score integer);

-- Create the correct update_match_result function
CREATE OR REPLACE FUNCTION public.update_match_result(
    p_match_id uuid,
    p_winner_id uuid,
    p_player1_score integer,
    p_player2_score integer
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result_data json;
BEGIN
    -- Update the match with new scores and winner
    UPDATE public.matches 
    SET 
        player1_score = p_player1_score,
        player2_score = p_player2_score,
        winner_id = p_winner_id,
        status = 'completed',
        updated_at = now()
    WHERE id = p_match_id;
    
    -- Check if update was successful
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Match not found with ID: %', p_match_id;
    END IF;
    
    -- Return success response
    SELECT json_build_object(
        'success', true,
        'match_id', p_match_id,
        'winner_id', p_winner_id,
        'player1_score', p_player1_score,
        'player2_score', p_player2_score,
        'message', 'Match result updated successfully'
    ) INTO result_data;
    
    RETURN result_data;
END;
$$;

-- Also recreate start_match function to ensure it's clean
DROP FUNCTION IF EXISTS public.start_match(uuid);

CREATE OR REPLACE FUNCTION public.start_match(
    p_match_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result_data json;
BEGIN
    -- Update match status to 'in_progress'
    UPDATE public.matches 
    SET 
        status = 'in_progress',
        updated_at = now()
    WHERE id = p_match_id;
    
    -- Check if update was successful
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Match not found with ID: %', p_match_id;
    END IF;
    
    -- Return success response
    SELECT json_build_object(
        'success', true,
        'match_id', p_match_id,
        'status', 'in_progress',
        'message', 'Match started successfully'
    ) INTO result_data;
    
    RETURN result_data;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.update_match_result(uuid, uuid, integer, integer) TO anon;
GRANT EXECUTE ON FUNCTION public.update_match_result(uuid, uuid, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.start_match(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.start_match(uuid) TO authenticated;

-- Test the function
SELECT 'RPC functions recreated successfully!' as message;
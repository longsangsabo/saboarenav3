-- Create RPC function for automatic tournament progression
-- This function will be called from Flutter app to trigger auto-fill

CREATE OR REPLACE FUNCTION auto_tournament_progression(tournament_id_param TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result_data JSON;
    completed_round INTEGER;
    next_round INTEGER;
    winner_count INTEGER;
    expected_winners INTEGER;
    match_record RECORD;
    next_match_record RECORD;
    progression_results JSON[] DEFAULT '{}';
BEGIN
    -- Log the start
    RAISE NOTICE 'Starting auto progression for tournament: %', tournament_id_param;
    
    -- Find the highest completed round
    SELECT COALESCE(MAX(round_number), 0) INTO completed_round
    FROM matches 
    WHERE tournament_id = tournament_id_param::UUID 
    AND winner_id IS NOT NULL;
    
    RAISE NOTICE 'Highest completed round: %', completed_round;
    
    -- Check if we have any completed rounds
    IF completed_round = 0 THEN
        RETURN json_build_object(
            'success', false,
            'message', 'No completed matches found',
            'updated_matches', 0
        );
    END IF;
    
    -- Calculate next round
    next_round := completed_round + 1;
    
    -- Count winners in completed round
    SELECT COUNT(*) INTO winner_count
    FROM matches 
    WHERE tournament_id = tournament_id_param::UUID 
    AND round_number = completed_round 
    AND winner_id IS NOT NULL;
    
    -- Calculate expected winners (should be even number for next round)
    expected_winners := winner_count;
    
    RAISE NOTICE 'Winners in round %: %', completed_round, winner_count;
    
    -- Check if we have enough winners to create next round
    IF winner_count < 2 THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Not enough winners to create next round',
            'updated_matches', 0
        );
    END IF;
    
    -- Check if next round already has players
    SELECT COUNT(*) INTO winner_count
    FROM matches 
    WHERE tournament_id = tournament_id_param::UUID 
    AND round_number = next_round 
    AND (player1_id IS NOT NULL OR player2_id IS NOT NULL);
    
    IF winner_count > 0 THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Next round already has players assigned',
            'updated_matches', 0
        );
    END IF;
    
    -- Get winners from completed round in order
    FOR match_record IN 
        SELECT winner_id, match_number
        FROM matches 
        WHERE tournament_id = tournament_id_param::UUID 
        AND round_number = completed_round 
        AND winner_id IS NOT NULL
        ORDER BY match_number
    LOOP
        -- Find corresponding next round match
        -- For SE16: R1M1,R1M2 -> R2M1; R1M3,R1M4 -> R2M2, etc.
        SELECT * INTO next_match_record
        FROM matches 
        WHERE tournament_id = tournament_id_param::UUID 
        AND round_number = next_round 
        AND match_number = CEIL(match_record.match_number::FLOAT / 2)
        LIMIT 1;
        
        IF FOUND THEN
            -- Assign winner to next round match
            IF next_match_record.player1_id IS NULL THEN
                UPDATE matches 
                SET player1_id = match_record.winner_id,
                    updated_at = NOW()
                WHERE id = next_match_record.id;
                
                progression_results := progression_results || json_build_object(
                    'match_id', next_match_record.id,
                    'player_slot', 1,
                    'player_id', match_record.winner_id
                );
                
            ELSIF next_match_record.player2_id IS NULL THEN
                UPDATE matches 
                SET player2_id = match_record.winner_id,
                    updated_at = NOW()
                WHERE id = next_match_record.id;
                
                progression_results := progression_results || json_build_object(
                    'match_id', next_match_record.id,
                    'player_slot', 2,
                    'player_id', match_record.winner_id
                );
            END IF;
        END IF;
    END LOOP;
    
    -- Return results
    result_data := json_build_object(
        'success', true,
        'message', 'Auto progression completed',
        'updated_matches', array_length(progression_results, 1),
        'progressions', progression_results,
        'from_round', completed_round,
        'to_round', next_round
    );
    
    RAISE NOTICE 'Auto progression result: %', result_data;
    
    RETURN result_data;
    
EXCEPTION WHEN others THEN
    RAISE NOTICE 'Error in auto progression: %', SQLERRM;
    RETURN json_build_object(
        'success', false,
        'message', 'Error: ' || SQLERRM,
        'updated_matches', 0
    );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION auto_tournament_progression(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION auto_tournament_progression(TEXT) TO authenticated;
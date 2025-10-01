-- =============================================
-- UNIVERSAL TOURNAMENT SYSTEM - DATABASE TRIGGERS & FUNCTIONS
-- Automatic match progression and tournament management
-- =============================================

-- =============================================
-- 1. TOURNAMENT BRACKET GENERATION FUNCTION
-- =============================================

CREATE OR REPLACE FUNCTION generate_tournament_bracket(
    p_tournament_id UUID,
    p_format TEXT,
    p_max_participants INTEGER
) RETURNS JSON AS $$
DECLARE
    result JSON;
    total_matches INTEGER;
    rounds_data JSON;
BEGIN
    -- Delete existing matches for this tournament
    DELETE FROM matches WHERE tournament_id = p_tournament_id;
    
    -- Generate matches based on format
    IF p_format = 'single_elimination' THEN
        -- Single elimination: n-1 matches for n players
        total_matches := p_max_participants - 1;
        SELECT generate_single_elimination_matches(p_tournament_id, p_max_participants) INTO rounds_data;
        
    ELSIF p_format = 'double_elimination' THEN
        -- Double elimination: ~2*(n-1) matches for n players
        total_matches := CASE 
            WHEN p_max_participants = 4 THEN 6
            WHEN p_max_participants = 8 THEN 14
            WHEN p_max_participants = 16 THEN 30
            WHEN p_max_participants = 32 THEN 62
            WHEN p_max_participants = 64 THEN 126
            ELSE p_max_participants * 2 - 2
        END;
        SELECT generate_double_elimination_matches(p_tournament_id, p_max_participants) INTO rounds_data;
        
    ELSE
        RAISE EXCEPTION 'Unsupported tournament format: %', p_format;
    END IF;
    
    -- Update tournament status
    UPDATE tournaments 
    SET status = 'ready', updated_at = NOW()
    WHERE id = p_tournament_id;
    
    -- Return result
    result := json_build_object(
        'success', true,
        'tournament_id', p_tournament_id,
        'format', p_format,
        'total_matches', total_matches,
        'rounds', rounds_data
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 2. SINGLE ELIMINATION MATCH GENERATION
-- =============================================

CREATE OR REPLACE FUNCTION generate_single_elimination_matches(
    p_tournament_id UUID,
    p_max_participants INTEGER
) RETURNS JSON AS $$
DECLARE
    match_counter INTEGER := 1;
    round_num INTEGER;
    matches_in_round INTEGER;
    i INTEGER;
    max_rounds INTEGER;
    rounds_info JSON := '{}';
BEGIN
    -- Calculate number of rounds
    max_rounds := CEIL(LOG(2, p_max_participants));
    
    -- Generate matches for each round
    FOR round_num IN 1..max_rounds LOOP
        matches_in_round := p_max_participants / POWER(2, round_num);
        
        -- Insert matches for this round
        FOR i IN 1..matches_in_round LOOP
            INSERT INTO matches (
                id, tournament_id, round_number, match_number,
                status, player1_score, player2_score,
                created_at, updated_at
            ) VALUES (
                gen_random_uuid(), p_tournament_id, round_num, match_counter,
                'pending', 0, 0,
                NOW(), NOW()
            );
            
            match_counter := match_counter + 1;
        END LOOP;
        
        -- Add round info
        rounds_info := rounds_info || json_build_object(round_num::text, matches_in_round);
    END LOOP;
    
    RETURN rounds_info;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 3. DOUBLE ELIMINATION MATCH GENERATION
-- =============================================

CREATE OR REPLACE FUNCTION generate_double_elimination_matches(
    p_tournament_id UUID,
    p_max_participants INTEGER
) RETURNS JSON AS $$
DECLARE
    match_counter INTEGER := 1;
    wb_rounds INTEGER;
    lb_rounds INTEGER;
    round_num INTEGER;
    matches_in_round INTEGER;
    i INTEGER;
    rounds_info JSON := '{}';
BEGIN
    -- Calculate bracket structure
    CASE p_max_participants
        WHEN 4 THEN wb_rounds := 2; lb_rounds := 2;
        WHEN 8 THEN wb_rounds := 3; lb_rounds := 5;
        WHEN 16 THEN wb_rounds := 4; lb_rounds := 7;
        WHEN 32 THEN wb_rounds := 5; lb_rounds := 9;
        WHEN 64 THEN wb_rounds := 6; lb_rounds := 11;
        ELSE 
            wb_rounds := CEIL(LOG(2, p_max_participants));
            lb_rounds := wb_rounds + 3;
    END CASE;
    
    -- Generate Winners Bracket matches
    FOR round_num IN 1..wb_rounds LOOP
        matches_in_round := p_max_participants / POWER(2, round_num);
        
        FOR i IN 1..matches_in_round LOOP
            INSERT INTO matches (
                id, tournament_id, round_number, match_number,
                status, player1_score, player2_score,
                created_at, updated_at
            ) VALUES (
                gen_random_uuid(), p_tournament_id, round_num, match_counter,
                'pending', 0, 0,
                NOW(), NOW()
            );
            
            match_counter := match_counter + 1;
        END LOOP;
        
        rounds_info := rounds_info || json_build_object(round_num::text, matches_in_round);
    END LOOP;
    
    -- Generate Losers Bracket matches (starting from round 101)
    FOR round_num IN 101..(100 + lb_rounds) LOOP
        -- Calculate matches for each LB round
        IF round_num = 101 THEN
            matches_in_round := p_max_participants / 4; -- First LB round
        ELSE
            -- Simplified LB calculation
            matches_in_round := GREATEST(1, matches_in_round / 2);
        END IF;
        
        FOR i IN 1..matches_in_round LOOP
            INSERT INTO matches (
                id, tournament_id, round_number, match_number,
                status, player1_score, player2_score,
                created_at, updated_at
            ) VALUES (
                gen_random_uuid(), p_tournament_id, round_num, match_counter,
                'pending', 0, 0,
                NOW(), NOW()
            );
            
            match_counter := match_counter + 1;
        END LOOP;
        
        rounds_info := rounds_info || json_build_object(round_num::text, matches_in_round);
    END LOOP;
    
    -- Generate Grand Final
    INSERT INTO matches (
        id, tournament_id, round_number, match_number,
        status, player1_score, player2_score,
        created_at, updated_at
    ) VALUES (
        gen_random_uuid(), p_tournament_id, wb_rounds + lb_rounds + 1, 9999,
        'pending', 0, 0,
        NOW(), NOW()
    );
    
    rounds_info := rounds_info || json_build_object((wb_rounds + lb_rounds + 1)::text, 1);
    
    RETURN rounds_info;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 4. AUTOMATIC PLAYER ADVANCEMENT TRIGGER
-- =============================================

CREATE OR REPLACE FUNCTION auto_advance_players() RETURNS TRIGGER AS $$
DECLARE
    tournament_format TEXT;
    advancement_result JSON;
BEGIN
    -- Only process if match was just completed
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.winner_id IS NOT NULL THEN
        
        -- Get tournament format
        SELECT bracket_format INTO tournament_format
        FROM tournaments
        WHERE id = NEW.tournament_id;
        
        -- Execute format-specific advancement
        IF tournament_format = 'single_elimination' THEN
            SELECT advance_single_elimination_players(NEW.tournament_id, NEW.id, NEW.winner_id) INTO advancement_result;
        ELSIF tournament_format = 'double_elimination' THEN
            SELECT advance_double_elimination_players(NEW.tournament_id, NEW.id, NEW.winner_id) INTO advancement_result;
        END IF;
        
        -- Log advancement (optional)
        RAISE NOTICE 'Player advancement completed: %', advancement_result;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS match_completion_trigger ON matches;
CREATE TRIGGER match_completion_trigger
    AFTER UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION auto_advance_players();

-- =============================================
-- 5. SINGLE ELIMINATION ADVANCEMENT LOGIC
-- =============================================

CREATE OR REPLACE FUNCTION advance_single_elimination_players(
    p_tournament_id UUID,
    p_match_id UUID,
    p_winner_id UUID
) RETURNS JSON AS $$
DECLARE
    current_match RECORD;
    next_match_number INTEGER;
    next_match_id UUID;
    advancement_count INTEGER := 0;
BEGIN
    -- Get current match info
    SELECT round_number, match_number INTO current_match
    FROM matches
    WHERE id = p_match_id;
    
    -- Calculate next match number (winner advances)
    SELECT calculate_se_next_match(current_match.match_number, current_match.round_number, p_tournament_id) 
    INTO next_match_number;
    
    -- Advance winner if there's a next match
    IF next_match_number IS NOT NULL THEN
        -- Find the next match
        SELECT id INTO next_match_id
        FROM matches
        WHERE tournament_id = p_tournament_id AND match_number = next_match_number;
        
        -- Assign winner to next match
        IF (SELECT player1_id FROM matches WHERE id = next_match_id) IS NULL THEN
            UPDATE matches SET player1_id = p_winner_id WHERE id = next_match_id;
            advancement_count := advancement_count + 1;
        ELSIF (SELECT player2_id FROM matches WHERE id = next_match_id) IS NULL THEN
            UPDATE matches SET player2_id = p_winner_id WHERE id = next_match_id;
            advancement_count := advancement_count + 1;
        END IF;
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'advancements', advancement_count,
        'winner_advanced_to', next_match_number
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 6. DOUBLE ELIMINATION ADVANCEMENT LOGIC
-- =============================================

CREATE OR REPLACE FUNCTION advance_double_elimination_players(
    p_tournament_id UUID,
    p_match_id UUID,
    p_winner_id UUID
) RETURNS JSON AS $$
DECLARE
    current_match RECORD;
    loser_id UUID;
    winner_next_match INTEGER;
    loser_next_match INTEGER;
    advancement_count INTEGER := 0;
BEGIN
    -- Get current match info and determine loser
    SELECT round_number, match_number, player1_id, player2_id 
    INTO current_match
    FROM matches
    WHERE id = p_match_id;
    
    -- Determine loser
    loser_id := CASE 
        WHEN current_match.player1_id = p_winner_id THEN current_match.player2_id
        ELSE current_match.player1_id
    END;
    
    -- Calculate advancement destinations
    SELECT calculate_de_winner_next_match(current_match.match_number, current_match.round_number, p_tournament_id)
    INTO winner_next_match;
    
    SELECT calculate_de_loser_next_match(current_match.match_number, current_match.round_number, p_tournament_id)
    INTO loser_next_match;
    
    -- Advance winner
    IF winner_next_match IS NOT NULL THEN
        PERFORM advance_player_to_match(p_tournament_id, p_winner_id, winner_next_match);
        advancement_count := advancement_count + 1;
    END IF;
    
    -- Advance loser (if not eliminated)
    IF loser_next_match IS NOT NULL THEN
        PERFORM advance_player_to_match(p_tournament_id, loser_id, loser_next_match);
        advancement_count := advancement_count + 1;
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'advancements', advancement_count,
        'winner_advanced_to', winner_next_match,
        'loser_advanced_to', loser_next_match
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 7. HELPER FUNCTIONS
-- =============================================

-- Calculate next match for Single Elimination
CREATE OR REPLACE FUNCTION calculate_se_next_match(
    p_current_match INTEGER,
    p_current_round INTEGER,
    p_tournament_id UUID
) RETURNS INTEGER AS $$
DECLARE
    max_round INTEGER;
    next_match INTEGER;
BEGIN
    -- Get max round
    SELECT MAX(round_number) INTO max_round
    FROM matches
    WHERE tournament_id = p_tournament_id;
    
    -- If final match, no advancement
    IF p_current_round >= max_round THEN
        RETURN NULL;
    END IF;
    
    -- Calculate next match (simplified)
    SELECT MIN(match_number) INTO next_match
    FROM matches
    WHERE tournament_id = p_tournament_id 
      AND round_number = p_current_round + 1
      AND (player1_id IS NULL OR player2_id IS NULL);
    
    RETURN next_match;
END;
$$ LANGUAGE plpgsql;

-- Calculate winner advancement for Double Elimination
CREATE OR REPLACE FUNCTION calculate_de_winner_next_match(
    p_current_match INTEGER,
    p_current_round INTEGER,
    p_tournament_id UUID
) RETURNS INTEGER AS $$
DECLARE
    next_match INTEGER;
BEGIN
    -- Winners bracket advancement (simplified)
    IF p_current_round < 100 THEN -- Winners bracket
        SELECT MIN(match_number) INTO next_match
        FROM matches
        WHERE tournament_id = p_tournament_id 
          AND round_number = p_current_round + 1
          AND round_number < 100
          AND (player1_id IS NULL OR player2_id IS NULL);
    ELSE -- Losers bracket
        SELECT MIN(match_number) INTO next_match
        FROM matches
        WHERE tournament_id = p_tournament_id 
          AND round_number = p_current_round + 1
          AND (player1_id IS NULL OR player2_id IS NULL);
    END IF;
    
    RETURN next_match;
END;
$$ LANGUAGE plpgsql;

-- Calculate loser advancement for Double Elimination
CREATE OR REPLACE FUNCTION calculate_de_loser_next_match(
    p_current_match INTEGER,
    p_current_round INTEGER,
    p_tournament_id UUID
) RETURNS INTEGER AS $$
DECLARE
    next_match INTEGER;
BEGIN
    -- Only winners bracket losers advance (to losers bracket)
    IF p_current_round < 100 THEN
        -- Find appropriate losers bracket match
        SELECT MIN(match_number) INTO next_match
        FROM matches
        WHERE tournament_id = p_tournament_id 
          AND round_number >= 101
          AND (player1_id IS NULL OR player2_id IS NULL);
    ELSE
        -- Losers bracket losers are eliminated
        RETURN NULL;
    END IF;
    
    RETURN next_match;
END;
$$ LANGUAGE plpgsql;

-- Advance player to specific match
CREATE OR REPLACE FUNCTION advance_player_to_match(
    p_tournament_id UUID,
    p_player_id UUID,
    p_target_match INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    target_match_id UUID;
BEGIN
    -- Get target match ID
    SELECT id INTO target_match_id
    FROM matches
    WHERE tournament_id = p_tournament_id AND match_number = p_target_match;
    
    -- Assign to first available slot
    IF (SELECT player1_id FROM matches WHERE id = target_match_id) IS NULL THEN
        UPDATE matches SET player1_id = p_player_id WHERE id = target_match_id;
        RETURN TRUE;
    ELSIF (SELECT player2_id FROM matches WHERE id = target_match_id) IS NULL THEN
        UPDATE matches SET player2_id = p_player_id WHERE id = target_match_id;
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 8. TOURNAMENT COMPLETION CHECK
-- =============================================

CREATE OR REPLACE FUNCTION check_tournament_completion(p_tournament_id UUID) RETURNS BOOLEAN AS $$
DECLARE
    total_matches INTEGER;
    completed_matches INTEGER;
BEGIN
    -- Count total and completed matches
    SELECT COUNT(*) INTO total_matches
    FROM matches
    WHERE tournament_id = p_tournament_id;
    
    SELECT COUNT(*) INTO completed_matches
    FROM matches
    WHERE tournament_id = p_tournament_id AND status = 'completed';
    
    -- Update tournament status if complete
    IF total_matches > 0 AND completed_matches = total_matches THEN
        UPDATE tournaments
        SET status = 'completed', updated_at = NOW()
        WHERE id = p_tournament_id;
        
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- EXAMPLES OF USAGE
-- =============================================

/*
-- Generate bracket for a tournament
SELECT generate_tournament_bracket(
    '95cee835-9265-4b08-95b1-a5f9a67c1ec8'::UUID,
    'double_elimination',
    16
);

-- Check tournament completion
SELECT check_tournament_completion('95cee835-9265-4b08-95b1-a5f9a67c1ec8'::UUID);

-- The triggers will automatically handle player advancement when matches are completed
*/
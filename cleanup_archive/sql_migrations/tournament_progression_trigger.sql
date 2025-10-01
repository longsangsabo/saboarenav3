-- Auto Tournament Progression Trigger
-- Creates next round matches automatically when current round completes

CREATE OR REPLACE FUNCTION create_next_round_matches()
RETURNS TRIGGER AS $$
DECLARE
    tournament_rec RECORD;
    current_round_number INTEGER;
    total_matches INTEGER;
    completed_matches INTEGER;
    next_round_matches INTEGER;
    match_counter INTEGER := 1;
    winner_1 UUID;
    winner_2 UUID;
    participants_count INTEGER;
    max_rounds INTEGER;
BEGIN
    -- Only process if winner_id was updated (not NULL)
    IF NEW.winner_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Get tournament info
    SELECT * INTO tournament_rec FROM tournaments WHERE id = NEW.tournament_id;
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;
    
    current_round_number := NEW.round_number;
    
    -- Count total matches and completed matches with winners in current round
    SELECT COUNT(*) INTO total_matches 
    FROM matches 
    WHERE tournament_id = NEW.tournament_id 
    AND round_number = current_round_number;
    
    SELECT COUNT(*) INTO completed_matches 
    FROM matches 
    WHERE tournament_id = NEW.tournament_id 
    AND round_number = current_round_number 
    AND winner_id IS NOT NULL;
    
    -- Calculate max rounds based on participants (for single elimination)
    SELECT COUNT(*) INTO participants_count 
    FROM tournament_participants 
    WHERE tournament_id = NEW.tournament_id;
    
    -- For single elimination: 16 players = 4 rounds, 32 players = 5 rounds
    max_rounds := CEIL(LOG(2, participants_count));
    
    -- Check if this is the final round
    IF current_round_number >= max_rounds THEN
        -- Tournament is complete, do not create more rounds
        RAISE NOTICE 'Tournament % completed at round %', NEW.tournament_id, current_round_number;
        RETURN NEW;
    END IF;
    
    -- If all matches in current round are complete, create next round
    IF completed_matches = total_matches AND total_matches > 1 THEN
        
        -- Check if next round already exists
        SELECT COUNT(*) INTO next_round_matches
        FROM matches 
        WHERE tournament_id = NEW.tournament_id 
        AND round_number = current_round_number + 1;
        
        -- Only create if next round doesn't exist
        IF next_round_matches = 0 THEN
            
            -- Create next round matches by pairing winners
            FOR i IN 1..total_matches/2 LOOP
                -- Get winners from current round matches
                SELECT winner_id INTO winner_1 
                FROM matches 
                WHERE tournament_id = NEW.tournament_id 
                AND round_number = current_round_number 
                AND match_number = (i-1)*2 + 1;
                
                SELECT winner_id INTO winner_2 
                FROM matches 
                WHERE tournament_id = NEW.tournament_id 
                AND round_number = current_round_number 
                AND match_number = (i-1)*2 + 2;
                
                -- Create the next round match
                IF winner_1 IS NOT NULL AND winner_2 IS NOT NULL THEN
                    INSERT INTO matches (
                        tournament_id,
                        round_number,
                        match_number,
                        player1_id,
                        player2_id,
                        status,
                        player1_score,
                        player2_score,
                        created_at
                    ) VALUES (
                        NEW.tournament_id,
                        current_round_number + 1,
                        match_counter,
                        winner_1,
                        winner_2,
                        'pending',
                        0,
                        0,
                        NOW()
                    );
                    
                    match_counter := match_counter + 1;
                    
                    RAISE NOTICE 'Created match for round % between % and %', 
                        current_round_number + 1, winner_1, winner_2;
                END IF;
            END LOOP;
            
            RAISE NOTICE 'Created % matches for round %', 
                match_counter - 1, current_round_number + 1;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_create_next_round ON matches;

-- Create the trigger
CREATE TRIGGER auto_create_next_round
    AFTER UPDATE OF winner_id ON matches
    FOR EACH ROW
    WHEN (NEW.winner_id IS NOT NULL AND OLD.winner_id IS NULL)
    EXECUTE FUNCTION create_next_round_matches();
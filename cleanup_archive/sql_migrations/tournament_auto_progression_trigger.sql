-- =============================================
-- TOURNAMENT AUTO PROGRESSION SYSTEM
-- Tự động fill winners vào round tiếp theo khi matches hoàn thành
-- =============================================

-- Drop existing function if exists
DROP FUNCTION IF EXISTS trigger_tournament_progression();

-- Create the auto progression function
CREATE OR REPLACE FUNCTION trigger_tournament_progression()
RETURNS TRIGGER AS $$
DECLARE
    tournament_format TEXT;
    total_matches INTEGER;
    rec RECORD;
    source_winner UUID;
    target_exists BOOLEAN;
    filled_count INTEGER := 0;
BEGIN
    -- Only proceed if a match was completed (winner_id was set)
    IF NEW.winner_id IS NOT NULL AND OLD.winner_id IS NULL THEN
        
        RAISE NOTICE 'Tournament progression triggered for tournament: %', NEW.tournament_id;
        
        -- Detect tournament format based on total matches
        SELECT COUNT(*) INTO total_matches 
        FROM matches 
        WHERE tournament_id = NEW.tournament_id;
        
        IF total_matches = 15 THEN
            tournament_format := 'DE8';
        ELSIF total_matches = 27 THEN
            tournament_format := 'DE16';
        ELSIF total_matches = 57 THEN
            tournament_format := 'DE32';
        ELSE
            RAISE NOTICE 'Unknown tournament format with % matches', total_matches;
            RETURN NEW;
        END IF;
        
        RAISE NOTICE 'Detected format: % (% matches)', tournament_format, total_matches;
        
        -- Apply progression rules based on format
        IF tournament_format = 'DE8' THEN
            -- DE8 Progression Rules
            FOR rec IN (
                VALUES 
                    ('R2M1', ARRAY['R1M1', 'R1M2']),
                    ('R2M2', ARRAY['R1M3', 'R1M4']),
                    ('R2M3', ARRAY['R1M5', 'R1M6']),
                    ('R2M4', ARRAY['R1M7', 'R1M8']),
                    ('R3M1', ARRAY['R2M1', 'R2M2']),
                    ('R3M2', ARRAY['R2M3', 'R2M4']),
                    ('R4M1', ARRAY['R3M1', 'R3M2'])
            ) AS t(target, sources)
            LOOP
                PERFORM apply_progression_rule(NEW.tournament_id, rec.target, rec.sources);
            END LOOP;
            
        ELSIF tournament_format = 'DE16' THEN
            -- DE16 Progression Rules
            FOR rec IN (
                VALUES 
                    ('R2M1', ARRAY['R1M1', 'R1M2']),
                    ('R2M2', ARRAY['R1M3', 'R1M4']),
                    ('R2M3', ARRAY['R1M5', 'R1M6']),
                    ('R2M4', ARRAY['R1M7', 'R1M8']),
                    ('R2M5', ARRAY['R1M9', 'R1M10']),
                    ('R2M6', ARRAY['R1M11', 'R1M12']),
                    ('R2M7', ARRAY['R1M13', 'R1M14']),
                    ('R2M8', ARRAY['R1M15', 'R1M16']),
                    ('R3M1', ARRAY['R2M1', 'R2M2']),
                    ('R3M2', ARRAY['R2M3', 'R2M4']),
                    ('R3M3', ARRAY['R2M5', 'R2M6']),
                    ('R3M4', ARRAY['R2M7', 'R2M8']),
                    ('R4M1', ARRAY['R3M1', 'R3M2']),
                    ('R4M2', ARRAY['R3M3', 'R3M4']),
                    ('R5M1', ARRAY['R4M1', 'R4M2'])
            ) AS t(target, sources)
            LOOP
                PERFORM apply_progression_rule(NEW.tournament_id, rec.target, rec.sources);
            END LOOP;
        END IF;
        
        RAISE NOTICE 'Tournament progression completed for: %', NEW.tournament_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Helper function to apply progression rule
CREATE OR REPLACE FUNCTION apply_progression_rule(
    tournament_id_param UUID,
    target_match TEXT,
    source_matches TEXT[]
)
RETURNS VOID AS $$
DECLARE
    target_round INTEGER;
    target_match_num INTEGER;
    source_round INTEGER;
    source_match_num INTEGER;
    winner1 UUID;
    winner2 UUID;
    current_p1 UUID;
    current_p2 UUID;
    source_match TEXT;
BEGIN
    -- Parse target match (e.g., "R2M1" -> round=2, match=1)
    target_round := SUBSTRING(target_match FROM 2 FOR 1)::INTEGER;
    target_match_num := SUBSTRING(target_match FROM 4)::INTEGER;
    
    -- Check if target match already has players
    SELECT player1_id, player2_id INTO current_p1, current_p2
    FROM matches 
    WHERE tournament_id = tournament_id_param 
      AND round_number = target_round 
      AND match_number = target_match_num;
      
    IF current_p1 IS NOT NULL AND current_p2 IS NOT NULL THEN
        -- Target already has players, skip
        RETURN;
    END IF;
    
    -- Get winners from source matches
    winner1 := NULL;
    winner2 := NULL;
    
    -- First source match
    source_match := source_matches[1];
    source_round := SUBSTRING(source_match FROM 2 FOR 1)::INTEGER;
    source_match_num := SUBSTRING(source_match FROM 4)::INTEGER;
    
    SELECT winner_id INTO winner1
    FROM matches 
    WHERE tournament_id = tournament_id_param 
      AND round_number = source_round 
      AND match_number = source_match_num;
    
    -- Second source match
    source_match := source_matches[2];
    source_round := SUBSTRING(source_match FROM 2 FOR 1)::INTEGER;
    source_match_num := SUBSTRING(source_match FROM 4)::INTEGER;
    
    SELECT winner_id INTO winner2
    FROM matches 
    WHERE tournament_id = tournament_id_param 
      AND round_number = source_round 
      AND match_number = source_match_num;
    
    -- If both winners exist, update target match
    IF winner1 IS NOT NULL AND winner2 IS NOT NULL THEN
        UPDATE matches 
        SET player1_id = winner1,
            player2_id = winner2,
            status = 'pending'
        WHERE tournament_id = tournament_id_param 
          AND round_number = target_round 
          AND match_number = target_match_num;
          
        RAISE NOTICE 'Updated %: % vs %', target_match, winner1, winner2;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS tournament_auto_progression_trigger ON matches;

-- Create the trigger
CREATE TRIGGER tournament_auto_progression_trigger
    AFTER UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION trigger_tournament_progression();

-- Test notification
RAISE NOTICE 'Tournament Auto Progression System installed successfully!';
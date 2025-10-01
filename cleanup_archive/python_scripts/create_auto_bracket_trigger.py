from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

# Create the trigger function
trigger_function = """
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
                END IF;
            END LOOP;
            
            -- If only 1 match created in next round, that's the final
            IF match_counter = 2 THEN
                -- This means we have a final match, tournament is almost complete
                RAISE NOTICE 'Final match created for tournament %', NEW.tournament_id;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
"""

# Create the trigger
trigger_sql = """
DROP TRIGGER IF EXISTS auto_create_next_round ON matches;
CREATE TRIGGER auto_create_next_round
    AFTER UPDATE OF winner_id ON matches
    FOR EACH ROW
    WHEN (NEW.winner_id IS NOT NULL AND OLD.winner_id IS NULL)
    EXECUTE FUNCTION create_next_round_matches();
"""

print("=== CREATING AUTO BRACKET PROGRESSION TRIGGER ===")

try:
    # Execute the function creation
    result = supabase.rpc('execute_sql', {'sql': trigger_function}).execute()
    print("✅ Created trigger function")
except Exception as e:
    print(f"❌ Failed to create function: {e}")

try:
    # Execute the trigger creation
    result = supabase.rpc('execute_sql', {'sql': trigger_sql}).execute()
    print("✅ Created trigger")
except Exception as e:
    print(f"❌ Failed to create trigger: {e}")

print("\n=== TESTING TRIGGER ===")
print("Now when a match gets a winner_id, it should automatically create next round matches!")

# Test by checking current state
tournament_id = '6c0658f7-bf94-44a0-82b1-de117ec9ea29'
matches = supabase.table('matches').select('round_number, match_number, status, winner_id').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()

round_stats = {}
for match in matches.data:
    rnd = match['round_number']
    if rnd not in round_stats:
        round_stats[rnd] = {'total': 0, 'with_winner': 0}
    round_stats[rnd]['total'] += 1
    if match['winner_id']:
        round_stats[rnd]['with_winner'] += 1

for rnd, stats in round_stats.items():
    status = "COMPLETE" if stats['with_winner'] == stats['total'] else "INCOMPLETE"
    print(f"Round {rnd}: {stats['with_winner']}/{stats['total']} matches with winners - {status}")
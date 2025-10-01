-- 🏆 SABO ARENA - Smart Bracket Integration Schema
-- Mở rộng database hiện tại thay vì tạo bảng mới

-- 1. Thêm cột bracket_data vào bảng tournaments (JSONB column)
ALTER TABLE tournaments 
ADD COLUMN IF NOT EXISTS bracket_data JSONB DEFAULT '{}';

-- 2. Thêm bracket-specific columns vào matches table
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS bracket_type TEXT DEFAULT 'winner'; -- 'winner', 'loser', 'grand_final'

ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS parent_match_id UUID REFERENCES matches(id); -- For progression tracking

ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS bracket_position INTEGER; -- Position in bracket visualization

-- 3. Thêm seeding và bracket metadata vào tournament_participants
ALTER TABLE tournament_participants 
ADD COLUMN IF NOT EXISTS bracket_seed INTEGER;

ALTER TABLE tournament_participants 
ADD COLUMN IF NOT EXISTS bracket_metadata JSONB DEFAULT '{}';

-- 4. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_matches_tournament_round 
ON matches(tournament_id, round_number);

CREATE INDEX IF NOT EXISTS idx_matches_bracket_type 
ON matches(tournament_id, bracket_type);

CREATE INDEX IF NOT EXISTS idx_participants_seed 
ON tournament_participants(tournament_id, bracket_seed);

-- 5. Comments để document structure
COMMENT ON COLUMN tournaments.bracket_data IS 'JSONB structure containing bracket metadata, generated structure, and seeding information';

COMMENT ON COLUMN matches.bracket_type IS 'Type of bracket: winner, loser, grand_final for double elimination';

COMMENT ON COLUMN matches.parent_match_id IS 'Reference to the match whose winner/loser feeds into this match';

COMMENT ON COLUMN matches.bracket_position IS 'Position number for bracket visualization and ordering';

COMMENT ON COLUMN tournament_participants.bracket_seed IS 'Seeding position for tournament bracket (1 = highest seed)';

COMMENT ON COLUMN tournament_participants.bracket_metadata IS 'Additional bracket-specific data like ELO at seeding time';

-- 6. Sample bracket_data structure (example for documentation)
/*
Example tournaments.bracket_data structure:
{
  "format": "single_elimination",
  "bracketSize": 16,
  "totalRounds": 4,
  "seedingMethod": "elo_rating",
  "structure": {
    "type": "single_elimination",
    "rounds": [
      {
        "round": 1,
        "name": "Vòng 1",
        "matchCount": 8
      },
      {
        "round": 2, 
        "name": "Tứ kết",
        "matchCount": 4
      }
    ]
  },
  "generatedAt": "2025-09-26T12:00:00Z",
  "generatedBy": "BracketGeneratorService"
}

Example tournament_participants.bracket_metadata:
{
  "eloAtSeeding": 1500,
  "rankAtSeeding": "E",
  "seedingMethod": "elo_rating",
  "bracketPosition": 1
}

Example matches progression:
Round 1, Match 1: Player1 vs Player2 -> Winner goes to Round 2, Match 1
Round 1, Match 2: Player3 vs Player4 -> Winner goes to Round 2, Match 1
Round 2, Match 1: Winner(R1M1) vs Winner(R1M2) -> Winner goes to Round 3, Match 1
*/
-- ⚔️ SABO ARENA - ENHANCED CHALLENGE SYSTEM WITH RULES
-- Database schema to support comprehensive challenge rules, handicap system, and SPA betting

-- 1. Challenge Configurations Table (SPA Betting Rules)
CREATE TABLE IF NOT EXISTS challenge_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bet_amount INTEGER NOT NULL UNIQUE,
  race_to INTEGER NOT NULL,
  description VARCHAR(100) NOT NULL,
  description_vi VARCHAR(100) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert SPA betting configurations
INSERT INTO challenge_configurations (bet_amount, race_to, description, description_vi) VALUES
(100, 8, 'Entry level challenge', 'Thách đấu sơ cấp'),
(200, 12, 'Basic challenge', 'Thách đấu cơ bản'),
(300, 14, 'Medium challenge', 'Thách đấu trung bình'),
(400, 16, 'Intermediate challenge', 'Thách đấu trung cấp'),
(500, 18, 'Advanced challenge', 'Thách đấu trung cao'),
(600, 22, 'Expert challenge', 'Thách đấu cao cấp')
ON CONFLICT (bet_amount) DO NOTHING;

-- 2. Rank System Table (SABO 12-tier ranking)
CREATE TABLE IF NOT EXISTS rank_system (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rank_code VARCHAR(10) NOT NULL UNIQUE,
  rank_value INTEGER NOT NULL UNIQUE,
  rank_name VARCHAR(50) NOT NULL,
  rank_name_vi VARCHAR(50) NOT NULL,
  color_hex VARCHAR(7) NOT NULL,
  elo_min INTEGER,
  elo_max INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert SABO rank system
INSERT INTO rank_system (rank_code, rank_value, rank_name, rank_name_vi, color_hex, elo_min, elo_max) VALUES
('K', 1, 'Starter', 'Khởi đầu', '#4CAF50', 0, 999),
('K+', 2, 'Starter Plus', 'Khởi đầu+', '#4CAF50', 1000, 1199),
('I', 3, 'Beginner', 'Sơ cấp', '#2196F3', 1200, 1399),
('I+', 4, 'Beginner Plus', 'Sơ cấp+', '#2196F3', 1400, 1599),
('H', 5, 'Intermediate', 'Trung cấp', '#FF9800', 1600, 1799),
('H+', 6, 'Intermediate Plus', 'Trung cấp+', '#FF9800', 1800, 1999),
('G', 7, 'Advanced', 'Trung cao', '#9C27B0', 2000, 2199),
('G+', 8, 'Advanced Plus', 'Trung cao+', '#9C27B0', 2200, 2399),
('F', 9, 'Expert', 'Cao cấp', '#F44336', 2400, 2599),
('F+', 10, 'Expert Plus', 'Cao cấp+', '#F44336', 2600, 2799),
('E', 11, 'Professional', 'Chuyên nghiệp', '#607D8B', 2800, 2999),
('E+', 12, 'Master', 'Bậc thầy', '#607D8B', 3000, 5000)
ON CONFLICT (rank_code) DO NOTHING;

-- 3. Handicap Rules Table
CREATE TABLE IF NOT EXISTS handicap_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rank_difference_type VARCHAR(20) NOT NULL, -- '1_sub', '1_main', '1.5_main', '2_main'
  rank_difference_value INTEGER NOT NULL, -- Actual sub-rank difference (1, 2, 3, 4)
  bet_amount INTEGER NOT NULL REFERENCES challenge_configurations(bet_amount),
  handicap_value DECIMAL(3,1) NOT NULL,
  description VARCHAR(100),
  description_vi VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(rank_difference_type, bet_amount)
);

-- Insert handicap matrix
INSERT INTO handicap_rules (rank_difference_type, rank_difference_value, bet_amount, handicap_value, description, description_vi) VALUES
-- 1 sub-rank difference
('1_sub', 1, 100, 0.5, '1 sub-rank, 100 SPA', '1 sub-rank, 100 SPA'),
('1_sub', 1, 200, 1.0, '1 sub-rank, 200 SPA', '1 sub-rank, 200 SPA'),
('1_sub', 1, 300, 1.5, '1 sub-rank, 300 SPA', '1 sub-rank, 300 SPA'),
('1_sub', 1, 400, 1.5, '1 sub-rank, 400 SPA', '1 sub-rank, 400 SPA'),
('1_sub', 1, 500, 2.0, '1 sub-rank, 500 SPA', '1 sub-rank, 500 SPA'),
('1_sub', 1, 600, 2.5, '1 sub-rank, 600 SPA', '1 sub-rank, 600 SPA'),

-- 1 main rank difference (2 sub-ranks)
('1_main', 2, 100, 1.0, '1 main rank, 100 SPA', '1 hạng chính, 100 SPA'),
('1_main', 2, 200, 1.5, '1 main rank, 200 SPA', '1 hạng chính, 200 SPA'),
('1_main', 2, 300, 2.0, '1 main rank, 300 SPA', '1 hạng chính, 300 SPA'),
('1_main', 2, 400, 2.5, '1 main rank, 400 SPA', '1 hạng chính, 400 SPA'),
('1_main', 2, 500, 3.0, '1 main rank, 500 SPA', '1 hạng chính, 500 SPA'),
('1_main', 2, 600, 3.5, '1 main rank, 600 SPA', '1 hạng chính, 600 SPA'),

-- 1.5 main rank difference (3 sub-ranks)
('1.5_main', 3, 100, 1.5, '1.5 main rank, 100 SPA', '1.5 hạng chính, 100 SPA'),
('1.5_main', 3, 200, 2.5, '1.5 main rank, 200 SPA', '1.5 hạng chính, 200 SPA'),
('1.5_main', 3, 300, 3.5, '1.5 main rank, 300 SPA', '1.5 hạng chính, 300 SPA'),
('1.5_main', 3, 400, 4.0, '1.5 main rank, 400 SPA', '1.5 hạng chính, 400 SPA'),
('1.5_main', 3, 500, 5.0, '1.5 main rank, 500 SPA', '1.5 hạng chính, 500 SPA'),
('1.5_main', 3, 600, 6.0, '1.5 main rank, 600 SPA', '1.5 hạng chính, 600 SPA'),

-- 2 main rank difference (4 sub-ranks - maximum allowed)
('2_main', 4, 100, 2.0, '2 main rank, 100 SPA', '2 hạng chính, 100 SPA'),
('2_main', 4, 200, 3.0, '2 main rank, 200 SPA', '2 hạng chính, 200 SPA'),
('2_main', 4, 300, 4.0, '2 main rank, 300 SPA', '2 hạng chính, 300 SPA'),
('2_main', 4, 400, 5.0, '2 main rank, 400 SPA', '2 hạng chính, 400 SPA'),
('2_main', 4, 500, 6.0, '2 main rank, 500 SPA', '2 hạng chính, 500 SPA'),
('2_main', 4, 600, 7.0, '2 main rank, 600 SPA', '2 hạng chính, 600 SPA')
ON CONFLICT (rank_difference_type, bet_amount) DO NOTHING;

-- 4. Challenge Eligibility View (who can challenge whom)
CREATE OR REPLACE VIEW challenge_eligibility AS
SELECT 
  r1.rank_code as challenger_rank,
  r1.rank_value as challenger_value,
  r2.rank_code as target_rank,
  r2.rank_value as target_value,
  ABS(r1.rank_value - r2.rank_value) as rank_difference,
  CASE 
    WHEN ABS(r1.rank_value - r2.rank_value) <= 4 THEN true 
    ELSE false 
  END as can_challenge
FROM rank_system r1
CROSS JOIN rank_system r2
WHERE ABS(r1.rank_value - r2.rank_value) <= 4;

-- 5. Enhanced challenges table (if not exists or missing columns)
DO $$ 
BEGIN
  -- Add missing columns to challenges table
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'challenges' AND column_name = 'challenge_config_id') THEN
    ALTER TABLE challenges ADD COLUMN challenge_config_id UUID REFERENCES challenge_configurations(id);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'challenges' AND column_name = 'handicap_challenger') THEN
    ALTER TABLE challenges ADD COLUMN handicap_challenger DECIMAL(3,1) DEFAULT 0.0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'challenges' AND column_name = 'handicap_challenged') THEN
    ALTER TABLE challenges ADD COLUMN handicap_challenged DECIMAL(3,1) DEFAULT 0.0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'challenges' AND column_name = 'rank_difference') THEN
    ALTER TABLE challenges ADD COLUMN rank_difference INTEGER DEFAULT 0;
  END IF;
END $$;

-- 6. Performance indexes
CREATE INDEX IF NOT EXISTS idx_challenge_configurations_bet_amount ON challenge_configurations(bet_amount);
CREATE INDEX IF NOT EXISTS idx_rank_system_rank_code ON rank_system(rank_code);
CREATE INDEX IF NOT EXISTS idx_rank_system_rank_value ON rank_system(rank_value);
CREATE INDEX IF NOT EXISTS idx_handicap_rules_difference_bet ON handicap_rules(rank_difference_type, bet_amount);
CREATE INDEX IF NOT EXISTS idx_challenges_config_id ON challenges(challenge_config_id);

-- 7. Database functions for challenge validation

-- Function: Check if challenge is allowed between two ranks
CREATE OR REPLACE FUNCTION can_challenge_rank(
  challenger_rank VARCHAR(10),
  target_rank VARCHAR(10)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  challenger_value INTEGER;
  target_value INTEGER;
  rank_diff INTEGER;
BEGIN
  -- Get rank values
  SELECT rank_value INTO challenger_value FROM rank_system WHERE rank_code = challenger_rank;
  SELECT rank_value INTO target_value FROM rank_system WHERE rank_code = target_rank;
  
  IF challenger_value IS NULL OR target_value IS NULL THEN
    RETURN false;
  END IF;
  
  rank_diff := ABS(challenger_value - target_value);
  RETURN rank_diff <= 4; -- Max 2 main ranks (4 sub-ranks)
END;
$$;

-- Function: Calculate handicap for challenge
CREATE OR REPLACE FUNCTION calculate_challenge_handicap(
  challenger_rank VARCHAR(10),
  target_rank VARCHAR(10),
  bet_amount INTEGER
)
RETURNS TABLE (
  is_valid BOOLEAN,
  challenger_handicap DECIMAL(3,1),
  challenged_handicap DECIMAL(3,1),
  race_to INTEGER,
  explanation TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  challenger_value INTEGER;
  target_value INTEGER;
  rank_diff INTEGER;
  handicap_type VARCHAR(20);
  handicap_value DECIMAL(3,1);
  race_to_value INTEGER;
BEGIN
  -- Get rank values
  SELECT rank_value INTO challenger_value FROM rank_system WHERE rank_code = challenger_rank;
  SELECT rank_value INTO target_value FROM rank_system WHERE rank_code = target_rank;
  
  -- Get race_to value
  SELECT cc.race_to INTO race_to_value FROM challenge_configurations cc WHERE cc.bet_amount = calculate_challenge_handicap.bet_amount;
  
  IF challenger_value IS NULL OR target_value IS NULL OR race_to_value IS NULL THEN
    RETURN QUERY SELECT false, 0.0::DECIMAL(3,1), 0.0::DECIMAL(3,1), 8, 'Invalid parameters';
    RETURN;
  END IF;
  
  rank_diff := ABS(challenger_value - target_value);
  
  -- Check if challenge is allowed
  IF rank_diff > 4 THEN
    RETURN QUERY SELECT false, 0.0::DECIMAL(3,1), 0.0::DECIMAL(3,1), race_to_value, 'Rank difference too large';
    RETURN;
  END IF;
  
  -- No handicap for same rank
  IF rank_diff = 0 THEN
    RETURN QUERY SELECT true, 0.0::DECIMAL(3,1), 0.0::DECIMAL(3,1), race_to_value, 'Same rank - no handicap';
    RETURN;
  END IF;
  
  -- Determine handicap type
  IF rank_diff = 1 THEN handicap_type := '1_sub';
  ELSIF rank_diff = 2 THEN handicap_type := '1_main';
  ELSIF rank_diff = 3 THEN handicap_type := '1.5_main';
  ELSIF rank_diff = 4 THEN handicap_type := '2_main';
  END IF;
  
  -- Get handicap value
  SELECT hr.handicap_value INTO handicap_value 
  FROM handicap_rules hr 
  WHERE hr.rank_difference_type = handicap_type 
  AND hr.bet_amount = calculate_challenge_handicap.bet_amount;
  
  IF handicap_value IS NULL THEN
    RETURN QUERY SELECT false, 0.0::DECIMAL(3,1), 0.0::DECIMAL(3,1), race_to_value, 'Handicap rule not found';
    RETURN;
  END IF;
  
  -- Apply handicap to weaker player
  IF challenger_value < target_value THEN
    -- Challenger is weaker, gets handicap
    RETURN QUERY SELECT true, handicap_value, 0.0::DECIMAL(3,1), race_to_value, 
      challenger_rank || ' gets +' || handicap_value || ' handicap vs ' || target_rank;
  ELSE
    -- Target is weaker, gets handicap
    RETURN QUERY SELECT true, 0.0::DECIMAL(3,1), handicap_value, race_to_value,
      target_rank || ' gets +' || handicap_value || ' handicap vs ' || challenger_rank;
  END IF;
END;
$$;

-- 8. Comments for documentation
COMMENT ON TABLE challenge_configurations IS 'SPA betting configurations with race-to rules';
COMMENT ON TABLE rank_system IS 'SABO 12-tier ranking system (K to E+)';
COMMENT ON TABLE handicap_rules IS 'Handicap matrix based on rank difference and bet amount';
COMMENT ON VIEW challenge_eligibility IS 'Shows which ranks can challenge each other';

-- 9. RLS Policies
ALTER TABLE challenge_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE rank_system ENABLE ROW LEVEL SECURITY;
ALTER TABLE handicap_rules ENABLE ROW LEVEL SECURITY;

-- Allow read access to configuration tables for all authenticated users
CREATE POLICY "challenge_configurations_read" ON challenge_configurations FOR SELECT TO authenticated USING (true);
CREATE POLICY "rank_system_read" ON rank_system FOR SELECT TO authenticated USING (true);
CREATE POLICY "handicap_rules_read" ON handicap_rules FOR SELECT TO authenticated USING (true);

SELECT 'Enhanced challenge system with rules implemented successfully!' as result;
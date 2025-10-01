-- Migration: Update Vietnamese Billiards Ranking System
-- Date: 2025-09-18
-- Description: Update users.rank and tournaments.skill_level to support Vietnamese billiards ranking

-- 1. Update users table rank column to support Vietnamese ranking
ALTER TABLE users ALTER COLUMN rank TYPE VARCHAR(5);

-- Add check constraint for valid Vietnamese ranks
ALTER TABLE users ADD CONSTRAINT users_rank_check 
CHECK (rank IN ('K', 'K+', 'I', 'I+', 'H', 'H+', 'G', 'G+', 'F', 'F+', 'E', 'E+'));

-- Update default rank to Vietnamese system starting rank
ALTER TABLE users ALTER COLUMN rank SET DEFAULT 'K';

-- 2. Update tournaments table skill_level_required to support Vietnamese ranking
-- Column already exists as skill_level_required, just update the type
ALTER TABLE tournaments ALTER COLUMN skill_level_required TYPE VARCHAR(20);

-- Add check constraint for valid skill levels (Vietnamese ranks or general levels)
ALTER TABLE tournaments ADD CONSTRAINT tournaments_skill_level_check 
CHECK (skill_level_required IN ('K', 'K+', 'I', 'I+', 'H', 'H+', 'G', 'G+', 'F', 'F+', 'E', 'E+', 
                                'beginner', 'intermediate', 'advanced', 'professional') OR skill_level_required IS NULL);

-- 3. Create Vietnamese ranking helper functions
CREATE OR REPLACE FUNCTION get_rank_elo_min(rank_name VARCHAR(5))
RETURNS INTEGER AS $$
BEGIN
  CASE rank_name
    WHEN 'K' THEN RETURN 600;
    WHEN 'K+' THEN RETURN 700;
    WHEN 'I' THEN RETURN 800;
    WHEN 'I+' THEN RETURN 1000;
    WHEN 'H' THEN RETURN 1200;
    WHEN 'H+' THEN RETURN 1400;
    WHEN 'G' THEN RETURN 1600;
    WHEN 'G+' THEN RETURN 1800;
    WHEN 'F' THEN RETURN 2000;
    WHEN 'F+' THEN RETURN 2200;
    WHEN 'E' THEN RETURN 2400;
    WHEN 'E+' THEN RETURN 2600;
    ELSE RETURN 500; -- Default minimum
  END CASE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_rank_elo_max(rank_name VARCHAR(5))
RETURNS INTEGER AS $$
BEGIN
  CASE rank_name
    WHEN 'K' THEN RETURN 699;
    WHEN 'K+' THEN RETURN 799;
    WHEN 'I' THEN RETURN 999;
    WHEN 'I+' THEN RETURN 1199;
    WHEN 'H' THEN RETURN 1399;
    WHEN 'H+' THEN RETURN 1599;
    WHEN 'G' THEN RETURN 1799;
    WHEN 'G+' THEN RETURN 1999;
    WHEN 'F' THEN RETURN 2199;
    WHEN 'F+' THEN RETURN 2399;
    WHEN 'E' THEN RETURN 2599;
    WHEN 'E+' THEN RETURN 3000;
    ELSE RETURN 3000; -- Default maximum
  END CASE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_rank_from_elo(elo_rating INTEGER)
RETURNS VARCHAR(5) AS $$
BEGIN
  IF elo_rating >= 2600 THEN RETURN 'E+';
  ELSIF elo_rating >= 2400 THEN RETURN 'E';
  ELSIF elo_rating >= 2200 THEN RETURN 'F+';
  ELSIF elo_rating >= 2000 THEN RETURN 'F';
  ELSIF elo_rating >= 1800 THEN RETURN 'G+';
  ELSIF elo_rating >= 1600 THEN RETURN 'G';
  ELSIF elo_rating >= 1400 THEN RETURN 'H+';
  ELSIF elo_rating >= 1200 THEN RETURN 'H';
  ELSIF elo_rating >= 1000 THEN RETURN 'I+';
  ELSIF elo_rating >= 800 THEN RETURN 'I';
  ELSIF elo_rating >= 700 THEN RETURN 'K+';
  ELSE RETURN 'K';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 4. Update existing users to use Vietnamese ranking system
UPDATE users SET rank = get_rank_from_elo(elo_rating) WHERE rank IN ('A', 'B', 'C', 'D', 'E');

-- 5. Add comments for documentation
COMMENT ON COLUMN users.rank IS 'Vietnamese billiards ranking: K, K+, I, I+, H, H+, G, G+, F, F+, E, E+';
COMMENT ON COLUMN tournaments.skill_level_required IS 'Required skill level: Vietnamese ranks (K to E+) or general levels (beginner, intermediate, advanced, professional)';

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_rank ON users(rank);
CREATE INDEX IF NOT EXISTS idx_tournaments_skill_level ON tournaments(skill_level_required);
CREATE INDEX IF NOT EXISTS idx_users_elo_rating ON users(elo_rating);

-- Migration completed successfully
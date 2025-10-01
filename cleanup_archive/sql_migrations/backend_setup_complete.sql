-- SABO ARENA - COMPLETE BACKEND SETUP FOR OPPONENT TAB
-- Run this in Supabase SQL Editor with service_role key

-- 1. EXTEND MATCHES TABLE FOR CHALLENGE SYSTEM
ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_type VARCHAR(50) DEFAULT 'tournament';
ALTER TABLE matches ADD COLUMN IF NOT EXISTS invitation_type VARCHAR(50) DEFAULT 'none';
ALTER TABLE matches ADD COLUMN IF NOT EXISTS stakes_type VARCHAR(50) DEFAULT 'none';
ALTER TABLE matches ADD COLUMN IF NOT EXISTS spa_stakes_amount INTEGER DEFAULT 0;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS challenger_id UUID REFERENCES users(id);
ALTER TABLE matches ADD COLUMN IF NOT EXISTS challenge_message TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS response_message TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_conditions JSONB DEFAULT '{}';
ALTER TABLE matches ADD COLUMN IF NOT EXISTS is_public_challenge BOOLEAN DEFAULT false;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS spa_payout_processed BOOLEAN DEFAULT false;

-- 2. EXTEND USERS TABLE FOR LOCATION AND CHALLENGE FEATURES
ALTER TABLE users ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8);
ALTER TABLE users ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8);
ALTER TABLE users ADD COLUMN IF NOT EXISTS location_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points INTEGER DEFAULT 1000;
ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points_won INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points_lost INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS challenge_win_streak INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_available_for_challenges BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_match_type VARCHAR(50) DEFAULT 'both';
ALTER TABLE users ADD COLUMN IF NOT EXISTS max_challenge_distance INTEGER DEFAULT 10;

-- 3. CREATE SPA TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS spa_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  match_id UUID REFERENCES matches(id) ON DELETE SET NULL,
  transaction_type VARCHAR(50) NOT NULL,
  amount INTEGER NOT NULL,
  balance_before INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. CREATE CHALLENGES TABLE (separate from matches for pending challenges)
CREATE TABLE IF NOT EXISTS challenges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  challenger_id UUID REFERENCES users(id) ON DELETE CASCADE,
  challenged_id UUID REFERENCES users(id) ON DELETE CASCADE,
  challenge_type VARCHAR(50) NOT NULL DEFAULT 'giao_luu', -- 'giao_luu' or 'thach_dau'
  message TEXT,
  stakes_type VARCHAR(50) DEFAULT 'none',
  stakes_amount INTEGER DEFAULT 0,
  match_conditions JSONB DEFAULT '{}',
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'expired', 'cancelled'
  response_message TEXT,
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
  responded_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. CREATE INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_matches_match_type ON matches(match_type);
CREATE INDEX IF NOT EXISTS idx_matches_challenger_id ON matches(challenger_id);
CREATE INDEX IF NOT EXISTS idx_matches_stakes ON matches(stakes_type, spa_stakes_amount);
CREATE INDEX IF NOT EXISTS idx_users_location ON users(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_users_available_challenges ON users(is_available_for_challenges);
CREATE INDEX IF NOT EXISTS idx_spa_transactions_user_id ON spa_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_spa_transactions_match_id ON spa_transactions(match_id);
CREATE INDEX IF NOT EXISTS idx_challenges_challenger ON challenges(challenger_id);
CREATE INDEX IF NOT EXISTS idx_challenges_challenged ON challenges(challenged_id);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_expires ON challenges(expires_at);

-- 6. FUNCTION: Get nearby players for opponent tab
CREATE OR REPLACE FUNCTION public.get_nearby_players(
    center_lat DECIMAL,
    center_lng DECIMAL,
    radius_km INTEGER DEFAULT 10
)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    skill_level TEXT,
    elo_rating INTEGER,
    ranking_points INTEGER,
    distance_km DECIMAL,
    is_online BOOLEAN,
    is_available_for_challenges BOOLEAN,
    preferred_match_type TEXT,
    spa_points INTEGER,
    challenge_win_streak INTEGER,
    location_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.username,
        u.display_name,
        u.avatar_url,
        u.skill_level,
        u.elo_rating,
        u.ranking_points,
        -- Simple distance calculation (Haversine approximation)
        ROUND(
            (111.111 * SQRT(
                POW(CAST(u.latitude AS DECIMAL) - center_lat, 2) + 
                POW((CAST(u.longitude AS DECIMAL) - center_lng) * COS(RADIANS(center_lat)), 2)
            ))::DECIMAL, 2
        ) AS distance_km,
        (u.last_seen > NOW() - INTERVAL '15 minutes') AS is_online,
        COALESCE(u.is_available_for_challenges, true) AS is_available_for_challenges,
        COALESCE(u.preferred_match_type, 'both') AS preferred_match_type,
        COALESCE(u.spa_points, 1000) AS spa_points,
        COALESCE(u.challenge_win_streak, 0) AS challenge_win_streak,
        u.location_name
    FROM public.users u
    WHERE 
        u.latitude IS NOT NULL 
        AND u.longitude IS NOT NULL
        AND u.is_active = true
        AND u.id != auth.uid() -- Exclude current user
        AND (111.111 * SQRT(
            POW(CAST(u.latitude AS DECIMAL) - center_lat, 2) + 
            POW((CAST(u.longitude AS DECIMAL) - center_lng) * COS(RADIANS(center_lat)), 2)
        )) <= radius_km
    ORDER BY distance_km, u.elo_rating DESC
    LIMIT 50;
EXCEPTION
    WHEN OTHERS THEN
        RETURN;
END;
$$;

-- 7. FUNCTION: Create a challenge
CREATE OR REPLACE FUNCTION public.create_challenge(
    challenged_user_id UUID,
    challenge_type_param TEXT,
    message_param TEXT DEFAULT NULL,
    stakes_type_param TEXT DEFAULT 'none',
    stakes_amount_param INTEGER DEFAULT 0,
    match_conditions_param JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    challenge_id UUID;
    challenger_user_id UUID;
BEGIN
    -- Get current user ID
    challenger_user_id := auth.uid();
    
    IF challenger_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    IF challenger_user_id = challenged_user_id THEN
        RAISE EXCEPTION 'Cannot challenge yourself';
    END IF;
    
    -- Check if target user exists and is available
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = challenged_user_id 
        AND is_active = true 
        AND COALESCE(is_available_for_challenges, true) = true
    ) THEN
        RAISE EXCEPTION 'Target user is not available for challenges';
    END IF;
    
    -- Check for existing pending challenge between these users
    IF EXISTS (
        SELECT 1 FROM challenges 
        WHERE ((challenger_id = challenger_user_id AND challenged_id = challenged_user_id)
               OR (challenger_id = challenged_user_id AND challenged_id = challenger_user_id))
        AND status = 'pending'
        AND expires_at > NOW()
    ) THEN
        RAISE EXCEPTION 'There is already a pending challenge between these users';
    END IF;
    
    -- Create the challenge
    INSERT INTO challenges (
        challenger_id,
        challenged_id,
        challenge_type,
        message,
        stakes_type,
        stakes_amount,
        match_conditions
    ) VALUES (
        challenger_user_id,
        challenged_user_id,
        challenge_type_param,
        message_param,
        stakes_type_param,
        stakes_amount_param,
        match_conditions_param
    ) RETURNING id INTO challenge_id;
    
    RETURN challenge_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to create challenge: %', SQLERRM;
END;
$$;

-- 8. FUNCTION: Accept a challenge
CREATE OR REPLACE FUNCTION public.accept_challenge(
    challenge_id_param UUID,
    response_message_param TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    match_id UUID;
    challenge_record RECORD;
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Get challenge details
    SELECT * INTO challenge_record
    FROM challenges 
    WHERE id = challenge_id_param 
    AND challenged_id = current_user_id
    AND status = 'pending'
    AND expires_at > NOW();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Challenge not found or not available';
    END IF;
    
    -- Update challenge status
    UPDATE challenges 
    SET status = 'accepted',
        response_message = response_message_param,
        responded_at = NOW(),
        updated_at = NOW()
    WHERE id = challenge_id_param;
    
    -- Create match record
    INSERT INTO matches (
        player1_id,
        player2_id,
        challenger_id,
        match_type,
        invitation_type,
        stakes_type,
        spa_stakes_amount,
        challenge_message,
        response_message,
        match_conditions,
        status,
        scheduled_time
    ) VALUES (
        challenge_record.challenger_id,
        challenge_record.challenged_id,
        challenge_record.challenger_id,
        CASE 
            WHEN challenge_record.challenge_type = 'thach_dau' THEN 'competitive'
            ELSE 'friendly'
        END,
        'challenge_accepted',
        challenge_record.stakes_type,
        challenge_record.stakes_amount,
        challenge_record.message,
        response_message_param,
        challenge_record.match_conditions,
        'scheduled',
        NOW() + INTERVAL '30 minutes' -- Default schedule 30 minutes from now
    ) RETURNING id INTO match_id;
    
    RETURN match_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to accept challenge: %', SQLERRM;
END;
$$;

-- 9. FUNCTION: Decline a challenge
CREATE OR REPLACE FUNCTION public.decline_challenge(
    challenge_id_param UUID,
    response_message_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Update challenge status
    UPDATE challenges 
    SET status = 'declined',
        response_message = response_message_param,
        responded_at = NOW(),
        updated_at = NOW()
    WHERE id = challenge_id_param 
    AND challenged_id = current_user_id
    AND status = 'pending';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Challenge not found or not available';
    END IF;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to decline challenge: %', SQLERRM;
END;
$$;

-- 10. FUNCTION: Get user's challenges (sent and received)
CREATE OR REPLACE FUNCTION public.get_user_challenges(
    user_uuid UUID DEFAULT NULL,
    status_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
    challenge_id UUID,
    challenger_id UUID,
    challenger_name TEXT,
    challenger_avatar TEXT,
    challenged_id UUID,
    challenged_name TEXT,
    challenged_avatar TEXT,
    challenge_type TEXT,
    message TEXT,
    stakes_type TEXT,
    stakes_amount INTEGER,
    status TEXT,
    response_message TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    is_challenger BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    target_user_id UUID;
BEGIN
    target_user_id := COALESCE(user_uuid, auth.uid());
    
    IF target_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    RETURN QUERY
    SELECT 
        c.id,
        c.challenger_id,
        u1.display_name,
        u1.avatar_url,
        c.challenged_id,
        u2.display_name,
        u2.avatar_url,
        c.challenge_type,
        c.message,
        c.stakes_type,
        c.stakes_amount,
        c.status,
        c.response_message,
        c.expires_at,
        c.created_at,
        (c.challenger_id = target_user_id) AS is_challenger
    FROM challenges c
    JOIN users u1 ON c.challenger_id = u1.id
    JOIN users u2 ON c.challenged_id = u2.id
    WHERE (c.challenger_id = target_user_id OR c.challenged_id = target_user_id)
    AND (status_filter IS NULL OR c.status = status_filter)
    ORDER BY c.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        RETURN;
END;
$$;

-- 11. GRANT PERMISSIONS (with error handling)
DO $$
BEGIN
    -- Grant permissions, ignore if already granted
    GRANT EXECUTE ON FUNCTION public.get_nearby_players(DECIMAL, DECIMAL, INTEGER) TO authenticated;
    GRANT EXECUTE ON FUNCTION public.create_challenge(UUID, TEXT, TEXT, TEXT, INTEGER, JSONB) TO authenticated;
    GRANT EXECUTE ON FUNCTION public.accept_challenge(UUID, TEXT) TO authenticated;
    GRANT EXECUTE ON FUNCTION public.decline_challenge(UUID, TEXT) TO authenticated;
    GRANT EXECUTE ON FUNCTION public.get_user_challenges(UUID, TEXT) TO authenticated;
    
    RAISE NOTICE 'Function permissions granted successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Note: Some permissions may have been already granted: %', SQLERRM;
END $$;

-- 12. ROW LEVEL SECURITY POLICIES
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE spa_transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist and recreate them
DO $$
BEGIN
    -- Drop and recreate challenges policies
    DROP POLICY IF EXISTS "Users can view their own challenges" ON challenges;
    CREATE POLICY "Users can view their own challenges" ON challenges
        FOR SELECT USING (
            challenger_id = auth.uid() OR challenged_id = auth.uid()
        );

    DROP POLICY IF EXISTS "Users can create challenges" ON challenges;
    CREATE POLICY "Users can create challenges" ON challenges
        FOR INSERT WITH CHECK (
            challenger_id = auth.uid()
        );

    DROP POLICY IF EXISTS "Users can update challenges they received" ON challenges;
    CREATE POLICY "Users can update challenges they received" ON challenges
        FOR UPDATE USING (
            challenged_id = auth.uid() AND status = 'pending'
        );

    -- Drop and recreate spa_transactions policies
    DROP POLICY IF EXISTS "Users can view their own spa transactions" ON spa_transactions;
    CREATE POLICY "Users can view their own spa transactions" ON spa_transactions
        FOR SELECT USING (user_id = auth.uid());
        
    RAISE NOTICE 'RLS policies created successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating RLS policies: %', SQLERRM;
END $$;

-- 13. COMMENTS FOR DOCUMENTATION
COMMENT ON COLUMN matches.match_type IS 'tournament, friendly, competitive, practice';
COMMENT ON COLUMN matches.invitation_type IS 'none, challenge_sent, challenge_received, challenge_accepted, friend_invite, auto_match';
COMMENT ON COLUMN matches.stakes_type IS 'none, spa_points, tournament_prize, bragging_rights';
COMMENT ON COLUMN matches.spa_stakes_amount IS 'SPA bonus points at stake (100, 500, 1000, etc.)';
COMMENT ON COLUMN matches.challenger_id IS 'Who sent the challenge (might be different from player1)';
COMMENT ON COLUMN matches.match_conditions IS 'Custom rules: {"format": "8ball", "race_to": 7, "time_limit": 30}';

COMMENT ON COLUMN users.preferred_match_type IS 'giao_luu, thach_dau, or both';
COMMENT ON COLUMN users.max_challenge_distance IS 'Maximum distance in km for receiving challenges';

COMMENT ON TABLE challenges IS 'Pending and historical challenge requests between users';
COMMENT ON COLUMN challenges.challenge_type IS 'giao_luu (friendly) or thach_dau (competitive)';
COMMENT ON COLUMN challenges.status IS 'pending, accepted, declined, expired, cancelled';

COMMENT ON TABLE spa_transactions IS 'Log of all SPA points transactions';
COMMENT ON COLUMN spa_transactions.transaction_type IS 'challenge_win, challenge_loss, tournament_prize, daily_bonus, purchase';

SELECT 'Backend setup completed successfully!' as result;
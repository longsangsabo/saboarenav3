-- Sabo Arena - Supabase Database Schema
-- This schema supports a billiards tournament and social platform

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ========================================
-- CORE TABLES - UPDATED TO MATCH ACTUAL DATABASE
-- ========================================
-- NOTE: This schema was corrected based on actual Supabase database structure
-- discovered during development. Some fields in the original schema file
-- did not match the production database.

-- Users/Players Table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  cover_photo_url TEXT,
  
  -- Billiards specific fields
  rank VARCHAR(10) DEFAULT 'E', -- A, B, C, D, E
  elo_rating INTEGER DEFAULT 1200,
  spa_points INTEGER DEFAULT 0,
  favorite_game VARCHAR(20) DEFAULT '8-Ball',
  
  -- Statistics
  total_matches INTEGER DEFAULT 0,
  wins INTEGER DEFAULT 0,
  losses INTEGER DEFAULT 0,
  win_streak INTEGER DEFAULT 0,
  tournaments_played INTEGER DEFAULT 0,
  tournament_wins INTEGER DEFAULT 0,
  
  -- Location (for find opponents)
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  location_updated_at TIMESTAMPTZ,
  
  -- Status
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Clubs Table
CREATE TABLE clubs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  avatar_url TEXT,
  cover_photo_url TEXT,
  
  -- Location
  address TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  
  -- Contact Info
  phone VARCHAR(20),
  email VARCHAR(255),
  website_url TEXT,
  
  -- Operating hours (JSON format)
  operating_hours JSONB,
  
  -- Statistics
  total_tournaments INTEGER DEFAULT 0,
  total_members INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0.00,
  total_reviews INTEGER DEFAULT 0,
  
  -- Metadata
  owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tournaments Table
CREATE TABLE tournaments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
  
  -- Basic Info
  title VARCHAR(200) NOT NULL,
  description TEXT,
  format VARCHAR(20) NOT NULL, -- 8-Ball, 9-Ball, 10-Ball
  tournament_type VARCHAR(20) NOT NULL, -- Additional field found in actual schema
  cover_image TEXT, -- Changed from cover_image_url
  cover_image_url TEXT,
  
  -- Tournament Details
  entry_fee DECIMAL(10,2) DEFAULT 0.00,
  prize_pool DECIMAL(12,2),
  prize_distribution JSONB, -- Additional field found in actual schema
  max_participants INTEGER NOT NULL,
  current_participants INTEGER DEFAULT 0,
  
  -- Scheduling
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  registration_deadline TIMESTAMPTZ,
  registration_end_time TIMESTAMPTZ, -- Additional field found in actual schema
  
  -- Tournament Settings
  skill_level_required VARCHAR(20), -- Changed from skill_level to match actual schema
  requirements JSONB, -- Additional field found in actual schema
  has_live_stream BOOLEAN DEFAULT false,
  live_stream_url TEXT,
  is_public BOOLEAN DEFAULT true, -- Additional field found in actual schema
  
  -- Status
  status VARCHAR(20) DEFAULT 'upcoming', -- upcoming, live, completed, cancelled
  
  -- Rules and Notes
  rules JSONB, -- Changed from TEXT[] to JSONB to match actual schema
  notes TEXT,
  
  -- Metadata
  organizer_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Changed from created_by to match actual schema
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tournament Participants (Many-to-Many)
CREATE TABLE tournament_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  -- Registration Info
  registered_at TIMESTAMPTZ DEFAULT NOW(), -- Changed from registration_date to match actual schema
  payment_status VARCHAR(20) DEFAULT 'pending', -- pending, paid, refunded
  status VARCHAR(20) DEFAULT 'registered', -- Additional field found in actual schema (registered, confirmed, cancelled)
  seed_number INTEGER, -- Additional field found in actual schema for tournament seeding
  notes TEXT, -- Additional field found in actual schema for payment method and other notes
  
  -- Tournament Performance (kept as they might be used later)
  final_position INTEGER,
  matches_played INTEGER DEFAULT 0,
  matches_won INTEGER DEFAULT 0,
  
  -- Unique constraint
  UNIQUE(tournament_id, user_id)
);

-- Matches Table (Individual games) - FIXED SCHEMA BASED ON ACTUAL DATABASE
-- IMPORTANT: The actual database uses 'scheduled_time' NOT 'scheduled_at'
-- IMPORTANT: Status enum values include 'pending', 'live', 'completed', 'cancelled'  
-- IMPORTANT: Fields like 'started_at', 'completed_at', 'match_data', 'table_number' do NOT exist
-- IMPORTANT: Field 'format' DOES exist in actual database
CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
  
  -- Match Details
  match_number INTEGER,
  round_number INTEGER,
  
  -- Players
  player1_id UUID REFERENCES users(id) ON DELETE SET NULL,
  player2_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Scores
  player1_score INTEGER DEFAULT 0,
  player2_score INTEGER DEFAULT 0,
  
  -- Result
  winner_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Status (enum: pending, live, completed, cancelled)
  status VARCHAR(20) DEFAULT 'pending',
  
  -- Match Time - FIXED: uses scheduled_time NOT scheduled_at
  scheduled_time TIMESTAMPTZ,
  
  -- Format (this field exists in actual database)
  format VARCHAR(20),
  
  -- Notes field exists
  notes TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- SOCIAL FEATURES
-- ========================================

-- Posts Table (Social Feed)
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  -- Content
  content TEXT NOT NULL,
  image_urls TEXT[],
  
  -- Location
  location_name VARCHAR(200),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  
  -- Tags
  hashtags VARCHAR(50)[],
  
  -- Engagement
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  
  -- Related entities
  tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
  club_id UUID REFERENCES clubs(id) ON DELETE SET NULL,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Post Likes
CREATE TABLE post_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint
  UNIQUE(post_id, user_id)
);

-- Comments
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  -- Content
  content TEXT NOT NULL,
  
  -- Threading (for replies)
  parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Friendships
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID REFERENCES users(id) ON DELETE CASCADE,
  addressee_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, declined, blocked
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint
  UNIQUE(requester_id, addressee_id)
);

-- ========================================
-- GAMIFICATION & ACHIEVEMENTS
-- ========================================

-- Achievements
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Achievement Details
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT NOT NULL,
  icon_url TEXT,
  category VARCHAR(50), -- tournament, social, skill, etc.
  
  -- Requirements (JSON for flexibility)
  requirements JSONB NOT NULL,
  
  -- Rewards
  spa_points_reward INTEGER DEFAULT 0,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Achievements
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
  
  -- Progress
  progress INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  
  -- Unique constraint
  UNIQUE(user_id, achievement_id)
);

-- ========================================
-- MEMBERSHIP & PERMISSIONS
-- ========================================

-- Club Members
CREATE TABLE club_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  -- Membership
  role VARCHAR(20) DEFAULT 'member', -- owner, admin, member
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active, suspended, banned
  
  -- Unique constraint
  UNIQUE(club_id, user_id)
);

-- Club Reviews
CREATE TABLE club_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  -- Review Content
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint (one review per user per club)
  UNIQUE(club_id, user_id)
);

-- ========================================
-- NOTIFICATIONS
-- ========================================

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  -- Notification Content
  type VARCHAR(50) NOT NULL, -- tournament_invite, match_result, friend_request, etc.
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  
  -- Related entities (JSON for flexibility)
  data JSONB,
  
  -- Status
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

-- User indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_elo_rating ON users(elo_rating);
CREATE INDEX idx_users_location ON users USING GIST(ll_to_earth(latitude, longitude)) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
CREATE INDEX idx_users_online ON users(is_online, last_seen);

-- Tournament indexes
CREATE INDEX idx_tournaments_club ON tournaments(club_id);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_dates ON tournaments(start_date, end_date);
CREATE INDEX idx_tournaments_registration ON tournaments(registration_deadline);

-- Post indexes
CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_posts_hashtags ON posts USING GIN(hashtags);
CREATE INDEX idx_posts_location ON posts USING GIST(ll_to_earth(latitude, longitude)) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Match indexes
CREATE INDEX idx_matches_tournament ON matches(tournament_id);
CREATE INDEX idx_matches_players ON matches(player1_id, player2_id);
CREATE INDEX idx_matches_status ON matches(status);

-- Social indexes
CREATE INDEX idx_post_likes_post ON post_likes(post_id);
CREATE INDEX idx_post_likes_user ON post_likes(user_id);
CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_friendships_users ON friendships(requester_id, addressee_id);

-- Club indexes
CREATE INDEX idx_club_members_club ON club_members(club_id);
CREATE INDEX idx_club_members_user ON club_members(user_id);
CREATE INDEX idx_club_reviews_club ON club_reviews(club_id);

-- Notification indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read, created_at DESC);

-- ========================================
-- TRIGGERS FOR UPDATED_AT
-- ========================================

-- Function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_clubs_updated_at BEFORE UPDATE ON clubs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tournaments_updated_at BEFORE UPDATE ON tournaments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON matches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_friendships_updated_at BEFORE UPDATE ON friendships FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users: Users can see public profiles and update their own
CREATE POLICY "Users can view public profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- Posts: Public read, users can create/update their own
CREATE POLICY "Posts are publicly readable" ON posts FOR SELECT USING (true);
CREATE POLICY "Users can create own posts" ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own posts" ON posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON posts FOR DELETE USING (auth.uid() = user_id);

-- Post Likes: Users can like/unlike posts
CREATE POLICY "Post likes are publicly readable" ON post_likes FOR SELECT USING (true);
CREATE POLICY "Users can like posts" ON post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike posts" ON post_likes FOR DELETE USING (auth.uid() = user_id);

-- Comments: Public read, users can create/update their own
CREATE POLICY "Comments are publicly readable" ON comments FOR SELECT USING (true);
CREATE POLICY "Users can create comments" ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own comments" ON comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON comments FOR DELETE USING (auth.uid() = user_id);

-- Tournaments: Public read, club owners/admins can manage
CREATE POLICY "Tournaments are publicly readable" ON tournaments FOR SELECT USING (true);
CREATE POLICY "Club owners can manage tournaments" ON tournaments FOR ALL USING (
  EXISTS (
    SELECT 1 FROM clubs 
    WHERE clubs.id = tournaments.club_id 
    AND clubs.owner_id = auth.uid()
  )
);
CREATE POLICY "Tournament organizers can manage tournaments" ON tournaments FOR ALL USING (auth.uid() = organizer_id);

-- Tournament Participants: Users can register and view participants
CREATE POLICY "Tournament participants are publicly readable" ON tournament_participants FOR SELECT USING (true);
CREATE POLICY "Users can register for tournaments" ON tournament_participants FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own participation" ON tournament_participants FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can withdraw from tournaments" ON tournament_participants FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Tournament organizers can manage participants" ON tournament_participants FOR ALL USING (
  EXISTS (
    SELECT 1 FROM tournaments t
    WHERE t.id = tournament_participants.tournament_id 
    AND t.organizer_id = auth.uid()
  )
);

-- Club Members: Club-specific access
CREATE POLICY "Club members are readable by club members" ON club_members FOR SELECT USING (
  auth.uid() = user_id OR 
  EXISTS (
    SELECT 1 FROM club_members cm 
    WHERE cm.club_id = club_members.club_id 
    AND cm.user_id = auth.uid()
  )
);
CREATE POLICY "Users can join clubs" ON club_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave clubs" ON club_members FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Club admins can manage members" ON club_members FOR ALL USING (
  EXISTS (
    SELECT 1 FROM club_members cm
    WHERE cm.club_id = club_members.club_id 
    AND cm.user_id = auth.uid() 
    AND cm.role IN ('owner', 'admin')
  )
);

-- Notifications: Users can only see their own
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- ========================================
-- SAMPLE DATA FOR TESTING
-- ========================================

-- Insert some sample achievements
INSERT INTO achievements (name, description, icon_url, category, requirements, spa_points_reward) VALUES
('First Win', 'Win your first match', null, 'skill', '{"wins": 1}', 100),
('Tournament Rookie', 'Participate in your first tournament', null, 'tournament', '{"tournaments_played": 1}', 150),
('Social Butterfly', 'Make 10 friends', null, 'social', '{"friends": 10}', 200),
('Rising Star', 'Reach Rank C', null, 'skill', '{"rank": "C"}', 300),
('Champion', 'Win a tournament', null, 'tournament', '{"tournament_wins": 1}', 500);

-- ========================================
-- FUNCTIONS FOR COMMON OPERATIONS
-- ========================================

-- Function to calculate win rate
CREATE OR REPLACE FUNCTION calculate_win_rate(user_uuid UUID)
RETURNS DECIMAL AS $$
BEGIN
  RETURN (
    SELECT CASE 
      WHEN total_matches > 0 THEN ROUND((wins::DECIMAL / total_matches) * 100, 2)
      ELSE 0 
    END
    FROM users 
    WHERE id = user_uuid
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get nearby players
CREATE OR REPLACE FUNCTION get_nearby_players(
  center_lat DECIMAL,
  center_lng DECIMAL,
  radius_km INTEGER DEFAULT 10
)
RETURNS TABLE (
  user_id UUID,
  username VARCHAR,
  display_name VARCHAR,
  avatar_url TEXT,
  rank VARCHAR,
  distance_km DECIMAL,
  is_online BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.username,
    u.display_name,
    u.avatar_url,
    u.rank,
    ROUND(
      (point(u.longitude, u.latitude) <@> point(center_lng, center_lat)) * 1.609344, 2
    ) AS distance_km,
    u.is_online
  FROM users u
  WHERE 
    u.latitude IS NOT NULL 
    AND u.longitude IS NOT NULL
    AND (point(u.longitude, u.latitude) <@> point(center_lng, center_lat)) * 1.609344 <= radius_km
  ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;

-- Function to update user statistics after match
CREATE OR REPLACE FUNCTION update_user_stats_after_match()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update if match is completed
  IF NEW.status = 'completed' AND NEW.winner_id IS NOT NULL THEN
    -- Update winner stats
    UPDATE users 
    SET 
      total_matches = total_matches + 1,
      wins = wins + 1,
      win_streak = win_streak + 1
    WHERE id = NEW.winner_id;
    
    -- Update loser stats  
    UPDATE users 
    SET 
      total_matches = total_matches + 1,
      losses = losses + 1,
      win_streak = 0
    WHERE id = (
      CASE 
        WHEN NEW.player1_id = NEW.winner_id THEN NEW.player2_id
        ELSE NEW.player1_id
      END
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger
CREATE TRIGGER update_stats_after_match 
  AFTER UPDATE ON matches 
  FOR EACH ROW 
  EXECUTE FUNCTION update_user_stats_after_match();

-- ========================================
-- TOURNAMENT PARTICIPANT MANAGEMENT FUNCTIONS
-- ========================================

-- Function to increment tournament participants
CREATE OR REPLACE FUNCTION increment_tournament_participants(tournament_id UUID)
RETURNS void 
LANGUAGE sql
AS $$
  UPDATE tournaments 
  SET current_participants = current_participants + 1,
      updated_at = NOW()
  WHERE id = tournament_id;
$$;

-- Function to decrement tournament participants
CREATE OR REPLACE FUNCTION decrement_tournament_participants(tournament_id UUID)
RETURNS void
LANGUAGE sql  
AS $$
  UPDATE tournaments 
  SET current_participants = GREATEST(current_participants - 1, 0),
      updated_at = NOW()
  WHERE id = tournament_id;
$$;

-- Grant permissions for tournament functions
GRANT EXECUTE ON FUNCTION increment_tournament_participants(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION decrement_tournament_participants(UUID) TO authenticated;

-- ========================================
-- VIEWS FOR COMMON QUERIES
-- ========================================

-- View for tournament leaderboard
CREATE VIEW tournament_leaderboard AS
SELECT 
  tp.tournament_id,
  tp.user_id,
  u.display_name,
  u.avatar_url,
  u.rank,
  tp.final_position,
  tp.matches_played,
  tp.matches_won,
  CASE 
    WHEN tp.matches_played > 0 
    THEN ROUND((tp.matches_won::DECIMAL / tp.matches_played) * 100, 1)
    ELSE 0 
  END as win_percentage
FROM tournament_participants tp
JOIN users u ON tp.user_id = u.id
WHERE tp.final_position IS NOT NULL
ORDER BY tp.tournament_id, tp.final_position;

-- View for user feed (posts from friends and followed clubs)
CREATE VIEW user_feed AS
SELECT DISTINCT
  p.id,
  p.user_id,
  u.display_name as author_name,
  u.avatar_url as author_avatar,
  p.content,
  p.image_urls,
  p.location_name,
  p.hashtags,
  p.like_count,
  p.comment_count,
  p.share_count,
  p.created_at
FROM posts p
JOIN users u ON p.user_id = u.id
ORDER BY p.created_at DESC;

-- This completes the initial schema setup for Sabo Arena
-- Next steps: Install Supabase Flutter package and implement service layer
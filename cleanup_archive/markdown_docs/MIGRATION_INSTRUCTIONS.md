🎯 SPA CHALLENGE SYSTEM - MANUAL MIGRATION
════════════════════════════════════════════

⚠️ Supabase không cho phép chạy DDL qua API từ bên ngoài.
Bạn cần copy SQL này và paste vào Supabase Dashboard:

📍 STEPS:
1. Mở https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr
2. Vào SQL Editor (bên trái menu)
3. Copy toàn bộ SQL bên dưới
4. Paste vào SQL Editor và click "Run"

═══════════════════════════════════════════════════════════

-- SPA CHALLENGE SYSTEM MIGRATION
-- Copy từ đây ↓

-- 1. EXTEND MATCHES TABLE
ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_type VARCHAR(50) DEFAULT 'tournament';
-- Values: tournament, friendly, challenge, spa_challenge, practice

ALTER TABLE matches ADD COLUMN IF NOT EXISTS invitation_type VARCHAR(50) DEFAULT 'none';
-- Values: none, challenge_sent, challenge_received, friend_invite, auto_match

ALTER TABLE matches ADD COLUMN IF NOT EXISTS stakes_type VARCHAR(50) DEFAULT 'none';
-- Values: none, spa_points, tournament_prize, bragging_rights

ALTER TABLE matches ADD COLUMN IF NOT EXISTS spa_stakes_amount INTEGER DEFAULT 0;
-- SPA bonus points at stake (100, 500, 1000, etc.)

ALTER TABLE matches ADD COLUMN IF NOT EXISTS challenger_id UUID;
-- Who sent the challenge (might be different from player1)

ALTER TABLE matches ADD COLUMN IF NOT EXISTS challenge_message TEXT;
-- "Dare to face me? 1000 SPA on the line!"

ALTER TABLE matches ADD COLUMN IF NOT EXISTS response_message TEXT;
-- "Challenge accepted! Let's do this!"

ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_conditions JSONB DEFAULT '{}';
-- {"format": "8ball", "race_to": 7, "time_limit": 30}

ALTER TABLE matches ADD COLUMN IF NOT EXISTS is_public_challenge BOOLEAN DEFAULT false;
-- Can others see this challenge?

ALTER TABLE matches ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;
-- Challenge expires if not accepted within timeframe

ALTER TABLE matches ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP WITH TIME ZONE;
-- When challenge was accepted

ALTER TABLE matches ADD COLUMN IF NOT EXISTS spa_payout_processed BOOLEAN DEFAULT false;
-- Track if SPA points were transferred to winner

-- 2. EXTEND USERS TABLE
ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points INTEGER DEFAULT 1000;
-- Starting SPA bonus points for new users

ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points_won INTEGER DEFAULT 0;
-- Total SPA points won from challenges

ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points_lost INTEGER DEFAULT 0;
-- Total SPA points lost in challenges

ALTER TABLE users ADD COLUMN IF NOT EXISTS challenge_win_streak INTEGER DEFAULT 0;
-- Current winning streak in SPA challenges

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

-- 4. CREATE INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_matches_match_type ON matches(match_type);
CREATE INDEX IF NOT EXISTS idx_matches_challenger_id ON matches(challenger_id);
CREATE INDEX IF NOT EXISTS idx_matches_stakes ON matches(stakes_type, spa_stakes_amount);
CREATE INDEX IF NOT EXISTS idx_spa_transactions_user_id ON spa_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_spa_transactions_match_id ON spa_transactions(match_id);

-- Copy đến đây ↑
═══════════════════════════════════════════════════════════

🎉 SAU KHI RUN SQL THÀNH CÔNG:
1. Quay lại terminal này
2. Run: dart run scripts/create_spa_test_data.dart
3. Test opponent tab trong Flutter app

💡 HOẶC NẾU BẠN MUỐN TÔI TẠO SAMPLE DATA NGAY:
   (Giả sử migration đã chạy thành công)

🚀 BẠN ĐÃ SẴNG SÀNG RUN SQL MIGRATION CHƯA?
-- ================================
-- FIX USER_PROFILES TRIGGER ERROR
-- Run this SQL in Supabase Dashboard -> SQL Editor
-- ================================

-- 1. Drop all existing triggers that might reference user_profiles
DROP TRIGGER IF EXISTS update_stats_after_match ON matches CASCADE;
DROP TRIGGER IF EXISTS on_match_completed ON matches CASCADE;
DROP TRIGGER IF EXISTS trigger_notify_match_completed ON matches CASCADE;
DROP TRIGGER IF EXISTS update_user_stats_trigger ON matches CASCADE;
DROP TRIGGER IF EXISTS matches_user_profiles_trigger ON matches CASCADE;

-- 2. Drop all existing functions that might reference user_profiles
DROP FUNCTION IF EXISTS update_user_stats_after_match() CASCADE;
DROP FUNCTION IF EXISTS handle_match_completion() CASCADE;
DROP FUNCTION IF EXISTS notify_match_completed() CASCADE;
DROP FUNCTION IF EXISTS update_user_profiles_after_match() CASCADE;

-- 3. Create clean new function that ONLY uses 'users' table
CREATE OR REPLACE FUNCTION update_user_stats_after_match()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update if match is completed and has winner
  IF NEW.status = 'completed' AND NEW.winner_id IS NOT NULL THEN
    
    -- Update winner stats in USERS table (NOT user_profiles)
    UPDATE users 
    SET 
      total_wins = COALESCE(total_wins, 0) + 1,
      ranking_points = COALESCE(ranking_points, 0) + 10,
      updated_at = NOW()
    WHERE id = NEW.winner_id;
    
    -- Update loser stats in USERS table (NOT user_profiles) 
    UPDATE users 
    SET 
      total_losses = COALESCE(total_losses, 0) + 1,
      updated_at = NOW()
    WHERE id = (
      CASE 
        WHEN NEW.player1_id = NEW.winner_id THEN NEW.player2_id
        ELSE NEW.player1_id
      END
    );
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create new trigger
CREATE TRIGGER update_stats_after_match 
  AFTER UPDATE ON matches 
  FOR EACH ROW 
  EXECUTE FUNCTION update_user_stats_after_match();

-- 5. Verify no user_profiles references remain
-- This query should return empty if successful
SELECT 
  routine_name,
  routine_definition
FROM information_schema.routines 
WHERE routine_definition ILIKE '%user_profiles%'
  AND routine_schema = 'public';

-- Success message
SELECT 'TRIGGER FIXED! Now test match update with status=completed' as result;
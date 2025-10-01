-- Fix challenges table by adding missing columns
-- Run this in Supabase Dashboard > SQL Editor

-- Add missing columns to existing challenges table
ALTER TABLE public.challenges 
ADD COLUMN IF NOT EXISTS game_type VARCHAR(20) DEFAULT '8-ball',
ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS location VARCHAR(255),
ADD COLUMN IF NOT EXISTS handicap INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS spa_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days');

-- Add indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_challenges_game_type ON public.challenges(game_type);
CREATE INDEX IF NOT EXISTS idx_challenges_scheduled_time ON public.challenges(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_challenges_expires_at ON public.challenges(expires_at);
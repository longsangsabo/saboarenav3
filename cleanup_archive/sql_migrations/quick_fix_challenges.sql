-- Simple SQL to create challenges table with game_type column
CREATE TABLE IF NOT EXISTS public.challenges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  challenger_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  challenged_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_type VARCHAR(50) DEFAULT 'giao_luu',
  game_type VARCHAR(20) DEFAULT '8-ball',
  scheduled_time TIMESTAMP WITH TIME ZONE,
  location VARCHAR(255),
  handicap INTEGER DEFAULT 0,
  spa_points INTEGER DEFAULT 0,
  message TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns if they don't exist (safe operations)
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS game_type VARCHAR(20) DEFAULT '8-ball';
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS location VARCHAR(255);
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS handicap INTEGER DEFAULT 0;
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS spa_points INTEGER DEFAULT 0;
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_challenges_challenger_id ON public.challenges(challenger_id);
CREATE INDEX IF NOT EXISTS idx_challenges_challenged_id ON public.challenges(challenged_id);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON public.challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_game_type ON public.challenges(game_type);

-- Enable RLS
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

-- Basic RLS policy
CREATE POLICY IF NOT EXISTS "Users can view their challenges" ON public.challenges
FOR SELECT USING (
  auth.uid() = challenger_id OR 
  auth.uid() = challenged_id
);
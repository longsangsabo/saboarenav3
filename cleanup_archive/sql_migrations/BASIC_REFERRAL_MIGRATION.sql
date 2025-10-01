-- SABO Arena Referral System - SIMPLIFIED BASIC SETUP
-- Execute this in Supabase Dashboard > SQL Editor
-- Simple single-type referral system for easy management

BEGIN;

-- Create referral_codes table (simplified)
CREATE TABLE IF NOT EXISTS referral_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    code TEXT UNIQUE NOT NULL,
    max_uses INTEGER DEFAULT NULL,  -- NULL = unlimited
    current_uses INTEGER DEFAULT 0,
    spa_reward_referrer INTEGER DEFAULT 100,  -- Fixed SPA reward for referrer
    spa_reward_referred INTEGER DEFAULT 50,   -- Fixed SPA reward for referred user
    expires_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create referral_usage table (simplified)
CREATE TABLE IF NOT EXISTS referral_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referral_code_id UUID REFERENCES referral_codes(id) ON DELETE CASCADE,
    referrer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    referred_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    spa_awarded_referrer INTEGER NOT NULL,
    spa_awarded_referred INTEGER NOT NULL,
    used_at TIMESTAMP DEFAULT NOW()
);

-- Extend users table safely
DO $$ 
BEGIN
    -- Add referral_stats column (simplified)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'referral_stats') THEN
        ALTER TABLE users ADD COLUMN referral_stats JSONB DEFAULT '{"total_referred": 0, "total_spa_earned": 0}';
    END IF;
    
    -- Add referred_by column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'referred_by') THEN
        ALTER TABLE users ADD COLUMN referred_by UUID;
    END IF;
    
    -- Add referral_code column (user's own code)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'referral_code') THEN
        ALTER TABLE users ADD COLUMN referral_code TEXT UNIQUE;
    END IF;
END $$;

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_referral_codes_user_id ON referral_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON referral_codes(code);
CREATE INDEX IF NOT EXISTS idx_referral_codes_active ON referral_codes(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_referral_usage_referrer ON referral_usage(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referral_usage_referred ON referral_usage(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code) WHERE referral_code IS NOT NULL;

-- Create triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_referral_codes_updated_at BEFORE UPDATE ON referral_codes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to auto-generate user referral code
CREATE OR REPLACE FUNCTION generate_user_referral_code()
RETURNS TRIGGER AS $$
DECLARE
    base_code TEXT;
    final_code TEXT;
    counter INTEGER := 1;
BEGIN
    -- Generate base code from username or id
    IF NEW.username IS NOT NULL AND NEW.username != '' THEN
        base_code := 'SABO-' || UPPER(LEFT(REGEXP_REPLACE(NEW.username, '[^A-Za-z0-9]', '', 'g'), 8));
    ELSE
        base_code := 'SABO-USER' || SUBSTR(REPLACE(NEW.id::text, '-', ''), 1, 6);
    END IF;
    
    final_code := base_code;
    
    -- Ensure uniqueness
    WHILE EXISTS (SELECT 1 FROM users WHERE referral_code = final_code) LOOP
        final_code := base_code || LPAD(counter::text, 2, '0');
        counter := counter + 1;
    END LOOP;
    
    NEW.referral_code := final_code;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to auto-generate referral code for new users
CREATE TRIGGER trigger_generate_referral_code 
    BEFORE INSERT ON users 
    FOR EACH ROW 
    WHEN (NEW.referral_code IS NULL)
    EXECUTE FUNCTION generate_user_referral_code();

-- Insert test data (simplified)
INSERT INTO referral_codes (user_id, code, spa_reward_referrer, spa_reward_referred) 
SELECT 
    u.id,
    'SABO-GIANG-2025',
    150,  -- Higher reward for testing
    75
FROM users u 
WHERE u.username = 'SABO123456'
AND NOT EXISTS (SELECT 1 FROM referral_codes WHERE code = 'SABO-GIANG-2025');

-- Update existing user with referral code if not exists
UPDATE users 
SET referral_code = 'SABO-GIANG-MAIN'
WHERE username = 'SABO123456' 
AND referral_code IS NULL;

COMMIT;

-- Verification queries
SELECT 'Referral Codes Count' as check_name, COUNT(*) as result FROM referral_codes;
SELECT 'Referral Usage Count' as check_name, COUNT(*) as result FROM referral_usage;
SELECT 'Users with Referral Codes' as check_name, COUNT(*) as result FROM users WHERE referral_code IS NOT NULL;

-- Show test data
SELECT 'Test referral codes:' as info;
SELECT code, spa_reward_referrer, spa_reward_referred, is_active, created_at 
FROM referral_codes 
WHERE code LIKE 'SABO-%' 
ORDER BY created_at DESC;

-- Success message
SELECT '✅ SABO Arena Basic Referral System Setup Complete!' as status;
-- Add QR columns to existing users table
-- This migration adds user_code and qr_data columns to support QR scanning

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS user_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS qr_data TEXT;

-- Add index for faster QR lookups
CREATE INDEX IF NOT EXISTS idx_users_user_code ON users(user_code);
CREATE INDEX IF NOT EXISTS idx_users_qr_data ON users(qr_data);

-- Add comment
COMMENT ON COLUMN users.user_code IS 'Unique QR code for user (e.g., SABO123456)';
COMMENT ON COLUMN users.qr_data IS 'QR code data payload';

-- Verify the columns were added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('user_code', 'qr_data');
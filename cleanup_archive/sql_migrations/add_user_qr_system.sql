-- Migration: Add QR Code system to users table
-- Date: 2025-09-19
-- Purpose: Store user_code and qr_data permanently in database for better performance and future features

-- Add user_code and qr_data columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS user_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS qr_data TEXT,
ADD COLUMN IF NOT EXISTS qr_generated_at TIMESTAMP WITH TIME ZONE;

-- Create index for faster user_code lookups (important for QR scanning)
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_code ON users(user_code);

-- Create index for QR data queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_qr_data ON users(qr_data);

-- Add comments for documentation
COMMENT ON COLUMN users.user_code IS 'Unique user code for QR sharing (e.g., SABO123ABC)';
COMMENT ON COLUMN users.qr_data IS 'QR code data URL for profile sharing';
COMMENT ON COLUMN users.qr_generated_at IS 'Timestamp when QR code was generated';

-- Function to auto-generate user_code for existing users
CREATE OR REPLACE FUNCTION generate_user_codes_for_existing_users()
RETURNS void AS $$
DECLARE
    user_record RECORD;
    new_user_code TEXT;
    counter INTEGER := 1;
BEGIN
    -- Loop through users without user_code
    FOR user_record IN 
        SELECT id FROM users WHERE user_code IS NULL
    LOOP
        -- Generate unique code
        LOOP
            new_user_code := 'SABO' || LPAD(counter::TEXT, 6, '0');
            
            -- Check if code already exists
            IF NOT EXISTS (SELECT 1 FROM users WHERE user_code = new_user_code) THEN
                EXIT;
            END IF;
            
            counter := counter + 1;
        END LOOP;
        
        -- Update user with new code
        UPDATE users 
        SET 
            user_code = new_user_code,
            qr_data = 'https://saboarena.com/user/' || user_record.id,
            qr_generated_at = NOW()
        WHERE id = user_record.id;
        
        counter := counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Generated user codes for % users', counter - 1;
END;
$$ LANGUAGE plpgsql;

-- Execute the function to generate codes for existing users
SELECT generate_user_codes_for_existing_users();

-- Drop the function after use (optional)
DROP FUNCTION IF EXISTS generate_user_codes_for_existing_users();

-- Create function to auto-generate user_code on new user registration
CREATE OR REPLACE FUNCTION auto_generate_user_code()
RETURNS TRIGGER AS $$
DECLARE
    new_user_code TEXT;
    counter INTEGER := 1;
    base_code TEXT;
BEGIN
    -- Only generate if user_code is not already set
    IF NEW.user_code IS NULL THEN
        -- Generate base code from user ID (last 6 chars)
        base_code := 'SABO' || UPPER(RIGHT(NEW.id::TEXT, 6));
        
        -- Check if base code is available
        IF NOT EXISTS (SELECT 1 FROM users WHERE user_code = base_code) THEN
            new_user_code := base_code;
        ELSE
            -- Generate alternative with counter
            LOOP
                new_user_code := 'SABO' || LPAD(counter::TEXT, 6, '0');
                
                IF NOT EXISTS (SELECT 1 FROM users WHERE user_code = new_user_code) THEN
                    EXIT;
                END IF;
                
                counter := counter + 1;
            END LOOP;
        END IF;
        
        -- Set the generated code and QR data
        NEW.user_code := new_user_code;
        NEW.qr_data := 'https://saboarena.com/user/' || NEW.id;
        NEW.qr_generated_at := NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate user_code on INSERT
DROP TRIGGER IF EXISTS trigger_auto_generate_user_code ON users;
CREATE TRIGGER trigger_auto_generate_user_code
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_user_code();

-- Grant necessary permissions
GRANT SELECT, UPDATE ON users TO authenticated;
GRANT SELECT ON users TO anon;

-- Test the migration (optional verification queries)
-- SELECT COUNT(*) as total_users, COUNT(user_code) as users_with_codes FROM users;
-- SELECT user_code, qr_data FROM users LIMIT 5;

COMMIT;
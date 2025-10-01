-- Create admin user directly in database
-- Run this SQL in Supabase SQL Editor after creating the auth user

-- Insert admin user profile (replace the UUID with the actual user ID from auth)
-- You can get the user ID from Supabase Auth dashboard
INSERT INTO users (
  id, 
  email, 
  display_name, 
  full_name, 
  role,
  skill_level,
  is_verified,
  is_active,
  total_wins,
  total_losses,
  total_tournaments,
  ranking_points,
  created_at,
  updated_at
) VALUES (
  '6888d85c-15f2-4c12-8779-53630949a140', -- Replace with actual auth user ID
  'admin@saboarena.com',
  'Admin',
  'System Administrator',
  'admin',
  'Expert',
  true,
  true,
  0,
  0,
  0,
  2000,
  NOW(),
  NOW()
) ON CONFLICT (id) DO UPDATE SET 
  role = 'admin',
  is_verified = true,
  is_active = true,
  updated_at = NOW();

-- Verify the admin user was created
SELECT id, email, display_name, role, is_verified FROM users WHERE role = 'admin';
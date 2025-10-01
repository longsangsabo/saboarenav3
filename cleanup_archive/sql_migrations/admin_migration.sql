-- Migration: Add admin approval system for clubs
-- Run this SQL in Supabase SQL Editor

-- Add new columns to clubs table for approval system
ALTER TABLE clubs 
ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES users(id);

-- Update existing clubs to be approved by default (backward compatibility)
UPDATE clubs 
SET approval_status = 'approved', 
    approved_at = NOW(),
    is_active = true
WHERE approval_status IS NULL OR approval_status = 'pending';

-- Create admin_logs table for audit trail
CREATE TABLE IF NOT EXISTS admin_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(50) NOT NULL,
  target_id UUID NOT NULL,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_admin_logs_admin_id ON admin_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created_at ON admin_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_clubs_approval_status ON clubs(approval_status);

-- Create a test admin user (optional - for development)
-- Replace email/password with your preferred admin credentials
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES (
  'admin-00000000-0000-0000-0000-000000000001',
  'admin@saboarena.com',
  crypt('admin123456', gen_salt('bf')), -- Change this password!
  NOW(),
  NOW(),
  NOW()
) ON CONFLICT (email) DO NOTHING;

-- Create user profile for admin
INSERT INTO users (
  id, 
  email, 
  display_name, 
  full_name, 
  role,
  skill_level,
  is_verified,
  created_at,
  updated_at
) VALUES (
  'admin-00000000-0000-0000-0000-000000000001',
  'admin@saboarena.com',
  'System Admin',
  'Administrator',
  'admin',
  'Expert',
  true,
  NOW(),
  NOW()
) ON CONFLICT (id) DO UPDATE SET 
  role = 'admin',
  is_verified = true;

-- Add RLS policies for admin functions
-- Admin can read all clubs regardless of approval status
CREATE POLICY "Admins can view all clubs" ON clubs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Admin can update club approval status
CREATE POLICY "Admins can update club approval" ON clubs
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Admin can view admin logs
CREATE POLICY "Admins can view admin logs" ON admin_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Admin can insert admin logs
CREATE POLICY "Admins can insert admin logs" ON admin_logs
  FOR INSERT WITH CHECK (
    admin_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );
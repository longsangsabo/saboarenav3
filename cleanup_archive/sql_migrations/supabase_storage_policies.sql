-- ==========================================
-- SUPABASE STORAGE SECURITY POLICIES
-- ==========================================
-- Copy and paste this SQL into Supabase SQL Editor
-- Go to: https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql

-- Enable Row Level Security on storage tables
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can upload their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view profile images" ON storage.objects;
DROP POLICY IF EXISTS "Public can access profiles bucket" ON storage.buckets;

-- 1. Policy: Users can upload their own profile images
CREATE POLICY "Users can upload their own profile images" 
ON storage.objects
FOR INSERT 
WITH CHECK (
  bucket_id = 'profiles' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 2. Policy: Users can update their own profile images  
CREATE POLICY "Users can update their own profile images" 
ON storage.objects
FOR UPDATE 
USING (
  bucket_id = 'profiles' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 3. Policy: Users can delete their own profile images
CREATE POLICY "Users can delete their own profile images" 
ON storage.objects
FOR DELETE 
USING (
  bucket_id = 'profiles' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 4. Policy: Public can view profile images
CREATE POLICY "Public can view profile images" 
ON storage.objects
FOR SELECT 
USING (bucket_id = 'profiles');

-- 5. Policy: Public can access profiles bucket
CREATE POLICY "Public can access profiles bucket" 
ON storage.buckets
FOR SELECT 
USING (id = 'profiles');

-- ==========================================
-- VERIFICATION QUERIES
-- ==========================================
-- Run these to verify everything is set up correctly:

-- Check if bucket exists
SELECT id, name, public, file_size_limit, allowed_mime_types 
FROM storage.buckets 
WHERE id = 'profiles';

-- Check if policies exist
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname;

-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename IN ('objects', 'buckets');

-- ==========================================
-- SUCCESS MESSAGE
-- ==========================================
-- If all queries run successfully, you should see:
-- ✅ Bucket 'profiles' exists
-- ✅ 4 policies created for storage.objects
-- ✅ 1 policy created for storage.buckets  
-- ✅ RLS enabled on both tables
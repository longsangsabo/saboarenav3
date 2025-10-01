-- Supabase Storage Setup for SABO Arena App
-- Run these SQL commands in Supabase SQL editor

-- 1. Create profiles bucket for storing avatar and cover photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profiles',
  'profiles',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
);

-- 2. Create storage policy to allow authenticated users to upload their own files
CREATE POLICY "Users can upload their own profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profiles' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 3. Create storage policy to allow authenticated users to update their own files
CREATE POLICY "Users can update their own profile images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profiles' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 4. Create storage policy to allow authenticated users to delete their own files
CREATE POLICY "Users can delete their own profile images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profiles' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 5. Create storage policy to allow public access to view profile images
CREATE POLICY "Public can view profile images" ON storage.objects
FOR SELECT USING (bucket_id = 'profiles');

-- 6. Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 7. Enable RLS on storage.buckets if not already enabled  
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- 8. Create policy for bucket access
CREATE POLICY "Public can access profiles bucket" ON storage.buckets
FOR SELECT USING (id = 'profiles');
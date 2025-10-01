-- Create storage bucket for club logos
-- Run this in Supabase SQL Editor

INSERT INTO storage.buckets (id, name, public)
VALUES ('club-logos', 'club-logos', true);

-- Create policy to allow authenticated users to upload logos
CREATE POLICY "Club owners can upload logos" 
ON storage.objects 
FOR INSERT 
WITH CHECK (
  bucket_id = 'club-logos' 
  AND auth.role() = 'authenticated'
);

-- Create policy to allow public read access to logos
CREATE POLICY "Anyone can view club logos" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'club-logos');

-- Create policy to allow club owners to update their logos
CREATE POLICY "Club owners can update their logos" 
ON storage.objects 
FOR UPDATE 
USING (
  bucket_id = 'club-logos' 
  AND auth.role() = 'authenticated'
);

-- Create policy to allow club owners to delete their logos
CREATE POLICY "Club owners can delete their logos" 
ON storage.objects 
FOR DELETE 
USING (
  bucket_id = 'club-logos' 
  AND auth.role() = 'authenticated'
);
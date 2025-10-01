-- Check table structures for tournament_participants and related tables
-- This will help us understand the correct data types and relationships

-- 1. Check tournament_participants table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'tournament_participants'
ORDER BY ordinal_position;

-- 2. Check users table structure  
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- 3. Check tournaments table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'tournaments'
ORDER BY ordinal_position;

-- 4. Check existing RLS policies
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    cmd as operation,
    roles,
    qual as condition
FROM pg_policies 
WHERE tablename IN ('tournament_participants', 'users', 'tournaments')
ORDER BY tablename, policyname;
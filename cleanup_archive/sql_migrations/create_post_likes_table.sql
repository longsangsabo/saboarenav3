-- Create post_likes table
CREATE TABLE IF NOT EXISTS post_likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, post_id)
);

-- Enable RLS
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view all likes" ON post_likes
    FOR SELECT USING (true);

CREATE POLICY "Users can like posts" ON post_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike their own likes" ON post_likes
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_created_at ON post_likes(created_at);

-- Create increment/decrement like count functions
CREATE OR REPLACE FUNCTION increment_post_likes(post_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE posts SET likes_count = COALESCE(likes_count, 0) + 1 WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrement_post_likes(post_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE posts SET likes_count = GREATEST(COALESCE(likes_count, 0) - 1, 0) WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create RPC functions for like/unlike operations
CREATE OR REPLACE FUNCTION like_post(post_id UUID)
RETURNS json AS $$
DECLARE
    user_id UUID := auth.uid();
    result json;
BEGIN
    -- Check if user is authenticated
    IF user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not authenticated');
    END IF;

    -- Insert like record
    INSERT INTO post_likes (user_id, post_id)
    VALUES (user_id, post_id)
    ON CONFLICT (user_id, post_id) DO NOTHING;

    -- Check if the insert was successful (not a duplicate)
    IF FOUND THEN
        -- Increment likes count
        PERFORM increment_post_likes(post_id);
        result := json_build_object('success', true, 'message', 'Post liked successfully');
    ELSE
        result := json_build_object('success', false, 'error', 'Post already liked');
    END IF;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION unlike_post(post_id UUID)
RETURNS json AS $$
DECLARE
    user_id UUID := auth.uid();
    result json;
BEGIN
    -- Check if user is authenticated
    IF user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not authenticated');
    END IF;

    -- Delete like record
    DELETE FROM post_likes 
    WHERE user_id = user_id AND post_id = post_id;

    -- Check if the delete was successful
    IF FOUND THEN
        -- Decrement likes count
        PERFORM decrement_post_likes(post_id);
        result := json_build_object('success', true, 'message', 'Post unliked successfully');
    ELSE
        result := json_build_object('success', false, 'error', 'Like not found');
    END IF;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION has_user_liked_post(post_id UUID)
RETURNS boolean AS $$
DECLARE
    user_id UUID := auth.uid();
BEGIN
    -- Check if user is authenticated
    IF user_id IS NULL THEN
        RETURN false;
    END IF;

    -- Check if like exists
    RETURN EXISTS (
        SELECT 1 FROM post_likes 
        WHERE user_id = user_id AND post_id = post_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
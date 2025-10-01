-- Create post_comments table
CREATE TABLE IF NOT EXISTS post_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (length(content) > 0 AND length(content) <= 1000),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view all comments" ON post_comments;
DROP POLICY IF EXISTS "Users can create comments" ON post_comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON post_comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON post_comments;

-- RLS Policies for post_comments
CREATE POLICY "Users can view all comments" ON post_comments
    FOR SELECT USING (true);

CREATE POLICY "Users can create comments" ON post_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments" ON post_comments
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" ON post_comments
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_post_comments_user_id ON post_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_created_at ON post_comments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_comments_post_created ON post_comments(post_id, created_at DESC);

-- Create comment count functions
CREATE OR REPLACE FUNCTION increment_post_comments(post_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE posts SET comments_count = COALESCE(comments_count, 0) + 1 WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrement_post_comments(post_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE posts SET comments_count = GREATEST(COALESCE(comments_count, 0) - 1, 0) WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger function to update comment count automatically
CREATE OR REPLACE FUNCTION update_post_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM increment_post_comments(NEW.post_id);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM decrement_post_comments(OLD.post_id);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists and create new one
DROP TRIGGER IF EXISTS trigger_update_comment_count ON post_comments;
CREATE TRIGGER trigger_update_comment_count
    AFTER INSERT OR DELETE ON post_comments
    FOR EACH ROW EXECUTE FUNCTION update_post_comment_count();

-- Create RPC functions for comment operations
CREATE OR REPLACE FUNCTION create_comment(post_id UUID, content TEXT)
RETURNS json AS $$
DECLARE
    user_id UUID := auth.uid();
    new_comment post_comments;
    user_info json;
    result json;
BEGIN
    -- Check if user is authenticated
    IF user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not authenticated');
    END IF;

    -- Validate content
    IF content IS NULL OR trim(content) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Comment content cannot be empty');
    END IF;

    IF length(trim(content)) > 1000 THEN
        RETURN json_build_object('success', false, 'error', 'Comment too long (max 1000 characters)');
    END IF;

    -- Insert comment
    INSERT INTO post_comments (user_id, post_id, content)
    VALUES (user_id, post_id, trim(content))
    RETURNING * INTO new_comment;

    -- Get user info
    SELECT json_build_object(
        'id', u.id,
        'email', u.email,
        'full_name', u.full_name,
        'avatar_url', u.avatar_url
    ) INTO user_info
    FROM users u WHERE u.id = user_id;

    -- Build result with comment and user info
    result := json_build_object(
        'success', true,
        'comment', json_build_object(
            'id', new_comment.id,
            'user_id', new_comment.user_id,
            'post_id', new_comment.post_id,
            'content', new_comment.content,
            'created_at', new_comment.created_at,
            'updated_at', new_comment.updated_at,
            'user', user_info
        )
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_post_comments(post_id UUID, limit_count INTEGER DEFAULT 20, offset_count INTEGER DEFAULT 0)
RETURNS json AS $$
DECLARE
    comments json;
BEGIN
    -- Get comments with user info
    SELECT json_agg(
        json_build_object(
            'id', c.id,
            'user_id', c.user_id,
            'post_id', c.post_id,
            'content', c.content,
            'created_at', c.created_at,
            'updated_at', c.updated_at,
            'user', json_build_object(
                'id', u.id,
                'email', u.email,
                'full_name', u.full_name,
                'avatar_url', u.avatar_url
            )
        ) ORDER BY c.created_at DESC
    ) INTO comments
    FROM post_comments c
    JOIN users u ON c.user_id = u.id
    WHERE c.post_id = get_post_comments.post_id
    LIMIT limit_count OFFSET offset_count;

    RETURN json_build_object(
        'success', true,
        'comments', COALESCE(comments, '[]'::json)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION delete_comment(comment_id UUID)
RETURNS json AS $$
DECLARE
    user_id UUID := auth.uid();
    comment_exists BOOLEAN;
BEGIN
    -- Check if user is authenticated
    IF user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not authenticated');
    END IF;

    -- Check if comment exists and belongs to user
    SELECT EXISTS (
        SELECT 1 FROM post_comments 
        WHERE id = comment_id AND user_id = delete_comment.user_id
    ) INTO comment_exists;

    IF NOT comment_exists THEN
        RETURN json_build_object('success', false, 'error', 'Comment not found or access denied');
    END IF;

    -- Delete comment
    DELETE FROM post_comments WHERE id = comment_id;

    RETURN json_build_object('success', true, 'message', 'Comment deleted successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC function to get comment count for a specific post
CREATE OR REPLACE FUNCTION get_post_comment_count(post_id UUID)
RETURNS INTEGER AS $$
DECLARE
    comment_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO comment_count
    FROM post_comments
    WHERE post_comments.post_id = get_post_comment_count.post_id;
    
    RETURN COALESCE(comment_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC function to update/edit a comment
CREATE OR REPLACE FUNCTION update_comment(comment_id UUID, new_content TEXT)
RETURNS json AS $$
DECLARE
    user_id UUID := auth.uid();
    updated_comment post_comments;
    user_info json;
    result json;
BEGIN
    -- Check if user is authenticated
    IF user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not authenticated');
    END IF;

    -- Validate content
    IF new_content IS NULL OR trim(new_content) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Comment content cannot be empty');
    END IF;

    IF length(trim(new_content)) > 1000 THEN
        RETURN json_build_object('success', false, 'error', 'Comment too long (max 1000 characters)');
    END IF;

    -- Update comment (RLS will ensure user can only update their own comments)
    UPDATE post_comments 
    SET content = trim(new_content), updated_at = timezone('utc'::text, now())
    WHERE id = comment_id AND user_id = update_comment.user_id
    RETURNING * INTO updated_comment;

    -- Check if comment was found and updated
    IF updated_comment.id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Comment not found or access denied');
    END IF;

    -- Get user info
    SELECT json_build_object(
        'id', u.id,
        'email', u.email,
        'full_name', u.full_name,
        'avatar_url', u.avatar_url
    ) INTO user_info
    FROM users u WHERE u.id = user_id;

    -- Build result with updated comment and user info
    result := json_build_object(
        'success', true,
        'comment', json_build_object(
            'id', updated_comment.id,
            'user_id', updated_comment.user_id,
            'post_id', updated_comment.post_id,
            'content', updated_comment.content,
            'created_at', updated_comment.created_at,
            'updated_at', updated_comment.updated_at,
            'user', user_info
        )
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
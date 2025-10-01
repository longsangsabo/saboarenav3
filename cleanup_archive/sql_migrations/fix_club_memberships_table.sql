-- Fix table club_memberships missing error
-- This script will create the missing table and update the function

-- 1. Create club_memberships table if not exists
CREATE TABLE IF NOT EXISTS public.club_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(club_id, user_id)
);

-- 2. Enable RLS on the table
ALTER TABLE public.club_memberships ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS policies
CREATE POLICY "Users can view their own memberships" ON public.club_memberships
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Club owners can manage memberships" ON public.club_memberships
    FOR ALL USING (
        club_id IN (
            SELECT id FROM public.clubs WHERE owner_id = auth.uid()
        )
    );

-- 4. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_club_memberships_user_id ON public.club_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_club_memberships_club_id ON public.club_memberships(club_id);
CREATE INDEX IF NOT EXISTS idx_club_memberships_role ON public.club_memberships(role);

-- 5. Update the function to use correct table name
DROP FUNCTION IF EXISTS get_pending_rank_change_requests();

CREATE OR REPLACE FUNCTION get_pending_rank_change_requests()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_requests JSON;
    v_is_admin BOOLEAN := false;
    v_user_club_id UUID;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Check if user is system admin
    SELECT (role = 'admin') INTO v_is_admin
    FROM users 
    WHERE id = v_user_id;

    -- Get user's club if they're not admin
    IF NOT v_is_admin THEN
        SELECT club_id INTO v_user_club_id
        FROM club_memberships 
        WHERE user_id = v_user_id 
        AND role IN ('owner', 'admin')
        LIMIT 1;
        
        -- If user is not admin and not club admin, return empty array
        IF v_user_club_id IS NULL THEN
            RETURN '[]'::JSON;
        END IF;
    END IF;

    -- Get pending requests based on user permissions
    SELECT json_agg(
        json_build_object(
            'id', n.id,
            'user_id', n.user_id,
            'user_name', u.full_name,
            'user_email', u.email,
            'user_avatar', u.avatar_url,
            'current_rank', (n.data->>'current_rank'),
            'requested_rank', (n.data->>'requested_rank'),
            'reason', (n.data->>'reason'),
            'evidence_urls', (n.data->'evidence_urls'),
            'submitted_at', (n.data->>'submitted_at'),
            'workflow_status', (n.data->>'workflow_status'),
            'user_club_id', (n.data->>'user_club_id'),
            'created_at', n.created_at
        )
    ) INTO v_requests
    FROM notifications n
    JOIN users u ON n.user_id = u.id
    WHERE n.type = 'rank_change_request'
    AND (n.data->>'workflow_status') IN ('pending_club_review', 'pending_admin_review')
    AND (
        v_is_admin OR  -- System admin sees all
        (n.data->>'user_club_id')::UUID = v_user_club_id  -- Club admin sees their club's requests
    )
    ORDER BY n.created_at DESC;

    RETURN COALESCE(v_requests, '[]'::JSON);
END;
$$;

-- 6. Grant permissions
GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests() TO authenticated;

-- 7. Test
SELECT 'Table and function fixed successfully' as status;
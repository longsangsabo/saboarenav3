-- Privacy Settings Schema for User Profile Visibility Control
-- Add privacy settings table for users

-- Create privacy settings table
CREATE TABLE IF NOT EXISTS user_privacy_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Social interaction visibility
    show_in_social_feed BOOLEAN DEFAULT true,
    show_in_challenge_list BOOLEAN DEFAULT true,
    show_in_tournament_participants BOOLEAN DEFAULT true,
    show_in_leaderboard BOOLEAN DEFAULT true,
    
    -- Profile information visibility
    show_real_name BOOLEAN DEFAULT false,
    show_phone_number BOOLEAN DEFAULT false,
    show_email BOOLEAN DEFAULT false,
    show_location BOOLEAN DEFAULT true,
    show_club_membership BOOLEAN DEFAULT true,
    
    -- Activity visibility
    show_match_history BOOLEAN DEFAULT true,
    show_win_loss_record BOOLEAN DEFAULT true,
    show_current_rank BOOLEAN DEFAULT true,
    show_achievements BOOLEAN DEFAULT true,
    show_online_status BOOLEAN DEFAULT true,
    
    -- Challenge and matchmaking
    allow_challenges_from_strangers BOOLEAN DEFAULT true,
    allow_tournament_invitations BOOLEAN DEFAULT true,
    allow_friend_requests BOOLEAN DEFAULT true,
    
    -- Notification preferences
    notify_on_challenge BOOLEAN DEFAULT true,
    notify_on_tournament_invite BOOLEAN DEFAULT true,
    notify_on_friend_request BOOLEAN DEFAULT true,
    notify_on_match_result BOOLEAN DEFAULT true,
    
    -- Search and discovery
    searchable_by_username BOOLEAN DEFAULT true,
    searchable_by_real_name BOOLEAN DEFAULT false,
    searchable_by_phone BOOLEAN DEFAULT false,
    appear_in_suggestions BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_privacy_settings_user_id ON user_privacy_settings(user_id);

-- RLS Policies for privacy settings
ALTER TABLE user_privacy_settings ENABLE ROW LEVEL SECURITY;

-- Users can only see and modify their own privacy settings
CREATE POLICY "Users can view own privacy settings" ON user_privacy_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own privacy settings" ON user_privacy_settings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own privacy settings" ON user_privacy_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Function to get user privacy settings with defaults
CREATE OR REPLACE FUNCTION get_user_privacy_settings(target_user_id UUID)
RETURNS TABLE (
    show_in_social_feed BOOLEAN,
    show_in_challenge_list BOOLEAN,
    show_in_tournament_participants BOOLEAN,
    show_in_leaderboard BOOLEAN,
    show_real_name BOOLEAN,
    show_phone_number BOOLEAN,
    show_email BOOLEAN,
    show_location BOOLEAN,
    show_club_membership BOOLEAN,
    show_match_history BOOLEAN,
    show_win_loss_record BOOLEAN,
    show_current_rank BOOLEAN,
    show_achievements BOOLEAN,
    show_online_status BOOLEAN,
    allow_challenges_from_strangers BOOLEAN,
    allow_tournament_invitations BOOLEAN,
    allow_friend_requests BOOLEAN,
    searchable_by_username BOOLEAN,
    searchable_by_real_name BOOLEAN,
    searchable_by_phone BOOLEAN,
    appear_in_suggestions BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(ups.show_in_social_feed, true),
        COALESCE(ups.show_in_challenge_list, true),
        COALESCE(ups.show_in_tournament_participants, true),
        COALESCE(ups.show_in_leaderboard, true),
        COALESCE(ups.show_real_name, false),
        COALESCE(ups.show_phone_number, false),
        COALESCE(ups.show_email, false),
        COALESCE(ups.show_location, true),
        COALESCE(ups.show_club_membership, true),
        COALESCE(ups.show_match_history, true),
        COALESCE(ups.show_win_loss_record, true),
        COALESCE(ups.show_current_rank, true),
        COALESCE(ups.show_achievements, true),
        COALESCE(ups.show_online_status, true),
        COALESCE(ups.allow_challenges_from_strangers, true),
        COALESCE(ups.allow_tournament_invitations, true),
        COALESCE(ups.allow_friend_requests, true),
        COALESCE(ups.searchable_by_username, true),
        COALESCE(ups.searchable_by_real_name, false),
        COALESCE(ups.searchable_by_phone, false),
        COALESCE(ups.appear_in_suggestions, true)
    FROM user_privacy_settings ups
    WHERE ups.user_id = target_user_id
    UNION ALL
    SELECT 
        true, true, true, true, -- social visibility defaults
        false, false, false, true, true, -- profile info defaults
        true, true, true, true, true, -- activity defaults
        true, true, true, -- challenge defaults
        true, false, false, true -- search defaults
    WHERE NOT EXISTS (
        SELECT 1 FROM user_privacy_settings WHERE user_id = target_user_id
    )
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to save user privacy settings
CREATE OR REPLACE FUNCTION save_user_privacy_settings(
    target_user_id UUID,
    settings JSONB
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO user_privacy_settings (
        user_id,
        show_in_social_feed,
        show_in_challenge_list,
        show_in_tournament_participants,
        show_in_leaderboard,
        show_real_name,
        show_phone_number,
        show_email,
        show_location,
        show_club_membership,
        show_match_history,
        show_win_loss_record,
        show_current_rank,
        show_achievements,
        show_online_status,
        allow_challenges_from_strangers,
        allow_tournament_invitations,
        allow_friend_requests,
        notify_on_challenge,
        notify_on_tournament_invite,
        notify_on_friend_request,
        notify_on_match_result,
        searchable_by_username,
        searchable_by_real_name,
        searchable_by_phone,
        appear_in_suggestions,
        updated_at
    ) VALUES (
        target_user_id,
        (settings->>'show_in_social_feed')::BOOLEAN,
        (settings->>'show_in_challenge_list')::BOOLEAN,
        (settings->>'show_in_tournament_participants')::BOOLEAN,
        (settings->>'show_in_leaderboard')::BOOLEAN,
        (settings->>'show_real_name')::BOOLEAN,
        (settings->>'show_phone_number')::BOOLEAN,
        (settings->>'show_email')::BOOLEAN,
        (settings->>'show_location')::BOOLEAN,
        (settings->>'show_club_membership')::BOOLEAN,
        (settings->>'show_match_history')::BOOLEAN,
        (settings->>'show_win_loss_record')::BOOLEAN,
        (settings->>'show_current_rank')::BOOLEAN,
        (settings->>'show_achievements')::BOOLEAN,
        (settings->>'show_online_status')::BOOLEAN,
        (settings->>'allow_challenges_from_strangers')::BOOLEAN,
        (settings->>'allow_tournament_invitations')::BOOLEAN,
        (settings->>'allow_friend_requests')::BOOLEAN,
        (settings->>'notify_on_challenge')::BOOLEAN,
        (settings->>'notify_on_tournament_invite')::BOOLEAN,
        (settings->>'notify_on_friend_request')::BOOLEAN,
        (settings->>'notify_on_match_result')::BOOLEAN,
        (settings->>'searchable_by_username')::BOOLEAN,
        (settings->>'searchable_by_real_name')::BOOLEAN,
        (settings->>'searchable_by_phone')::BOOLEAN,
        (settings->>'appear_in_suggestions')::BOOLEAN,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        show_in_social_feed = (settings->>'show_in_social_feed')::BOOLEAN,
        show_in_challenge_list = (settings->>'show_in_challenge_list')::BOOLEAN,
        show_in_tournament_participants = (settings->>'show_in_tournament_participants')::BOOLEAN,
        show_in_leaderboard = (settings->>'show_in_leaderboard')::BOOLEAN,
        show_real_name = (settings->>'show_real_name')::BOOLEAN,
        show_phone_number = (settings->>'show_phone_number')::BOOLEAN,
        show_email = (settings->>'show_email')::BOOLEAN,
        show_location = (settings->>'show_location')::BOOLEAN,
        show_club_membership = (settings->>'show_club_membership')::BOOLEAN,
        show_match_history = (settings->>'show_match_history')::BOOLEAN,
        show_win_loss_record = (settings->>'show_win_loss_record')::BOOLEAN,
        show_current_rank = (settings->>'show_current_rank')::BOOLEAN,
        show_achievements = (settings->>'show_achievements')::BOOLEAN,
        show_online_status = (settings->>'show_online_status')::BOOLEAN,
        allow_challenges_from_strangers = (settings->>'allow_challenges_from_strangers')::BOOLEAN,
        allow_tournament_invitations = (settings->>'allow_tournament_invitations')::BOOLEAN,
        allow_friend_requests = (settings->>'allow_friend_requests')::BOOLEAN,
        notify_on_challenge = (settings->>'notify_on_challenge')::BOOLEAN,
        notify_on_tournament_invite = (settings->>'notify_on_tournament_invite')::BOOLEAN,
        notify_on_friend_request = (settings->>'notify_on_friend_request')::BOOLEAN,
        notify_on_match_result = (settings->>'notify_on_match_result')::BOOLEAN,
        searchable_by_username = (settings->>'searchable_by_username')::BOOLEAN,
        searchable_by_real_name = (settings->>'searchable_by_real_name')::BOOLEAN,
        searchable_by_phone = (settings->>'searchable_by_phone')::BOOLEAN,
        appear_in_suggestions = (settings->>'appear_in_suggestions')::BOOLEAN,
        updated_at = NOW();
    
    RETURN true;
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update timestamp
CREATE OR REPLACE FUNCTION update_privacy_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_privacy_settings_updated_at
    BEFORE UPDATE ON user_privacy_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_privacy_settings_updated_at();

-- Sample data insertion for existing users (optional)
-- INSERT INTO user_privacy_settings (user_id) 
-- SELECT id FROM users WHERE id NOT IN (SELECT user_id FROM user_privacy_settings);

COMMENT ON TABLE user_privacy_settings IS 'Privacy settings for user profile visibility and interaction preferences';
COMMENT ON FUNCTION get_user_privacy_settings(UUID) IS 'Get user privacy settings with default values if not set';
COMMENT ON FUNCTION save_user_privacy_settings(UUID, JSONB) IS 'Save or update user privacy settings';
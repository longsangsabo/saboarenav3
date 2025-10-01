-- ====================================
-- SABO ARENA - MESSAGING RPC FUNCTIONS
-- Complete RPC functions for messaging system
-- ====================================

-- ====================================
-- 1. CHAT MANAGEMENT FUNCTIONS
-- ====================================

-- Create private chat
CREATE OR REPLACE FUNCTION create_private_chat(
  other_user_id UUID,
  initial_message TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  existing_chat_id UUID;
  new_chat_id UUID;
  current_user_name TEXT;
  other_user_name TEXT;
  chat_name TEXT;
  result JSON;
BEGIN
  -- Check if private chat already exists
  SELECT c.id INTO existing_chat_id
  FROM chats c
  JOIN chat_participants cp1 ON c.id = cp1.chat_id AND cp1.user_id = auth.uid()
  JOIN chat_participants cp2 ON c.id = cp2.chat_id AND cp2.user_id = other_user_id
  WHERE c.type = 'private' 
    AND cp1.is_active = true 
    AND cp2.is_active = true
  LIMIT 1;
  
  -- If exists, return existing chat
  IF existing_chat_id IS NOT NULL THEN
    SELECT json_build_object(
      'chat_id', existing_chat_id,
      'created', false
    ) INTO result;
    RETURN result;
  END IF;
  
  -- Get usernames
  SELECT raw_user_meta_data->>'username' INTO current_user_name
  FROM auth.users WHERE id = auth.uid();
  
  SELECT raw_user_meta_data->>'username' INTO other_user_name
  FROM auth.users WHERE id = other_user_id;
  
  -- Create chat name
  chat_name := current_user_name || ', ' || other_user_name;
  
  -- Create new chat
  INSERT INTO chats (name, type, created_by)
  VALUES (chat_name, 'private', auth.uid())
  RETURNING id INTO new_chat_id;
  
  -- Add participants
  INSERT INTO chat_participants (chat_id, user_id, role)
  VALUES 
    (new_chat_id, auth.uid(), 'admin'),
    (new_chat_id, other_user_id, 'admin');
  
  -- Send initial message if provided
  IF initial_message IS NOT NULL AND initial_message != '' THEN
    PERFORM send_message(new_chat_id, initial_message, 'text');
  END IF;
  
  -- Send system message
  INSERT INTO messages (chat_id, sender_id, content, type)
  VALUES (new_chat_id, 'system', 'Chat created', 'system');
  
  SELECT json_build_object(
    'chat_id', new_chat_id,
    'created', true
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create group chat
CREATE OR REPLACE FUNCTION create_group_chat(
  chat_name TEXT,
  description TEXT DEFAULT NULL,
  participant_ids UUID[] DEFAULT ARRAY[]::UUID[],
  avatar_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  new_chat_id UUID;
  participant_id UUID;
  creator_name TEXT;
BEGIN
  -- Create chat
  INSERT INTO chats (name, description, type, avatar_url, created_by)
  VALUES (chat_name, description, 'group', avatar_url, auth.uid())
  RETURNING id INTO new_chat_id;
  
  -- Add creator as owner
  INSERT INTO chat_participants (chat_id, user_id, role)
  VALUES (new_chat_id, auth.uid(), 'owner');
  
  -- Add other participants
  FOREACH participant_id IN ARRAY participant_ids
  LOOP
    IF participant_id != auth.uid() THEN
      INSERT INTO chat_participants (chat_id, user_id, role, invited_by)
      VALUES (new_chat_id, participant_id, 'member', auth.uid());
    END IF;
  END LOOP;
  
  -- Get creator name
  SELECT raw_user_meta_data->>'username' INTO creator_name
  FROM auth.users WHERE id = auth.uid();
  
  -- Send system message
  INSERT INTO messages (chat_id, sender_id, content, type)
  VALUES (new_chat_id, 'system', creator_name || ' created "' || chat_name || '"', 'system');
  
  RETURN new_chat_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add participants to chat
CREATE OR REPLACE FUNCTION add_chat_participants(
  chat_id UUID,
  participant_ids UUID[]
)
RETURNS BOOLEAN AS $$
DECLARE
  participant_id UUID;
  chat_info RECORD;
  current_user_role TEXT;
  user_name TEXT;
BEGIN
  -- Check permissions
  SELECT cp.role INTO current_user_role
  FROM chat_participants cp
  WHERE cp.chat_id = add_chat_participants.chat_id 
    AND cp.user_id = auth.uid() 
    AND cp.is_active = true;
  
  IF current_user_role IS NULL THEN
    RAISE EXCEPTION 'User is not a participant of this chat';
  END IF;
  
  -- Get chat info
  SELECT * INTO chat_info FROM chats WHERE id = chat_id;
  
  -- Check if user can add participants
  IF chat_info.type = 'private' THEN
    RAISE EXCEPTION 'Cannot add participants to private chat';
  END IF;
  
  IF NOT (current_user_role IN ('owner', 'admin') OR 
          (chat_info.settings->>'allow_members_to_add_others')::boolean) THEN
    RAISE EXCEPTION 'No permission to add participants';
  END IF;
  
  -- Add participants
  FOREACH participant_id IN ARRAY participant_ids
  LOOP
    -- Skip if already participant
    IF NOT EXISTS (
      SELECT 1 FROM chat_participants 
      WHERE chat_id = add_chat_participants.chat_id 
        AND user_id = participant_id
    ) THEN
      INSERT INTO chat_participants (chat_id, user_id, role, invited_by)
      VALUES (chat_id, participant_id, 'member', auth.uid());
      
      -- Get user name and send system message
      SELECT raw_user_meta_data->>'username' INTO user_name
      FROM auth.users WHERE id = participant_id;
      
      INSERT INTO messages (chat_id, sender_id, content, type)
      VALUES (chat_id, 'system', user_name || ' was added to the group', 'system');
    END IF;
  END LOOP;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remove participant from chat
CREATE OR REPLACE FUNCTION remove_chat_participant(
  chat_id UUID,
  participant_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  current_user_role TEXT;
  target_user_role TEXT;
  user_name TEXT;
BEGIN
  -- Get current user role
  SELECT role INTO current_user_role
  FROM chat_participants
  WHERE chat_id = remove_chat_participant.chat_id 
    AND user_id = auth.uid() 
    AND is_active = true;
  
  -- Get target user role
  SELECT role INTO target_user_role
  FROM chat_participants
  WHERE chat_id = remove_chat_participant.chat_id 
    AND user_id = participant_id 
    AND is_active = true;
  
  -- Check permissions
  IF current_user_role IS NULL THEN
    RAISE EXCEPTION 'User is not a participant of this chat';
  END IF;
  
  IF target_user_role IS NULL THEN
    RAISE EXCEPTION 'Target user is not a participant of this chat';
  END IF;
  
  -- Owner can remove anyone except other owners
  -- Admin can remove members only
  -- Members can only remove themselves
  IF NOT (
    (current_user_role = 'owner' AND target_user_role != 'owner') OR
    (current_user_role = 'admin' AND target_user_role = 'member') OR
    (auth.uid() = participant_id)
  ) THEN
    RAISE EXCEPTION 'No permission to remove this participant';
  END IF;
  
  -- Mark as left
  UPDATE chat_participants 
  SET is_active = false, left_at = NOW()
  WHERE chat_id = remove_chat_participant.chat_id 
    AND user_id = participant_id;
  
  -- Get user name and send system message
  SELECT raw_user_meta_data->>'username' INTO user_name
  FROM auth.users WHERE id = participant_id;
  
  IF auth.uid() = participant_id THEN
    INSERT INTO messages (chat_id, sender_id, content, type)
    VALUES (chat_id, 'system', user_name || ' left the group', 'system');
  ELSE
    INSERT INTO messages (chat_id, sender_id, content, type)
    VALUES (chat_id, 'system', user_name || ' was removed from the group', 'system');
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update participant role
CREATE OR REPLACE FUNCTION update_participant_role(
  chat_id UUID,
  participant_id UUID,
  new_role TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  current_user_role TEXT;
  user_name TEXT;
BEGIN
  -- Check if current user is owner or admin
  SELECT role INTO current_user_role
  FROM chat_participants
  WHERE chat_id = update_participant_role.chat_id 
    AND user_id = auth.uid() 
    AND is_active = true;
  
  IF current_user_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'No permission to update participant roles';
  END IF;
  
  -- Only owners can promote to admin or change owner
  IF new_role IN ('admin', 'owner') AND current_user_role != 'owner' THEN
    RAISE EXCEPTION 'Only owners can promote to admin or owner';
  END IF;
  
  -- Update role
  UPDATE chat_participants 
  SET role = new_role
  WHERE chat_id = update_participant_role.chat_id 
    AND user_id = participant_id;
  
  -- Send system message
  SELECT raw_user_meta_data->>'username' INTO user_name
  FROM auth.users WHERE id = participant_id;
  
  INSERT INTO messages (chat_id, sender_id, content, type)
  VALUES (chat_id, 'system', user_name || ' is now ' || new_role, 'system');
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 2. MESSAGE FUNCTIONS
-- ====================================

-- Get messages for a chat (with pagination)
CREATE OR REPLACE FUNCTION get_chat_messages(
  chat_id UUID,
  limit_count INTEGER DEFAULT 20,
  offset_count INTEGER DEFAULT 0,
  before_message_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  sender_id UUID,
  sender_name TEXT,
  sender_avatar_url TEXT,
  content TEXT,
  type TEXT,
  status TEXT,
  attachments JSONB,
  metadata JSONB,
  reply_to_id UUID,
  is_edited BOOLEAN,
  created_at TIMESTAMPTZ,
  reactions JSONB
) AS $$
BEGIN
  -- Check if user is participant
  IF NOT EXISTS (
    SELECT 1 FROM chat_participants 
    WHERE chat_id = get_chat_messages.chat_id 
      AND user_id = auth.uid() 
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'User is not a participant of this chat';
  END IF;
  
  RETURN QUERY
  SELECT 
    m.id,
    m.sender_id,
    COALESCE(sender.raw_user_meta_data->>'username', 'System') as sender_name,
    sender.raw_user_meta_data->>'avatar_url' as sender_avatar_url,
    m.content,
    m.type,
    m.status,
    m.attachments,
    m.metadata,
    m.reply_to_id,
    m.is_edited,
    m.created_at,
    COALESCE(
      (SELECT jsonb_object_agg(
        mr.emoji,
        jsonb_build_object(
          'count', COUNT(mr.id),
          'users', jsonb_agg(reactor.raw_user_meta_data->>'username')
        )
      )
      FROM message_reactions mr
      LEFT JOIN auth.users reactor ON mr.user_id = reactor.id
      WHERE mr.message_id = m.id
      GROUP BY mr.emoji
      ), '{}'::jsonb
    ) as reactions
  FROM messages m
  LEFT JOIN auth.users sender ON m.sender_id = sender.id
  WHERE m.chat_id = get_chat_messages.chat_id
    AND m.is_deleted = false
    AND (before_message_id IS NULL OR m.created_at < (
      SELECT created_at FROM messages WHERE id = before_message_id
    ))
  ORDER BY m.created_at DESC
  LIMIT limit_count
  OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Send message (enhanced version)
CREATE OR REPLACE FUNCTION send_message_enhanced(
  chat_id UUID,
  content TEXT,
  message_type TEXT DEFAULT 'text',
  attachments JSONB DEFAULT '[]',
  reply_to_id UUID DEFAULT NULL,
  metadata JSONB DEFAULT '{}'
)
RETURNS JSON AS $$
DECLARE
  message_id UUID;
  result JSON;
BEGIN
  -- Check if user is participant
  IF NOT EXISTS (
    SELECT 1 FROM chat_participants 
    WHERE chat_id = send_message_enhanced.chat_id 
      AND user_id = auth.uid() 
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'User is not a participant of this chat';
  END IF;
  
  -- Insert message
  INSERT INTO messages (chat_id, sender_id, content, type, attachments, reply_to_id, metadata)
  VALUES (chat_id, auth.uid(), content, message_type, attachments, reply_to_id, metadata)
  RETURNING id INTO message_id;
  
  -- Track analytics
  INSERT INTO message_analytics (event_type, user_id, chat_id, message_id, metadata)
  VALUES ('message_sent', auth.uid(), chat_id, message_id, jsonb_build_object(
    'message_type', message_type,
    'has_attachments', jsonb_array_length(attachments) > 0
  ));
  
  SELECT json_build_object(
    'message_id', message_id,
    'status', 'sent'
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add reaction to message
CREATE OR REPLACE FUNCTION add_message_reaction(
  message_id UUID,
  emoji TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  chat_id UUID;
BEGIN
  -- Get chat_id and check permissions
  SELECT m.chat_id INTO chat_id
  FROM messages m
  WHERE m.id = add_message_reaction.message_id;
  
  IF NOT EXISTS (
    SELECT 1 FROM chat_participants 
    WHERE chat_id = add_message_reaction.chat_id 
      AND user_id = auth.uid() 
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'User is not a participant of this chat';
  END IF;
  
  -- Insert or update reaction
  INSERT INTO message_reactions (message_id, user_id, emoji)
  VALUES (message_id, auth.uid(), emoji)
  ON CONFLICT (message_id, user_id, emoji) DO NOTHING;
  
  -- Track analytics
  INSERT INTO message_analytics (event_type, user_id, chat_id, message_id, metadata)
  VALUES ('reaction_added', auth.uid(), chat_id, message_id, jsonb_build_object(
    'emoji', emoji
  ));
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remove reaction from message
CREATE OR REPLACE FUNCTION remove_message_reaction(
  message_id UUID,
  emoji TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  DELETE FROM message_reactions 
  WHERE message_id = remove_message_reaction.message_id 
    AND user_id = auth.uid() 
    AND emoji = remove_message_reaction.emoji;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 3. TYPING INDICATORS
-- ====================================

-- Start typing
CREATE OR REPLACE FUNCTION start_typing(chat_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- Check if user is participant
  IF NOT EXISTS (
    SELECT 1 FROM chat_participants 
    WHERE chat_id = start_typing.chat_id 
      AND user_id = auth.uid() 
      AND is_active = true
  ) THEN
    RETURN FALSE;
  END IF;
  
  -- Insert or update typing indicator
  INSERT INTO typing_indicators (chat_id, user_id, is_typing, expires_at)
  VALUES (chat_id, auth.uid(), true, NOW() + INTERVAL '10 seconds')
  ON CONFLICT (chat_id, user_id) 
  DO UPDATE SET 
    is_typing = true,
    started_at = NOW(),
    expires_at = NOW() + INTERVAL '10 seconds';
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Stop typing
CREATE OR REPLACE FUNCTION stop_typing(chat_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  DELETE FROM typing_indicators 
  WHERE chat_id = stop_typing.chat_id AND user_id = auth.uid();
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get typing users
CREATE OR REPLACE FUNCTION get_typing_users(chat_id UUID)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  started_at TIMESTAMPTZ
) AS $$
BEGIN
  -- Clean up expired indicators first
  DELETE FROM typing_indicators WHERE expires_at < NOW();
  
  RETURN QUERY
  SELECT 
    ti.user_id,
    u.raw_user_meta_data->>'username' as username,
    ti.started_at
  FROM typing_indicators ti
  JOIN auth.users u ON ti.user_id = u.id
  WHERE ti.chat_id = get_typing_users.chat_id 
    AND ti.user_id != auth.uid()
    AND ti.is_typing = true
    AND ti.expires_at > NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 4. USER CHAT SETTINGS
-- ====================================

-- Mute chat
CREATE OR REPLACE FUNCTION mute_chat(
  chat_id UUID,
  muted_until TIMESTAMPTZ DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  INSERT INTO user_chat_settings (user_id, chat_id, is_muted, muted_until, muted_at)
  VALUES (auth.uid(), chat_id, true, muted_until, NOW())
  ON CONFLICT (user_id, chat_id)
  DO UPDATE SET 
    is_muted = true,
    muted_until = EXCLUDED.muted_until,
    muted_at = NOW();
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Unmute chat
CREATE OR REPLACE FUNCTION unmute_chat(chat_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE user_chat_settings 
  SET is_muted = false, muted_until = NULL, muted_at = NULL
  WHERE user_id = auth.uid() AND chat_id = unmute_chat.chat_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Archive chat
CREATE OR REPLACE FUNCTION archive_chat(chat_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  INSERT INTO user_chat_settings (user_id, chat_id, is_archived, archived_at)
  VALUES (auth.uid(), chat_id, true, NOW())
  ON CONFLICT (user_id, chat_id)
  DO UPDATE SET 
    is_archived = true,
    archived_at = NOW();
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Unarchive chat
CREATE OR REPLACE FUNCTION unarchive_chat(chat_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE user_chat_settings 
  SET is_archived = false, archived_at = NULL
  WHERE user_id = auth.uid() AND chat_id = unarchive_chat.chat_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(
  chat_id UUID,
  last_message_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  target_message_id UUID;
BEGIN
  -- If no message_id provided, use the latest message
  IF last_message_id IS NULL THEN
    SELECT id INTO target_message_id
    FROM messages 
    WHERE chat_id = mark_messages_as_read.chat_id
      AND is_deleted = false
    ORDER BY created_at DESC
    LIMIT 1;
  ELSE
    target_message_id := last_message_id;
  END IF;
  
  -- Update participant's last read message
  UPDATE chat_participants 
  SET 
    last_read_message_id = target_message_id,
    last_read_at = NOW()
  WHERE chat_id = mark_messages_as_read.chat_id 
    AND user_id = auth.uid();
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 5. SEARCH FUNCTIONS
-- ====================================

-- Search users for chat creation
CREATE OR REPLACE FUNCTION search_users_for_chat(
  search_query TEXT,
  exclude_chat_id UUID DEFAULT NULL,
  limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  username TEXT,
  avatar_url TEXT,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.raw_user_meta_data->>'username' as username,
    u.raw_user_meta_data->>'avatar_url' as avatar_url,
    COALESCE(u.raw_user_meta_data->>'status', 'offline') as status
  FROM auth.users u
  WHERE u.id != auth.uid()
    AND (
      u.raw_user_meta_data->>'username' ILIKE '%' || search_query || '%' OR
      u.raw_user_meta_data->>'full_name' ILIKE '%' || search_query || '%'
    )
    AND (exclude_chat_id IS NULL OR NOT EXISTS (
      SELECT 1 FROM chat_participants cp 
      WHERE cp.chat_id = exclude_chat_id 
        AND cp.user_id = u.id 
        AND cp.is_active = true
    ))
  ORDER BY u.raw_user_meta_data->>'username'
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search messages in chats
CREATE OR REPLACE FUNCTION search_messages(
  search_query TEXT,
  chat_id UUID DEFAULT NULL,
  limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
  message_id UUID,
  chat_id UUID,
  chat_name TEXT,
  sender_name TEXT,
  content TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id as message_id,
    m.chat_id,
    c.name as chat_name,
    COALESCE(u.raw_user_meta_data->>'username', 'System') as sender_name,
    m.content,
    m.created_at
  FROM messages m
  JOIN chats c ON m.chat_id = c.id
  JOIN chat_participants cp ON c.id = cp.chat_id AND cp.user_id = auth.uid() AND cp.is_active = true
  LEFT JOIN auth.users u ON m.sender_id = u.id
  WHERE m.content ILIKE '%' || search_query || '%'
    AND m.is_deleted = false
    AND m.type IN ('text', 'system')
    AND (chat_id IS NULL OR m.chat_id = search_messages.chat_id)
  ORDER BY m.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 6. ANALYTICS FUNCTIONS
-- ====================================

-- Get unread message count for user
CREATE OR REPLACE FUNCTION get_unread_message_count()
RETURNS INTEGER AS $$
DECLARE
  total_unread INTEGER := 0;
BEGIN
  SELECT COALESCE(SUM(
    (SELECT COUNT(*) FROM messages m 
     WHERE m.chat_id = cp.chat_id 
       AND m.created_at > COALESCE(cp.last_read_at, cp.joined_at)
       AND m.sender_id != auth.uid()
       AND m.is_deleted = false
    )
  ), 0) INTO total_unread
  FROM chat_participants cp
  LEFT JOIN user_chat_settings ucs ON cp.chat_id = ucs.chat_id AND ucs.user_id = auth.uid()
  WHERE cp.user_id = auth.uid() 
    AND cp.is_active = true
    AND COALESCE(ucs.is_archived, false) = false;
  
  RETURN total_unread;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Track chat opened
CREATE OR REPLACE FUNCTION track_chat_opened(chat_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  INSERT INTO message_analytics (event_type, user_id, chat_id, metadata)
  VALUES ('chat_opened', auth.uid(), chat_id, jsonb_build_object(
    'timestamp', extract(epoch from now())
  ));
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON SCHEMA public IS 'SABO Arena Messaging System - RPC Functions Complete';
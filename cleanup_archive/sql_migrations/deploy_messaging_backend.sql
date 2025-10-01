-- ====================================
-- SABO ARENA - COMPLETE MESSAGING BACKEND DEPLOYMENT
-- Deploy all messaging system components to Supabase
-- ====================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_crypto";

-- Set timezone
SET timezone = 'UTC';

-- ====================================
-- 1. MESSAGING TABLES (from messaging_backend_schema.sql)
-- ====================================

-- Messages table
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  chat_id UUID NOT NULL,
  sender_id UUID, -- NULL for system messages
  content TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'image', 'file', 'voice', 'video', 'system', 'sticker', 'location')),
  status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sending', 'sent', 'delivered', 'read', 'failed')),
  attachments JSONB DEFAULT '[]',
  metadata JSONB DEFAULT '{}',
  reply_to_id UUID REFERENCES messages(id),
  is_edited BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chats table
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL DEFAULT 'group' CHECK (type IN ('private', 'group', 'channel')),
  avatar_url TEXT,
  settings JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_by UUID,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat participants table
CREATE TABLE IF NOT EXISTS public.chat_participants (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  invited_by UUID,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  last_read_message_id UUID REFERENCES messages(id),
  last_read_at TIMESTAMPTZ,
  UNIQUE(chat_id, user_id)
);

-- Message reactions table
CREATE TABLE IF NOT EXISTS public.message_reactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id, emoji)
);

-- User chat settings table
CREATE TABLE IF NOT EXISTS public.user_chat_settings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL,
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  is_muted BOOLEAN DEFAULT false,
  muted_until TIMESTAMPTZ,
  muted_at TIMESTAMPTZ,
  is_archived BOOLEAN DEFAULT false,
  archived_at TIMESTAMPTZ,
  custom_name TEXT,
  theme_color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, chat_id)
);

-- Message analytics table
CREATE TABLE IF NOT EXISTS public.message_analytics (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  event_type TEXT NOT NULL,
  user_id UUID,
  chat_id UUID,
  message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

-- Typing indicators table
CREATE TABLE IF NOT EXISTS public.typing_indicators (
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  is_typing BOOLEAN DEFAULT true,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '10 seconds',
  PRIMARY KEY (chat_id, user_id)
);

-- ====================================
-- 2. INDEXES
-- ====================================

-- Messages indexes
CREATE INDEX IF NOT EXISTS idx_messages_chat_id_created_at ON messages(chat_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_reply_to_id ON messages(reply_to_id);
CREATE INDEX IF NOT EXISTS idx_messages_content_text_search ON messages USING gin(to_tsvector('english', content));
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(type);
CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status);

-- Chats indexes
CREATE INDEX IF NOT EXISTS idx_chats_created_by ON chats(created_by);
CREATE INDEX IF NOT EXISTS idx_chats_type ON chats(type);
CREATE INDEX IF NOT EXISTS idx_chats_is_active ON chats(is_active);

-- Chat participants indexes
CREATE INDEX IF NOT EXISTS idx_chat_participants_chat_id ON chat_participants(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user_id ON chat_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user_active ON chat_participants(user_id, is_active);

-- Message reactions indexes
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON message_reactions(user_id);

-- User chat settings indexes
CREATE INDEX IF NOT EXISTS idx_user_chat_settings_user_id ON user_chat_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_chat_settings_chat_id ON user_chat_settings(chat_id);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_message_analytics_event_type ON message_analytics(event_type);
CREATE INDEX IF NOT EXISTS idx_message_analytics_user_id ON message_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_message_analytics_timestamp ON message_analytics(timestamp);

-- Typing indicators indexes
CREATE INDEX IF NOT EXISTS idx_typing_indicators_expires_at ON typing_indicators(expires_at);

-- ====================================
-- 3. RLS POLICIES
-- ====================================

-- Enable RLS on all tables
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_chat_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.typing_indicators ENABLE ROW LEVEL SECURITY;

-- Messages policies
CREATE POLICY "Users can view messages in their chats" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_participants cp 
      WHERE cp.chat_id = messages.chat_id 
        AND cp.user_id = auth.uid() 
        AND cp.is_active = true
    )
  );

CREATE POLICY "Users can insert messages to their chats" ON messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM chat_participants cp 
      WHERE cp.chat_id = messages.chat_id 
        AND cp.user_id = auth.uid() 
        AND cp.is_active = true
    )
  );

CREATE POLICY "Users can update their own messages" ON messages
  FOR UPDATE USING (sender_id = auth.uid());

CREATE POLICY "Users can delete their own messages" ON messages
  FOR DELETE USING (sender_id = auth.uid());

-- Chats policies
CREATE POLICY "Users can view chats they participate in" ON chats
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_participants cp 
      WHERE cp.chat_id = chats.id 
        AND cp.user_id = auth.uid() 
        AND cp.is_active = true
    )
  );

CREATE POLICY "Authenticated users can create chats" ON chats
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND created_by = auth.uid());

CREATE POLICY "Chat owners and admins can update chats" ON chats
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM chat_participants cp 
      WHERE cp.chat_id = chats.id 
        AND cp.user_id = auth.uid() 
        AND cp.role IN ('owner', 'admin')
        AND cp.is_active = true
    )
  );

-- Chat participants policies
CREATE POLICY "Users can view participants in their chats" ON chat_participants
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM chat_participants cp 
      WHERE cp.chat_id = chat_participants.chat_id 
        AND cp.user_id = auth.uid() 
        AND cp.is_active = true
    )
  );

CREATE POLICY "Chat owners and admins can manage participants" ON chat_participants
  FOR ALL USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM chat_participants cp 
      WHERE cp.chat_id = chat_participants.chat_id 
        AND cp.user_id = auth.uid() 
        AND cp.role IN ('owner', 'admin')
        AND cp.is_active = true
    )
  );

-- Message reactions policies
CREATE POLICY "Users can view reactions on messages in their chats" ON message_reactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM messages m
      JOIN chat_participants cp ON m.chat_id = cp.chat_id
      WHERE m.id = message_reactions.message_id 
        AND cp.user_id = auth.uid() 
        AND cp.is_active = true
    )
  );

CREATE POLICY "Users can manage their own reactions" ON message_reactions
  FOR ALL USING (user_id = auth.uid());

-- User chat settings policies
CREATE POLICY "Users can manage their own chat settings" ON user_chat_settings
  FOR ALL USING (user_id = auth.uid());

-- Message analytics policies (admin only for viewing)
CREATE POLICY "Users can insert their own analytics" ON message_analytics
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view their own analytics" ON message_analytics
  FOR SELECT USING (user_id = auth.uid());

-- Typing indicators policies
CREATE POLICY "Users can view typing indicators in their chats" ON typing_indicators
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_participants cp 
      WHERE cp.chat_id = typing_indicators.chat_id 
        AND cp.user_id = auth.uid() 
        AND cp.is_active = true
    )
  );

CREATE POLICY "Users can manage their own typing indicators" ON typing_indicators
  FOR ALL USING (user_id = auth.uid());

-- ====================================
-- 4. TRIGGERS
-- ====================================

-- Update timestamps trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create update triggers
CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chats_updated_at BEFORE UPDATE ON chats
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_chat_settings_updated_at BEFORE UPDATE ON user_chat_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Chat statistics trigger function
CREATE OR REPLACE FUNCTION update_chat_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update chat's last activity
  IF TG_OP = 'INSERT' THEN
    UPDATE chats SET updated_at = NOW() WHERE id = NEW.chat_id;
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ language 'plpgsql';

-- Create chat stats trigger
CREATE TRIGGER update_chat_stats_on_message AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_chat_stats();

-- Clean up expired typing indicators
CREATE OR REPLACE FUNCTION cleanup_expired_typing()
RETURNS void AS $$
BEGIN
  DELETE FROM typing_indicators WHERE expires_at < NOW();
END;
$$ language 'plpgsql';

-- ====================================
-- 5. VIEWS
-- ====================================

-- User chats view with latest message
CREATE OR REPLACE VIEW user_chats_with_latest AS
SELECT 
  c.*,
  cp.role as user_role,
  cp.last_read_at,
  cp.last_read_message_id,
  (
    SELECT COUNT(*)::int FROM messages m 
    WHERE m.chat_id = c.id 
      AND m.created_at > COALESCE(cp.last_read_at, cp.joined_at)
      AND m.sender_id != cp.user_id
      AND m.is_deleted = false
  ) as unread_count,
  latest_msg.content as latest_message_content,
  latest_msg.type as latest_message_type,
  latest_msg.created_at as latest_message_at,
  latest_sender.raw_user_meta_data->>'username' as latest_sender_name,
  COALESCE(ucs.is_muted, false) as is_muted,
  COALESCE(ucs.is_archived, false) as is_archived,
  ucs.custom_name
FROM chats c
JOIN chat_participants cp ON c.id = cp.chat_id
LEFT JOIN user_chat_settings ucs ON c.id = ucs.chat_id AND cp.user_id = ucs.user_id
LEFT JOIN LATERAL (
  SELECT m.* FROM messages m 
  WHERE m.chat_id = c.id AND m.is_deleted = false
  ORDER BY m.created_at DESC 
  LIMIT 1
) latest_msg ON true
LEFT JOIN auth.users latest_sender ON latest_msg.sender_id = latest_sender.id
WHERE cp.user_id = auth.uid() AND cp.is_active = true;

-- Message details view with sender info
CREATE OR REPLACE VIEW message_details AS
SELECT 
  m.*,
  sender.raw_user_meta_data->>'username' as sender_username,
  sender.raw_user_meta_data->>'avatar_url' as sender_avatar_url,
  reply_msg.content as reply_content,
  reply_sender.raw_user_meta_data->>'username' as reply_sender_name
FROM messages m
LEFT JOIN auth.users sender ON m.sender_id = sender.id
LEFT JOIN messages reply_msg ON m.reply_to_id = reply_msg.id
LEFT JOIN auth.users reply_sender ON reply_msg.sender_id = reply_sender.id;

-- ====================================
-- 6. RPC FUNCTIONS (from messaging_rpc_functions.sql)
-- ====================================

-- Create private chat function
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
    INSERT INTO messages (chat_id, sender_id, content, type)
    VALUES (new_chat_id, auth.uid(), initial_message, 'text');
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

-- Get user chats function  
CREATE OR REPLACE FUNCTION get_user_chats(
  include_archived BOOLEAN DEFAULT false
)
RETURNS SETOF user_chats_with_latest AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM user_chats_with_latest
  WHERE (include_archived OR NOT COALESCE(is_archived, false))
  ORDER BY latest_message_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Send message function
CREATE OR REPLACE FUNCTION send_message(
  chat_id UUID,
  content TEXT,
  message_type TEXT DEFAULT 'text'
)
RETURNS UUID AS $$
DECLARE
  message_id UUID;
BEGIN
  -- Check if user is participant
  IF NOT EXISTS (
    SELECT 1 FROM chat_participants 
    WHERE chat_id = send_message.chat_id 
      AND user_id = auth.uid() 
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'User is not a participant of this chat';
  END IF;
  
  -- Insert message
  INSERT INTO messages (chat_id, sender_id, content, type)
  VALUES (chat_id, auth.uid(), content, message_type)
  RETURNING id INTO message_id;
  
  RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark messages as read function
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

-- Get unread count function
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

-- ====================================
-- 7. STORAGE BUCKETS (for file attachments)
-- ====================================

-- Create storage bucket for message attachments
INSERT INTO storage.buckets (id, name, public)
VALUES ('message-attachments', 'message-attachments', false)
ON CONFLICT (id) DO NOTHING;

-- Create storage policy for message attachments
CREATE POLICY "Users can upload their message attachments"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'message-attachments' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view message attachments in their chats"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'message-attachments' AND
  EXISTS (
    -- Check if user has access to any chat with messages containing this file
    SELECT 1 FROM messages m
    JOIN chat_participants cp ON m.chat_id = cp.chat_id
    WHERE cp.user_id = auth.uid() 
      AND cp.is_active = true
      AND m.attachments ? name
  )
);

-- ====================================
-- 8. REALTIME CONFIGURATION
-- ====================================

-- Enable realtime on messaging tables
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chats;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE typing_indicators;

-- ====================================
-- DEPLOYMENT COMPLETE
-- ====================================

COMMENT ON SCHEMA public IS 'SABO Arena Complete Messaging Backend - Deployment Ready';

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'SABO Arena Messaging System Backend deployed successfully!';
  RAISE NOTICE 'Tables created: messages, chats, chat_participants, message_reactions, user_chat_settings, message_analytics, typing_indicators';
  RAISE NOTICE 'RLS policies enabled and configured';
  RAISE NOTICE 'RPC functions created for frontend integration';
  RAISE NOTICE 'Storage bucket configured for file attachments';
  RAISE NOTICE 'Realtime subscriptions enabled';
  RAISE NOTICE 'Backend is ready for frontend integration!';
END $$;
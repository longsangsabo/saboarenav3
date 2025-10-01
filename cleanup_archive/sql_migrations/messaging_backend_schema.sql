-- ====================================
-- SABO ARENA - MESSAGING SYSTEM BACKEND
-- Complete Database Schema for Messaging
-- ====================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_crypto";

-- ====================================
-- 1. MESSAGES TABLE
-- ====================================

-- Drop existing tables if they exist (to avoid conflicts)
DROP TABLE IF EXISTS message_reactions CASCADE;
DROP TABLE IF EXISTS message_analytics CASCADE;
DROP TABLE IF EXISTS user_chat_settings CASCADE;
DROP TABLE IF EXISTS chat_participants CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS chats CASCADE;

-- Main messages table
CREATE TABLE messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  chat_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  
  -- Message Content
  content TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'image', 'file', 'voice', 'system', 'sticker', 'location')),
  
  -- Message Status
  status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed')),
  
  -- Attachments (JSON array)
  attachments JSONB DEFAULT '[]',
  
  -- Metadata (for system messages, reactions, etc.)
  metadata JSONB DEFAULT '{}',
  
  -- Reply Information
  reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  
  -- Message State
  is_edited BOOLEAN DEFAULT FALSE,
  edited_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMPTZ,
  
  -- Encryption
  is_encrypted BOOLEAN DEFAULT FALSE,
  encryption_key_id TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Foreign key will be added after chats table is created
  CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Indexes for messages
CREATE INDEX idx_messages_chat_id ON messages(chat_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX idx_messages_status ON messages(status);
CREATE INDEX idx_messages_type ON messages(type);
CREATE INDEX idx_messages_reply_to ON messages(reply_to_id) WHERE reply_to_id IS NOT NULL;

-- ====================================
-- 2. CHATS TABLE
-- ====================================

CREATE TABLE chats (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  
  -- Chat Information
  name VARCHAR(255) NOT NULL,
  description TEXT,
  type TEXT NOT NULL DEFAULT 'private' CHECK (type IN ('private', 'group', 'channel', 'broadcast')),
  
  -- Avatar and Media
  avatar_url TEXT,
  
  -- Chat Settings (JSON)
  settings JSONB DEFAULT '{
    "allow_members_to_add_others": false,
    "allow_members_to_edit_info": false,
    "message_retention_days": 365,
    "max_participants": 500,
    "require_approval_for_join": false,
    "allow_message_forwarding": true,
    "allow_media_sharing": true,
    "mute_notifications": false
  }',
  
  -- Administration
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- State
  is_archived BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMPTZ,
  
  -- Last Activity
  last_message_id UUID,
  last_activity_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Statistics
  message_count INTEGER DEFAULT 0,
  participant_count INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key constraint for chat_id in messages
ALTER TABLE messages ADD CONSTRAINT fk_messages_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE;

-- Add foreign key for last_message_id
ALTER TABLE chats ADD CONSTRAINT fk_chats_last_message FOREIGN KEY (last_message_id) REFERENCES messages(id) ON DELETE SET NULL;

-- Indexes for chats
CREATE INDEX idx_chats_created_by ON chats(created_by);
CREATE INDEX idx_chats_type ON chats(type);
CREATE INDEX idx_chats_last_activity ON chats(last_activity_at DESC);
CREATE INDEX idx_chats_is_deleted ON chats(is_deleted);

-- ====================================
-- 3. CHAT PARTICIPANTS TABLE
-- ====================================

CREATE TABLE chat_participants (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Role and Permissions
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  
  -- Participant Status
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Join/Leave Information
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  invited_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Permissions (JSON)
  permissions JSONB DEFAULT '{
    "can_send_messages": true,
    "can_add_members": false,
    "can_remove_members": false,
    "can_edit_chat_info": false,
    "can_delete_messages": false,
    "can_pin_messages": false
  }',
  
  -- Last Read Message
  last_read_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  last_read_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint
  UNIQUE(chat_id, user_id)
);

-- Indexes for chat_participants
CREATE INDEX idx_chat_participants_chat_id ON chat_participants(chat_id);
CREATE INDEX idx_chat_participants_user_id ON chat_participants(user_id);
CREATE INDEX idx_chat_participants_role ON chat_participants(role);
CREATE INDEX idx_chat_participants_active ON chat_participants(is_active);

-- ====================================
-- 4. MESSAGE REACTIONS TABLE
-- ====================================

CREATE TABLE message_reactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Reaction Information
  emoji VARCHAR(50) NOT NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint (one reaction per user per message per emoji)
  UNIQUE(message_id, user_id, emoji)
);

-- Indexes for message_reactions
CREATE INDEX idx_message_reactions_message_id ON message_reactions(message_id);
CREATE INDEX idx_message_reactions_user_id ON message_reactions(user_id);

-- ====================================
-- 5. USER CHAT SETTINGS TABLE
-- ====================================

CREATE TABLE user_chat_settings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  
  -- Chat-specific user settings
  is_muted BOOLEAN DEFAULT FALSE,
  muted_until TIMESTAMPTZ,
  muted_at TIMESTAMPTZ,
  
  is_archived BOOLEAN DEFAULT FALSE,
  archived_at TIMESTAMPTZ,
  
  is_pinned BOOLEAN DEFAULT FALSE,
  pinned_at TIMESTAMPTZ,
  
  -- Notification settings
  notification_settings JSONB DEFAULT '{
    "sound": true,
    "vibration": true,
    "preview": true,
    "badge": true
  }',
  
  -- Custom nickname for this chat
  custom_chat_name VARCHAR(255),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint
  UNIQUE(user_id, chat_id)
);

-- Indexes for user_chat_settings
CREATE INDEX idx_user_chat_settings_user_id ON user_chat_settings(user_id);
CREATE INDEX idx_user_chat_settings_chat_id ON user_chat_settings(chat_id);

-- ====================================
-- 6. MESSAGE ANALYTICS TABLE
-- ====================================

CREATE TABLE message_analytics (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  
  -- Event Information
  event_type VARCHAR(100) NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  chat_id UUID REFERENCES chats(id) ON DELETE SET NULL,
  message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  
  -- Event Data
  metadata JSONB DEFAULT '{}',
  
  -- Timestamp
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for message_analytics
CREATE INDEX idx_message_analytics_event_type ON message_analytics(event_type);
CREATE INDEX idx_message_analytics_timestamp ON message_analytics(timestamp DESC);
CREATE INDEX idx_message_analytics_user_id ON message_analytics(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_message_analytics_chat_id ON message_analytics(chat_id) WHERE chat_id IS NOT NULL;

-- ====================================
-- 7. TYPING INDICATORS TABLE (Temporary)
-- ====================================

CREATE TABLE typing_indicators (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Typing status
  is_typing BOOLEAN DEFAULT TRUE,
  
  -- Timestamps
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '10 seconds'),
  
  -- Unique constraint
  UNIQUE(chat_id, user_id)
);

-- Indexes for typing_indicators
CREATE INDEX idx_typing_indicators_chat_id ON typing_indicators(chat_id);
CREATE INDEX idx_typing_indicators_expires_at ON typing_indicators(expires_at);

-- ====================================
-- 8. FUNCTIONS AND TRIGGERS
-- ====================================

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_messages_updated_at
  BEFORE UPDATE ON messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chats_updated_at
  BEFORE UPDATE ON chats
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_participants_updated_at
  BEFORE UPDATE ON chat_participants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_chat_settings_updated_at
  BEFORE UPDATE ON user_chat_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update chat statistics
CREATE OR REPLACE FUNCTION update_chat_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update message count and last activity
  IF TG_OP = 'INSERT' THEN
    UPDATE chats 
    SET 
      message_count = message_count + 1,
      last_message_id = NEW.id,
      last_activity_at = NEW.created_at
    WHERE id = NEW.chat_id;
    
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE chats 
    SET message_count = GREATEST(message_count - 1, 0)
    WHERE id = OLD.chat_id;
    
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for chat statistics
CREATE TRIGGER update_chat_stats_trigger
  AFTER INSERT OR DELETE ON messages
  FOR EACH ROW EXECUTE FUNCTION update_chat_stats();

-- Function to update participant count
CREATE OR REPLACE FUNCTION update_participant_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE chats 
    SET participant_count = participant_count + 1
    WHERE id = NEW.chat_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE chats 
    SET participant_count = GREATEST(participant_count - 1, 0)
    WHERE id = OLD.chat_id;
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Handle active status change
    IF OLD.is_active != NEW.is_active THEN
      IF NEW.is_active THEN
        UPDATE chats SET participant_count = participant_count + 1 WHERE id = NEW.chat_id;
      ELSE
        UPDATE chats SET participant_count = GREATEST(participant_count - 1, 0) WHERE id = NEW.chat_id;
      END IF;
    END IF;
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for participant count
CREATE TRIGGER update_participant_count_trigger
  AFTER INSERT OR DELETE OR UPDATE ON chat_participants
  FOR EACH ROW EXECUTE FUNCTION update_participant_count();

-- Function to clean up expired typing indicators
CREATE OR REPLACE FUNCTION cleanup_typing_indicators()
RETURNS void AS $$
BEGIN
  DELETE FROM typing_indicators 
  WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ====================================
-- 9. ROW LEVEL SECURITY (RLS)
-- ====================================

-- Enable RLS on all tables
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_chat_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;

-- Messages policies
CREATE POLICY "Users can view messages in their chats" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_participants 
      WHERE chat_id = messages.chat_id 
      AND user_id = auth.uid() 
      AND is_active = true
    )
  );

CREATE POLICY "Users can send messages to their chats" ON messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM chat_participants 
      WHERE chat_id = messages.chat_id 
      AND user_id = auth.uid() 
      AND is_active = true
    )
  );

CREATE POLICY "Users can update their own messages" ON messages
  FOR UPDATE USING (sender_id = auth.uid());

CREATE POLICY "Users can delete their own messages" ON messages
  FOR DELETE USING (sender_id = auth.uid());

-- Chats policies
CREATE POLICY "Users can view their chats" ON chats
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_participants 
      WHERE chat_id = chats.id 
      AND user_id = auth.uid() 
      AND is_active = true
    )
  );

CREATE POLICY "Users can create chats" ON chats
  FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Chat admins can update chats" ON chats
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM chat_participants 
      WHERE chat_id = chats.id 
      AND user_id = auth.uid() 
      AND role IN ('owner', 'admin')
      AND is_active = true
    )
  );

-- Chat participants policies
CREATE POLICY "Users can view participants in their chats" ON chat_participants
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_participants cp 
      WHERE cp.chat_id = chat_participants.chat_id 
      AND cp.user_id = auth.uid() 
      AND cp.is_active = true
    )
  );

CREATE POLICY "Chat admins can manage participants" ON chat_participants
  FOR ALL USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM chat_participants 
      WHERE chat_id = chat_participants.chat_id 
      AND user_id = auth.uid() 
      AND role IN ('owner', 'admin')
      AND is_active = true
    )
  );

-- Message reactions policies
CREATE POLICY "Users can view reactions in their chats" ON message_reactions
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

-- Typing indicators policies
CREATE POLICY "Users can view typing in their chats" ON typing_indicators
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_participants 
      WHERE chat_id = typing_indicators.chat_id 
      AND user_id = auth.uid() 
      AND is_active = true
    )
  );

CREATE POLICY "Users can manage their own typing status" ON typing_indicators
  FOR ALL USING (user_id = auth.uid());

-- Analytics policies (admin only for now)
CREATE POLICY "Service role can access analytics" ON message_analytics
  FOR ALL USING (auth.role() = 'service_role');

-- ====================================
-- 10. USEFUL VIEWS
-- ====================================

-- View for chat list with last message info
CREATE OR REPLACE VIEW chat_list_view AS
SELECT 
  c.*,
  lm.content as last_message_content,
  lm.created_at as last_message_at,
  lm.sender_id as last_message_sender_id,
  sender.raw_user_meta_data->>'username' as last_message_sender_name,
  COALESCE(
    (SELECT COUNT(*) FROM messages m2 
     WHERE m2.chat_id = c.id 
     AND m2.created_at > COALESCE(cp.last_read_at, cp.joined_at)
     AND m2.sender_id != cp.user_id
    ), 0
  ) as unread_count
FROM chats c
LEFT JOIN messages lm ON c.last_message_id = lm.id
LEFT JOIN auth.users sender ON lm.sender_id = sender.id
LEFT JOIN chat_participants cp ON c.id = cp.chat_id AND cp.user_id = auth.uid();

-- View for message details with sender info
CREATE OR REPLACE VIEW message_details_view AS
SELECT 
  m.*,
  sender.raw_user_meta_data->>'username' as sender_name,
  sender.raw_user_meta_data->>'avatar_url' as sender_avatar_url,
  COALESCE(
    jsonb_object_agg(
      mr.emoji, 
      jsonb_build_object(
        'count', COUNT(mr.id),
        'users', jsonb_agg(reactor.raw_user_meta_data->>'username')
      )
    ) FILTER (WHERE mr.emoji IS NOT NULL),
    '{}'::jsonb
  ) as reactions
FROM messages m
LEFT JOIN auth.users sender ON m.sender_id = sender.id
LEFT JOIN message_reactions mr ON m.id = mr.message_id
LEFT JOIN auth.users reactor ON mr.user_id = reactor.id
GROUP BY m.id, sender.id, sender.raw_user_meta_data;

-- ====================================
-- 11. SAMPLE RPC FUNCTIONS
-- ====================================

-- Function to get user chats
CREATE OR REPLACE FUNCTION get_user_chats()
RETURNS TABLE (
  chat_id UUID,
  chat_name VARCHAR,
  chat_type TEXT,
  chat_avatar_url TEXT,
  last_message_content TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count BIGINT,
  is_muted BOOLEAN,
  is_archived BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.name,
    c.type,
    c.avatar_url,
    lm.content,
    lm.created_at,
    COALESCE(
      (SELECT COUNT(*) FROM messages m2 
       WHERE m2.chat_id = c.id 
       AND m2.created_at > COALESCE(cp.last_read_at, cp.joined_at)
       AND m2.sender_id != auth.uid()
      ), 0
    ),
    COALESCE(ucs.is_muted, FALSE),
    COALESCE(ucs.is_archived, FALSE)
  FROM chats c
  JOIN chat_participants cp ON c.id = cp.chat_id
  LEFT JOIN messages lm ON c.last_message_id = lm.id
  LEFT JOIN user_chat_settings ucs ON c.id = ucs.chat_id AND ucs.user_id = auth.uid()
  WHERE cp.user_id = auth.uid() AND cp.is_active = TRUE
  ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to send message
CREATE OR REPLACE FUNCTION send_message(
  p_chat_id UUID,
  p_content TEXT,
  p_type TEXT DEFAULT 'text',
  p_attachments JSONB DEFAULT '[]',
  p_reply_to_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  message_id UUID;
BEGIN
  -- Check if user is participant
  IF NOT EXISTS (
    SELECT 1 FROM chat_participants 
    WHERE chat_id = p_chat_id 
    AND user_id = auth.uid() 
    AND is_active = true
  ) THEN
    RAISE EXCEPTION 'User is not a participant of this chat';
  END IF;
  
  -- Insert message
  INSERT INTO messages (chat_id, sender_id, content, type, attachments, reply_to_id)
  VALUES (p_chat_id, auth.uid(), p_content, p_type, p_attachments, p_reply_to_id)
  RETURNING id INTO message_id;
  
  RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- CLEANUP AND MAINTENANCE
-- ====================================

-- Schedule cleanup of typing indicators (would be run by a cron job)
SELECT cron.schedule('cleanup-typing-indicators', '*/1 * * * *', 'SELECT cleanup_typing_indicators();');

COMMENT ON DATABASE postgres IS 'SABO Arena Messaging System - Backend Schema Complete';
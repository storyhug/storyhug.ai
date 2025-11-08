-- ============================================================================
-- StoryHug Complete Database Schema
-- ============================================================================
-- This file contains all database schemas, functions, views, and policies
-- for the StoryHug application.
--
-- Author: StoryHug Development Team
-- Date: October 25, 2025
-- Version: 1.0.0
-- ============================================================================

-- ============================================================================
-- TABLE OF CONTENTS
-- ============================================================================
-- 1. User Voices Management
-- 2. Favorite Stories System
-- 3. Stories & Content
-- 4. Child Profiles
-- 5. Listening History & Analytics
-- 6. Dashboard Analytics Functions
-- 7. Safety & Compliance
-- 8. Indexes & Performance Optimization
-- ============================================================================


-- ============================================================================
-- 1. USER VOICES MANAGEMENT
-- ============================================================================
-- Stores multiple recorded voices for each user (Mom, Dad, Grandma, etc.)
-- ============================================================================

DROP TABLE IF EXISTS user_voices CASCADE;

CREATE TABLE user_voices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  voice_id TEXT NOT NULL,              -- ElevenLabs or TTS voice ID
  voice_name TEXT NOT NULL,            -- Custom name (e.g., "Mom", "Dad", "Grandma")
  voice_description TEXT,              -- Optional description
  is_active BOOLEAN DEFAULT TRUE,      -- Soft delete flag
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Ensure unique voice names per user
  UNIQUE(user_id, voice_name)
);

-- Indexes for performance
CREATE INDEX idx_user_voices_user_id ON user_voices(user_id);
CREATE INDEX idx_user_voices_is_active ON user_voices(is_active);

-- Enable Row Level Security (RLS)
ALTER TABLE user_voices ENABLE ROW LEVEL SECURITY;

-- Policy: Each user can only manage their own voices
CREATE POLICY "Users can manage their own voices"
ON user_voices
FOR ALL
USING (auth.uid() = user_id);

-- View: Combines voice info with user email
CREATE OR REPLACE VIEW user_voice_info AS
SELECT 
    uv.id,
    uv.user_id,
    uv.voice_id,
    uv.voice_name,
    uv.voice_description,
    uv.is_active,
    uv.created_at,
    uv.updated_at,
    u.email AS user_email
FROM user_voices uv
JOIN auth.users u ON uv.user_id = u.id
WHERE uv.is_active = TRUE;

GRANT SELECT ON user_voice_info TO authenticated;

-- Function: Get all active voices for a user
CREATE OR REPLACE FUNCTION get_user_voices(user_uuid UUID)
RETURNS TABLE(
  id UUID,
  voice_id TEXT,
  voice_name TEXT,
  voice_description TEXT,
  created_at TIMESTAMP WITH TIME ZONE
)
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uv.id,
    uv.voice_id,
    uv.voice_name,
    uv.voice_description,
    uv.created_at
  FROM user_voices uv
  WHERE uv.user_id = user_uuid 
    AND uv.is_active = TRUE
  ORDER BY uv.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_user_voices(UUID) TO authenticated;

COMMENT ON TABLE user_voices IS 'Stores all recorded voices per user.';
COMMENT ON COLUMN user_voices.voice_name IS 'Friendly name for the voice (e.g., Mom, Dad).';
COMMENT ON FUNCTION get_user_voices IS 'Fetches all active voices for a user.';


-- ============================================================================
-- 2. FAVORITE STORIES SYSTEM
-- ============================================================================
-- Tracks user's favorite stories with real-time synchronization
-- ============================================================================

DROP TABLE IF EXISTS favorite_stories CASCADE;

CREATE TABLE favorite_stories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  story_id TEXT NOT NULL,                  -- Story unique ID
  story_title TEXT,                        -- For display in dashboard
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Prevent duplicate favorites
  UNIQUE(user_id, story_id)
);

CREATE INDEX idx_favorites_user_id ON favorite_stories(user_id);
CREATE INDEX idx_favorites_story_id ON favorite_stories(story_id);

ALTER TABLE favorite_stories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own favorites"
ON favorite_stories
FOR ALL
USING (auth.uid() = user_id);

-- Function: Check if a story is favorited (for heart icon state)
CREATE OR REPLACE FUNCTION is_story_favorited(user_uuid UUID, story_uuid TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS(
    SELECT 1
    FROM favorite_stories
    WHERE user_id = user_uuid AND story_id = story_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Add story to favorites
CREATE OR REPLACE FUNCTION add_favorite_story(user_uuid UUID, story_uuid TEXT, title TEXT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO favorite_stories (user_id, story_id, story_title)
  VALUES (user_uuid, story_uuid, title)
  ON CONFLICT (user_id, story_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Remove story from favorites
CREATE OR REPLACE FUNCTION remove_favorite_story(user_uuid UUID, story_uuid TEXT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM favorite_stories
  WHERE user_id = user_uuid AND story_id = story_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Toggle favorite (add/remove)
CREATE OR REPLACE FUNCTION toggle_favorite_story(user_uuid UUID, story_uuid TEXT, title TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  is_favorited BOOLEAN;
BEGIN
  -- Check current state
  is_favorited := is_story_favorited(user_uuid, story_uuid);
  
  IF is_favorited THEN
    -- Remove from favorites
    PERFORM remove_favorite_story(user_uuid, story_uuid);
    RETURN FALSE; -- Now unfavorited
  ELSE
    -- Add to favorites
    PERFORM add_favorite_story(user_uuid, story_uuid, title);
    RETURN TRUE; -- Now favorited
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get all favorite stories for a user
CREATE OR REPLACE FUNCTION get_favorite_stories(user_uuid UUID)
RETURNS TABLE(
  story_id TEXT,
  story_title TEXT,
  added_at TIMESTAMP WITH TIME ZONE
)
AS $$
BEGIN
  RETURN QUERY
  SELECT fs.story_id, fs.story_title, fs.added_at
  FROM favorite_stories fs
  WHERE fs.user_id = user_uuid
  ORDER BY fs.added_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get count of favorites for a user
CREATE OR REPLACE FUNCTION get_favorites_count(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM favorite_stories
    WHERE user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION is_story_favorited(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_favorite_story(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_favorite_story(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_favorite_story(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_favorite_stories(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_favorites_count(UUID) TO authenticated;

COMMENT ON TABLE favorite_stories IS 'Tracks all stories favorited by users in real time.';
COMMENT ON FUNCTION is_story_favorited IS 'Checks if a story is already favorited by the user.';
COMMENT ON FUNCTION toggle_favorite_story IS 'Toggles favorite status (add if not favorited, remove if favorited).';
COMMENT ON FUNCTION get_favorites_count IS 'Returns the count of favorited stories for a user.';


-- ============================================================================
-- 3. STORIES & CONTENT
-- ============================================================================
-- Main stories table for all story content
-- ============================================================================

CREATE TABLE IF NOT EXISTS stories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  category TEXT NOT NULL,
  min_age INTEGER NOT NULL,
  max_age INTEGER NOT NULL,
  audio_default_url TEXT,
  duration_minutes INTEGER DEFAULT 5,
  thumbnail_url TEXT,
  keywords TEXT[],
  moral TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_stories_category ON stories(category);
CREATE INDEX idx_stories_age_range ON stories(min_age, max_age);
CREATE INDEX idx_stories_is_premium ON stories(is_premium);
CREATE INDEX idx_stories_is_active ON stories(is_active);

ALTER TABLE stories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Stories are publicly readable"
ON stories
FOR SELECT
USING (is_active = TRUE);

COMMENT ON TABLE stories IS 'Main stories table for all story content.';


-- ============================================================================
-- 4. CHILD PROFILES
-- ============================================================================
-- Manages child profiles for personalized content
-- ============================================================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  child_name TEXT NOT NULL,
  age_bucket INTEGER NOT NULL CHECK (age_bucket BETWEEN 3 AND 12),
  avatar_url TEXT,
  nickname TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_profiles_is_active ON profiles(is_active);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own profiles"
ON profiles
FOR ALL
USING (auth.uid() = user_id);

COMMENT ON TABLE profiles IS 'Child profiles for personalized content.';


-- ============================================================================
-- 5. LISTENING HISTORY & ANALYTICS
-- ============================================================================
-- Tracks user listening behavior for analytics
-- ============================================================================

CREATE TABLE IF NOT EXISTS listens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  duration_seconds INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  listened_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_listens_user_id ON listens(user_id);
CREATE INDEX idx_listens_story_id ON listens(story_id);
CREATE INDEX idx_listens_profile_id ON listens(profile_id);
CREATE INDEX idx_listens_user_story ON listens(user_id, story_id);
CREATE INDEX idx_listens_timestamp ON listens(listened_at DESC);

ALTER TABLE listens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own listens"
ON listens
FOR ALL
USING (auth.uid() = user_id);

COMMENT ON TABLE listens IS 'Tracks user listening history for analytics.';


-- ============================================================================
-- 6. DASHBOARD ANALYTICS FUNCTIONS
-- ============================================================================
-- Functions for real-time dashboard statistics
-- ============================================================================

-- Function: Get favorite category (most listened)
CREATE OR REPLACE FUNCTION get_favorite_category(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
  fav_category TEXT;
BEGIN
  SELECT s.category INTO fav_category
  FROM listens l
  JOIN stories s ON l.story_id = s.id
  WHERE l.user_id = user_uuid
  GROUP BY s.category
  ORDER BY COUNT(*) DESC
  LIMIT 1;
  
  RETURN COALESCE(fav_category, 'None');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get comprehensive dashboard stats
CREATE OR REPLACE FUNCTION get_dashboard_stats(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
  stats JSON;
BEGIN
  SELECT json_build_object(
    'total_stories', COUNT(DISTINCT l.story_id),
    'total_minutes', COALESCE(SUM(l.duration_seconds) / 60, 0),
    'favorite_category', (
      SELECT s.category
      FROM listens l2
      JOIN stories s ON l2.story_id = s.id
      WHERE l2.user_id = user_uuid
      GROUP BY s.category
      ORDER BY COUNT(*) DESC
      LIMIT 1
    ),
    'active_children', (
      SELECT COUNT(*)
      FROM profiles p
      WHERE p.user_id = user_uuid AND p.is_active = TRUE
    ),
    'favorites_count', (
      SELECT COUNT(*)
      FROM favorite_stories
      WHERE user_id = user_uuid
    ),
    'last_updated', NOW()
  ) INTO stats
  FROM listens l
  WHERE l.user_id = user_uuid;
  
  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get stories listened count
CREATE OR REPLACE FUNCTION get_stories_listened_count(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(DISTINCT story_id)::INTEGER
    FROM listens
    WHERE user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get total listening time in minutes
CREATE OR REPLACE FUNCTION get_listening_time(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COALESCE(SUM(duration_seconds) / 60, 0)::INTEGER
    FROM listens
    WHERE user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get active children count
CREATE OR REPLACE FUNCTION get_active_children_count(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM profiles
    WHERE user_id = user_uuid AND is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_favorite_category(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_dashboard_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_stories_listened_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_listening_time(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_active_children_count(UUID) TO authenticated;

COMMENT ON FUNCTION get_favorite_category IS 'Returns the most listened story category for a user';
COMMENT ON FUNCTION get_dashboard_stats IS 'Returns comprehensive dashboard statistics as JSON';


-- ============================================================================
-- 7. SAFETY & COMPLIANCE TABLES
-- ============================================================================
-- Voice consent, data retention, and content safety tracking
-- ============================================================================

-- Voice Consent Management
CREATE TABLE IF NOT EXISTS voice_consents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  voice_id TEXT NOT NULL,
  consent_given BOOLEAN DEFAULT TRUE,
  consent_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  consent_type TEXT DEFAULT 'voice_cloning',
  parent_signature TEXT,
  ip_address INET,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_voice_consents_user_id ON voice_consents(user_id);
CREATE INDEX idx_voice_consents_voice_id ON voice_consents(voice_id);

ALTER TABLE voice_consents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own consents"
ON voice_consents
FOR ALL
USING (auth.uid() = user_id);

-- Data Retention Policies
CREATE TABLE IF NOT EXISTS retention_policies (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  data_type TEXT NOT NULL,
  retention_days INTEGER DEFAULT 365,
  auto_delete BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_retention_policies_user_id ON retention_policies(user_id);

ALTER TABLE retention_policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own retention policies"
ON retention_policies
FOR ALL
USING (auth.uid() = user_id);

-- Content Safety Log
CREATE TABLE IF NOT EXISTS content_safety_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content_type TEXT NOT NULL,
  content_id TEXT NOT NULL,
  safety_check_result TEXT,
  flagged BOOLEAN DEFAULT FALSE,
  flagged_reason TEXT,
  checked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_content_safety_content_id ON content_safety_log(content_id);
CREATE INDEX idx_content_safety_flagged ON content_safety_log(flagged);

COMMENT ON TABLE voice_consents IS 'Tracks voice recording consent for COPPA/GDPR compliance.';
COMMENT ON TABLE retention_policies IS 'Manages data retention policies per user.';
COMMENT ON TABLE content_safety_log IS 'Logs content safety checks and flagged content.';


-- ============================================================================
-- 8. SUBSCRIPTIONS & PREMIUM FEATURES
-- ============================================================================

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_type TEXT DEFAULT 'free' CHECK (plan_type IN ('free', 'premium', 'family')),
  is_active BOOLEAN DEFAULT FALSE,
  started_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  auto_renew BOOLEAN DEFAULT TRUE,
  payment_provider TEXT,
  external_subscription_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_is_active ON subscriptions(is_active);
CREATE INDEX idx_subscriptions_expires_at ON subscriptions(expires_at);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own subscriptions"
ON subscriptions
FOR SELECT
USING (auth.uid() = user_id);

COMMENT ON TABLE subscriptions IS 'Manages user subscription plans and premium features.';


-- ============================================================================
-- 9. PERFORMANCE OPTIMIZATION
-- ============================================================================
-- Additional indexes for better query performance
-- ============================================================================

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_listens_user_completed ON listens(user_id, completed);
CREATE INDEX IF NOT EXISTS idx_stories_category_age ON stories(category, min_age, max_age);
CREATE INDEX IF NOT EXISTS idx_profiles_user_active ON profiles(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_favorites_user_story ON favorite_stories(user_id, story_id);

-- Partial indexes for filtered queries
CREATE INDEX IF NOT EXISTS idx_stories_premium_active ON stories(is_premium) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_profiles_active ON profiles(user_id) WHERE is_active = TRUE;


-- ============================================================================
-- 10. TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Trigger: Update updated_at column automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at column
CREATE TRIGGER update_user_voices_updated_at
    BEFORE UPDATE ON user_voices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_stories_updated_at
    BEFORE UPDATE ON stories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'StoryHug Database Schema Setup Complete!';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Created Tables:';
    RAISE NOTICE '  ✓ user_voices';
    RAISE NOTICE '  ✓ favorite_stories';
    RAISE NOTICE '  ✓ stories';
    RAISE NOTICE '  ✓ profiles';
    RAISE NOTICE '  ✓ listens';
    RAISE NOTICE '  ✓ voice_consents';
    RAISE NOTICE '  ✓ retention_policies';
    RAISE NOTICE '  ✓ content_safety_log';
    RAISE NOTICE '  ✓ subscriptions';
    RAISE NOTICE '';
    RAISE NOTICE 'Created Functions:';
    RAISE NOTICE '  ✓ Voice management functions';
    RAISE NOTICE '  ✓ Favorites management functions';
    RAISE NOTICE '  ✓ Dashboard analytics functions';
    RAISE NOTICE '';
    RAISE NOTICE 'Row Level Security: ENABLED';
    RAISE NOTICE 'Indexes: CREATED';
    RAISE NOTICE 'Triggers: ACTIVE';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Database is ready for StoryHug app!';
    RAISE NOTICE '============================================';
END $$;


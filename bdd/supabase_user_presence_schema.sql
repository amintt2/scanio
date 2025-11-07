-- =====================================================
-- TomoScan User Presence & Online Status System
-- =====================================================
-- This schema manages user online/offline status with Realtime support
-- Features:
-- - Track user online/offline status
-- - Last seen timestamp
-- - Automatic cleanup of stale presence records
-- - Realtime updates for instant status changes
-- =====================================================

-- Enable Realtime for presence updates
-- Run this in Supabase SQL Editor after creating the table:
-- ALTER PUBLICATION supabase_realtime ADD TABLE scanio_user_presence;

-- =====================================================
-- Table: scanio_user_presence
-- =====================================================
-- Stores current online status for each user
-- Updated in real-time when users connect/disconnect

CREATE TABLE IF NOT EXISTS scanio_user_presence (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    is_online BOOLEAN NOT NULL DEFAULT false,
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- Indexes
-- =====================================================

-- Index for querying online users
CREATE INDEX IF NOT EXISTS idx_user_presence_online 
    ON scanio_user_presence(is_online) 
    WHERE is_online = true;

-- Index for last_seen queries (e.g., "last seen 5 minutes ago")
CREATE INDEX IF NOT EXISTS idx_user_presence_last_seen 
    ON scanio_user_presence(last_seen DESC);

-- =====================================================
-- Row Level Security (RLS)
-- =====================================================

ALTER TABLE scanio_user_presence ENABLE ROW LEVEL SECURITY;

-- Anyone can view presence status (for public profiles, chat, etc.)
CREATE POLICY "Anyone can view user presence"
    ON scanio_user_presence
    FOR SELECT
    USING (true);

-- Users can only update their own presence
CREATE POLICY "Users can update own presence"
    ON scanio_user_presence
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- Function: Update user presence
-- =====================================================
-- Upserts user presence record and updates timestamp

CREATE OR REPLACE FUNCTION scanio_update_user_presence(
    p_is_online BOOLEAN
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO scanio_user_presence (user_id, is_online, last_seen, updated_at)
    VALUES (auth.uid(), p_is_online, NOW(), NOW())
    ON CONFLICT (user_id)
    DO UPDATE SET
        is_online = EXCLUDED.is_online,
        last_seen = NOW(),
        updated_at = NOW();
END;
$$;

-- =====================================================
-- Function: Get user presence
-- =====================================================
-- Returns presence info for a specific user

CREATE OR REPLACE FUNCTION scanio_get_user_presence(
    p_user_id UUID
)
RETURNS TABLE (
    user_id UUID,
    is_online BOOLEAN,
    last_seen TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.user_id,
        up.is_online,
        up.last_seen
    FROM scanio_user_presence up
    WHERE up.user_id = p_user_id;
END;
$$;

-- =====================================================
-- Function: Get multiple users presence
-- =====================================================
-- Returns presence info for multiple users (for chat, friends list, etc.)

CREATE OR REPLACE FUNCTION scanio_get_users_presence(
    p_user_ids UUID[]
)
RETURNS TABLE (
    user_id UUID,
    is_online BOOLEAN,
    last_seen TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.user_id,
        up.is_online,
        up.last_seen
    FROM scanio_user_presence up
    WHERE up.user_id = ANY(p_user_ids);
END;
$$;

-- =====================================================
-- Function: Cleanup stale presence records
-- =====================================================
-- Marks users as offline if they haven't updated in 5 minutes
-- Should be run periodically (e.g., via pg_cron or Edge Function)

CREATE OR REPLACE FUNCTION scanio_cleanup_stale_presence()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE scanio_user_presence
    SET 
        is_online = false,
        updated_at = NOW()
    WHERE 
        is_online = true 
        AND updated_at < NOW() - INTERVAL '5 minutes';
END;
$$;

-- =====================================================
-- Trigger: Auto-update updated_at timestamp
-- =====================================================

CREATE OR REPLACE FUNCTION scanio_update_presence_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_presence_timestamp
    BEFORE UPDATE ON scanio_user_presence
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_presence_timestamp();

-- =====================================================
-- IMPORTANT: Enable Realtime
-- =====================================================
-- Run this command in Supabase SQL Editor to enable Realtime:
-- 
-- ALTER PUBLICATION supabase_realtime ADD TABLE scanio_user_presence;
--
-- This allows clients to subscribe to presence changes in real-time
-- =====================================================

-- =====================================================
-- Usage Examples
-- =====================================================

-- Set user online:
-- SELECT scanio_update_user_presence(true);

-- Set user offline:
-- SELECT scanio_update_user_presence(false);

-- Get user presence:
-- SELECT * FROM scanio_get_user_presence('user-uuid-here');

-- Get multiple users presence:
-- SELECT * FROM scanio_get_users_presence(ARRAY['uuid1', 'uuid2', 'uuid3']);

-- Cleanup stale presence (run periodically):
-- SELECT scanio_cleanup_stale_presence();

-- =====================================================
-- Notes for Future Features
-- =====================================================
-- This schema is designed to support:
-- 1. Real-time chat presence indicators
-- 2. Friends list online status
-- 3. "Last seen X minutes ago" feature
-- 4. Activity indicators in comments/forums
-- 5. User availability for messaging
-- =====================================================


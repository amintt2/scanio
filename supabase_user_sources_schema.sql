-- ============================================================================
-- Scanio User Sources Schema for Supabase
-- Stores user-installed sources with download URLs for auto-installation
-- Execute this SQL in your Supabase SQL Editor
-- ============================================================================

-- Enable UUID extension (safe if already exists)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USER SOURCES TABLE (Tracks sources installed by each user)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_user_sources (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    source_id TEXT NOT NULL,
    source_name TEXT,
    source_lang TEXT,
    source_url TEXT,  -- URL to download the source (.aix file)
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure a user can't add the same source twice
    CONSTRAINT unique_user_source UNIQUE (user_id, source_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_scanio_user_sources_user_id 
    ON public.scanio_user_sources(user_id);

CREATE INDEX IF NOT EXISTS idx_scanio_user_sources_source_id 
    ON public.scanio_user_sources(source_id);

-- Enable Row Level Security
ALTER TABLE public.scanio_user_sources ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Users can view their own sources
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scanio_user_sources' 
        AND policyname = 'Users can view own sources'
    ) THEN
        CREATE POLICY "Users can view own sources"
            ON public.scanio_user_sources FOR SELECT
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- Users can insert their own sources
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scanio_user_sources' 
        AND policyname = 'Users can insert own sources'
    ) THEN
        CREATE POLICY "Users can insert own sources"
            ON public.scanio_user_sources FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- Users can delete their own sources
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scanio_user_sources' 
        AND policyname = 'Users can delete own sources'
    ) THEN
        CREATE POLICY "Users can delete own sources"
            ON public.scanio_user_sources FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- Users can update their own sources
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scanio_user_sources' 
        AND policyname = 'Users can update own sources'
    ) THEN
        CREATE POLICY "Users can update own sources"
            ON public.scanio_user_sources FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to add or update a user source
CREATE OR REPLACE FUNCTION public.upsert_user_source(
    p_user_id UUID,
    p_source_id TEXT,
    p_source_name TEXT DEFAULT NULL,
    p_source_lang TEXT DEFAULT NULL,
    p_source_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_id UUID;
BEGIN
    -- Check if user is authenticated
    IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- Insert or update the source
    INSERT INTO public.scanio_user_sources (
        user_id,
        source_id,
        source_name,
        source_lang,
        source_url,
        added_at
    )
    VALUES (
        p_user_id,
        p_source_id,
        p_source_name,
        p_source_lang,
        p_source_url,
        NOW()
    )
    ON CONFLICT (user_id, source_id) 
    DO UPDATE SET
        source_name = COALESCE(EXCLUDED.source_name, scanio_user_sources.source_name),
        source_lang = COALESCE(EXCLUDED.source_lang, scanio_user_sources.source_lang),
        source_url = COALESCE(EXCLUDED.source_url, scanio_user_sources.source_url)
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

-- Function to get user sources with download URLs
CREATE OR REPLACE FUNCTION public.get_user_sources(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    source_id TEXT,
    source_name TEXT,
    source_lang TEXT,
    source_url TEXT,
    added_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Use provided user_id or current authenticated user
    v_user_id := COALESCE(p_user_id, auth.uid());
    
    -- Check if user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- Return user sources
    RETURN QUERY
    SELECT 
        s.id,
        s.user_id,
        s.source_id,
        s.source_name,
        s.source_lang,
        s.source_url,
        s.added_at
    FROM public.scanio_user_sources s
    WHERE s.user_id = v_user_id
    ORDER BY s.added_at DESC;
END;
$$;

-- Function to remove a user source
CREATE OR REPLACE FUNCTION public.remove_user_source(
    p_user_id UUID,
    p_source_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if user is authenticated
    IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- Delete the source
    DELETE FROM public.scanio_user_sources
    WHERE user_id = p_user_id AND source_id = p_source_id;

    RETURN FOUND;
END;
$$;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.upsert_user_source TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_sources TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_user_source TO authenticated;

-- ============================================================================
-- MIGRATION: Add source_url to existing rows (if table already exists)
-- ============================================================================

-- If the table already exists without source_url column, add it
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'scanio_user_sources'
    ) THEN
        -- Add source_url column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'scanio_user_sources' 
            AND column_name = 'source_url'
        ) THEN
            ALTER TABLE public.scanio_user_sources 
            ADD COLUMN source_url TEXT;
            
            RAISE NOTICE 'Added source_url column to scanio_user_sources table';
        END IF;
    END IF;
END $$;

-- ============================================================================
-- VERIFICATION QUERIES (Optional - for testing)
-- ============================================================================

-- Uncomment to verify the table structure:
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = 'scanio_user_sources'
-- ORDER BY ordinal_position;

-- Uncomment to verify policies:
-- SELECT policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'scanio_user_sources';

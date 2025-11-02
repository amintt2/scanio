-- ============================================================================
-- Scanio User Library RPC Functions - CoreData Sync
-- ============================================================================
-- These functions handle synchronization between CoreData and Supabase
-- Execute this SQL in your Supabase SQL Editor AFTER supabase_user_library_schema.sql
-- ============================================================================

-- ============================================================================
-- FUNCTION: Upsert manga to user library
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_upsert_user_library(
    p_user_id UUID,
    p_canonical_manga_id UUID,
    p_source_id TEXT,
    p_manga_id TEXT,
    p_date_added TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    p_last_opened TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_last_read TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_last_updated TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_library_id UUID;
BEGIN
    INSERT INTO public.scanio_user_library (
        user_id,
        canonical_manga_id,
        source_id,
        manga_id,
        date_added,
        last_opened,
        last_read,
        last_updated,
        updated_at
    )
    VALUES (
        p_user_id,
        p_canonical_manga_id,
        p_source_id,
        p_manga_id,
        p_date_added,
        p_last_opened,
        p_last_read,
        p_last_updated,
        NOW()
    )
    ON CONFLICT (user_id, canonical_manga_id)
    DO UPDATE SET
        source_id = EXCLUDED.source_id,
        manga_id = EXCLUDED.manga_id,
        last_opened = COALESCE(EXCLUDED.last_opened, scanio_user_library.last_opened),
        last_read = COALESCE(EXCLUDED.last_read, scanio_user_library.last_read),
        last_updated = COALESCE(EXCLUDED.last_updated, scanio_user_library.last_updated),
        updated_at = NOW()
    RETURNING id INTO v_library_id;
    
    RETURN v_library_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.scanio_upsert_user_library(
    UUID, UUID, TEXT, TEXT, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE
) TO authenticated;

-- ============================================================================
-- FUNCTION: Remove manga from user library
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_remove_from_library(
    p_user_id UUID,
    p_canonical_manga_id UUID
)
RETURNS void AS $$
BEGIN
    DELETE FROM public.scanio_user_library
    WHERE user_id = p_user_id AND canonical_manga_id = p_canonical_manga_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.scanio_remove_from_library(UUID, UUID) TO authenticated;

-- ============================================================================
-- FUNCTION: Upsert category
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_upsert_category(
    p_user_id UUID,
    p_title TEXT
)
RETURNS UUID AS $$
DECLARE
    v_category_id UUID;
BEGIN
    INSERT INTO public.scanio_user_categories (
        user_id,
        title,
        updated_at
    )
    VALUES (
        p_user_id,
        p_title,
        NOW()
    )
    ON CONFLICT (user_id, title)
    DO UPDATE SET
        updated_at = NOW()
    RETURNING id INTO v_category_id;
    
    RETURN v_category_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.scanio_upsert_category(UUID, TEXT) TO authenticated;

-- ============================================================================
-- FUNCTION: Delete category
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_delete_category(
    p_user_id UUID,
    p_title TEXT
)
RETURNS void AS $$
BEGIN
    DELETE FROM public.scanio_user_categories
    WHERE user_id = p_user_id AND title = p_title;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.scanio_delete_category(UUID, TEXT) TO authenticated;

-- ============================================================================
-- FUNCTION: Add category to library manga
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_add_library_category(
    p_user_id UUID,
    p_canonical_manga_id UUID,
    p_category_title TEXT
)
RETURNS void AS $$
DECLARE
    v_library_id UUID;
    v_category_id UUID;
BEGIN
    -- Get library ID
    SELECT id INTO v_library_id
    FROM public.scanio_user_library
    WHERE user_id = p_user_id AND canonical_manga_id = p_canonical_manga_id;
    
    IF v_library_id IS NULL THEN
        RAISE EXCEPTION 'Manga not found in library';
    END IF;
    
    -- Get or create category
    v_category_id := scanio_upsert_category(p_user_id, p_category_title);
    
    -- Link category to library manga
    INSERT INTO public.scanio_user_library_categories (user_library_id, category_id)
    VALUES (v_library_id, v_category_id)
    ON CONFLICT (user_library_id, category_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.scanio_add_library_category(UUID, UUID, TEXT) TO authenticated;

-- ============================================================================
-- FUNCTION: Remove category from library manga
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_remove_library_category(
    p_user_id UUID,
    p_canonical_manga_id UUID,
    p_category_title TEXT
)
RETURNS void AS $$
DECLARE
    v_library_id UUID;
    v_category_id UUID;
BEGIN
    -- Get library ID
    SELECT id INTO v_library_id
    FROM public.scanio_user_library
    WHERE user_id = p_user_id AND canonical_manga_id = p_canonical_manga_id;
    
    -- Get category ID
    SELECT id INTO v_category_id
    FROM public.scanio_user_categories
    WHERE user_id = p_user_id AND title = p_category_title;
    
    IF v_library_id IS NOT NULL AND v_category_id IS NOT NULL THEN
        DELETE FROM public.scanio_user_library_categories
        WHERE user_library_id = v_library_id AND category_id = v_category_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.scanio_remove_library_category(UUID, UUID, TEXT) TO authenticated;

-- ============================================================================
-- FUNCTION: Upsert tracker
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_upsert_tracker(
    p_user_id UUID,
    p_canonical_manga_id UUID,
    p_tracker_id TEXT,
    p_tracker_manga_id TEXT,
    p_title TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_score REAL DEFAULT NULL,
    p_progress INTEGER DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_tracker_id UUID;
BEGIN
    INSERT INTO public.scanio_user_trackers (
        user_id,
        canonical_manga_id,
        tracker_id,
        tracker_manga_id,
        title,
        status,
        score,
        progress,
        updated_at
    )
    VALUES (
        p_user_id,
        p_canonical_manga_id,
        p_tracker_id,
        p_tracker_manga_id,
        p_title,
        p_status,
        p_score,
        p_progress,
        NOW()
    )
    ON CONFLICT (user_id, canonical_manga_id, tracker_id)
    DO UPDATE SET
        tracker_manga_id = EXCLUDED.tracker_manga_id,
        title = COALESCE(EXCLUDED.title, scanio_user_trackers.title),
        status = COALESCE(EXCLUDED.status, scanio_user_trackers.status),
        score = COALESCE(EXCLUDED.score, scanio_user_trackers.score),
        progress = COALESCE(EXCLUDED.progress, scanio_user_trackers.progress),
        updated_at = NOW()
    RETURNING id INTO v_tracker_id;
    
    RETURN v_tracker_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.scanio_upsert_tracker(
    UUID, UUID, TEXT, TEXT, TEXT, TEXT, REAL, INTEGER
) TO authenticated;

-- ============================================================================
-- FUNCTION: Remove tracker
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_remove_tracker(
    p_user_id UUID,
    p_canonical_manga_id UUID,
    p_tracker_id TEXT
)
RETURNS void AS $$
BEGIN
    DELETE FROM public.scanio_user_trackers
    WHERE user_id = p_user_id 
      AND canonical_manga_id = p_canonical_manga_id 
      AND tracker_id = p_tracker_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.scanio_remove_tracker(UUID, UUID, TEXT) TO authenticated;

-- ============================================================================
-- FUNCTION: Update library timestamps
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_update_library_timestamps(
    p_user_id UUID,
    p_canonical_manga_id UUID,
    p_last_opened TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_last_read TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    UPDATE public.scanio_user_library
    SET 
        last_opened = COALESCE(p_last_opened, last_opened),
        last_read = COALESCE(p_last_read, last_read),
        updated_at = NOW()
    WHERE user_id = p_user_id AND canonical_manga_id = p_canonical_manga_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.scanio_update_library_timestamps(
    UUID, UUID, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE
) TO authenticated;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Scanio User Library RPC functions installed successfully!';
    RAISE NOTICE '🔧 Functions created:';
    RAISE NOTICE '   - scanio_upsert_user_library()';
    RAISE NOTICE '   - scanio_remove_from_library()';
    RAISE NOTICE '   - scanio_upsert_category()';
    RAISE NOTICE '   - scanio_delete_category()';
    RAISE NOTICE '   - scanio_add_library_category()';
    RAISE NOTICE '   - scanio_remove_library_category()';
    RAISE NOTICE '   - scanio_upsert_tracker()';
    RAISE NOTICE '   - scanio_remove_tracker()';
    RAISE NOTICE '   - scanio_update_library_timestamps()';
    RAISE NOTICE '🔄 Ready for CoreData synchronization';
END $$;


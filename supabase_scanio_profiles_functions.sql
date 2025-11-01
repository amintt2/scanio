-- ============================================================================
-- Scanio Profile Functions and Triggers
-- Execute AFTER supabase_scanio_profiles_extended.sql
-- ============================================================================

-- ============================================================================
-- FUNCTION: Update reading history and progress
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_update_reading_progress()
RETURNS TRIGGER AS $$
DECLARE
    v_canonical_id UUID;
BEGIN
    -- Get canonical manga ID
    v_canonical_id := NEW.canonical_manga_id;
    
    -- Update manga progress
    INSERT INTO public.scanio_manga_progress (
        user_id,
        canonical_manga_id,
        last_chapter_read,
        total_chapters_read,
        last_read_at
    )
    VALUES (
        NEW.user_id,
        v_canonical_id,
        NEW.chapter_number,
        1,
        NEW.last_read_at
    )
    ON CONFLICT (user_id, canonical_manga_id) 
    DO UPDATE SET
        last_chapter_read = EXCLUDED.last_chapter_read,
        total_chapters_read = scanio_manga_progress.total_chapters_read + 1,
        last_read_at = EXCLUDED.last_read_at,
        updated_at = NOW();
    
    -- Update user profile stats
    UPDATE public.scanio_profiles
    SET 
        total_chapters_read = total_chapters_read + 1,
        updated_at = NOW()
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Update total manga read count
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_update_total_manga_read()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.scanio_profiles
        SET 
            total_manga_read = (
                SELECT COUNT(DISTINCT canonical_manga_id)
                FROM public.scanio_manga_progress
                WHERE user_id = NEW.user_id
            ),
            updated_at = NOW()
        WHERE id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Auto-update rank positions when inserting/updating
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_auto_update_rank_positions()
RETURNS TRIGGER AS $$
BEGIN
    -- If no rank_position provided, set it to the next available position
    IF NEW.rank_position IS NULL OR NEW.rank_position = 0 THEN
        SELECT COALESCE(MAX(rank_position), 0) + 1 
        INTO NEW.rank_position
        FROM public.scanio_personal_rankings
        WHERE user_id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Get user reading statistics
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_get_user_stats(p_user_id UUID)
RETURNS TABLE (
    total_chapters_read INTEGER,
    total_manga_read INTEGER,
    total_favorites INTEGER,
    total_completed INTEGER,
    total_reading INTEGER,
    total_plan_to_read INTEGER,
    karma INTEGER,
    is_public BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.total_chapters_read,
        p.total_manga_read,
        (SELECT COUNT(*) FROM public.scanio_personal_rankings WHERE user_id = p_user_id AND is_favorite = true)::INTEGER,
        (SELECT COUNT(*) FROM public.scanio_personal_rankings WHERE user_id = p_user_id AND reading_status = 'completed')::INTEGER,
        (SELECT COUNT(*) FROM public.scanio_personal_rankings WHERE user_id = p_user_id AND reading_status = 'reading')::INTEGER,
        (SELECT COUNT(*) FROM public.scanio_personal_rankings WHERE user_id = p_user_id AND reading_status = 'plan_to_read')::INTEGER,
        p.karma,
        p.is_public
    FROM public.scanio_profiles p
    WHERE p.id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Get user's top ranked manga
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_get_top_ranked_manga(p_user_id UUID, p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    rank_position INTEGER,
    manga_id UUID,
    manga_title TEXT,
    personal_rating INTEGER,
    reading_status TEXT,
    is_favorite BOOLEAN,
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pr.rank_position,
        cm.id,
        cm.title,
        pr.personal_rating,
        pr.reading_status,
        pr.is_favorite,
        pr.notes
    FROM public.scanio_personal_rankings pr
    JOIN public.scanio_canonical_manga cm ON pr.canonical_manga_id = cm.id
    WHERE pr.user_id = p_user_id
    ORDER BY pr.rank_position ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Get recent reading history
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_get_recent_reading_history(p_user_id UUID, p_limit INTEGER DEFAULT 20)
RETURNS TABLE (
    manga_id UUID,
    manga_title TEXT,
    chapter_number TEXT,
    chapter_title TEXT,
    page_number INTEGER,
    total_pages INTEGER,
    is_completed BOOLEAN,
    last_read_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cm.id,
        cm.title,
        rh.chapter_number,
        rh.chapter_title,
        rh.page_number,
        rh.total_pages,
        rh.is_completed,
        rh.last_read_at
    FROM public.scanio_reading_history rh
    JOIN public.scanio_canonical_manga cm ON rh.canonical_manga_id = cm.id
    WHERE rh.user_id = p_user_id
    ORDER BY rh.last_read_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Get currently reading manga
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_get_currently_reading(p_user_id UUID)
RETURNS TABLE (
    manga_id UUID,
    manga_title TEXT,
    last_chapter_read TEXT,
    total_chapters_read INTEGER,
    last_read_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cm.id,
        cm.title,
        mp.last_chapter_read,
        mp.total_chapters_read,
        mp.last_read_at
    FROM public.scanio_manga_progress mp
    JOIN public.scanio_canonical_manga cm ON mp.canonical_manga_id = cm.id
    WHERE mp.user_id = p_user_id
    ORDER BY mp.last_read_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update reading progress when new history entry is added
DROP TRIGGER IF EXISTS scanio_on_reading_history_insert ON public.scanio_reading_history;
CREATE TRIGGER scanio_on_reading_history_insert
    AFTER INSERT ON public.scanio_reading_history
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_reading_progress();

-- Update total manga read count
DROP TRIGGER IF EXISTS scanio_on_manga_progress_insert ON public.scanio_manga_progress;
CREATE TRIGGER scanio_on_manga_progress_insert
    AFTER INSERT ON public.scanio_manga_progress
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_total_manga_read();

-- Auto-update rank positions
DROP TRIGGER IF EXISTS scanio_on_personal_ranking_insert ON public.scanio_personal_rankings;
CREATE TRIGGER scanio_on_personal_ranking_insert
    BEFORE INSERT ON public.scanio_personal_rankings
    FOR EACH ROW
    EXECUTE FUNCTION scanio_auto_update_rank_positions();

-- Update updated_at timestamps
DROP TRIGGER IF EXISTS scanio_update_personal_rankings_updated_at ON public.scanio_personal_rankings;
CREATE TRIGGER scanio_update_personal_rankings_updated_at
    BEFORE UPDATE ON public.scanio_personal_rankings
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_updated_at();

DROP TRIGGER IF EXISTS scanio_update_manga_progress_updated_at ON public.scanio_manga_progress;
CREATE TRIGGER scanio_update_manga_progress_updated_at
    BEFORE UPDATE ON public.scanio_manga_progress
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_updated_at();

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: Reading history with manga info
CREATE OR REPLACE VIEW public.scanio_reading_history_with_manga AS
SELECT 
    rh.id,
    rh.user_id,
    rh.canonical_manga_id,
    cm.title as manga_title,
    cm.normalized_title,
    rh.source_id,
    rh.manga_id,
    rh.chapter_number,
    rh.chapter_title,
    rh.page_number,
    rh.total_pages,
    rh.is_completed,
    rh.last_read_at,
    rh.created_at
FROM public.scanio_reading_history rh
JOIN public.scanio_canonical_manga cm ON rh.canonical_manga_id = cm.id;

-- View: Personal rankings with manga info
CREATE OR REPLACE VIEW public.scanio_personal_rankings_with_manga AS
SELECT 
    pr.id,
    pr.user_id,
    pr.canonical_manga_id,
    cm.title as manga_title,
    cm.normalized_title,
    pr.rank_position,
    pr.personal_rating,
    pr.notes,
    pr.is_favorite,
    pr.reading_status,
    pr.created_at,
    pr.updated_at
FROM public.scanio_personal_rankings pr
JOIN public.scanio_canonical_manga cm ON pr.canonical_manga_id = cm.id;

-- View: Manga progress with manga info
CREATE OR REPLACE VIEW public.scanio_manga_progress_with_manga AS
SELECT 
    mp.id,
    mp.user_id,
    mp.canonical_manga_id,
    cm.title as manga_title,
    cm.normalized_title,
    mp.last_chapter_read,
    mp.total_chapters_read,
    mp.started_at,
    mp.last_read_at,
    mp.updated_at
FROM public.scanio_manga_progress mp
JOIN public.scanio_canonical_manga cm ON mp.canonical_manga_id = cm.id;

-- Grant access to views
GRANT SELECT ON public.scanio_reading_history_with_manga TO authenticated, anon;
GRANT SELECT ON public.scanio_personal_rankings_with_manga TO authenticated, anon;
GRANT SELECT ON public.scanio_manga_progress_with_manga TO authenticated, anon;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Scanio profile extensions installed successfully!';
    RAISE NOTICE '📊 New tables: scanio_reading_history, scanio_personal_rankings, scanio_manga_progress';
    RAISE NOTICE '🔧 New functions: User stats, top rankings, reading history';
    RAISE NOTICE '⚡ Triggers: Auto-update progress and stats';
END $$;


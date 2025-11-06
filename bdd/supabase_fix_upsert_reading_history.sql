-- ============================================================================
-- FIX: Create RPC function for upserting reading history
-- ============================================================================
-- This fixes the HTTP 409 duplicate key error by using proper UPSERT
-- ============================================================================

CREATE OR REPLACE FUNCTION scanio_upsert_reading_history(
    p_user_id UUID,
    p_canonical_manga_id UUID,
    p_source_id TEXT,
    p_manga_id TEXT,
    p_chapter_id TEXT,
    p_chapter_number TEXT,
    p_chapter_title TEXT,
    p_page_number INTEGER,
    p_total_pages INTEGER,
    p_is_completed BOOLEAN
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.scanio_reading_history (
        user_id,
        canonical_manga_id,
        source_id,
        manga_id,
        chapter_number,
        chapter_title,
        page_number,
        total_pages,
        is_completed,
        last_read_at
    )
    VALUES (
        p_user_id,
        p_canonical_manga_id,
        p_source_id,
        p_manga_id,
        p_chapter_number,
        p_chapter_title,
        p_page_number,
        p_total_pages,
        p_is_completed,
        NOW()
    )
    ON CONFLICT (user_id, canonical_manga_id, chapter_number)
    DO UPDATE SET
        page_number = EXCLUDED.page_number,
        total_pages = EXCLUDED.total_pages,
        is_completed = EXCLUDED.is_completed,
        last_read_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.scanio_upsert_reading_history(
    UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER, BOOLEAN
) TO authenticated;

-- ============================================================================
-- Test the function (optional)
-- ============================================================================
-- SELECT scanio_upsert_reading_history(
--     auth.uid(),
--     'ba9554ba-14fc-461b-a298-3688d86f8975'::UUID,
--     'multi.webtoon',
--     '3596',
--     '4',
--     '4.0',
--     'Chapter 4',
--     27,
--     146,
--     true
-- );


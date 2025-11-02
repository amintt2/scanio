-- ============================================================================
-- PHASE 3 - Task 3.4: Update favorites counter in user stats
-- ============================================================================
-- This updates the scanio_get_user_stats function to count favorites correctly
-- from scanio_personal_rankings table where is_favorite = true
--
-- Execute this SQL in your Supabase SQL Editor
-- ============================================================================

DROP FUNCTION IF EXISTS scanio_get_user_stats(uuid);

CREATE OR REPLACE FUNCTION scanio_get_user_stats(p_user_id UUID)
RETURNS TABLE (
    total_chapters_read INTEGER,
    total_manga_read INTEGER,
    total_favorites INTEGER,
    total_completed INTEGER,
    total_reading INTEGER,
    total_plan_to_read INTEGER,
    total_comments INTEGER,
    karma INTEGER,
    is_public BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        -- Count distinct chapters from reading_history
        COALESCE((
            SELECT COUNT(DISTINCT chapter_number)::INTEGER 
            FROM public.scanio_reading_history 
            WHERE user_id = p_user_id
        ), 0) as total_chapters_read,
        
        -- Count distinct manga from reading_history
        COALESCE((
            SELECT COUNT(DISTINCT canonical_manga_id)::INTEGER 
            FROM public.scanio_reading_history 
            WHERE user_id = p_user_id
        ), 0) as total_manga_read,
        
        -- Count favorites from personal_rankings (UPDATED for Task 3.4)
        COALESCE((
            SELECT COUNT(*)::INTEGER 
            FROM public.scanio_personal_rankings 
            WHERE user_id = p_user_id AND is_favorite = true
        ), 0) as total_favorites,
        
        -- Count completed from personal_rankings
        COALESCE((
            SELECT COUNT(*)::INTEGER 
            FROM public.scanio_personal_rankings 
            WHERE user_id = p_user_id AND reading_status = 'completed'
        ), 0) as total_completed,
        
        -- Count currently reading from personal_rankings
        COALESCE((
            SELECT COUNT(*)::INTEGER 
            FROM public.scanio_personal_rankings 
            WHERE user_id = p_user_id AND reading_status = 'reading'
        ), 0) as total_reading,
        
        -- Count plan to read from personal_rankings
        COALESCE((
            SELECT COUNT(*)::INTEGER 
            FROM public.scanio_personal_rankings 
            WHERE user_id = p_user_id AND reading_status = 'plan_to_read'
        ), 0) as total_plan_to_read,
        
        -- Count total comments posted by user
        COALESCE((
            SELECT COUNT(*)::INTEGER 
            FROM public.scanio_chapter_comments 
            WHERE user_id = p_user_id
        ), 0) as total_comments,
        
        -- Get karma and is_public from profile
        COALESCE(p.karma, 0) as karma,
        COALESCE(p.is_public, true) as is_public
    FROM public.scanio_profiles p
    WHERE p.id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.scanio_get_user_stats(UUID) TO authenticated;

-- ============================================================================
-- Test the function (optional - run this to verify it works)
-- ============================================================================
-- SELECT * FROM scanio_get_user_stats(auth.uid());


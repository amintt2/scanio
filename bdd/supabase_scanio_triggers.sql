-- ============================================================================
-- Scanio Triggers for Supabase (Self-Hosted)
-- Execute AFTER running supabase_scanio_schema.sql and supabase_scanio_functions.sql
-- ============================================================================

-- ============================================================================
-- TRIGGERS: Chapter comment votes
-- ============================================================================
DROP TRIGGER IF EXISTS scanio_on_chapter_comment_vote_insert ON public.scanio_chapter_comment_votes;
CREATE TRIGGER scanio_on_chapter_comment_vote_insert
    AFTER INSERT ON public.scanio_chapter_comment_votes
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_chapter_comment_votes();

DROP TRIGGER IF EXISTS scanio_on_chapter_comment_vote_update ON public.scanio_chapter_comment_votes;
CREATE TRIGGER scanio_on_chapter_comment_vote_update
    AFTER UPDATE ON public.scanio_chapter_comment_votes
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_chapter_comment_votes();

DROP TRIGGER IF EXISTS scanio_on_chapter_comment_vote_delete ON public.scanio_chapter_comment_votes;
CREATE TRIGGER scanio_on_chapter_comment_vote_delete
    AFTER DELETE ON public.scanio_chapter_comment_votes
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_chapter_comment_votes();

-- ============================================================================
-- TRIGGERS: Manga review votes
-- ============================================================================
DROP TRIGGER IF EXISTS scanio_on_manga_review_vote_insert ON public.scanio_manga_review_votes;
CREATE TRIGGER scanio_on_manga_review_vote_insert
    AFTER INSERT ON public.scanio_manga_review_votes
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_manga_review_votes();

DROP TRIGGER IF EXISTS scanio_on_manga_review_vote_update ON public.scanio_manga_review_votes;
CREATE TRIGGER scanio_on_manga_review_vote_update
    AFTER UPDATE ON public.scanio_manga_review_votes
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_manga_review_votes();

DROP TRIGGER IF EXISTS scanio_on_manga_review_vote_delete ON public.scanio_manga_review_votes;
CREATE TRIGGER scanio_on_manga_review_vote_delete
    AFTER DELETE ON public.scanio_manga_review_votes
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_manga_review_votes();

-- ============================================================================
-- TRIGGERS: Chapter comment replies
-- ============================================================================
DROP TRIGGER IF EXISTS scanio_on_chapter_comment_insert ON public.scanio_chapter_comments;
CREATE TRIGGER scanio_on_chapter_comment_insert
    BEFORE INSERT ON public.scanio_chapter_comments
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_chapter_comment_replies();

DROP TRIGGER IF EXISTS scanio_on_chapter_comment_delete ON public.scanio_chapter_comments;
CREATE TRIGGER scanio_on_chapter_comment_delete
    AFTER DELETE ON public.scanio_chapter_comments
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_chapter_comment_replies();

-- ============================================================================
-- TRIGGERS: User karma updates
-- ============================================================================
DROP TRIGGER IF EXISTS scanio_on_chapter_comment_vote_karma ON public.scanio_chapter_comment_votes;
CREATE TRIGGER scanio_on_chapter_comment_vote_karma
    AFTER INSERT OR UPDATE OR DELETE ON public.scanio_chapter_comment_votes
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_user_karma();

DROP TRIGGER IF EXISTS scanio_on_manga_review_vote_karma ON public.scanio_manga_review_votes;
CREATE TRIGGER scanio_on_manga_review_vote_karma
    AFTER INSERT OR UPDATE OR DELETE ON public.scanio_manga_review_votes
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_user_karma();

-- ============================================================================
-- TRIGGERS: Auto-create profile on user signup
-- ============================================================================
DROP TRIGGER IF EXISTS scanio_on_auth_user_created ON auth.users;
CREATE TRIGGER scanio_on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION scanio_handle_new_user();

-- ============================================================================
-- TRIGGERS: Update updated_at timestamps
-- ============================================================================
DROP TRIGGER IF EXISTS scanio_update_profiles_updated_at ON public.scanio_profiles;
CREATE TRIGGER scanio_update_profiles_updated_at
    BEFORE UPDATE ON public.scanio_profiles
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_updated_at();

DROP TRIGGER IF EXISTS scanio_update_chapter_comments_updated_at ON public.scanio_chapter_comments;
CREATE TRIGGER scanio_update_chapter_comments_updated_at
    BEFORE UPDATE ON public.scanio_chapter_comments
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_updated_at();

DROP TRIGGER IF EXISTS scanio_update_manga_reviews_updated_at ON public.scanio_manga_reviews;
CREATE TRIGGER scanio_update_manga_reviews_updated_at
    BEFORE UPDATE ON public.scanio_manga_reviews
    FOR EACH ROW
    EXECUTE FUNCTION scanio_update_updated_at();

-- ============================================================================
-- VIEWS: Chapter comments with user information
-- ============================================================================
CREATE OR REPLACE VIEW public.scanio_chapter_comments_with_users AS
SELECT 
    c.id,
    c.canonical_manga_id,
    c.chapter_number,
    c.user_id,
    p.user_name,
    p.avatar_url AS user_avatar,
    p.karma AS user_karma,
    c.content,
    c.parent_comment_id,
    c.depth,
    c.created_at,
    c.updated_at,
    c.upvotes,
    c.downvotes,
    c.score,
    c.replies_count
FROM public.scanio_chapter_comments c
LEFT JOIN public.scanio_profiles p ON c.user_id = p.id;

-- ============================================================================
-- VIEWS: Manga reviews with user information
-- ============================================================================
CREATE OR REPLACE VIEW public.scanio_manga_reviews_with_users AS
SELECT 
    r.id,
    r.canonical_manga_id,
    r.user_id,
    p.user_name,
    p.avatar_url AS user_avatar,
    p.karma AS user_karma,
    r.content,
    r.rating,
    r.created_at,
    r.updated_at,
    r.upvotes,
    r.downvotes,
    r.score
FROM public.scanio_manga_reviews r
LEFT JOIN public.scanio_profiles p ON r.user_id = p.id;

-- ============================================================================
-- GRANT access to views
-- ============================================================================
GRANT SELECT ON public.scanio_chapter_comments_with_users TO authenticated, anon;
GRANT SELECT ON public.scanio_manga_reviews_with_users TO authenticated, anon;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Scanio database schema, functions, and triggers installed successfully!';
    RAISE NOTICE '📊 Tables created: scanio_profiles, scanio_canonical_manga, scanio_manga_sources, scanio_chapter_comments, scanio_manga_reviews, scanio_chapter_comment_votes, scanio_manga_review_votes';
    RAISE NOTICE '🔧 Functions created: scanio_normalize_title, scanio_get_or_create_canonical_manga, and vote/karma update functions';
    RAISE NOTICE '⚡ Triggers created: Auto-update votes, karma, replies, and timestamps';
    RAISE NOTICE '👁️ Views created: scanio_chapter_comments_with_users, scanio_manga_reviews_with_users';
END $$;


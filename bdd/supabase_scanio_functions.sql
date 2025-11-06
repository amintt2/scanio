-- ============================================================================
-- Scanio Functions and Triggers for Supabase (Self-Hosted)
-- Execute AFTER running supabase_scanio_schema.sql
-- ============================================================================

-- ============================================================================
-- FUNCTION: Normalize manga title for matching across sources
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_normalize_title(title TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN lower(regexp_replace(title, '[^a-zA-Z0-9]', '', 'g'));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- FUNCTION: Get or create canonical manga (combines same manga from different sources)
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_get_or_create_canonical_manga(
    p_title TEXT,
    p_source_id TEXT,
    p_manga_id TEXT
)
RETURNS UUID AS $$
DECLARE
    v_normalized_title TEXT;
    v_canonical_id UUID;
BEGIN
    v_normalized_title := scanio_normalize_title(p_title);
    
    -- Try to find existing canonical manga
    SELECT id INTO v_canonical_id
    FROM public.scanio_canonical_manga
    WHERE normalized_title = v_normalized_title;
    
    -- If not found, create it
    IF v_canonical_id IS NULL THEN
        INSERT INTO public.scanio_canonical_manga (title, normalized_title)
        VALUES (p_title, v_normalized_title)
        RETURNING id INTO v_canonical_id;
    END IF;
    
    -- Link this source to the canonical manga if not already linked
    INSERT INTO public.scanio_manga_sources (canonical_manga_id, source_id, manga_id, title)
    VALUES (v_canonical_id, p_source_id, p_manga_id, p_title)
    ON CONFLICT (source_id, manga_id) DO NOTHING;
    
    RETURN v_canonical_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Update chapter comment votes and score
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_update_chapter_comment_votes()
RETURNS TRIGGER AS $$
DECLARE
    upvote_delta INTEGER := 0;
    downvote_delta INTEGER := 0;
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.vote_type = 1 THEN
            upvote_delta := 1;
        ELSE
            downvote_delta := 1;
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.vote_type = 1 THEN
            upvote_delta := -1;
        ELSE
            downvote_delta := -1;
        END IF;
        IF NEW.vote_type = 1 THEN
            upvote_delta := upvote_delta + 1;
        ELSE
            downvote_delta := downvote_delta + 1;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.vote_type = 1 THEN
            upvote_delta := -1;
        ELSE
            downvote_delta := -1;
        END IF;
    END IF;

    UPDATE public.scanio_chapter_comments
    SET 
        upvotes = upvotes + upvote_delta,
        downvotes = downvotes + downvote_delta,
        score = (upvotes + upvote_delta) - (downvotes + downvote_delta)
    WHERE id = COALESCE(NEW.comment_id, OLD.comment_id);

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Update manga review votes and score
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_update_manga_review_votes()
RETURNS TRIGGER AS $$
DECLARE
    upvote_delta INTEGER := 0;
    downvote_delta INTEGER := 0;
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.vote_type = 1 THEN
            upvote_delta := 1;
        ELSE
            downvote_delta := 1;
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.vote_type = 1 THEN
            upvote_delta := -1;
        ELSE
            downvote_delta := -1;
        END IF;
        IF NEW.vote_type = 1 THEN
            upvote_delta := upvote_delta + 1;
        ELSE
            downvote_delta := downvote_delta + 1;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.vote_type = 1 THEN
            upvote_delta := -1;
        ELSE
            downvote_delta := -1;
        END IF;
    END IF;

    UPDATE public.scanio_manga_reviews
    SET 
        upvotes = upvotes + upvote_delta,
        downvotes = downvotes + downvote_delta,
        score = (upvotes + upvote_delta) - (downvotes + downvote_delta)
    WHERE id = COALESCE(NEW.review_id, OLD.review_id);

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Update chapter comment replies count and depth
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_update_chapter_comment_replies()
RETURNS TRIGGER AS $$
DECLARE
    parent_depth INTEGER;
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.parent_comment_id IS NOT NULL THEN
            -- Get parent depth and increment for this comment
            SELECT depth INTO parent_depth 
            FROM public.scanio_chapter_comments 
            WHERE id = NEW.parent_comment_id;
            
            NEW.depth := COALESCE(parent_depth, 0) + 1;
            
            -- Increment parent's reply count
            UPDATE public.scanio_chapter_comments
            SET replies_count = replies_count + 1
            WHERE id = NEW.parent_comment_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.parent_comment_id IS NOT NULL THEN
            -- Decrement parent's reply count
            UPDATE public.scanio_chapter_comments
            SET replies_count = replies_count - 1
            WHERE id = OLD.parent_comment_id;
        END IF;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Update user karma based on votes
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_update_user_karma()
RETURNS TRIGGER AS $$
DECLARE
    comment_user_id UUID;
    karma_delta INTEGER := 0;
BEGIN
    -- Get the user who owns the comment/review
    IF TG_TABLE_NAME = 'scanio_chapter_comment_votes' THEN
        SELECT user_id INTO comment_user_id 
        FROM public.scanio_chapter_comments 
        WHERE id = COALESCE(NEW.comment_id, OLD.comment_id);
    ELSIF TG_TABLE_NAME = 'scanio_manga_review_votes' THEN
        SELECT user_id INTO comment_user_id 
        FROM public.scanio_manga_reviews 
        WHERE id = COALESCE(NEW.review_id, OLD.review_id);
    END IF;

    -- Calculate karma change
    IF TG_OP = 'INSERT' THEN
        karma_delta := NEW.vote_type;
    ELSIF TG_OP = 'UPDATE' THEN
        karma_delta := NEW.vote_type - OLD.vote_type;
    ELSIF TG_OP = 'DELETE' THEN
        karma_delta := -OLD.vote_type;
    END IF;

    -- Update user karma
    UPDATE public.scanio_profiles
    SET karma = karma + karma_delta
    WHERE id = comment_user_id;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Auto-create profile on user signup
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.scanio_profiles (id, user_name, karma, created_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'user_name', split_part(NEW.email, '@', 1)),
        0,
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Update updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION scanio_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


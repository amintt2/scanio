-- Supabase Database Schema for Scanio
-- Execute this SQL in your Supabase SQL Editor
-- Self-hosted Supabase compatible

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    user_name TEXT,
    avatar_url TEXT,
    karma INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Canonical Manga table (to combine same manga from different sources)
CREATE TABLE IF NOT EXISTS public.canonical_manga (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    normalized_title TEXT NOT NULL, -- lowercase, no special chars for matching
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(normalized_title)
);

-- Enable Row Level Security
ALTER TABLE public.canonical_manga ENABLE ROW LEVEL SECURITY;

-- Policies for canonical_manga
CREATE POLICY "Canonical manga are viewable by everyone"
    ON public.canonical_manga FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create canonical manga"
    ON public.canonical_manga FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Manga sources mapping (links manga from different sources to canonical manga)
CREATE TABLE IF NOT EXISTS public.manga_sources (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    canonical_manga_id UUID REFERENCES public.canonical_manga(id) ON DELETE CASCADE NOT NULL,
    source_id TEXT NOT NULL,
    manga_id TEXT NOT NULL,
    title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(source_id, manga_id)
);

-- Enable Row Level Security
ALTER TABLE public.manga_sources ENABLE ROW LEVEL SECURITY;

-- Policies for manga_sources
CREATE POLICY "Manga sources are viewable by everyone"
    ON public.manga_sources FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create manga sources"
    ON public.manga_sources FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Chapter Comments table (comments on specific chapters)
CREATE TABLE IF NOT EXISTS public.chapter_comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    canonical_manga_id UUID REFERENCES public.canonical_manga(id) ON DELETE CASCADE NOT NULL,
    chapter_number TEXT NOT NULL, -- normalized chapter number for matching across sources
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    parent_comment_id UUID REFERENCES public.chapter_comments(id) ON DELETE CASCADE,
    depth INTEGER DEFAULT 0, -- for visual threading
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    score INTEGER DEFAULT 0, -- upvotes - downvotes
    replies_count INTEGER DEFAULT 0
);

-- Enable Row Level Security
ALTER TABLE public.chapter_comments ENABLE ROW LEVEL SECURITY;

-- Policies for chapter_comments
CREATE POLICY "Chapter comments are viewable by everyone"
    ON public.chapter_comments FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create chapter comments"
    ON public.chapter_comments FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can update own chapter comments"
    ON public.chapter_comments FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own chapter comments"
    ON public.chapter_comments FOR DELETE
    USING (auth.uid() = user_id);

-- Manga Reviews table (reviews on manga page with star rating)
CREATE TABLE IF NOT EXISTS public.manga_reviews (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    canonical_manga_id UUID REFERENCES public.canonical_manga(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 0 AND rating <= 10), -- 0-10 stars
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    score INTEGER DEFAULT 0,
    UNIQUE(canonical_manga_id, user_id) -- one review per user per manga
);

-- Enable Row Level Security
ALTER TABLE public.manga_reviews ENABLE ROW LEVEL SECURITY;

-- Policies for manga_reviews
CREATE POLICY "Manga reviews are viewable by everyone"
    ON public.manga_reviews FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create manga reviews"
    ON public.manga_reviews FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can update own manga reviews"
    ON public.manga_reviews FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own manga reviews"
    ON public.manga_reviews FOR DELETE
    USING (auth.uid() = user_id);

-- Chapter Comment Votes table (upvote/downvote)
CREATE TABLE IF NOT EXISTS public.chapter_comment_votes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    comment_id UUID REFERENCES public.chapter_comments(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    vote_type INTEGER NOT NULL CHECK (vote_type IN (-1, 1)), -- -1 = downvote, 1 = upvote
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(comment_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE public.chapter_comment_votes ENABLE ROW LEVEL SECURITY;

-- Policies for chapter_comment_votes
CREATE POLICY "Chapter comment votes are viewable by everyone"
    ON public.chapter_comment_votes FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can vote on chapter comments"
    ON public.chapter_comment_votes FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can change their votes"
    ON public.chapter_comment_votes FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can remove their votes"
    ON public.chapter_comment_votes FOR DELETE
    USING (auth.uid() = user_id);

-- Manga Review Votes table (upvote/downvote)
CREATE TABLE IF NOT EXISTS public.manga_review_votes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    review_id UUID REFERENCES public.manga_reviews(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    vote_type INTEGER NOT NULL CHECK (vote_type IN (-1, 1)),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(review_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE public.manga_review_votes ENABLE ROW LEVEL SECURITY;

-- Policies for manga_review_votes
CREATE POLICY "Manga review votes are viewable by everyone"
    ON public.manga_review_votes FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can vote on manga reviews"
    ON public.manga_review_votes FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can change their review votes"
    ON public.manga_review_votes FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can remove their review votes"
    ON public.manga_review_votes FOR DELETE
    USING (auth.uid() = user_id);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_canonical_manga_normalized_title ON public.canonical_manga(normalized_title);
CREATE INDEX IF NOT EXISTS idx_manga_sources_canonical_id ON public.manga_sources(canonical_manga_id);
CREATE INDEX IF NOT EXISTS idx_manga_sources_source_manga ON public.manga_sources(source_id, manga_id);

CREATE INDEX IF NOT EXISTS idx_chapter_comments_canonical_manga ON public.chapter_comments(canonical_manga_id, chapter_number);
CREATE INDEX IF NOT EXISTS idx_chapter_comments_user_id ON public.chapter_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_chapter_comments_parent_id ON public.chapter_comments(parent_comment_id);
CREATE INDEX IF NOT EXISTS idx_chapter_comments_score ON public.chapter_comments(score DESC);
CREATE INDEX IF NOT EXISTS idx_chapter_comments_created_at ON public.chapter_comments(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_manga_reviews_canonical_manga ON public.manga_reviews(canonical_manga_id);
CREATE INDEX IF NOT EXISTS idx_manga_reviews_user_id ON public.manga_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_manga_reviews_score ON public.manga_reviews(score DESC);
CREATE INDEX IF NOT EXISTS idx_manga_reviews_rating ON public.manga_reviews(rating DESC);

CREATE INDEX IF NOT EXISTS idx_chapter_comment_votes_comment_id ON public.chapter_comment_votes(comment_id);
CREATE INDEX IF NOT EXISTS idx_chapter_comment_votes_user_id ON public.chapter_comment_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_manga_review_votes_review_id ON public.manga_review_votes(review_id);
CREATE INDEX IF NOT EXISTS idx_manga_review_votes_user_id ON public.manga_review_votes(user_id);

-- Function to update chapter comment votes and score
CREATE OR REPLACE FUNCTION update_chapter_comment_votes()
RETURNS TRIGGER AS $$
DECLARE
    old_vote INTEGER;
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

    UPDATE public.chapter_comments
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

-- Function to update manga review votes and score
CREATE OR REPLACE FUNCTION update_manga_review_votes()
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

    UPDATE public.manga_reviews
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

-- Function to update replies_count and depth when a reply is added
CREATE OR REPLACE FUNCTION update_chapter_comment_replies()
RETURNS TRIGGER AS $$
DECLARE
    parent_depth INTEGER;
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.parent_comment_id IS NOT NULL THEN
            -- Get parent depth and increment for this comment
            SELECT depth INTO parent_depth FROM public.chapter_comments WHERE id = NEW.parent_comment_id;
            NEW.depth := COALESCE(parent_depth, 0) + 1;

            -- Increment parent's reply count
            UPDATE public.chapter_comments
            SET replies_count = replies_count + 1
            WHERE id = NEW.parent_comment_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.parent_comment_id IS NOT NULL THEN
            -- Decrement parent's reply count
            UPDATE public.chapter_comments
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

-- Function to update user karma based on votes
CREATE OR REPLACE FUNCTION update_user_karma()
RETURNS TRIGGER AS $$
DECLARE
    comment_user_id UUID;
    karma_delta INTEGER := 0;
BEGIN
    -- Get the user who owns the comment/review
    IF TG_TABLE_NAME = 'chapter_comment_votes' THEN
        SELECT user_id INTO comment_user_id FROM public.chapter_comments WHERE id = COALESCE(NEW.comment_id, OLD.comment_id);
    ELSIF TG_TABLE_NAME = 'manga_review_votes' THEN
        SELECT user_id INTO comment_user_id FROM public.manga_reviews WHERE id = COALESCE(NEW.review_id, OLD.review_id);
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
    UPDATE public.profiles
    SET karma = karma + karma_delta
    WHERE id = comment_user_id;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Triggers for chapter comment votes
CREATE TRIGGER on_chapter_comment_vote_insert
    AFTER INSERT ON public.chapter_comment_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_chapter_comment_votes();

CREATE TRIGGER on_chapter_comment_vote_update
    AFTER UPDATE ON public.chapter_comment_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_chapter_comment_votes();

CREATE TRIGGER on_chapter_comment_vote_delete
    AFTER DELETE ON public.chapter_comment_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_chapter_comment_votes();

-- Triggers for manga review votes
CREATE TRIGGER on_manga_review_vote_insert
    AFTER INSERT ON public.manga_review_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_manga_review_votes();

CREATE TRIGGER on_manga_review_vote_update
    AFTER UPDATE ON public.manga_review_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_manga_review_votes();

CREATE TRIGGER on_manga_review_vote_delete
    AFTER DELETE ON public.manga_review_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_manga_review_votes();

-- Triggers for chapter comment replies
CREATE TRIGGER on_chapter_comment_insert
    BEFORE INSERT ON public.chapter_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_chapter_comment_replies();

CREATE TRIGGER on_chapter_comment_delete
    AFTER DELETE ON public.chapter_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_chapter_comment_replies();

-- Triggers for user karma
CREATE TRIGGER on_chapter_comment_vote_karma
    AFTER INSERT OR UPDATE OR DELETE ON public.chapter_comment_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_user_karma();

CREATE TRIGGER on_manga_review_vote_karma
    AFTER INSERT OR UPDATE OR DELETE ON public.manga_review_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_user_karma();

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, user_name, karma, created_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'user_name', split_part(NEW.email, '@', 1)),
        0,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Function to normalize manga title for matching
CREATE OR REPLACE FUNCTION normalize_title(title TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN lower(regexp_replace(title, '[^a-zA-Z0-9]', '', 'g'));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get or create canonical manga
CREATE OR REPLACE FUNCTION get_or_create_canonical_manga(
    p_title TEXT,
    p_source_id TEXT,
    p_manga_id TEXT
)
RETURNS UUID AS $$
DECLARE
    v_normalized_title TEXT;
    v_canonical_id UUID;
BEGIN
    v_normalized_title := normalize_title(p_title);

    -- Try to find existing canonical manga
    SELECT id INTO v_canonical_id
    FROM public.canonical_manga
    WHERE normalized_title = v_normalized_title;

    -- If not found, create it
    IF v_canonical_id IS NULL THEN
        INSERT INTO public.canonical_manga (title, normalized_title)
        VALUES (p_title, v_normalized_title)
        RETURNING id INTO v_canonical_id;
    END IF;

    -- Link this source to the canonical manga if not already linked
    INSERT INTO public.manga_sources (canonical_manga_id, source_id, manga_id, title)
    VALUES (v_canonical_id, p_source_id, p_manga_id, p_title)
    ON CONFLICT (source_id, manga_id) DO NOTHING;

    RETURN v_canonical_id;
END;
$$ LANGUAGE plpgsql;

-- View to get chapter comments with user information and vote status
CREATE OR REPLACE VIEW public.chapter_comments_with_users AS
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
FROM public.chapter_comments c
LEFT JOIN public.profiles p ON c.user_id = p.id;

-- View to get manga reviews with user information
CREATE OR REPLACE VIEW public.manga_reviews_with_users AS
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
FROM public.manga_reviews r
LEFT JOIN public.profiles p ON r.user_id = p.id;

-- Grant access to the views
GRANT SELECT ON public.chapter_comments_with_users TO authenticated, anon;
GRANT SELECT ON public.manga_reviews_with_users TO authenticated, anon;


-- ============================================================================
-- Scanio Database Schema for Supabase (Self-Hosted)
-- Safe to execute - will not affect existing tables
-- Execute this SQL in your Supabase SQL Editor
-- ============================================================================

-- Enable UUID extension (safe if already exists)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- PROFILES TABLE (User profiles with karma)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    user_name TEXT,
    avatar_url TEXT,
    karma INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.scanio_profiles ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_profiles' AND policyname = 'Public profiles are viewable by everyone') THEN
        CREATE POLICY "Public profiles are viewable by everyone"
            ON public.scanio_profiles FOR SELECT
            USING (true);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_profiles' AND policyname = 'Users can update own profile') THEN
        CREATE POLICY "Users can update own profile"
            ON public.scanio_profiles FOR UPDATE
            USING (auth.uid() = id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_profiles' AND policyname = 'Users can insert own profile') THEN
        CREATE POLICY "Users can insert own profile"
            ON public.scanio_profiles FOR INSERT
            WITH CHECK (auth.uid() = id);
    END IF;
END $$;

-- ============================================================================
-- CANONICAL MANGA TABLE (Combines same manga from different sources)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_canonical_manga (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    normalized_title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scanio_canonical_manga_normalized_title_key'
    ) THEN
        ALTER TABLE public.scanio_canonical_manga 
        ADD CONSTRAINT scanio_canonical_manga_normalized_title_key 
        UNIQUE (normalized_title);
    END IF;
END $$;

ALTER TABLE public.scanio_canonical_manga ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_canonical_manga' AND policyname = 'Canonical manga are viewable by everyone') THEN
        CREATE POLICY "Canonical manga are viewable by everyone"
            ON public.scanio_canonical_manga FOR SELECT
            USING (true);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_canonical_manga' AND policyname = 'Authenticated users can create canonical manga') THEN
        CREATE POLICY "Authenticated users can create canonical manga"
            ON public.scanio_canonical_manga FOR INSERT
            WITH CHECK (auth.role() = 'authenticated');
    END IF;
END $$;

-- ============================================================================
-- MANGA SOURCES TABLE (Links manga from different sources to canonical manga)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_manga_sources (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE NOT NULL,
    source_id TEXT NOT NULL,
    manga_id TEXT NOT NULL,
    title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scanio_manga_sources_source_id_manga_id_key'
    ) THEN
        ALTER TABLE public.scanio_manga_sources 
        ADD CONSTRAINT scanio_manga_sources_source_id_manga_id_key 
        UNIQUE (source_id, manga_id);
    END IF;
END $$;

ALTER TABLE public.scanio_manga_sources ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_sources' AND policyname = 'Manga sources are viewable by everyone') THEN
        CREATE POLICY "Manga sources are viewable by everyone"
            ON public.scanio_manga_sources FOR SELECT
            USING (true);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_sources' AND policyname = 'Authenticated users can create manga sources') THEN
        CREATE POLICY "Authenticated users can create manga sources"
            ON public.scanio_manga_sources FOR INSERT
            WITH CHECK (auth.role() = 'authenticated');
    END IF;
END $$;

-- ============================================================================
-- CHAPTER COMMENTS TABLE (Comments on specific chapters with Reddit-style voting)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_chapter_comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE NOT NULL,
    chapter_number TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    parent_comment_id UUID REFERENCES public.scanio_chapter_comments(id) ON DELETE CASCADE,
    depth INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    score INTEGER DEFAULT 0,
    replies_count INTEGER DEFAULT 0
);

ALTER TABLE public.scanio_chapter_comments ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_chapter_comments' AND policyname = 'Chapter comments are viewable by everyone') THEN
        CREATE POLICY "Chapter comments are viewable by everyone"
            ON public.scanio_chapter_comments FOR SELECT
            USING (true);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_chapter_comments' AND policyname = 'Authenticated users can create chapter comments') THEN
        CREATE POLICY "Authenticated users can create chapter comments"
            ON public.scanio_chapter_comments FOR INSERT
            WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_chapter_comments' AND policyname = 'Users can update own chapter comments') THEN
        CREATE POLICY "Users can update own chapter comments"
            ON public.scanio_chapter_comments FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_chapter_comments' AND policyname = 'Users can delete own chapter comments') THEN
        CREATE POLICY "Users can delete own chapter comments"
            ON public.scanio_chapter_comments FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- MANGA REVIEWS TABLE (Reviews on manga page with 0-10 star rating)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_manga_reviews (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 0 AND rating <= 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    score INTEGER DEFAULT 0
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scanio_manga_reviews_canonical_manga_id_user_id_key'
    ) THEN
        ALTER TABLE public.scanio_manga_reviews 
        ADD CONSTRAINT scanio_manga_reviews_canonical_manga_id_user_id_key 
        UNIQUE (canonical_manga_id, user_id);
    END IF;
END $$;

ALTER TABLE public.scanio_manga_reviews ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_reviews' AND policyname = 'Manga reviews are viewable by everyone') THEN
        CREATE POLICY "Manga reviews are viewable by everyone"
            ON public.scanio_manga_reviews FOR SELECT
            USING (true);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_reviews' AND policyname = 'Authenticated users can create manga reviews') THEN
        CREATE POLICY "Authenticated users can create manga reviews"
            ON public.scanio_manga_reviews FOR INSERT
            WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_reviews' AND policyname = 'Users can update own manga reviews') THEN
        CREATE POLICY "Users can update own manga reviews"
            ON public.scanio_manga_reviews FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_reviews' AND policyname = 'Users can delete own manga reviews') THEN
        CREATE POLICY "Users can delete own manga reviews"
            ON public.scanio_manga_reviews FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- CHAPTER COMMENT VOTES TABLE (Upvote/Downvote for chapter comments)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_chapter_comment_votes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    comment_id UUID REFERENCES public.scanio_chapter_comments(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    vote_type INTEGER NOT NULL CHECK (vote_type IN (-1, 1)),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'scanio_chapter_comment_votes_comment_id_user_id_key'
    ) THEN
        ALTER TABLE public.scanio_chapter_comment_votes
        ADD CONSTRAINT scanio_chapter_comment_votes_comment_id_user_id_key
        UNIQUE (comment_id, user_id);
    END IF;
END $$;

ALTER TABLE public.scanio_chapter_comment_votes ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_chapter_comment_votes' AND policyname = 'Chapter comment votes are viewable by everyone') THEN
        CREATE POLICY "Chapter comment votes are viewable by everyone"
            ON public.scanio_chapter_comment_votes FOR SELECT
            USING (true);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_chapter_comment_votes' AND policyname = 'Authenticated users can vote on chapter comments') THEN
        CREATE POLICY "Authenticated users can vote on chapter comments"
            ON public.scanio_chapter_comment_votes FOR INSERT
            WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_chapter_comment_votes' AND policyname = 'Users can change their votes') THEN
        CREATE POLICY "Users can change their votes"
            ON public.scanio_chapter_comment_votes FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_chapter_comment_votes' AND policyname = 'Users can remove their votes') THEN
        CREATE POLICY "Users can remove their votes"
            ON public.scanio_chapter_comment_votes FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- MANGA REVIEW VOTES TABLE (Upvote/Downvote for manga reviews)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_manga_review_votes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    review_id UUID REFERENCES public.scanio_manga_reviews(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    vote_type INTEGER NOT NULL CHECK (vote_type IN (-1, 1)),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'scanio_manga_review_votes_review_id_user_id_key'
    ) THEN
        ALTER TABLE public.scanio_manga_review_votes
        ADD CONSTRAINT scanio_manga_review_votes_review_id_user_id_key
        UNIQUE (review_id, user_id);
    END IF;
END $$;

ALTER TABLE public.scanio_manga_review_votes ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_review_votes' AND policyname = 'Manga review votes are viewable by everyone') THEN
        CREATE POLICY "Manga review votes are viewable by everyone"
            ON public.scanio_manga_review_votes FOR SELECT
            USING (true);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_review_votes' AND policyname = 'Authenticated users can vote on manga reviews') THEN
        CREATE POLICY "Authenticated users can vote on manga reviews"
            ON public.scanio_manga_review_votes FOR INSERT
            WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_review_votes' AND policyname = 'Users can change their review votes') THEN
        CREATE POLICY "Users can change their review votes"
            ON public.scanio_manga_review_votes FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_review_votes' AND policyname = 'Users can remove their review votes') THEN
        CREATE POLICY "Users can remove their review votes"
            ON public.scanio_manga_review_votes FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- INDEXES for better performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_scanio_canonical_manga_normalized_title
    ON public.scanio_canonical_manga(normalized_title);

CREATE INDEX IF NOT EXISTS idx_scanio_manga_sources_canonical_id
    ON public.scanio_manga_sources(canonical_manga_id);

CREATE INDEX IF NOT EXISTS idx_scanio_manga_sources_source_manga
    ON public.scanio_manga_sources(source_id, manga_id);

CREATE INDEX IF NOT EXISTS idx_scanio_chapter_comments_canonical_manga
    ON public.scanio_chapter_comments(canonical_manga_id, chapter_number);

CREATE INDEX IF NOT EXISTS idx_scanio_chapter_comments_user_id
    ON public.scanio_chapter_comments(user_id);

CREATE INDEX IF NOT EXISTS idx_scanio_chapter_comments_parent_id
    ON public.scanio_chapter_comments(parent_comment_id);

CREATE INDEX IF NOT EXISTS idx_scanio_chapter_comments_score
    ON public.scanio_chapter_comments(score DESC);

CREATE INDEX IF NOT EXISTS idx_scanio_chapter_comments_created_at
    ON public.scanio_chapter_comments(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_scanio_manga_reviews_canonical_manga
    ON public.scanio_manga_reviews(canonical_manga_id);

CREATE INDEX IF NOT EXISTS idx_scanio_manga_reviews_user_id
    ON public.scanio_manga_reviews(user_id);

CREATE INDEX IF NOT EXISTS idx_scanio_manga_reviews_score
    ON public.scanio_manga_reviews(score DESC);

CREATE INDEX IF NOT EXISTS idx_scanio_manga_reviews_rating
    ON public.scanio_manga_reviews(rating DESC);

CREATE INDEX IF NOT EXISTS idx_scanio_chapter_comment_votes_comment_id
    ON public.scanio_chapter_comment_votes(comment_id);

CREATE INDEX IF NOT EXISTS idx_scanio_chapter_comment_votes_user_id
    ON public.scanio_chapter_comment_votes(user_id);

CREATE INDEX IF NOT EXISTS idx_scanio_manga_review_votes_review_id
    ON public.scanio_manga_review_votes(review_id);

CREATE INDEX IF NOT EXISTS idx_scanio_manga_review_votes_user_id
    ON public.scanio_manga_review_votes(user_id);


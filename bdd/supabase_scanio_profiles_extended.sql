-- ============================================================================
-- Scanio Extended Profiles - Historique, Rankings, Privacy
-- Execute AFTER supabase_scanio_schema.sql
-- ============================================================================

-- ============================================================================
-- UPDATE: Add privacy and bio to profiles
-- ============================================================================
DO $$ 
BEGIN
    -- Add is_public column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'scanio_profiles' AND column_name = 'is_public'
    ) THEN
        ALTER TABLE public.scanio_profiles ADD COLUMN is_public BOOLEAN DEFAULT true;
    END IF;

    -- Add bio column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'scanio_profiles' AND column_name = 'bio'
    ) THEN
        ALTER TABLE public.scanio_profiles ADD COLUMN bio TEXT;
    END IF;

    -- Add total_chapters_read column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'scanio_profiles' AND column_name = 'total_chapters_read'
    ) THEN
        ALTER TABLE public.scanio_profiles ADD COLUMN total_chapters_read INTEGER DEFAULT 0;
    END IF;

    -- Add total_manga_read column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'scanio_profiles' AND column_name = 'total_manga_read'
    ) THEN
        ALTER TABLE public.scanio_profiles ADD COLUMN total_manga_read INTEGER DEFAULT 0;
    END IF;
END $$;

-- ============================================================================
-- TABLE: Reading History (Historique de lecture)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_reading_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE NOT NULL,
    source_id TEXT NOT NULL,
    manga_id TEXT NOT NULL,
    chapter_number TEXT NOT NULL,
    chapter_title TEXT,
    page_number INTEGER DEFAULT 0,
    total_pages INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scanio_reading_history_user_manga_chapter_key'
    ) THEN
        ALTER TABLE public.scanio_reading_history 
        ADD CONSTRAINT scanio_reading_history_user_manga_chapter_key 
        UNIQUE (user_id, canonical_manga_id, chapter_number);
    END IF;
END $$;

ALTER TABLE public.scanio_reading_history ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_reading_history' AND policyname = 'Users can view own reading history') THEN
        CREATE POLICY "Users can view own reading history"
            ON public.scanio_reading_history FOR SELECT
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_reading_history' AND policyname = 'Users can insert own reading history') THEN
        CREATE POLICY "Users can insert own reading history"
            ON public.scanio_reading_history FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_reading_history' AND policyname = 'Users can update own reading history') THEN
        CREATE POLICY "Users can update own reading history"
            ON public.scanio_reading_history FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_reading_history' AND policyname = 'Users can delete own reading history') THEN
        CREATE POLICY "Users can delete own reading history"
            ON public.scanio_reading_history FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- TABLE: Personal Manga Rankings (Classement personnel)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_personal_rankings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE NOT NULL,
    rank_position INTEGER NOT NULL,
    personal_rating INTEGER CHECK (personal_rating >= 0 AND personal_rating <= 10),
    notes TEXT,
    is_favorite BOOLEAN DEFAULT false,
    reading_status TEXT CHECK (reading_status IN ('reading', 'completed', 'on_hold', 'dropped', 'plan_to_read')) DEFAULT 'reading',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scanio_personal_rankings_user_manga_key'
    ) THEN
        ALTER TABLE public.scanio_personal_rankings 
        ADD CONSTRAINT scanio_personal_rankings_user_manga_key 
        UNIQUE (user_id, canonical_manga_id);
    END IF;
END $$;

ALTER TABLE public.scanio_personal_rankings ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_personal_rankings' AND policyname = 'Users can view own rankings') THEN
        CREATE POLICY "Users can view own rankings"
            ON public.scanio_personal_rankings FOR SELECT
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_personal_rankings' AND policyname = 'Public rankings are viewable if profile is public') THEN
        CREATE POLICY "Public rankings are viewable if profile is public"
            ON public.scanio_personal_rankings FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM public.scanio_profiles 
                    WHERE id = scanio_personal_rankings.user_id 
                    AND is_public = true
                )
            );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_personal_rankings' AND policyname = 'Users can insert own rankings') THEN
        CREATE POLICY "Users can insert own rankings"
            ON public.scanio_personal_rankings FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_personal_rankings' AND policyname = 'Users can update own rankings') THEN
        CREATE POLICY "Users can update own rankings"
            ON public.scanio_personal_rankings FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_personal_rankings' AND policyname = 'Users can delete own rankings') THEN
        CREATE POLICY "Users can delete own rankings"
            ON public.scanio_personal_rankings FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- TABLE: Manga Progress (Progression par manga)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_manga_progress (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE NOT NULL,
    last_chapter_read TEXT,
    total_chapters_read INTEGER DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scanio_manga_progress_user_manga_key'
    ) THEN
        ALTER TABLE public.scanio_manga_progress 
        ADD CONSTRAINT scanio_manga_progress_user_manga_key 
        UNIQUE (user_id, canonical_manga_id);
    END IF;
END $$;

ALTER TABLE public.scanio_manga_progress ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_progress' AND policyname = 'Users can view own progress') THEN
        CREATE POLICY "Users can view own progress"
            ON public.scanio_manga_progress FOR SELECT
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_progress' AND policyname = 'Users can insert own progress') THEN
        CREATE POLICY "Users can insert own progress"
            ON public.scanio_manga_progress FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_progress' AND policyname = 'Users can update own progress') THEN
        CREATE POLICY "Users can update own progress"
            ON public.scanio_manga_progress FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_manga_progress' AND policyname = 'Users can delete own progress') THEN
        CREATE POLICY "Users can delete own progress"
            ON public.scanio_manga_progress FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- INDEXES for performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_scanio_reading_history_user_id 
    ON public.scanio_reading_history(user_id);

CREATE INDEX IF NOT EXISTS idx_scanio_reading_history_canonical_manga 
    ON public.scanio_reading_history(canonical_manga_id);

CREATE INDEX IF NOT EXISTS idx_scanio_reading_history_last_read 
    ON public.scanio_reading_history(user_id, last_read_at DESC);

CREATE INDEX IF NOT EXISTS idx_scanio_personal_rankings_user_id 
    ON public.scanio_personal_rankings(user_id);

CREATE INDEX IF NOT EXISTS idx_scanio_personal_rankings_rank 
    ON public.scanio_personal_rankings(user_id, rank_position);

CREATE INDEX IF NOT EXISTS idx_scanio_personal_rankings_favorites 
    ON public.scanio_personal_rankings(user_id, is_favorite) WHERE is_favorite = true;

CREATE INDEX IF NOT EXISTS idx_scanio_manga_progress_user_id 
    ON public.scanio_manga_progress(user_id);

CREATE INDEX IF NOT EXISTS idx_scanio_manga_progress_last_read 
    ON public.scanio_manga_progress(user_id, last_read_at DESC);


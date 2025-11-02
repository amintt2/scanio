-- ============================================================================
-- Scanio User Library Schema - CoreData Replication in Supabase
-- ============================================================================
-- This schema replicates CoreData entities in Supabase for cloud sync
-- Execute this SQL in your Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- TABLE: User Library (Réplique de LibraryMangaObject)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_user_library (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE NOT NULL,
    source_id TEXT NOT NULL,
    manga_id TEXT NOT NULL,
    date_added TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_opened TIMESTAMP WITH TIME ZONE,
    last_read TIMESTAMP WITH TIME ZONE,
    last_updated TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scanio_user_library_user_manga_key'
    ) THEN
        ALTER TABLE public.scanio_user_library 
        ADD CONSTRAINT scanio_user_library_user_manga_key 
        UNIQUE (user_id, canonical_manga_id);
    END IF;
END $$;

ALTER TABLE public.scanio_user_library ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_library' AND policyname = 'Users can view own library') THEN
        CREATE POLICY "Users can view own library"
            ON public.scanio_user_library FOR SELECT
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_library' AND policyname = 'Users can insert own library') THEN
        CREATE POLICY "Users can insert own library"
            ON public.scanio_user_library FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_library' AND policyname = 'Users can update own library') THEN
        CREATE POLICY "Users can update own library"
            ON public.scanio_user_library FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_library' AND policyname = 'Users can delete own library') THEN
        CREATE POLICY "Users can delete own library"
            ON public.scanio_user_library FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- TABLE: User Categories (Réplique de CategoryObject)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_user_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scanio_user_categories_user_title_key'
    ) THEN
        ALTER TABLE public.scanio_user_categories 
        ADD CONSTRAINT scanio_user_categories_user_title_key 
        UNIQUE (user_id, title);
    END IF;
END $$;

ALTER TABLE public.scanio_user_categories ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_categories' AND policyname = 'Users can view own categories') THEN
        CREATE POLICY "Users can view own categories"
            ON public.scanio_user_categories FOR SELECT
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_categories' AND policyname = 'Users can insert own categories') THEN
        CREATE POLICY "Users can insert own categories"
            ON public.scanio_user_categories FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_categories' AND policyname = 'Users can update own categories') THEN
        CREATE POLICY "Users can update own categories"
            ON public.scanio_user_categories FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_categories' AND policyname = 'Users can delete own categories') THEN
        CREATE POLICY "Users can delete own categories"
            ON public.scanio_user_categories FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- TABLE: User Library Categories (Liaison many-to-many)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_user_library_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_library_id UUID REFERENCES public.scanio_user_library(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES public.scanio_user_categories(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scanio_user_library_categories_library_category_key'
    ) THEN
        ALTER TABLE public.scanio_user_library_categories 
        ADD CONSTRAINT scanio_user_library_categories_library_category_key 
        UNIQUE (user_library_id, category_id);
    END IF;
END $$;

ALTER TABLE public.scanio_user_library_categories ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_library_categories' AND policyname = 'Users can view own library categories') THEN
        CREATE POLICY "Users can view own library categories"
            ON public.scanio_user_library_categories FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM public.scanio_user_library ul
                    WHERE ul.id = user_library_id AND ul.user_id = auth.uid()
                )
            );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_library_categories' AND policyname = 'Users can insert own library categories') THEN
        CREATE POLICY "Users can insert own library categories"
            ON public.scanio_user_library_categories FOR INSERT
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM public.scanio_user_library ul
                    WHERE ul.id = user_library_id AND ul.user_id = auth.uid()
                )
            );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_library_categories' AND policyname = 'Users can delete own library categories') THEN
        CREATE POLICY "Users can delete own library categories"
            ON public.scanio_user_library_categories FOR DELETE
            USING (
                EXISTS (
                    SELECT 1 FROM public.scanio_user_library ul
                    WHERE ul.id = user_library_id AND ul.user_id = auth.uid()
                )
            );
    END IF;
END $$;

-- ============================================================================
-- TABLE: User Trackers (Réplique de TrackObject)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scanio_user_trackers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE NOT NULL,
    tracker_id TEXT NOT NULL, -- 'myanimelist', 'anilist', 'kitsu', etc.
    tracker_manga_id TEXT NOT NULL,
    title TEXT,
    status TEXT,
    score REAL,
    progress INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if not exists
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'scanio_user_trackers_user_manga_tracker_key'
    ) THEN
        ALTER TABLE public.scanio_user_trackers 
        ADD CONSTRAINT scanio_user_trackers_user_manga_tracker_key 
        UNIQUE (user_id, canonical_manga_id, tracker_id);
    END IF;
END $$;

ALTER TABLE public.scanio_user_trackers ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_trackers' AND policyname = 'Users can view own trackers') THEN
        CREATE POLICY "Users can view own trackers"
            ON public.scanio_user_trackers FOR SELECT
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_trackers' AND policyname = 'Users can insert own trackers') THEN
        CREATE POLICY "Users can insert own trackers"
            ON public.scanio_user_trackers FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_trackers' AND policyname = 'Users can update own trackers') THEN
        CREATE POLICY "Users can update own trackers"
            ON public.scanio_user_trackers FOR UPDATE
            USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'scanio_user_trackers' AND policyname = 'Users can delete own trackers') THEN
        CREATE POLICY "Users can delete own trackers"
            ON public.scanio_user_trackers FOR DELETE
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- INDEXES for performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_scanio_user_library_user_id 
    ON public.scanio_user_library(user_id);

CREATE INDEX IF NOT EXISTS idx_scanio_user_library_canonical_manga 
    ON public.scanio_user_library(canonical_manga_id);

CREATE INDEX IF NOT EXISTS idx_scanio_user_library_updated_at 
    ON public.scanio_user_library(user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_scanio_user_categories_user_id 
    ON public.scanio_user_categories(user_id);

CREATE INDEX IF NOT EXISTS idx_scanio_user_trackers_user_id 
    ON public.scanio_user_trackers(user_id);

CREATE INDEX IF NOT EXISTS idx_scanio_user_trackers_canonical_manga 
    ON public.scanio_user_trackers(canonical_manga_id);

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Scanio User Library schema installed successfully!';
    RAISE NOTICE '📚 New tables: scanio_user_library, scanio_user_categories, scanio_user_library_categories, scanio_user_trackers';
    RAISE NOTICE '🔒 RLS policies enabled for all tables';
    RAISE NOTICE '⚡ Indexes created for performance';
    RAISE NOTICE '🔄 Ready for CoreData synchronization';
END $$;


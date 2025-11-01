-- Supabase Database Schema for Scanio
-- Execute this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    user_name TEXT,
    avatar_url TEXT,
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

-- Comments table
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chapter_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    parent_comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    likes_count INTEGER DEFAULT 0,
    replies_count INTEGER DEFAULT 0
);

-- Enable Row Level Security
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- Policies for comments
CREATE POLICY "Comments are viewable by authenticated users"
    ON public.comments FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create comments"
    ON public.comments FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can update own comments"
    ON public.comments FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
    ON public.comments FOR DELETE
    USING (auth.uid() = user_id);

-- Comment likes table
CREATE TABLE IF NOT EXISTS public.comment_likes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(comment_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;

-- Policies for comment_likes
CREATE POLICY "Comment likes are viewable by authenticated users"
    ON public.comment_likes FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can like comments"
    ON public.comment_likes FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can unlike comments"
    ON public.comment_likes FOR DELETE
    USING (auth.uid() = user_id);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_comments_chapter_id ON public.comments(chapter_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON public.comments(parent_comment_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON public.comments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comment_likes_comment_id ON public.comment_likes(comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_likes_user_id ON public.comment_likes(user_id);

-- Function to update likes_count when a like is added
CREATE OR REPLACE FUNCTION increment_comment_likes()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.comments
    SET likes_count = likes_count + 1
    WHERE id = NEW.comment_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update likes_count when a like is removed
CREATE OR REPLACE FUNCTION decrement_comment_likes()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.comments
    SET likes_count = likes_count - 1
    WHERE id = OLD.comment_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Function to update replies_count when a reply is added
CREATE OR REPLACE FUNCTION increment_comment_replies()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_comment_id IS NOT NULL THEN
        UPDATE public.comments
        SET replies_count = replies_count + 1
        WHERE id = NEW.parent_comment_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update replies_count when a reply is removed
CREATE OR REPLACE FUNCTION decrement_comment_replies()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.parent_comment_id IS NOT NULL THEN
        UPDATE public.comments
        SET replies_count = replies_count - 1
        WHERE id = OLD.parent_comment_id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Triggers for likes_count
CREATE TRIGGER on_comment_like_created
    AFTER INSERT ON public.comment_likes
    FOR EACH ROW
    EXECUTE FUNCTION increment_comment_likes();

CREATE TRIGGER on_comment_like_deleted
    AFTER DELETE ON public.comment_likes
    FOR EACH ROW
    EXECUTE FUNCTION decrement_comment_likes();

-- Triggers for replies_count
CREATE TRIGGER on_comment_reply_created
    AFTER INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION increment_comment_replies();

CREATE TRIGGER on_comment_reply_deleted
    AFTER DELETE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION decrement_comment_replies();

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, user_name, created_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'user_name', split_part(NEW.email, '@', 1)),
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

-- View to get comments with user information
CREATE OR REPLACE VIEW public.comments_with_users AS
SELECT 
    c.id,
    c.chapter_id,
    c.user_id,
    p.user_name,
    p.avatar_url AS user_avatar,
    c.content,
    c.parent_comment_id,
    c.created_at,
    c.updated_at,
    c.likes_count,
    c.replies_count
FROM public.comments c
LEFT JOIN public.profiles p ON c.user_id = p.id;

-- Grant access to the view
GRANT SELECT ON public.comments_with_users TO authenticated;


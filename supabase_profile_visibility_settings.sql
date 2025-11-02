-- PHASE 5, Task 5.2: Create profile visibility settings table
-- This table controls what information is visible on a user's public profile

CREATE TABLE IF NOT EXISTS public.scanio_profile_visibility_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    show_history BOOLEAN DEFAULT true,
    show_rankings BOOLEAN DEFAULT true,
    show_stats BOOLEAN DEFAULT true,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.scanio_profile_visibility_settings ENABLE ROW LEVEL SECURITY;

-- Users can view their own settings
DROP POLICY IF EXISTS "Users can view their own settings" ON public.scanio_profile_visibility_settings;
CREATE POLICY "Users can view their own settings"
ON public.scanio_profile_visibility_settings FOR SELECT
USING (auth.uid() = user_id);

-- Users can view public settings (for displaying public profiles)
DROP POLICY IF EXISTS "Users can view public settings" ON public.scanio_profile_visibility_settings;
CREATE POLICY "Users can view public settings"
ON public.scanio_profile_visibility_settings FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM scanio_profiles
        WHERE id = user_id AND is_public = true
    )
);

-- Users can update their own settings
DROP POLICY IF EXISTS "Users can update their own settings" ON public.scanio_profile_visibility_settings;
CREATE POLICY "Users can update their own settings"
ON public.scanio_profile_visibility_settings FOR UPDATE
USING (auth.uid() = user_id);

-- Users can insert their own settings
DROP POLICY IF EXISTS "Users can insert their own settings" ON public.scanio_profile_visibility_settings;
CREATE POLICY "Users can insert their own settings"
ON public.scanio_profile_visibility_settings FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Create default settings for existing users
INSERT INTO public.scanio_profile_visibility_settings (user_id, show_history, show_rankings, show_stats)
SELECT id, true, true, true
FROM scanio_profiles
WHERE id NOT IN (SELECT user_id FROM scanio_profile_visibility_settings)
ON CONFLICT (user_id) DO NOTHING;


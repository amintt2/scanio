-- ============================================
-- 🔍 DIAGNOSTIC COMPLET SUPABASE - TomoScan
-- ============================================
-- Exécutez ce script dans Supabase SQL Editor
-- pour diagnostiquer tous les problèmes potentiels
-- ============================================

-- ============================================
-- 1️⃣ VÉRIFICATION DES TABLES
-- ============================================

SELECT '=== 1. VÉRIFICATION DES TABLES ===' as section;

-- Lister toutes les tables scanio_*
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name LIKE 'scanio_%'
ORDER BY table_name;

-- ============================================
-- 2️⃣ VÉRIFICATION DES FONCTIONS
-- ============================================

SELECT '=== 2. VÉRIFICATION DES FONCTIONS ===' as section;

-- Lister toutes les fonctions scanio_*
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE 'scanio_%'
ORDER BY routine_name;

-- ============================================
-- 3️⃣ VÉRIFICATION DES VUES
-- ============================================

SELECT '=== 3. VÉRIFICATION DES VUES ===' as section;

-- Lister toutes les vues scanio_*
SELECT 
    table_name as view_name,
    view_definition
FROM information_schema.views
WHERE table_schema = 'public'
AND table_name LIKE 'scanio_%'
ORDER BY table_name;

-- ============================================
-- 4️⃣ VÉRIFICATION DES RLS POLICIES
-- ============================================

SELECT '=== 4. VÉRIFICATION DES RLS POLICIES ===' as section;

-- Lister toutes les policies sur les tables scanio_*
SELECT 
    tablename,
    policyname,
    permissive,
    cmd,
    CASE 
        WHEN qual IS NOT NULL THEN 'WITH CHECK'
        ELSE 'USING'
    END as policy_type
FROM pg_policies
WHERE schemaname = 'public'
AND tablename LIKE 'scanio_%'
ORDER BY tablename, policyname;

-- ============================================
-- 5️⃣ COMPTAGE DES DONNÉES
-- ============================================

SELECT '=== 5. COMPTAGE DES DONNÉES ===' as section;

-- Compter les enregistrements dans chaque table
SELECT 'scanio_profiles' as table_name, COUNT(*) as count FROM scanio_profiles
UNION ALL
SELECT 'scanio_reading_history', COUNT(*) FROM scanio_reading_history
UNION ALL
SELECT 'scanio_personal_rankings', COUNT(*) FROM scanio_personal_rankings
UNION ALL
SELECT 'scanio_canonical_manga', COUNT(*) FROM scanio_canonical_manga
UNION ALL
SELECT 'scanio_chapter_comments', COUNT(*) FROM scanio_chapter_comments
UNION ALL
SELECT 'scanio_profile_visibility_settings', COUNT(*) FROM scanio_profile_visibility_settings
ORDER BY table_name;

-- ============================================
-- 6️⃣ TEST DE LA FONCTION scanio_get_user_stats
-- ============================================

SELECT '=== 6. TEST DE scanio_get_user_stats ===' as section;

-- Vérifier que la fonction existe
SELECT 
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'scanio_get_user_stats';

-- Tester la fonction avec l'utilisateur actuel
SELECT * FROM scanio_get_user_stats(auth.uid());

-- ============================================
-- 7️⃣ VÉRIFICATION DES DONNÉES UTILISATEUR
-- ============================================

SELECT '=== 7. DONNÉES DE L''UTILISATEUR ACTUEL ===' as section;

-- Profil
SELECT 'Profile' as data_type, * FROM scanio_profiles WHERE id = auth.uid();

-- Historique de lecture
SELECT 'Reading History Count' as data_type, COUNT(*) as count 
FROM scanio_reading_history 
WHERE user_id = auth.uid();

-- Chapitres distincts lus
SELECT 'Distinct Chapters Read' as data_type, COUNT(DISTINCT chapter_id) as count 
FROM scanio_reading_history 
WHERE user_id = auth.uid();

-- Mangas distincts lus
SELECT 'Distinct Manga Read' as data_type, COUNT(DISTINCT canonical_manga_id) as count 
FROM scanio_reading_history 
WHERE user_id = auth.uid();

-- Favoris
SELECT 'Favorites Count' as data_type, COUNT(*) as count 
FROM scanio_personal_rankings 
WHERE user_id = auth.uid() AND is_favorite = true;

-- Commentaires
SELECT 'Comments Count' as data_type, COUNT(*) as count 
FROM scanio_chapter_comments 
WHERE user_id = auth.uid();

-- Paramètres de visibilité
SELECT 'Visibility Settings' as data_type, * 
FROM scanio_profile_visibility_settings 
WHERE user_id = auth.uid();

-- ============================================
-- 8️⃣ VÉRIFICATION DES VUES AVEC MANGA
-- ============================================

SELECT '=== 8. TEST DES VUES AVEC MANGA ===' as section;

-- Test de scanio_reading_history_with_manga
SELECT 'Reading History with Manga' as view_name, COUNT(*) as count
FROM scanio_reading_history_with_manga
WHERE user_id = auth.uid();

-- Test de scanio_personal_rankings_with_manga
SELECT 'Personal Rankings with Manga' as view_name, COUNT(*) as count
FROM scanio_personal_rankings_with_manga
WHERE user_id = auth.uid();

-- ============================================
-- 9️⃣ VÉRIFICATION DES INDEX
-- ============================================

SELECT '=== 9. VÉRIFICATION DES INDEX ===' as section;

-- Lister tous les index sur les tables scanio_*
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename LIKE 'scanio_%'
ORDER BY tablename, indexname;

-- ============================================
-- 🔟 DIAGNOSTIC DES PROBLÈMES POTENTIELS
-- ============================================

SELECT '=== 10. DIAGNOSTIC DES PROBLÈMES ===' as section;

-- Vérifier les profils sans stats
SELECT 'Profiles without stats' as issue, COUNT(*) as count
FROM scanio_profiles p
WHERE NOT EXISTS (
    SELECT 1 FROM scanio_reading_history rh WHERE rh.user_id = p.id
);

-- Vérifier les historiques sans manga canonique
SELECT 'History without canonical manga' as issue, COUNT(*) as count
FROM scanio_reading_history rh
WHERE NOT EXISTS (
    SELECT 1 FROM scanio_canonical_manga cm WHERE cm.id = rh.canonical_manga_id
);

-- Vérifier les rankings sans manga canonique
SELECT 'Rankings without canonical manga' as issue, COUNT(*) as count
FROM scanio_personal_rankings pr
WHERE NOT EXISTS (
    SELECT 1 FROM scanio_canonical_manga cm WHERE cm.id = pr.canonical_manga_id
);

-- Vérifier les utilisateurs sans paramètres de visibilité
SELECT 'Users without visibility settings' as issue, COUNT(*) as count
FROM scanio_profiles p
WHERE NOT EXISTS (
    SELECT 1 FROM scanio_profile_visibility_settings vs WHERE vs.user_id = p.id
);

-- ============================================
-- 1️⃣1️⃣ EXEMPLE DE DONNÉES
-- ============================================

SELECT '=== 11. EXEMPLES DE DONNÉES ===' as section;

-- 5 derniers historiques de lecture
SELECT 'Last 5 Reading History' as example_type;
SELECT * FROM scanio_reading_history_with_manga
WHERE user_id = auth.uid()
ORDER BY last_read_at DESC
LIMIT 5;

-- 5 premiers favoris
SELECT 'Top 5 Favorites' as example_type;
SELECT * FROM scanio_personal_rankings_with_manga
WHERE user_id = auth.uid() AND is_favorite = true
ORDER BY rank_position ASC
LIMIT 5;

-- ============================================
-- 1️⃣2️⃣ RÉSUMÉ FINAL
-- ============================================

SELECT '=== 12. RÉSUMÉ FINAL ===' as section;

SELECT 
    'User ID' as info,
    auth.uid()::text as value
UNION ALL
SELECT 
    'Profile exists',
    CASE WHEN EXISTS (SELECT 1 FROM scanio_profiles WHERE id = auth.uid()) 
        THEN '✅ Yes' 
        ELSE '❌ No' 
    END
UNION ALL
SELECT 
    'Reading history count',
    COUNT(*)::text
FROM scanio_reading_history
WHERE user_id = auth.uid()
UNION ALL
SELECT 
    'Favorites count',
    COUNT(*)::text
FROM scanio_personal_rankings
WHERE user_id = auth.uid() AND is_favorite = true
UNION ALL
SELECT 
    'Comments count',
    COUNT(*)::text
FROM scanio_chapter_comments
WHERE user_id = auth.uid()
UNION ALL
SELECT 
    'Visibility settings exist',
    CASE WHEN EXISTS (SELECT 1 FROM scanio_profile_visibility_settings WHERE user_id = auth.uid()) 
        THEN '✅ Yes' 
        ELSE '❌ No' 
    END;

-- ============================================
-- FIN DU DIAGNOSTIC
-- ============================================

SELECT '=== ✅ DIAGNOSTIC TERMINÉ ===' as section;


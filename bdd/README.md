# 🗄️ Base de Données - TomoScan

Documentation et scripts SQL pour la base de données Supabase de TomoScan.

## 📁 Structure

```
bdd/
├── Schema (Création de tables)
├── Functions (Fonctions SQL)
├── Triggers (Déclencheurs)
├── Fixes (Corrections)
└── Diagnostic (Outils de diagnostic)
```

## 📊 Fichiers par Catégorie

### 🏗️ Schema - Création de Tables

**Schémas principaux** :
- **`supabase_schema.sql`** - Schéma de base complet
- **`supabase_scanio_schema.sql`** - Schéma étendu TomoScan

**Schémas spécifiques** :
- **`supabase_scanio_profiles_extended.sql`** - Tables de profils utilisateur
- **`supabase_user_library_schema.sql`** - Bibliothèque utilisateur (favoris, lecture)
- **`supabase_user_sources_schema.sql`** - Sources personnalisées par utilisateur
- **`supabase_user_presence_schema.sql`** - ✅ **Système de présence en ligne** (nouveau)

### ⚙️ Functions - Fonctions SQL

**Fonctions principales** :
- **`supabase_scanio_functions.sql`** - Fonctions générales
- **`supabase_scanio_profiles_functions.sql`** - Fonctions de profil
- **`supabase_user_library_functions.sql`** - Fonctions de bibliothèque

**Fonctions spécifiques** :
- **`supabase_fix_user_stats_function.sql`** - Calcul des statistiques utilisateur
- **`supabase_update_favorites_count.sql`** - Mise à jour du compteur de favoris
- **`supabase_add_comments_stat.sql`** - Statistiques de commentaires

### 🔔 Triggers - Déclencheurs

- **`supabase_scanio_triggers.sql`** - Tous les triggers de l'application
  - Mise à jour automatique des timestamps
  - Calcul automatique des statistiques
  - Synchronisation des compteurs

### 🔧 Fixes - Corrections

- **`supabase_fix_upsert_reading_history.sql`** - Correction de l'historique de lecture
- **`supabase_fix_user_stats_function.sql`** - Correction du calcul des stats
- **`supabase_profile_visibility_settings.sql`** - Paramètres de visibilité du profil

### 🔍 Diagnostic - Outils de Diagnostic

- **`supabase_diagnostic.sql`** - Script de diagnostic complet
  - Vérification des tables
  - Vérification des fonctions
  - Vérification des triggers
  - Vérification des RLS policies
  - Statistiques de la base

- **`check_tables.sql`** - Vérification rapide des tables

## 🚀 Utilisation

### 1. Installation Initiale

Exécutez les scripts dans cet ordre :

```sql
-- 1. Créer le schéma de base
\i supabase_schema.sql

-- 2. Créer le schéma étendu
\i supabase_scanio_schema.sql

-- 3. Créer les tables de profils
\i supabase_scanio_profiles_extended.sql

-- 4. Créer les tables de bibliothèque
\i supabase_user_library_schema.sql

-- 5. Créer les tables de sources
\i supabase_user_sources_schema.sql

-- 6. Créer les tables de présence en ligne
\i supabase_user_presence_schema.sql

-- 7. Créer les fonctions
\i supabase_scanio_functions.sql
\i supabase_scanio_profiles_functions.sql
\i supabase_user_library_functions.sql

-- 8. Créer les triggers
\i supabase_scanio_triggers.sql

-- 9. Activer Realtime pour la présence
ALTER PUBLICATION supabase_realtime ADD TABLE scanio_user_presence;
```

### 2. Appliquer les Corrections

Si vous mettez à jour une base existante :

```sql
-- Corrections des fonctions
\i supabase_fix_user_stats_function.sql
\i supabase_fix_upsert_reading_history.sql
\i supabase_update_favorites_count.sql
\i supabase_add_comments_stat.sql
\i supabase_profile_visibility_settings.sql
```

### 3. Diagnostic

Pour vérifier l'état de la base :

```sql
-- Diagnostic complet
\i supabase_diagnostic.sql

-- Vérification rapide
\i check_tables.sql
```

## 📋 Tables Principales

### Profils Utilisateur
- `user_profiles` - Profils utilisateur de base
- `user_stats` - Statistiques de lecture
- `user_profile_visibility` - Paramètres de visibilité

### Bibliothèque
- `user_library` - Mangas dans la bibliothèque
- `reading_history` - Historique de lecture
- `user_favorites` - Favoris

### Rankings & Social
- `personal_rankings` - Classements personnels
- `comments` - Commentaires sur les mangas
- `comment_likes` - Likes sur les commentaires

### Sources
- `user_sources` - Sources personnalisées
- `user_source_manga` - Mangas des sources personnalisées

### Présence en Ligne ✅ NOUVEAU
- `scanio_user_presence` - Statut en ligne/hors ligne des utilisateurs
  - `user_id` : ID de l'utilisateur
  - `is_online` : Statut en ligne (boolean)
  - `last_seen` : Dernière activité (timestamp)
  - `updated_at` : Dernière mise à jour (timestamp)
  - Realtime activé pour mises à jour en temps réel

## 🔐 Row Level Security (RLS)

Toutes les tables ont des politiques RLS activées :

- **SELECT** : Utilisateurs authentifiés peuvent voir leurs propres données + données publiques
- **INSERT** : Utilisateurs peuvent créer leurs propres données
- **UPDATE** : Utilisateurs peuvent modifier leurs propres données
- **DELETE** : Utilisateurs peuvent supprimer leurs propres données

## 🔄 Synchronisation

Les données sont synchronisées entre :
- **Supabase** (source de vérité)
- **CoreData** (cache local iOS/macOS)

Voir [`../docs/features/COREDATA_SUPABASE_SYNC_PLAN.md`](../docs/features/COREDATA_SUPABASE_SYNC_PLAN.md) pour plus de détails.

## 🧪 Tests

Pour tester les fonctions SQL :

```sql
-- Tester la création de profil
SELECT create_user_profile('test-user-id', 'testuser');

-- Tester les statistiques
SELECT * FROM get_user_stats('test-user-id');

-- Tester l'historique
SELECT * FROM get_reading_history('test-user-id', 10);
```

## 📊 Fonctions Principales

### Profils
- `create_user_profile(user_id, username)` - Créer un profil
- `get_user_stats(user_id)` - Obtenir les statistiques
- `update_user_stats(user_id)` - Mettre à jour les stats

### Bibliothèque
- `upsert_reading_history(...)` - Ajouter/Mettre à jour l'historique
- `get_reading_history(user_id, limit)` - Obtenir l'historique
- `add_to_favorites(user_id, manga_id)` - Ajouter aux favoris

### Rankings
- `get_personal_rankings(user_id)` - Obtenir les classements
- `upsert_personal_ranking(...)` - Créer/Mettre à jour un classement

### Présence en Ligne ✅ NOUVEAU
- `scanio_update_user_presence(p_is_online)` - Mettre à jour le statut de l'utilisateur connecté
- `scanio_get_user_presence(p_user_id)` - Récupérer le statut d'un utilisateur
- `scanio_get_users_presence(p_user_ids[])` - Récupérer le statut de plusieurs utilisateurs (batch)
- `scanio_cleanup_stale_presence()` - Nettoyer les statuts obsolètes (>5 min)

## 🔍 Diagnostic Rapide

```sql
-- Vérifier les tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Vérifier les fonctions
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
ORDER BY routine_name;

-- Vérifier les triggers
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
ORDER BY event_object_table, trigger_name;

-- Compter les enregistrements
SELECT 
  'user_profiles' as table_name, COUNT(*) as count FROM user_profiles
UNION ALL
SELECT 'user_library', COUNT(*) FROM user_library
UNION ALL
SELECT 'reading_history', COUNT(*) FROM reading_history;
```

## 🛠️ Maintenance

### Backup
```bash
# Backup complet
pg_dump -h your-supabase-host -U postgres -d postgres > backup.sql

# Backup d'une table
pg_dump -h your-supabase-host -U postgres -d postgres -t user_profiles > user_profiles_backup.sql
```

### Restore
```bash
psql -h your-supabase-host -U postgres -d postgres < backup.sql
```

## 📝 Conventions

### Nommage
- **Tables** : `snake_case` au pluriel (ex: `user_profiles`)
- **Fonctions** : `snake_case` avec verbe (ex: `get_user_stats`)
- **Triggers** : `trigger_` + action (ex: `trigger_update_stats`)

### Timestamps
Toutes les tables ont :
- `created_at TIMESTAMPTZ DEFAULT NOW()`
- `updated_at TIMESTAMPTZ DEFAULT NOW()`

Avec trigger automatique pour `updated_at`.

## 🔗 Liens Utiles

- [Documentation Supabase](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Documentation TomoScan](../docs/README.md)

## 🟢 Nouveautés - Système de Présence en Ligne

### Vue d'ensemble
Le système de présence en ligne permet de suivre le statut en ligne/hors ligne des utilisateurs en temps réel.

### Fonctionnalités
- ✅ Statut en ligne/hors ligne automatique
- ✅ Indicateur "Vu il y a X min/h/j"
- ✅ Mise à jour en temps réel avec Supabase Realtime
- ✅ Cleanup automatique des utilisateurs inactifs (>5 min)
- ✅ Support pour fonctionnalités futures (chat, amis, commentaires)

### Déploiement
1. Exécuter `supabase_user_presence_schema.sql` dans Supabase SQL Editor
2. Activer Realtime :
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE scanio_user_presence;
   ```
3. (Optionnel) Configurer le cleanup automatique avec pg_cron :
   ```sql
   SELECT cron.schedule(
       'cleanup-stale-presence',
       '*/5 * * * *',
       $$SELECT scanio_cleanup_stale_presence()$$
   );
   ```

### Utilisation dans l'App
```swift
// Marquer comme en ligne
await SupabaseManager.shared.setOnline()

// Marquer comme hors ligne
await SupabaseManager.shared.setOffline()

// Récupérer le statut d'un utilisateur
let presence = try await SupabaseManager.shared.getUserPresence(userId: "...")

// Récupérer le statut de plusieurs utilisateurs (batch)
let presences = try await SupabaseManager.shared.getUsersPresence(userIds: [...])
```

### Fonctionnalités Futures Préparées
Voir [`../docs/features/FUTURE_FEATURES.md`](../docs/features/FUTURE_FEATURES.md) pour plus de détails :
- 💬 Chat en temps réel
- 👥 Liste d'amis
- 💬 Indicateurs dans les commentaires
- 🧹 Cleanup automatique

---

**Dernière mise à jour** : 2025-11-07
**Version** : 1.1 - Ajout du système de présence en ligne


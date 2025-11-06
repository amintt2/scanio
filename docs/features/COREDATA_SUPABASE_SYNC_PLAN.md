# 🔄 Plan de synchronisation CoreData ↔ Supabase

## 📋 Analyse de l'architecture actuelle

### ✅ Ce qui existe déjà

#### **CoreData (Local)**
- `LibraryMangaObject` : Mangas dans la bibliothèque locale
- `HistoryObject` : Historique de lecture (chapitres lus, progression)
- `MangaObject` : Métadonnées des mangas
- `ChapterObject` : Chapitres disponibles
- `CategoryObject` : Catégories personnalisées
- `TrackObject` : Liens avec trackers externes (MAL, AniList, etc.)

#### **Supabase (Cloud)**
- `scanio_reading_history` : Historique de lecture par chapitre
- `scanio_manga_progress` : Progression globale par manga
- `scanio_personal_rankings` : Classement personnel / favoris
- `scanio_canonical_manga` : Mangas canoniques (dédupliqués)
- `scanio_manga_sources` : Liens source → manga canonique
- `scanio_profiles` : Profils utilisateurs avec stats

#### **Synchronisation actuelle**
✅ **Reading History** : Déjà synchronisé dans `HistoryManager.swift`
- Quand un chapitre est lu → `syncProgressToSupabase()`
- Quand un chapitre est complété → `syncCompletedToSupabase()`
- Utilise la fonction RPC `scanio_upsert_reading_history()`

❌ **Library Manga** : PAS synchronisé
❌ **Categories** : PAS synchronisé
❌ **Trackers** : PAS synchronisé

---

## 🎯 Objectifs

### 1. **Éviter les doublons**
- Utiliser `canonical_manga_id` comme clé unique
- Synchroniser bidirectionnellement (CoreData ↔ Supabase)
- Gérer les conflits avec timestamps

### 2. **Code plus propre**
- Centraliser la logique de sync dans un `SyncManager`
- Utiliser des fonctions RPC Supabase pour les opérations complexes
- Éviter les appels directs à l'API REST

### 3. **Réplication complète**
- Library Manga → `scanio_user_library` (nouvelle table)
- Categories → `scanio_user_categories` (nouvelle table)
- Trackers → `scanio_user_trackers` (nouvelle table)

---

## 📊 Nouvelles tables Supabase nécessaires

### **1. `scanio_user_library`**
Réplique de `LibraryMangaObject` dans Supabase.

```sql
CREATE TABLE public.scanio_user_library (
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, canonical_manga_id)
);
```

### **2. `scanio_user_categories`**
Réplique de `CategoryObject` dans Supabase.

```sql
CREATE TABLE public.scanio_user_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, title)
);
```

### **3. `scanio_user_library_categories`**
Table de liaison entre library et categories.

```sql
CREATE TABLE public.scanio_user_library_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_library_id UUID REFERENCES public.scanio_user_library(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES public.scanio_user_categories(id) ON DELETE CASCADE NOT NULL,
    UNIQUE(user_library_id, category_id)
);
```

### **4. `scanio_user_trackers`**
Réplique de `TrackObject` dans Supabase.

```sql
CREATE TABLE public.scanio_user_trackers (
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, canonical_manga_id, tracker_id)
);
```

---

## 🔧 Architecture de synchronisation

### **SyncManager.swift** (nouveau fichier)

```swift
class SyncManager {
    static let shared = SyncManager()
    
    private let coreData = CoreDataManager.shared
    private let supabase = SupabaseManager.shared
    
    // MARK: - Library Sync
    
    /// Sync library manga to Supabase
    func syncLibraryToSupabase() async throws
    
    /// Fetch library from Supabase and merge with CoreData
    func syncLibraryFromSupabase() async throws
    
    /// Bidirectional sync (merge both ways)
    func syncLibrary() async throws
    
    // MARK: - Category Sync
    
    func syncCategoriesToSupabase() async throws
    func syncCategoriesFromSupabase() async throws
    func syncCategories() async throws
    
    // MARK: - Tracker Sync
    
    func syncTrackersToSupabase() async throws
    func syncTrackersFromSupabase() async throws
    func syncTrackers() async throws
    
    // MARK: - Full Sync
    
    /// Sync everything (library, categories, trackers, history)
    func syncAll() async throws {
        try await syncLibrary()
        try await syncCategories()
        try await syncTrackers()
        // Reading history is already synced in HistoryManager
    }
}
```

---

## 🚀 Plan d'implémentation

### **PHASE 1 : Créer les tables Supabase**
1. Créer `supabase_user_library_schema.sql`
2. Exécuter dans Supabase SQL Editor
3. Vérifier les RLS policies

### **PHASE 2 : Créer les fonctions RPC**
1. `scanio_upsert_user_library()` : Ajouter/mettre à jour un manga dans la bibliothèque
2. `scanio_remove_from_library()` : Retirer un manga de la bibliothèque
3. `scanio_sync_library()` : Synchroniser toute la bibliothèque
4. Fonctions similaires pour categories et trackers

### **PHASE 3 : Créer SyncManager**
1. Créer `Shared/Managers/SyncManager.swift`
2. Implémenter `syncLibraryToSupabase()`
3. Implémenter `syncLibraryFromSupabase()`
4. Implémenter la résolution de conflits (last-write-wins avec timestamps)

### **PHASE 4 : Intégrer dans l'app**
1. Appeler `SyncManager.shared.syncAll()` au lancement de l'app
2. Appeler `syncLibrary()` quand un manga est ajouté/retiré
3. Appeler `syncCategories()` quand une catégorie est créée/modifiée
4. Appeler `syncTrackers()` quand un tracker est lié/délié

### **PHASE 5 : Gérer les conflits**
1. Utiliser `updated_at` pour déterminer la version la plus récente
2. En cas de conflit, prendre la version la plus récente
3. Logger les conflits pour debugging

### **PHASE 6 : Tests et validation**
1. Tester l'ajout d'un manga → vérifier sync Supabase
2. Tester la suppression d'un manga → vérifier sync Supabase
3. Tester la modification de catégories → vérifier sync
4. Tester sur 2 appareils différents → vérifier merge

---

## ⚠️ Points d'attention

### **1. Conflits de synchronisation**
- **Problème** : Deux appareils modifient le même manga en même temps
- **Solution** : Last-write-wins avec `updated_at`

### **2. Performance**
- **Problème** : Synchroniser toute la bibliothèque peut être lent
- **Solution** : Sync incrémental (seulement les changements depuis le dernier sync)

### **3. Offline-first**
- **Problème** : L'app doit fonctionner sans connexion
- **Solution** : CoreData reste la source de vérité, Supabase est un backup

### **4. Migration des données existantes**
- **Problème** : Les utilisateurs ont déjà des données dans CoreData
- **Solution** : Première sync = upload complet vers Supabase

---

## 📝 Prochaines étapes

1. **Créer les tables Supabase** (PHASE 1)
2. **Créer les fonctions RPC** (PHASE 2)
3. **Implémenter SyncManager** (PHASE 3)
4. **Tester la synchronisation** (PHASE 6)

**Voulez-vous que je commence par la PHASE 1 ?**


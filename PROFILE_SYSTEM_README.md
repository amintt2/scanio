# 📱 Système de Profil Utilisateur Scanio

## 🎯 Vue d'ensemble

Système complet de profil utilisateur avec :
- ✅ Création de compte et authentification
- ✅ Historique de lecture automatique
- ✅ Classement personnel des mangas
- ✅ Profil public/privé
- ✅ Statistiques de lecture
- ✅ Favoris et statuts de lecture

## 📦 Fichiers créés

### SQL (Base de données)

1. **`supabase_scanio_profiles_extended.sql`**
   - Extension de la table `scanio_profiles` avec bio, privacy, stats
   - Table `scanio_reading_history` - Historique de lecture par chapitre
   - Table `scanio_personal_rankings` - Classement personnel avec notes
   - Table `scanio_manga_progress` - Progression par manga
   - Index pour performance

2. **`supabase_scanio_profiles_functions.sql`**
   - Fonctions PostgreSQL pour stats et classements
   - Triggers automatiques pour mise à jour des compteurs
   - Vues avec jointures (reading_history_with_manga, etc.)

### Swift (Modèles)

3. **`Shared/Models/UserProfile.swift`**
   - `UserProfile` - Profil utilisateur étendu
   - `UserStats` - Statistiques de lecture
   - `ReadingHistory` - Historique de lecture
   - `PersonalRanking` - Classement personnel
   - `MangaProgress` - Progression par manga
   - `ReadingStatus` - Enum pour statuts (reading, completed, etc.)

### Swift (Managers)

4. **`Shared/Managers/SupabaseManager.swift`** (modifié)
   - `fetchProfile()` - Récupérer le profil
   - `updateProfile()` - Mettre à jour le profil
   - `fetchUserStats()` - Récupérer les statistiques
   - `upsertReadingHistory()` - Enregistrer la lecture
   - `fetchReadingHistory()` - Historique de lecture
   - `fetchCurrentlyReading()` - Mangas en cours

5. **`Shared/Managers/SupabaseManager+Rankings.swift`**
   - `upsertPersonalRanking()` - Ajouter/modifier un classement
   - `fetchPersonalRankings()` - Récupérer le classement
   - `fetchFavorites()` - Récupérer les favoris
   - `fetchByReadingStatus()` - Filtrer par statut
   - `deletePersonalRanking()` - Supprimer un classement
   - `getOrCreateCanonicalManga()` - Helper pour manga canonique

### Swift (Vues)

6. **`iOS/UI/Settings/ProfileSettingsView.swift`**
   - Vue principale du profil dans les settings
   - Affichage des stats et du profil
   - Toggle public/privé
   - Navigation vers historique et classements

7. **`iOS/UI/Settings/SignUpView.swift`**
   - Formulaire de création de compte
   - Validation email/password
   - Confirmation par email

8. **`iOS/UI/Settings/SignInView.swift`**
   - Formulaire de connexion
   - Renvoi d'email de confirmation

## 🗄️ Structure de la base de données

### scanio_profiles (étendu)
```sql
- id (UUID)
- user_name (TEXT)
- avatar_url (TEXT)
- bio (TEXT) ← NOUVEAU
- karma (INTEGER)
- is_public (BOOLEAN) ← NOUVEAU
- total_chapters_read (INTEGER) ← NOUVEAU
- total_manga_read (INTEGER) ← NOUVEAU
- created_at, updated_at
```

### scanio_reading_history
```sql
- id (UUID)
- user_id (UUID)
- canonical_manga_id (UUID)
- source_id (TEXT)
- manga_id (TEXT)
- chapter_number (TEXT)
- chapter_title (TEXT)
- page_number (INTEGER)
- total_pages (INTEGER)
- is_completed (BOOLEAN)
- last_read_at (TIMESTAMP)
- created_at (TIMESTAMP)

UNIQUE(user_id, canonical_manga_id, chapter_number)
```

### scanio_personal_rankings
```sql
- id (UUID)
- user_id (UUID)
- canonical_manga_id (UUID)
- rank_position (INTEGER)
- personal_rating (INTEGER) -- 0-10
- notes (TEXT)
- is_favorite (BOOLEAN)
- reading_status (TEXT) -- reading, completed, on_hold, dropped, plan_to_read
- created_at, updated_at

UNIQUE(user_id, canonical_manga_id)
```

### scanio_manga_progress
```sql
- id (UUID)
- user_id (UUID)
- canonical_manga_id (UUID)
- last_chapter_read (TEXT)
- total_chapters_read (INTEGER)
- started_at (TIMESTAMP)
- last_read_at (TIMESTAMP)
- updated_at (TIMESTAMP)

UNIQUE(user_id, canonical_manga_id)
```

## 🔄 Flux de données

### 1. Création de compte
```
User remplit formulaire → SignUpView
    ↓
SupabaseManager.signUp(email, password, userName)
    ↓
Supabase Auth crée l'utilisateur
    ↓
Trigger auto-create profile dans scanio_profiles
    ↓
Email de confirmation envoyé
```

### 2. Enregistrement de lecture
```
User lit un chapitre → ReaderViewController
    ↓
SupabaseManager.getOrCreateCanonicalManga(title, sourceId, mangaId)
    ↓
Retourne canonical_manga_id
    ↓
SupabaseManager.upsertReadingHistory(
    canonicalMangaId,
    chapterNumber,
    pageNumber,
    ...
)
    ↓
Trigger met à jour scanio_manga_progress
    ↓
Trigger met à jour total_chapters_read dans scanio_profiles
```

### 3. Ajout au classement personnel
```
User ajoute manga aux favoris
    ↓
SupabaseManager.upsertPersonalRanking(
    canonicalMangaId,
    isFavorite: true,
    readingStatus: .reading,
    personalRating: 9
)
    ↓
Trigger auto-assign rank_position si null
    ↓
Manga ajouté au classement
```

## 📱 Intégration dans l'app

### Ajouter dans Settings.swift

```swift
// Dans iOS/New/Views/Settings/Settings.swift
.init(
    key: "Profile",
    title: "Profil",
    value: .page(.init(
        items: [],
        inlineTitle: true,
        icon: .system(name: "person.circle.fill", color: "purple")
    ))
)
```

### Ajouter dans SettingsView.swift

```swift
// Dans pageContentHandler
else if key == "Profile" {
    ProfileSettingsView()
}
```

### Enregistrer la lecture dans ReaderViewController

```swift
// Dans ReaderViewController.swift, quand l'utilisateur change de page
func pageDidChange(to page: Int) {
    guard let chapter = self.chapter,
          let manga = self.manga else { return }
    
    Task {
        do {
            // Get or create canonical manga
            let canonicalId = try await SupabaseManager.shared.getOrCreateCanonicalManga(
                title: manga.title ?? "",
                sourceId: manga.sourceId,
                mangaId: manga.id
            )
            
            // Update reading history
            try await SupabaseManager.shared.upsertReadingHistory(
                canonicalMangaId: canonicalId,
                sourceId: manga.sourceId,
                mangaId: manga.id,
                chapterNumber: chapter.chapterNum ?? "",
                chapterTitle: chapter.title,
                pageNumber: page,
                totalPages: totalPages,
                isCompleted: page >= totalPages - 1
            )
        } catch {
            print("Failed to update reading history: \(error)")
        }
    }
}
```

## 🚀 Installation

### 1. Exécuter les scripts SQL dans l'ordre

```bash
# Dans Supabase SQL Editor, exécuter dans l'ordre :
1. supabase_scanio_schema.sql
2. supabase_scanio_functions.sql
3. supabase_scanio_triggers.sql
4. supabase_scanio_profiles_extended.sql
5. supabase_scanio_profiles_functions.sql
```

### 2. Vérifier l'installation

```sql
-- Vérifier les tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE 'scanio_%';

-- Devrait retourner :
-- scanio_profiles
-- scanio_canonical_manga
-- scanio_manga_sources
-- scanio_chapter_comments
-- scanio_manga_reviews
-- scanio_chapter_comment_votes
-- scanio_manga_review_votes
-- scanio_reading_history
-- scanio_personal_rankings
-- scanio_manga_progress
```

### 3. Ajouter les vues dans Settings

Modifier `iOS/New/Views/Settings/Settings.swift` et `iOS/New/Views/Settings/SettingsView.swift` comme indiqué ci-dessus.

### 4. Intégrer l'enregistrement de lecture

Modifier `iOS/UI/Reader/ReaderViewController.swift` pour enregistrer automatiquement la progression.

## 🎨 Fonctionnalités à implémenter

### Vues manquantes (à créer)

1. **`EditProfileView.swift`**
   - Modifier nom d'utilisateur, bio, avatar
   - Upload d'avatar

2. **`ReadingHistoryView.swift`**
   - Liste de l'historique de lecture
   - Filtres par date, manga
   - Reprendre la lecture

3. **`PersonalRankingsView.swift`**
   - Liste du classement personnel
   - Drag & drop pour réorganiser
   - Filtres par statut (reading, completed, etc.)
   - Ajouter/modifier notes et ratings

4. **`MangaDetailView.swift`** (modifier existant)
   - Bouton "Ajouter au classement"
   - Afficher statut de lecture
   - Bouton favoris

## 📊 Statistiques disponibles

Via `SupabaseManager.shared.fetchUserStats()` :

- `totalChaptersRead` - Nombre total de chapitres lus
- `totalMangaRead` - Nombre de mangas différents lus
- `totalFavorites` - Nombre de favoris
- `totalCompleted` - Nombre de mangas terminés
- `totalReading` - Nombre de mangas en cours
- `totalPlanToRead` - Nombre de mangas à lire
- `karma` - Karma total (votes reçus)
- `isPublic` - Profil public ou privé

## 🔒 Confidentialité

- **Profil public** : Autres utilisateurs peuvent voir classement et stats
- **Profil privé** : Seul l'utilisateur peut voir ses données
- RLS (Row Level Security) activé sur toutes les tables
- Politiques pour protéger les données privées

## ✅ TODO

- [ ] Créer `EditProfileView.swift`
- [ ] Créer `ReadingHistoryView.swift`
- [ ] Créer `PersonalRankingsView.swift`
- [ ] Intégrer dans `Settings.swift`
- [ ] Intégrer dans `SettingsView.swift`
- [ ] Ajouter tracking de lecture dans `ReaderViewController.swift`
- [ ] Ajouter boutons favoris/classement dans `MangaDetailView.swift`
- [ ] Implémenter upload d'avatar
- [ ] Ajouter fonction `signOut()` dans `SupabaseManager`
- [ ] Tester l'authentification
- [ ] Tester l'enregistrement de lecture
- [ ] Tester le classement personnel


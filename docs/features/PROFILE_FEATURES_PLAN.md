# 📋 Plan de développement - Fonctionnalités Profil & Social

## 🎯 Objectif
Améliorer le système de profil utilisateur avec statistiques précises, système de favoris, classement personnel, et pages de profil publiques.

---

## ⚠️ IMPORTANT - Instructions pour les IA

### Workflow de développement
1. **Lire TOUT ce document avant de commencer**
2. **Travailler sur UNE tâche à la fois** (ne pas sauter d'étapes)
3. **Après CHAQUE modification de code**, lancer cette commande pour vérifier la compilation :
   ```bash
   xcodebuild -project Aidoku.xcodeproj -scheme "Aidoku (iOS)" -configuration Debug -sdk iphonesimulator -skipPackagePluginValidation build 2>&1 | grep -E "(\*\* BUILD)" | tail -1
   ```
4. **Si BUILD FAILED**, corriger les erreurs avant de continuer
5. **Si BUILD SUCCEEDED**, demander à l'utilisateur de tester et donner son feedback
6. **Ne passer à la tâche suivante qu'après validation de l'utilisateur**

### Règles de code
- ✅ **TOUJOURS** utiliser `codebase-retrieval` avant de modifier du code
- ✅ **TOUJOURS** utiliser `str-replace-editor` pour modifier les fichiers existants (JAMAIS réécrire un fichier entier)
- ✅ **TOUJOURS** respecter l'architecture existante (SwiftUI + Supabase + CoreData)
- ✅ **TOUJOURS** ajouter des logs de debug avec des emojis pour faciliter le débogage
- ❌ **JAMAIS** créer de nouveaux fichiers sans demander confirmation
- ❌ **JAMAIS** modifier plus de 150 lignes à la fois dans un fichier

---

## 🐛 PHASE 1 : Corrections urgentes (PRIORITÉ HAUTE)

### Tâche 1.1 : Corriger l'erreur "Les données n'ont pas pu être lues"

**Problème** : Erreur lors du chargement du profil dans Settings → Profile

**Diagnostic** :
- L'erreur vient probablement de `fetchUserStats()` qui échoue
- Vérifier que la fonction SQL `scanio_get_user_stats()` existe dans Supabase
- Vérifier que les RLS policies permettent l'accès

**Solution** :
1. Vérifier le code de `SupabaseManager.fetchUserStats()` dans `Shared/Managers/SupabaseManager.swift`
2. Ajouter des logs détaillés pour identifier l'erreur exacte
3. Vérifier la requête SQL dans Supabase SQL Editor :
   ```sql
   SELECT * FROM scanio_get_user_stats(auth.uid());
   ```
4. Si la fonction n'existe pas, la créer (voir section SQL ci-dessous)

**Fichiers à modifier** :
- `Shared/Managers/SupabaseManager.swift` (ajouter logs dans `fetchUserStats()`)
- `iOS/New/Views/Settings/ProfileSettingsView.swift` (améliorer gestion d'erreur)

**SQL à vérifier/créer dans Supabase** :
```sql
-- Vérifier si la fonction existe
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'scanio_get_user_stats';

-- Si elle n'existe pas, la créer :
CREATE OR REPLACE FUNCTION public.scanio_get_user_stats(p_user_id UUID)
RETURNS TABLE (
    total_chapters_read BIGINT,
    total_manga_read BIGINT,
    total_favorites BIGINT,
    total_completed BIGINT,
    total_reading BIGINT,
    total_plan_to_read BIGINT,
    karma INT,
    is_public BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(COUNT(DISTINCT rh.chapter_id), 0)::BIGINT as total_chapters_read,
        COALESCE(COUNT(DISTINCT rh.canonical_manga_id), 0)::BIGINT as total_manga_read,
        0::BIGINT as total_favorites, -- TODO: implémenter table favorites
        0::BIGINT as total_completed, -- TODO: calculer depuis reading_history
        COALESCE(COUNT(DISTINCT CASE WHEN rh.is_completed = false THEN rh.canonical_manga_id END), 0)::BIGINT as total_reading,
        0::BIGINT as total_plan_to_read, -- TODO: implémenter
        COALESCE(p.karma, 0) as karma,
        COALESCE(p.is_public, true) as is_public
    FROM scanio_profiles p
    LEFT JOIN scanio_reading_history rh ON rh.user_id = p.id
    WHERE p.id = p_user_id
    GROUP BY p.karma, p.is_public;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.scanio_get_user_stats(UUID) TO authenticated;
```

---

### Tâche 1.2 : Corriger le compteur "Chapitres lus" (affiche 0 au lieu de 5)

**Problème** : `totalChaptersRead` affiche 0 alors que l'historique contient 5 chapitres

**Diagnostic** :
- La fonction SQL `scanio_get_user_stats()` ne compte pas correctement les chapitres
- Vérifier que `scanio_reading_history` contient bien les données

**Solution** :
1. Vérifier dans Supabase SQL Editor :
   ```sql
   SELECT COUNT(*) FROM scanio_reading_history WHERE user_id = auth.uid();
   SELECT COUNT(DISTINCT chapter_id) FROM scanio_reading_history WHERE user_id = auth.uid();
   ```
2. Corriger la fonction `scanio_get_user_stats()` pour compter correctement
3. Tester avec la requête :
   ```sql
   SELECT * FROM scanio_get_user_stats(auth.uid());
   ```

**Fichiers à modifier** :
- Aucun fichier Swift (correction SQL uniquement)

---

### Tâche 1.3 : Renommer "Mangas lus" → "Histoires lues"

**Raison** : L'app supporte mangas, manhwa, manhua, etc.

**Solution** :
1. Modifier `iOS/New/Views/Settings/ProfileSettingsView.swift` ligne 174 :
   ```swift
   Label("Histoires lues", systemImage: "books.vertical.fill")
   ```

**Fichiers à modifier** :
- `iOS/New/Views/Settings/ProfileSettingsView.swift`

---

### Tâche 1.4 : Corriger le compteur "En cours" (affiche 0)

**Problème** : L'utilisateur a commencé une histoire mais le compteur affiche 0

**Diagnostic** :
- La fonction SQL ne compte pas correctement les histoires en cours
- Une histoire "en cours" = au moins 1 chapitre lu mais pas tous les chapitres terminés

**Solution** :
1. Modifier la fonction SQL `scanio_get_user_stats()` :
   ```sql
   -- Compter les histoires avec au moins 1 chapitre lu
   COALESCE(COUNT(DISTINCT rh.canonical_manga_id), 0)::BIGINT as total_reading
   ```
2. Vérifier avec :
   ```sql
   SELECT DISTINCT canonical_manga_id
   FROM scanio_reading_history
   WHERE user_id = auth.uid();
   ```

**Fichiers à modifier** :
- Aucun fichier Swift (correction SQL uniquement)

---

## 📊 PHASE 2 : Nouvelles statistiques

### Tâche 2.1 : Ajouter la stat "Nombre de commentaires"

**Objectif** : Afficher le nombre total de commentaires postés par l'utilisateur

**Solution** :
1. Modifier la fonction SQL `scanio_get_user_stats()` pour ajouter :
   ```sql
   COALESCE((SELECT COUNT(*) FROM scanio_comments WHERE user_id = p_user_id), 0)::BIGINT as total_comments
   ```
2. Modifier `Shared/Models/UserProfile.swift` pour ajouter le champ :
   ```swift
   struct UserStats: Codable {
       // ... champs existants ...
       let totalComments: Int

       enum CodingKeys: String, CodingKey {
           // ... keys existantes ...
           case totalComments = "total_comments"
       }
   }
   ```
3. Afficher dans `ProfileSettingsView.swift` :
   ```swift
   HStack {
       Label("Commentaires", systemImage: "bubble.left.and.bubble.right.fill")
       Spacer()
       Text("\(viewModel.stats?.totalComments ?? 0)")
           .foregroundColor(.secondary)
   }
   ```

**Fichiers à modifier** :
- `Shared/Models/UserProfile.swift`
- `iOS/New/Views/Settings/ProfileSettingsView.swift`
- SQL : fonction `scanio_get_user_stats()`

---

## ❤️ PHASE 3 : Système de Favoris

### Tâche 3.1 : Créer la table `scanio_favorites` dans Supabase

**SQL à lancer** :
```sql
CREATE TABLE IF NOT EXISTS public.scanio_favorites (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE NOT NULL,
    rank INT, -- Position dans le classement personnel (#1, #2, etc.)
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, canonical_manga_id)
);

-- Index pour recherche rapide
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.scanio_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_rank ON public.scanio_favorites(user_id, rank);

-- RLS Policies
ALTER TABLE public.scanio_favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own favorites" ON public.scanio_favorites;
CREATE POLICY "Users can view their own favorites"
ON public.scanio_favorites FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view public favorites" ON public.scanio_favorites;
CREATE POLICY "Users can view public favorites"
ON public.scanio_favorites FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM scanio_profiles
        WHERE id = user_id AND is_public = true
    )
);

DROP POLICY IF EXISTS "Users can insert their own favorites" ON public.scanio_favorites;
CREATE POLICY "Users can insert their own favorites"
ON public.scanio_favorites FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own favorites" ON public.scanio_favorites;
CREATE POLICY "Users can update their own favorites"
ON public.scanio_favorites FOR UPDATE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own favorites" ON public.scanio_favorites;
CREATE POLICY "Users can delete their own favorites"
ON public.scanio_favorites FOR DELETE
USING (auth.uid() = user_id);
```

---

### Tâche 3.2 : Créer `SupabaseManager+Favorites.swift`

**Créer le fichier** : `Shared/Managers/SupabaseManager+Favorites.swift`

**Contenu** :
```swift
import Foundation

// MARK: - Favorites Models
struct Favorite: Codable, Identifiable {
    let id: String
    let userId: String
    let canonicalMangaId: String
    var rank: Int?
    let addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case canonicalMangaId = "canonical_manga_id"
        case rank
        case addedAt = "added_at"
    }
}

extension SupabaseManager {
    // MARK: - Favorites API

    func addFavorite(canonicalMangaId: String) async throws {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_favorites")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")


### Tâche 3.3 : Ajouter le bouton "Favori" dans la page de détails du manga

**Objectif** : Permettre d'ajouter/retirer un manga des favoris depuis sa page de détails

**Fichiers à rechercher** :
- Utiliser `codebase-retrieval` pour trouver la vue de détails du manga
- Chercher "manga detail view" ou "manga info view"

**Solution** :
1. Trouver la vue de détails du manga (probablement `MangaView.swift` ou `MangaDetailView.swift`)
2. Ajouter un `@State` pour tracker si le manga est en favori
3. Ajouter un bouton cœur dans la toolbar ou en haut de la page
4. Implémenter la logique d'ajout/suppression :
   ```swift
   @State private var isFavorite = false

   Button {
       Task {
           if isFavorite {
               try? await SupabaseManager.shared.removeFavorite(canonicalMangaId: canonicalId)
           } else {
               try? await SupabaseManager.shared.addFavorite(canonicalMangaId: canonicalId)
           }
           isFavorite.toggle()
       }
   } label: {
       Image(systemName: isFavorite ? "heart.fill" : "heart")
           .foregroundColor(isFavorite ? .red : .gray)
   }
   ```

**Fichiers à modifier** :
- Vue de détails du manga (à identifier avec `codebase-retrieval`)

---

### Tâche 3.4 : Mettre à jour le compteur "Favoris" dans les stats

**Solution** :
1. Modifier la fonction SQL `scanio_get_user_stats()` :
   ```sql
   COALESCE((SELECT COUNT(*) FROM scanio_favorites WHERE user_id = p_user_id), 0)::BIGINT as total_favorites
   ```

**Fichiers à modifier** :
- SQL : fonction `scanio_get_user_stats()`

---

## 🏆 PHASE 4 : Classement personnel (Personal Rankings)

### Tâche 4.1 : Créer la vue `PersonalRankingsView.swift`

**Objectif** : Afficher la liste des favoris avec possibilité de réorganiser l'ordre

**Créer le fichier** : `iOS/New/Views/Settings/PersonalRankingsView.swift`

**Contenu** :
```swift
import SwiftUI

struct PersonalRankingsView: View {
    @StateObject private var viewModel = PersonalRankingsViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.favorites.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("Aucun favori")
                        .font(.headline)

                    Text("Ajoutez des histoires à vos favoris pour créer votre classement personnel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ForEach(viewModel.rankedFavorites) { favorite in
                    RankingRow(favorite: favorite, rank: viewModel.getRank(for: favorite))
                }
                .onMove { from, to in
                    viewModel.moveFavorite(from: from, to: to)
                }
            }
        }
        .navigationTitle("Classement personnel")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .task {
            await viewModel.loadFavorites()
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue")
        }
    }
}

struct RankingRow: View {
    let favorite: FavoriteWithManga
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)

                Text("#\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // Manga info
            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.mangaTitle)
                    .font(.headline)
                    .lineLimit(2)

                if let author = favorite.mangaAuthor {
                    Text(author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .blue
        }
    }
}

// MARK: - ViewModel

@MainActor
class PersonalRankingsViewModel: ObservableObject {
    @Published var favorites: [FavoriteWithManga] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?

    private let supabase = SupabaseManager.shared

    var rankedFavorites: [FavoriteWithManga] {
        favorites.sorted { ($0.rank ?? Int.max) < ($1.rank ?? Int.max) }
    }

    func getRank(for favorite: FavoriteWithManga) -> Int {
        rankedFavorites.firstIndex(where: { $0.id == favorite.id })! + 1
    }

    func loadFavorites() async {
        isLoading = true

        do {
            // TODO: Créer une fonction qui récupère les favoris avec les infos du manga
            // Pour l'instant, on récupère juste les favoris
            let favs = try await supabase.fetchFavorites()

            // TODO: Pour chaque favori, récupérer les infos du manga depuis scanio_canonical_manga
            // Temporairement, on crée des objets vides
            favorites = favs.map { fav in
                FavoriteWithManga(
                    id: fav.id,
                    userId: fav.userId,
                    canonicalMangaId: fav.canonicalMangaId,
                    rank: fav.rank,
                    addedAt: fav.addedAt,
                    mangaTitle: "Loading...",
                    mangaAuthor: nil,
                    mangaCoverUrl: nil
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func moveFavorite(from source: IndexSet, to destination: Int) {
        var ranked = rankedFavorites
        ranked.move(fromOffsets: source, toOffset: destination)

        // Update ranks
        Task {
            for (index, favorite) in ranked.enumerated() {
                let newRank = index + 1
                if favorite.rank != newRank {
                    try? await supabase.updateFavoriteRank(
                        canonicalMangaId: favorite.canonicalMangaId,
                        rank: newRank
                    )
                }
            }

            // Reload
            await loadFavorites()
        }
    }
}

// MARK: - Models

struct FavoriteWithManga: Identifiable {
    let id: String
    let userId: String
    let canonicalMangaId: String
    var rank: Int?
    let addedAt: Date

    // Manga info
    let mangaTitle: String
    let mangaAuthor: String?
    let mangaCoverUrl: String?
}
```

**Fichiers à créer** :
- `iOS/New/Views/Settings/PersonalRankingsView.swift`

---

## 👤 PHASE 5 : Pages de profil publiques

### Tâche 5.1 : Créer la vue `PublicProfileView.swift`

**Objectif** : Afficher le profil public d'un utilisateur (accessible en cliquant sur un commentaire)

**Créer le fichier** : `iOS/New/Views/Profile/PublicProfileView.swift`

**Contenu** :
```swift
import SwiftUI

struct PublicProfileView: View {
    let userId: String
    @StateObject private var viewModel = PublicProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let profile = viewModel.profile {
                    // Header
                    profileHeader(profile: profile)

                    // Stats (if public)
                    if profile.isPublic {
                        statsSection

                        // Rankings (if visible)
                        if viewModel.settings?.showRankings == true {
                            rankingsSection
                        }

                        // History (if visible)
                        if viewModel.settings?.showHistory == true {
                            historySection
                        }
                    } else {
                        privateProfileMessage
                    }
                } else {
                    Text("Profil introuvable")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile(userId: userId)
        }
    }

    private func profileHeader(profile: UserProfile) -> some View {
        VStack(spacing: 12) {
            // Avatar
            if let avatarUrl = profile.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 100, height: 100)
            }

            // Username
            Text(profile.userName ?? "Utilisateur")
                .font(.title2)
                .fontWeight(.bold)

            // Bio
            if let bio = profile.bio {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Karma
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                Text("\(profile.karma) karma")
                    .font(.headline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistiques")
                .font(.headline)

            if let stats = viewModel.stats {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Chapitres lus", value: "\(stats.totalChaptersRead)", icon: "book.fill")
                    StatCard(title: "Histoires lues", value: "\(stats.totalMangaRead)", icon: "books.vertical.fill")
                    StatCard(title: "Favoris", value: "\(stats.totalFavorites)", icon: "heart.fill")
                    StatCard(title: "Commentaires", value: "\(stats.totalComments)", icon: "bubble.left.and.bubble.right.fill")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var rankingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Classement personnel")
                .font(.headline)

            if viewModel.rankings.isEmpty {
                Text("Aucun classement")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(viewModel.rankings.prefix(5).enumerated()), id: \.element.id) { index, favorite in
                    HStack {
                        Text("#\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .frame(width: 40)

                        Text(favorite.mangaTitle)
                            .lineLimit(1)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historique récent")
                .font(.headline)

            if viewModel.recentHistory.isEmpty {
                Text("Aucun historique")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.recentHistory.prefix(5)) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.mangaTitle)
                                .font(.subheadline)
                            Text("Chapitre \(item.chapterNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(item.lastReadAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var privateProfileMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("Profil privé")
                .font(.headline)

            Text("Cet utilisateur a choisi de garder son profil privé")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - ViewModel

@MainActor
class PublicProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var stats: UserStats?
    @Published var settings: ProfileVisibilitySettings?
    @Published var rankings: [FavoriteWithManga] = []
    @Published var recentHistory: [HistoryItem] = []
    @Published var isLoading = false

    private let supabase = SupabaseManager.shared

    func loadProfile(userId: String) async {
        isLoading = true

        do {
            // Load profile
            profile = try await supabase.fetchPublicProfile(userId: userId)

            // If public, load stats and other data
            if profile?.isPublic == true {
                async let statsTask = supabase.fetchUserStats(userId: userId)
                async let settingsTask = supabase.fetchProfileVisibilitySettings(userId: userId)

                stats = try await statsTask
                settings = try await settingsTask

                // Load rankings if visible
                if settings?.showRankings == true {
                    rankings = try await supabase.fetchPublicRankings(userId: userId)
                }

                // Load history if visible
                if settings?.showHistory == true {
                    recentHistory = try await supabase.fetchPublicHistory(userId: userId, limit: 5)
                }
            }
        } catch {
            print("Error loading public profile: \(error)")
        }

        isLoading = false
    }
}

struct HistoryItem: Identifiable {
    let id: String
    let mangaTitle: String
    let chapterNumber: String
    let lastReadAt: Date
}
```

**Fichiers à créer** :
- `iOS/New/Views/Profile/PublicProfileView.swift`

---

### Tâche 5.2 : Créer la table `scanio_profile_visibility_settings`

**SQL à lancer** :
```sql
CREATE TABLE IF NOT EXISTS public.scanio_profile_visibility_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    show_history BOOLEAN DEFAULT true,
    show_rankings BOOLEAN DEFAULT true,
    show_stats BOOLEAN DEFAULT true,
    show_comments BOOLEAN DEFAULT true,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.scanio_profile_visibility_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own settings" ON public.scanio_profile_visibility_settings;
CREATE POLICY "Users can view their own settings"
ON public.scanio_profile_visibility_settings FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view public settings" ON public.scanio_profile_visibility_settings;
CREATE POLICY "Users can view public settings"
ON public.scanio_profile_visibility_settings FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM scanio_profiles
        WHERE id = user_id AND is_public = true
    )
);

DROP POLICY IF EXISTS "Users can update their own settings" ON public.scanio_profile_visibility_settings;
CREATE POLICY "Users can update their own settings"
ON public.scanio_profile_visibility_settings FOR UPDATE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own settings" ON public.scanio_profile_visibility_settings;
CREATE POLICY "Users can insert their own settings"
ON public.scanio_profile_visibility_settings FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

---

### Tâche 5.3 : Ajouter les paramètres de visibilité dans Settings → Profile

**Objectif** : Permettre à l'utilisateur de choisir ce qu'il veut afficher sur son profil public

**Solution** :
1. Modifier `iOS/New/Views/Settings/ProfileSettingsView.swift`
2. Ajouter une nouvelle section "Visibilité du profil" :
   ```swift
   private var visibilitySection: some View {
       Section {
           Toggle("Afficher l'historique", isOn: $viewModel.showHistory)
           Toggle("Afficher le classement", isOn: $viewModel.showRankings)
           Toggle("Afficher les statistiques", isOn: $viewModel.showStats)
           Toggle("Afficher les commentaires", isOn: $viewModel.showComments)
       } header: {
           Text("Visibilité du profil")
       } footer: {
           Text("Choisissez ce que les autres utilisateurs peuvent voir sur votre profil public")
       }
   }
   ```

**Fichiers à modifier** :
- `iOS/New/Views/Settings/ProfileSettingsView.swift`
- `Shared/Managers/SupabaseManager.swift` (ajouter fonctions pour gérer les settings)

---

### Tâche 5.4 : Rendre les noms d'utilisateur cliquables dans les commentaires

**Objectif** : Permettre de cliquer sur un nom d'utilisateur dans un commentaire pour voir son profil

**Solution** :
1. Trouver la vue des commentaires (probablement `CommentsView.swift`)
2. Modifier le `Text` du nom d'utilisateur pour être un `Button` :
   ```swift
   Button {
       showingProfile = true
       selectedUserId = comment.userId
   } label: {
       Text(comment.userName)
           .font(.subheadline)
           .fontWeight(.semibold)
   }
   .sheet(isPresented: $showingProfile) {
       if let userId = selectedUserId {
           NavigationView {
               PublicProfileView(userId: userId)
           }
       }
   }
   ```

**Fichiers à modifier** :
- `iOS/UI/Reader/CommentsView.swift`
- `iOS/UI/Reader/RepliesView.swift`

---

## 📚 PHASE 6 : Liste de lecture (Reading List)

### Tâche 6.1 : Différencier "Liste de lecture" et "Favoris"

**Concept** :
- **Liste de lecture** = Tous les mangas ajoutés à la bibliothèque (CoreData)
- **Favoris** = Mangas préférés avec classement personnel (Supabase)

**Solution** :
1. Modifier la stat "Liste de lecture" pour compter les mangas dans CoreData :
   ```swift
   let libraryCount = await CoreDataManager.shared.getLibraryMangaCount()
   ```
2. Ajouter cette stat dans `ProfileSettingsView.swift` :
   ```swift
   HStack {
       Label("Liste de lecture", systemImage: "books.vertical")
       Spacer()
       Text("\(viewModel.libraryCount)")
           .foregroundColor(.secondary)
   }
   ```

**Fichiers à modifier** :
- `iOS/New/Views/Settings/ProfileSettingsView.swift`
- `Shared/Data/CoreDataManager.swift` (ajouter fonction `getLibraryMangaCount()`)

---

## ✅ Checklist finale

Après avoir terminé TOUTES les tâches, vérifier :

- [ ] Toutes les stats affichent les bonnes valeurs (pas de 0 incorrect)
- [ ] Le bouton favori fonctionne dans la page de détails du manga
- [ ] Le classement personnel est réorganisable par drag & drop
- [ ] Les profils publics sont accessibles en cliquant sur les noms d'utilisateur
- [ ] Les paramètres de visibilité fonctionnent correctement
- [ ] La différence entre "Liste de lecture" et "Favoris" est claire
- [ ] Aucune erreur de compilation
- [ ] Aucune erreur SQL dans Supabase

---

## 🚀 Commande de test après chaque modification

```bash
xcodebuild -project Aidoku.xcodeproj -scheme "Aidoku (iOS)" -configuration Debug -sdk iphonesimulator -skipPackagePluginValidation build 2>&1 | grep -E "(\*\* BUILD)" | tail -1
```

**Si BUILD SUCCEEDED** → Demander à l'utilisateur de tester et donner son feedback

**Si BUILD FAILED** → Corriger les erreurs avant de continuer

---

## 📝 Notes importantes pour les IA

1. **NE PAS** tout faire d'un coup - travailler tâche par tâche
2. **TOUJOURS** demander confirmation avant de créer de nouveaux fichiers
3. **TOUJOURS** utiliser `codebase-retrieval` avant de modifier du code
4. **TOUJOURS** compiler après chaque modification
5. **TOUJOURS** attendre le feedback de l'utilisateur avant de passer à la tâche suivante
6. **NE JAMAIS** réécrire un fichier entier - utiliser `str-replace-editor`
7. **AJOUTER** des logs de debug avec emojis pour faciliter le débogage

---

## 🎯 Ordre de priorité

1. **PHASE 1** (Corrections urgentes) - À faire EN PREMIER
2. **PHASE 2** (Nouvelles stats) - Rapide, peut être fait en même temps que Phase 1
3. **PHASE 3** (Favoris) - Fonctionnalité importante
4. **PHASE 4** (Classement) - Dépend de Phase 3
5. **PHASE 5** (Profils publics) - Fonctionnalité sociale importante
6. **PHASE 6** (Liste de lecture) - Amélioration mineure
7. **PHASE 7** (Système de présence en ligne) - ✅ **TERMINÉ**

---

## 🟢 PHASE 7 : Système de Présence en Ligne (✅ TERMINÉ)

### Vue d'ensemble
Système complet de suivi de présence en ligne des utilisateurs avec indicateurs visuels et support pour fonctionnalités sociales futures.

### Tâche 7.1 : Infrastructure Backend ✅ TERMINÉ

**Fichiers créés** :
- `bdd/supabase_user_presence_schema.sql` : Schéma SQL complet avec Realtime
- `Shared/Managers/SupabaseManager+Presence.swift` : Extension pour gérer la présence

**Base de données** :
- **Table** : `scanio_user_presence`
  - `user_id` : UUID de l'utilisateur
  - `is_online` : Statut en ligne (boolean)
  - `last_seen` : Dernière activité (timestamp)
  - `updated_at` : Dernière mise à jour (timestamp)
  - RLS activé : Les utilisateurs peuvent voir tous les statuts, mais ne peuvent modifier que le leur
  - Realtime activé pour les mises à jour en temps réel

**Fonctions SQL** :
- `scanio_update_user_presence(p_is_online)` : Met à jour le statut de l'utilisateur connecté
- `scanio_get_user_presence(p_user_id)` : Récupère le statut d'un utilisateur spécifique
- `scanio_get_users_presence(p_user_ids[])` : Récupère le statut de plusieurs utilisateurs (batch)
- `scanio_cleanup_stale_presence()` : Nettoie automatiquement les statuts obsolètes (>5 min)

**API Swift** :
```swift
// Mise à jour du statut
func updatePresence(isOnline: Bool) async throws

// Récupération du statut
func getUserPresence(userId: String) async throws -> UserPresence?
func getUsersPresence(userIds: [String]) async throws -> [UserPresence]

// Helpers
func setOnline() async
func setOffline() async
func keepPresenceAlive() async
```

### Tâche 7.2 : Intégration Automatique ✅ TERMINÉ

**Fichiers modifiés** :
- `Shared/Models/UserProfile.swift` : Ajout de `isOnline` et `lastSeen`
- `Shared/Managers/SupabaseManager.swift` : Appels automatiques à `setOnline()` et `setOffline()`
- `iOS/New/Views/Settings/ProfileSettingsView.swift` : Déconnexion async

**Comportement** :
- ✅ Connexion → `setOnline()` automatique
- ✅ Déconnexion → `setOffline()` automatique
- ✅ Modèle `UserProfile` étendu avec statut de présence

### Tâche 7.3 : Interface Utilisateur ✅ TERMINÉ

**Fichiers modifiés** :
- `iOS/New/Views/Settings/ProfileSettingsView.swift` : Badge "En ligne" pour l'utilisateur connecté
- `iOS/New/Views/Profile/PublicProfileView.swift` : Indicateur de statut pour les profils publics
- `iOS/New/Views/Profile/UserProfileSheet.swift` : Indicateur de statut dans les sheets

**Affichage** :
- 🟢 **En ligne** : Point vert + "En ligne"
- 🔴 **Hors ligne récent** : "Vu il y a X min/h/j"
- ⚪ **Hors ligne** : Pas d'indicateur si pas de `lastSeen`

**Fonction de formatage** :
```swift
private func formatLastSeen(_ date: Date) -> String {
    // "Vu à l'instant" si < 1 min
    // "Vu il y a X min" si < 1h
    // "Vu il y a Xh" si < 24h
    // "Vu il y a Xj" si > 24h
}
```

### Tâche 7.4 : Fonctionnalités Futures (Préparées)

#### 🔮 Chat en Temps Réel
**Utilisation** : Voir qui est en ligne pour discuter
**Implémentation future** :
- Liste des utilisateurs en ligne dans l'interface de chat
- Notification quand un ami se connecte
- Indicateur "en train d'écrire..." avec Realtime

**Exemple de code** :
```swift
// Récupérer tous les amis en ligne
let friendIds = await getFriendsList()
let onlineFriends = try await supabase.getUsersPresence(userIds: friendIds)
    .filter { $0.isOnline }
```

#### 👥 Liste d'Amis
**Utilisation** : Voir quels amis sont en ligne
**Implémentation future** :
- Section "Amis en ligne" en haut de la liste
- Badge vert sur les avatars des amis en ligne
- Tri automatique : en ligne d'abord, puis par dernière activité

**Schéma SQL à créer** :
```sql
CREATE TABLE scanio_friendships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);
```

#### 💬 Indicateurs dans les Commentaires
**Utilisation** : Voir si l'auteur d'un commentaire est en ligne
**Implémentation future** :
- Badge "En ligne" à côté du nom d'utilisateur dans les commentaires
- Permet de savoir si on peut avoir une réponse rapide
- Charge le statut en batch pour tous les auteurs visibles

**Exemple de code** :
```swift
// Dans CommentView
let authorIds = comments.map { $0.userId }
let presences = try await supabase.getUsersPresence(userIds: authorIds)
let presenceDict = Dictionary(uniqueKeysWithValues: presences.map { ($0.userId, $0) })

// Afficher le badge si en ligne
if let presence = presenceDict[comment.userId], presence.isOnline {
    OnlineStatusBadge()
}
```

#### 🧹 Cleanup Automatique
**Utilisation** : Les utilisateurs inactifs >5 min sont marqués hors ligne
**Implémentation actuelle** :
- Fonction SQL `scanio_cleanup_stale_presence()` déjà créée
- Marque comme hors ligne si `updated_at` > 5 minutes

**À configurer sur Supabase** :
1. **Option 1 : pg_cron** (recommandé)
   ```sql
   SELECT cron.schedule(
       'cleanup-stale-presence',
       '*/5 * * * *', -- Toutes les 5 minutes
       $$SELECT scanio_cleanup_stale_presence()$$
   );
   ```

2. **Option 2 : Edge Function** (alternative)
   - Créer une Edge Function qui appelle `scanio_cleanup_stale_presence()`
   - Configurer un cron job externe (GitHub Actions, Vercel Cron, etc.)

3. **Option 3 : Client-side** (temporaire)
   - Appeler `keepPresenceAlive()` toutes les 2-3 minutes pendant que l'app est active
   - Implémenter dans `AppDelegate` ou `SceneDelegate`

**Exemple d'implémentation client-side** :
```swift
// Dans AppDelegate ou SceneDelegate
var presenceTimer: Timer?

func applicationDidBecomeActive(_ application: UIApplication) {
    if SupabaseManager.shared.isAuthenticated {
        Task { await SupabaseManager.shared.setOnline() }

        // Maintenir la présence active
        presenceTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { _ in
            Task { await SupabaseManager.shared.keepPresenceAlive() }
        }
    }
}

func applicationDidEnterBackground(_ application: UIApplication) {
    presenceTimer?.invalidate()
    presenceTimer = nil

    if SupabaseManager.shared.isAuthenticated {
        Task { await SupabaseManager.shared.setOffline() }
    }
}
```

### Tâche 7.5 : Déploiement et Configuration

**Étapes de déploiement** :
1. ✅ Exécuter `bdd/supabase_user_presence_schema.sql` dans Supabase SQL Editor
2. ✅ Activer Realtime :
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE scanio_user_presence;
   ```
3. ⏳ Configurer le cleanup automatique (pg_cron ou Edge Function)
4. ⏳ Implémenter les observers de lifecycle pour background/foreground
5. ⏳ Tester sur plusieurs appareils simultanément

**Tests à effectuer** :
- [ ] Connexion → Statut passe à "En ligne"
- [ ] Déconnexion → Statut passe à "Hors ligne"
- [ ] App en background → Statut passe à "Hors ligne" après 5 min
- [ ] App en foreground → Statut reste "En ligne"
- [ ] Profil public → Affiche le bon statut
- [ ] Plusieurs appareils → Synchronisation en temps réel

### Avantages du Système

✅ **Performance** :
- Requêtes batch pour récupérer plusieurs statuts en une fois
- Index sur `user_id` pour des requêtes rapides
- Cleanup automatique pour éviter l'accumulation de données

✅ **Scalabilité** :
- Realtime Supabase pour les mises à jour en temps réel
- RLS pour la sécurité
- Prêt pour des milliers d'utilisateurs simultanés

✅ **Extensibilité** :
- Base solide pour le chat en temps réel
- Support pour les listes d'amis
- Indicateurs dans les commentaires
- Notifications de présence

✅ **UX** :
- Feedback visuel immédiat
- Savoir qui est disponible pour discuter
- Meilleure expérience sociale

---

**Bonne chance ! 🚀**



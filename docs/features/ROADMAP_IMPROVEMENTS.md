# 🚀 TomoScan - Plan d'Améliorations

**Date de création** : 2025-11-06  
**Statut** : À implémenter  
**Priorité** : Haute

---

## 📋 Table des Matières

1. [Contexte du Projet](#contexte-du-projet)
2. [Problèmes Critiques à Résoudre](#problèmes-critiques-à-résoudre)
3. [Nouvelles Fonctionnalités](#nouvelles-fonctionnalités)
4. [Améliorations UX/UI](#améliorations-uxui)
5. [Ordre d'Implémentation](#ordre-dimplémentation)
6. [Guide de Build](#guide-de-build)

---

## 🎯 Contexte du Projet

### Architecture Actuelle

**Frontend**
- SwiftUI (nouvelles vues) + UIKit/Texture (vues legacy)
- Navigation : TabBarController avec 5 onglets (Library, Browse, History, Search, Settings)
- Accent Color : Actuellement cyan/turquoise (RGB: 0.2, 0.6, 1.0)

**Backend**
- Supabase (PostgreSQL + Auth + Realtime)
- CoreData (cache local)
- SyncManager (synchronisation bidirectionnelle)

**Problèmes Identifiés**
- ❌ Synchronisation library/sources/history ne fonctionne pas
- ❌ Système de commentaires a des bugs
- ❌ Pas de préchargement des chapitres suivants
- ❌ Navigation pas optimale (trop d'onglets, profil mal placé)

---

## 🔴 Problèmes Critiques à Résoudre

### Phase 0 : Corrections Urgentes (PRIORITÉ MAXIMALE)

#### 0.1 - Corriger la Synchronisation Library/Sources/History

**Problème Actuel**
```
📚 Fetched 0 items from Supabase
📚 Found 1 items in CoreData
📤 Uploading to Supabase: 3596
❌ SyncManager: Full sync failed: networkError
```

**Fichiers Concernés**
- `Shared/Managers/SyncManager.swift`
- `Shared/Managers/SupabaseManager.swift`
- `Shared/Managers/CoreData/CoreDataManager+LibraryManga.swift`

**Diagnostic à Faire**
1. Vérifier que `scanio_upsert_user_library` fonctionne correctement
2. Vérifier le format des données envoyées (canonical_manga_id)
3. Vérifier les permissions RLS sur les tables Supabase
4. Ajouter des logs détaillés pour identifier l'erreur exacte

**Solution Proposée**
```swift
// Dans SyncManager.swift - uploadLibraryItemToSupabase()
// Ajouter des logs détaillés :
print("📤 Uploading library item:")
print("  - User ID: \(userId)")
print("  - Canonical Manga ID: \(item.canonicalMangaId)")
print("  - Source ID: \(item.sourceId)")
print("  - Manga ID: \(item.mangaId)")

// Vérifier la réponse HTTP
if let httpResponse = response as? HTTPURLResponse {
    print("📊 HTTP Status: \(httpResponse.statusCode)")
    if !(200...299).contains(httpResponse.statusCode) {
        print("❌ Response body: \(String(data: data, encoding: .utf8) ?? "N/A")")
    }
}
```

**Tests à Effectuer**
1. Ajouter un manga à la library
2. Vérifier dans Supabase que l'entrée est créée
3. Se déconnecter et reconnecter
4. Vérifier que la library est restaurée

**Fichiers SQL à Vérifier**
- `bdd/supabase_user_library_functions.sql` - Fonction `scanio_upsert_user_library`
- `bdd/supabase_schema.sql` - RLS policies sur `scanio_user_library`

---

#### 0.2 - Corriger le Système de Commentaires

**Problème Actuel**
- Les commentaires ne s'affichent pas correctement
- Problèmes de synchronisation des votes
- Bugs non spécifiés à identifier

**Fichiers Concernés**
- `Shared/Managers/SupabaseManager+Comments.swift`
- `iOS/UI/Reader/CommentsView.swift`
- `iOS/UI/Reader/Comments/CommentsView.swift`

**Diagnostic à Faire**
1. Tester la création de commentaires
2. Tester l'affichage des commentaires
3. Tester les votes (upvote/downvote)
4. Tester les réponses (replies)
5. Vérifier les permissions RLS

**Tests à Effectuer**
1. Créer un commentaire sur un chapitre
2. Vérifier qu'il apparaît dans la liste
3. Voter sur un commentaire
4. Répondre à un commentaire
5. Supprimer un commentaire

**Fichiers SQL à Vérifier**
- `bdd/supabase_schema.sql` - Table `scanio_chapter_comments`
- `bdd/supabase_schema.sql` - Table `scanio_chapter_comment_votes`
- Vérifier les triggers et fonctions liées aux commentaires

---

## ✨ Nouvelles Fonctionnalités

### Phase 1 : Changement de Couleur d'Accent

**Objectif** : Passer du cyan/turquoise au bleu

**Fichiers à Modifier**
1. `Shared/Assets.xcassets/AccentColor.colorset/Contents.json`
2. `iOS/SceneDelegate.swift` (ligne 18 : `window.tintColor`)

**Changements**

```json
// Shared/Assets.xcassets/AccentColor.colorset/Contents.json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "1.000",
          "green" : "0.400",
          "red" : "0.000"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "1.000",
          "green" : "0.500",
          "red" : "0.200"
        }
      },
      "idiom" : "universal"
    }
  ]
}
```

```swift
// iOS/SceneDelegate.swift - ligne 18
window.tintColor = .systemBlue // Au lieu de .systemPink
```

**Tests**
- Vérifier que tous les boutons, liens et éléments interactifs utilisent le nouveau bleu
- Tester en mode clair et mode sombre

---

### Phase 2 : Préchargement du Chapitre Suivant

**Objectif** : Charger automatiquement le chapitre suivant quand l'utilisateur arrive vers la fin du chapitre actuel

**Fichiers Concernés**
- `iOS/UI/Reader/Readers/Paged/ReaderPagedViewController.swift`
- `iOS/UI/Reader/Readers/Webtoon/ReaderWebtoonViewController.swift`
- `iOS/UI/Reader/Readers/Paged/ReaderPagedViewModel.swift`

**Logique Actuelle**
- Le préchargement existe déjà (`viewModel.preload(chapter:)`)
- Il est déclenché uniquement quand on arrive sur la page de transition (page displayPageCount + 1)

**Amélioration Proposée**
```swift
// Dans ReaderPagedViewController.swift
func setCurrentPages(_ pages: ClosedRange<Int>) {
    // ... code existant ...
    
    // NOUVEAU: Précharger le chapitre suivant quand on atteint 80% du chapitre
    let progress = Float(pages.lowerBound) / Float(displayPageCount)
    if progress >= 0.8, let nextChapter = nextChapter {
        Task {
            await viewModel.preload(chapter: nextChapter)
            print("🔄 Préchargement du chapitre suivant: \(nextChapter.title ?? "N/A")")
        }
    }
}
```

**Pour Webtoon**
```swift
// Dans ReaderWebtoonViewController.swift - scrollViewDidScroll
func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // ... code existant ...
    
    // NOUVEAU: Précharger quand on arrive à 80% du scroll
    let scrollProgress = scrollView.contentOffset.y / (scrollView.contentSize.height - scrollView.frame.height)
    if scrollProgress >= 0.8, !isPreloadingNext {
        isPreloadingNext = true
        Task {
            await appendNextChapter()
            isPreloadingNext = false
        }
    }
}
```

**Tests**
- Lire un chapitre jusqu'à 80%
- Vérifier dans les logs que le préchargement démarre
- Scroller jusqu'au chapitre suivant
- Vérifier que la transition est instantanée

---

### Phase 3 : Long-Term Caching avec Supabase

**Objectif** : Stocker les chapitres sur Supabase pour streaming rapide

**Architecture Proposée**

```
┌─────────────────────────────────────────────────────────────┐
│                    TomoScan Client                          │
│                                                             │
│  1. User ajoute manga à library                            │
│  2. Test de performance (handshake)                        │
│     ├─ Test source originale (3 requêtes, moyenne)        │
│     └─ Test Supabase cache (si existe)                    │
│  3. Choix du meilleur serveur                             │
│  4. Stream depuis le serveur le plus rapide               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Backend                         │
│                                                             │
│  Table: scanio_cached_chapters                             │
│  ├─ id (UUID)                                              │
│  ├─ canonical_manga_id (UUID)                              │
│  ├─ chapter_number (TEXT)                                  │
│  ├─ pages (JSONB) - Array of page URLs                    │
│  ├─ cached_at (TIMESTAMP)                                  │
│  ├─ access_count (INTEGER)                                 │
│  └─ last_accessed (TIMESTAMP)                              │
│                                                             │
│  Storage: scanio-chapter-images                            │
│  └─ {canonical_manga_id}/{chapter_number}/{page_index}.jpg │
└─────────────────────────────────────────────────────────────┘
```

**Nouveaux Fichiers à Créer**

1. `Shared/Managers/CacheManager.swift`
```swift
class CacheManager {
    static let shared = CacheManager()
    
    // Test de performance
    func performHandshake(sourceId: String, mangaId: String, chapterId: String) async -> CacheSource {
        // Tester source originale (3 fois, moyenne)
        let sourceSpeed = await testSourceSpeed(sourceId: sourceId, mangaId: mangaId, chapterId: chapterId)
        
        // Tester Supabase cache (si existe)
        let cacheSpeed = await testCacheSpeed(mangaId: mangaId, chapterId: chapterId)
        
        return sourceSpeed < cacheSpeed ? .original : .supabase
    }
    
    // Upload chapitre vers Supabase
    func cacheChapter(canonicalMangaId: String, chapterNumber: String, pages: [Page]) async throws
    
    // Download chapitre depuis Supabase
    func getCachedChapter(canonicalMangaId: String, chapterNumber: String) async throws -> [Page]?
}

enum CacheSource {
    case original
    case supabase
}
```

2. `bdd/supabase_chapter_cache.sql`
```sql
-- Table pour stocker les métadonnées des chapitres cachés
CREATE TABLE IF NOT EXISTS public.scanio_cached_chapters (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE NOT NULL,
    chapter_number TEXT NOT NULL,
    pages JSONB NOT NULL, -- Array of {index, url, width, height}
    cached_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    access_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(canonical_manga_id, chapter_number)
);

-- Index pour recherche rapide
CREATE INDEX idx_cached_chapters_manga ON public.scanio_cached_chapters(canonical_manga_id);

-- RLS
ALTER TABLE public.scanio_cached_chapters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read cached chapters"
ON public.scanio_cached_chapters FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can cache chapters"
ON public.scanio_cached_chapters FOR INSERT
TO authenticated
WITH CHECK (true);
```

**Intégration dans le Reader**
```swift
// Dans ReaderPagedViewModel.swift - loadPages()
func loadPages(chapter: AidokuRunner.Chapter) async {
    // ... code existant ...
    
    // NOUVEAU: Vérifier le cache Supabase
    if let canonicalMangaId = manga.canonicalId {
        let chapterNumber = String(format: "%.1f", chapter.chapterNumber ?? 0)
        
        // Test de performance
        let cacheSource = await CacheManager.shared.performHandshake(
            sourceId: source?.key ?? manga.sourceKey,
            mangaId: manga.key,
            chapterId: chapter.key
        )
        
        if cacheSource == .supabase {
            // Charger depuis Supabase
            if let cachedPages = try? await CacheManager.shared.getCachedChapter(
                canonicalMangaId: canonicalMangaId,
                chapterNumber: chapterNumber
            ) {
                pages = cachedPages
                print("✅ Loaded from Supabase cache")
                return
            }
        }
    }
    
    // Fallback: charger depuis la source originale
    pages = (try? await source?.getPageList(manga: manga, chapter: chapter))?.map { ... } ?? []
}
```

**Tests**
- Ajouter un manga à la library
- Lire un chapitre (devrait cacher automatiquement)
- Relire le même chapitre (devrait charger depuis cache)
- Comparer les temps de chargement

---

### Phase 4 : Page "Découvrir" (Discover)

**Objectif** : Créer une page d'accueil avec recommandations et contenu populaire

**Nouvelle Structure de Navigation**
```
Avant:
[Library] [Browse] [History] [Search] [Settings]

Après:
[Discover] [Browse] [History] [Settings]
```

**Fichiers à Créer**

1. `iOS/New/Views/Discover/DiscoverView.swift`
2. `iOS/New/Views/Discover/DiscoverViewModel.swift`
3. `iOS/New/Views/Discover/ContinueReadingSection.swift`
4. `iOS/New/Views/Discover/PopularSection.swift`
5. `iOS/New/Views/Discover/TopRatedSection.swift`
6. `iOS/New/Views/Discover/GenreSection.swift`

**Structure de la Page**

```swift
struct DiscoverView: View {
    @StateObject var viewModel = DiscoverViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Section 1: Continuer de lire (en haut)
                ContinueReadingSection(items: viewModel.continueReading)
                
                // Section 2: Récemment populaire
                PopularSection(
                    title: "Récemment Populaire",
                    items: viewModel.recentlyPopular
                )
                
                // Section 3: Les mieux notés
                TopRatedSection(
                    title: "Les Mieux Notés",
                    items: viewModel.topRated
                )
                
                // Section 4: Par genre
                ForEach(viewModel.genres, id: \.self) { genre in
                    GenreSection(
                        genre: genre,
                        items: viewModel.mangaByGenre[genre] ?? []
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Découvrir")
        .onAppear {
            viewModel.loadData()
        }
    }
}
```

**Backend - Nouvelles Tables SQL**

```sql
-- Table pour tracker les lectures populaires
CREATE TABLE IF NOT EXISTS public.scanio_manga_popularity (
    canonical_manga_id UUID REFERENCES public.scanio_canonical_manga(id) ON DELETE CASCADE PRIMARY KEY,
    total_readers INTEGER DEFAULT 0,
    total_chapters_read INTEGER DEFAULT 0,
    last_7_days_readers INTEGER DEFAULT 0,
    last_30_days_readers INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fonction pour obtenir les mangas populaires
CREATE OR REPLACE FUNCTION scanio_get_popular_manga(
    p_limit INTEGER DEFAULT 20,
    p_period TEXT DEFAULT '7days' -- '7days', '30days', 'all'
)
RETURNS TABLE (
    canonical_manga_id UUID,
    title TEXT,
    cover_url TEXT,
    readers_count INTEGER,
    average_rating NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cm.id as canonical_manga_id,
        cm.title,
        cm.cover_url,
        CASE 
            WHEN p_period = '7days' THEN mp.last_7_days_readers
            WHEN p_period = '30days' THEN mp.last_30_days_readers
            ELSE mp.total_readers
        END as readers_count,
        COALESCE(AVG(pr.rating), 0) as average_rating
    FROM public.scanio_canonical_manga cm
    LEFT JOIN public.scanio_manga_popularity mp ON cm.id = mp.canonical_manga_id
    LEFT JOIN public.scanio_personal_rankings pr ON cm.id = pr.canonical_manga_id
    GROUP BY cm.id, cm.title, cm.cover_url, mp.last_7_days_readers, mp.last_30_days_readers, mp.total_readers
    ORDER BY readers_count DESC NULLS LAST
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Tests**
- Ouvrir la page Découvrir
- Vérifier que "Continuer de lire" affiche les derniers mangas lus
- Vérifier que les sections populaires se chargent
- Cliquer sur un manga (doit ouvrir la page du manga si source installée)

---

### Phase 5 : Recherche Globale Multi-Sources

**Objectif** : Rechercher dans toutes les sources installées au lieu de chercher une source

**Fichiers à Modifier**
- `iOS/UI/Browse/SearchViewController.swift` (ou créer nouveau)
- Supprimer l'onglet Search de la TabBar

**Nouvelle Logique**

```swift
class GlobalSearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var results: [SearchResult] = []
    @Published var isSearching = false

    struct SearchResult {
        let sourceId: String
        let sourceName: String
        let manga: AidokuRunner.Manga
    }

    func search(query: String) async {
        isSearching = true
        results = []

        // Obtenir toutes les sources installées
        let sources = SourceManager.shared.sources

        // Rechercher dans chaque source en parallèle
        await withTaskGroup(of: [SearchResult].self) { group in
            for source in sources {
                group.addTask {
                    do {
                        let mangas = try await source.getMangaList(
                            filters: [],
                            page: 1
                        )

                        // Filtrer par query
                        let filtered = mangas.filter { manga in
                            manga.title.localizedCaseInsensitiveContains(query)
                        }

                        return filtered.map { manga in
                            SearchResult(
                                sourceId: source.key,
                                sourceName: source.name,
                                manga: manga
                            )
                        }
                    } catch {
                        return []
                    }
                }
            }

            for await sourceResults in group {
                results.append(contentsOf: sourceResults)
            }
        }

        isSearching = false
    }
}
```

**Intégration dans Browse**
```swift
// Dans BrowseViewController.swift
// Ajouter un SearchBar en haut qui déclenche la recherche globale
```

**Tests**
- Taper "one piece" dans la recherche
- Vérifier que les résultats de toutes les sources s'affichent
- Vérifier que chaque résultat indique sa source
- Cliquer sur un résultat (doit ouvrir la page du manga)

---

### Phase 6 : Système de Notation (0-10 avec décimales)

**Objectif** : Remplacer les étoiles par une note de 0 à 10 (0.1 de précision)

**Fichiers à Modifier**
- `Shared/Models/UserProfile.swift` - Ajouter `rating: Double?` dans PersonalRanking
- `iOS/New/Views/Manga/MangaView.swift` - Ajouter UI de notation
- `bdd/supabase_schema.sql` - Modifier `scanio_personal_rankings.rating`

**Changements SQL**
```sql
-- Modifier la colonne rating pour accepter des décimales
ALTER TABLE public.scanio_personal_rankings
ALTER COLUMN rating TYPE NUMERIC(3,1); -- 0.0 à 10.0

-- Ajouter une contrainte
ALTER TABLE public.scanio_personal_rankings
ADD CONSTRAINT rating_range CHECK (rating >= 0 AND rating <= 10);
```

**UI de Notation**
```swift
struct RatingView: View {
    @Binding var rating: Double?
    @State private var tempRating: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            Text("Votre note")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // Slider de 0 à 10
                Slider(
                    value: Binding(
                        get: { rating ?? 0 },
                        set: { tempRating = $0 }
                    ),
                    in: 0...10,
                    step: 0.1
                )

                // Affichage de la note
                Text(String(format: "%.1f", rating ?? 0))
                    .font(.title2.bold())
                    .foregroundColor(.accentColor)
                    .frame(width: 50)
            }

            // Boutons rapides
            HStack(spacing: 8) {
                ForEach([5.0, 7.0, 8.0, 9.0, 10.0], id: \.self) { value in
                    Button(String(format: "%.0f", value)) {
                        rating = value
                    }
                    .buttonStyle(.bordered)
                    .tint(rating == value ? .accentColor : .gray)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}
```

**Intégration dans MangaView**
```swift
// Ajouter dans la section des actions (à côté de Favoris, etc.)
RatingView(rating: $viewModel.userRating)
    .onChange(of: viewModel.userRating) { newRating in
        Task {
            await viewModel.updateRating(newRating)
        }
    }
```

**Tests**
- Ouvrir un manga
- Noter avec le slider
- Vérifier que la note est sauvegardée
- Fermer et rouvrir le manga
- Vérifier que la note est affichée

---

### Phase 7 : Téléchargement/Suppression par Swipe

**Objectif** : Swipe à droite = télécharger, swipe à gauche = supprimer

**Fichiers à Modifier**
- `iOS/New/Views/Manga/ChapterTableCell.swift`
- `iOS/New/Views/Manga/MangaView.swift`

**Implémentation**
```swift
// Dans MangaView.swift - Liste des chapitres
List {
    ForEach(viewModel.chapters) { chapter in
        ChapterRow(chapter: chapter)
            .swipeActions(edge: .leading) {
                // Swipe à droite = Télécharger
                Button {
                    downloadChapter(chapter)
                } label: {
                    Label("Télécharger", systemImage: "arrow.down.circle.fill")
                }
                .tint(.blue)
            }
            .swipeActions(edge: .trailing) {
                // Swipe à gauche = Supprimer
                if isChapterDownloaded(chapter) {
                    Button(role: .destructive) {
                        deleteChapter(chapter)
                    } label: {
                        Label("Supprimer", systemImage: "trash.fill")
                    }
                }
            }
    }
}

func downloadChapter(_ chapter: Chapter) {
    Task {
        await DownloadManager.shared.downloadChapter(
            sourceId: manga.sourceKey,
            mangaId: manga.key,
            chapter: chapter
        )
    }
}

func deleteChapter(_ chapter: Chapter) {
    DownloadManager.shared.deleteChapter(
        sourceId: manga.sourceKey,
        mangaId: manga.key,
        chapterId: chapter.key
    )
}

func isChapterDownloaded(_ chapter: Chapter) -> Bool {
    DownloadManager.shared.isChapterDownloaded(
        chapter: chapter.toOld(
            sourceId: manga.sourceKey,
            mangaId: manga.key
        )
    )
}
```

**Affichage de la Taille**
```swift
struct ChapterRow: View {
    let chapter: Chapter
    @State private var downloadSize: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(chapter.title ?? "Chapitre \(chapter.chapterNumber ?? 0)")
                    .font(.body)

                if let size = downloadSize {
                    Text(size)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isDownloaded {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .task {
            if isDownloaded {
                downloadSize = await getChapterSize(chapter)
            }
        }
    }

    func getChapterSize(_ chapter: Chapter) async -> String {
        let bytes = DownloadManager.shared.getChapterSize(
            sourceId: manga.sourceKey,
            mangaId: manga.key,
            chapterId: chapter.key
        )
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
```

**Tests**
- Swiper un chapitre à droite
- Vérifier que le téléchargement démarre
- Vérifier que la taille s'affiche
- Swiper à gauche
- Vérifier que le chapitre est supprimé

---

### Phase 8 : Affichage de la Taille des Mangas

**Objectif** : Afficher la taille totale d'un manga téléchargé

**Fichiers à Modifier**
- `iOS/New/Views/Manga/MangaDetailsHeaderView.swift`
- `Shared/Managers/DownloadManager.swift`

**Nouvelle Fonction dans DownloadManager**
```swift
extension DownloadManager {
    func getMangaTotalSize(sourceId: String, mangaId: String) -> Int64 {
        var totalSize: Int64 = 0

        // Obtenir tous les chapitres téléchargés
        let chapters = getDownloadedChapters(sourceId: sourceId, mangaId: mangaId)

        for chapter in chapters {
            totalSize += Int64(getChapterSize(
                sourceId: sourceId,
                mangaId: mangaId,
                chapterId: chapter.id
            ))
        }

        return totalSize
    }

    func getChapterSize(sourceId: String, mangaId: String, chapterId: String) -> Int {
        let chapterPath = getChapterDirectory(
            sourceId: sourceId,
            mangaId: mangaId,
            chapterId: chapterId
        )

        guard let enumerator = FileManager.default.enumerator(atPath: chapterPath.path) else {
            return 0
        }

        var size = 0
        for case let file as String in enumerator {
            let filePath = chapterPath.appendingPathComponent(file)
            if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath.path) {
                size += attributes[.size] as? Int ?? 0
            }
        }

        return size
    }
}
```

**Affichage dans MangaDetailsHeaderView**
```swift
// Ajouter dans la section des statistiques
if downloadedChaptersCount > 0 {
    HStack(spacing: 4) {
        Image(systemName: "arrow.down.circle.fill")
            .foregroundColor(.green)
        Text("\(downloadedChaptersCount) chapitres")
        Text("•")
        Text(totalDownloadSize)
    }
    .font(.caption)
    .foregroundColor(.secondary)
}

// Variables
@State private var downloadedChaptersCount = 0
@State private var totalDownloadSize = ""

// Dans onAppear
Task {
    downloadedChaptersCount = DownloadManager.shared.getDownloadedChapters(
        sourceId: manga.sourceKey,
        mangaId: manga.key
    ).count

    let bytes = DownloadManager.shared.getMangaTotalSize(
        sourceId: manga.sourceKey,
        mangaId: manga.key
    )
    totalDownloadSize = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
}
```

---

### Phase 9 : Navigation Privée et Historique

**Objectif** : Respecter le mode navigation privée pour l'historique Supabase

**Fichiers à Modifier**
- `Shared/Managers/HistoryManager.swift`
- `iOS/UI/Reader/ReaderViewController.swift`

**Vérification du Mode Incognito**
```swift
// Dans HistoryManager.swift - setProgress()
func setProgress(chapter: Chapter, progress: Int, totalPages: Int, completed: Bool) async {
    // Sauvegarder localement (CoreData)
    await coreData.setProgress(
        sourceId: chapter.sourceId,
        mangaId: chapter.mangaId,
        chapterId: chapter.chapterId,
        progress: progress,
        totalPages: totalPages,
        completed: completed
    )

    // NOUVEAU: Vérifier le mode incognito
    let isIncognito = UserDefaults.standard.bool(forKey: "General.incognitoMode")

    // Ne synchroniser avec Supabase que si pas en mode incognito
    if !isIncognito, SupabaseManager.shared.isAuthenticated {
        do {
            try await SupabaseManager.shared.upsertReadingHistory(
                canonicalMangaId: chapter.canonicalMangaId ?? "",
                sourceId: chapter.sourceId,
                mangaId: chapter.mangaId,
                chapterId: chapter.chapterId,
                chapterNumber: String(chapter.chapterNum ?? 0),
                chapterTitle: chapter.title,
                pageNumber: progress,
                totalPages: totalPages,
                isCompleted: completed
            )
            print("✅ History synced to Supabase")
        } catch {
            print("❌ Failed to sync history: \(error)")
        }
    } else if isIncognito {
        print("🔒 Incognito mode: History not synced to Supabase")
    }
}
```

**Tests**
- Activer le mode navigation privée
- Lire un chapitre
- Vérifier que l'historique local est sauvegardé
- Vérifier que l'historique Supabase n'est PAS mis à jour
- Désactiver le mode navigation privée
- Lire un chapitre
- Vérifier que l'historique Supabase est mis à jour

---

### Phase 10 : Fusion Historique Local + Supabase

**Objectif** : Combiner l'onglet Historique avec l'historique Supabase

**Fichiers à Modifier**
- `iOS/New/Views/History/HistoryView.swift`
- `iOS/New/Views/History/HistoryView+ViewModel.swift`
- `iOS/New/Views/Settings/ProfileSettingsView.swift` (retirer l'onglet historique)

**Nouvelle Logique HistoryViewModel**
```swift
class HistoryViewModel: ObservableObject {
    @Published var history: [HistorySection] = []
    @Published var isLoading = false

    func loadHistory() async {
        isLoading = true

        // 1. Charger l'historique local (CoreData)
        let localHistory = await loadLocalHistory()

        // 2. Si authentifié, charger l'historique Supabase
        var supabaseHistory: [ReadingHistoryWithManga] = []
        if SupabaseManager.shared.isAuthenticated {
            supabaseHistory = (try? await SupabaseManager.shared.getReadingHistoryWithManga(limit: 1000)) ?? []
        }

        // 3. Fusionner les deux historiques
        let merged = mergeHistories(local: localHistory, supabase: supabaseHistory)

        // 4. Grouper par date
        history = groupByDate(merged)

        isLoading = false
    }

    func mergeHistories(
        local: [LocalHistoryEntry],
        supabase: [ReadingHistoryWithManga]
    ) -> [HistoryEntry] {
        var merged: [String: HistoryEntry] = [:]

        // Ajouter l'historique local
        for entry in local {
            let key = "\(entry.sourceId)-\(entry.mangaId)-\(entry.chapterId)"
            merged[key] = HistoryEntry(from: entry)
        }

        // Fusionner avec Supabase (prendre la date la plus récente)
        for entry in supabase {
            let key = "\(entry.sourceId)-\(entry.mangaId)-\(entry.chapterId)"

            if let existing = merged[key] {
                // Garder la date la plus récente
                if entry.lastReadAt > existing.lastReadAt {
                    merged[key] = HistoryEntry(from: entry)
                }
            } else {
                merged[key] = HistoryEntry(from: entry)
            }
        }

        return Array(merged.values).sorted { $0.lastReadAt > $1.lastReadAt }
    }
}
```

**Retirer l'Onglet Historique du Profil**
```swift
// Dans ProfileSettingsView.swift
// Supprimer la NavigationLink vers ReadingHistoryView
// L'historique est maintenant accessible uniquement via l'onglet principal
```

**Tests**
- Lire des chapitres en local
- Se connecter
- Vérifier que l'historique local et Supabase sont fusionnés
- Vérifier qu'il n'y a pas de doublons
- Vérifier que les dates sont correctes

---

### Phase 11 : Refonte de la Page Profil

**Objectif** : Améliorer l'affichage des statistiques et déplacer le profil hors de Settings

**Changements de Navigation**
```
Avant:
Settings > Profil

Après:
Bouton en haut à droite de Discover > Profil
```

**Fichiers à Modifier**
- `iOS/New/Views/Profile/UserProfileSheet.swift`
- `iOS/New/Views/Discover/DiscoverView.swift` (ajouter bouton profil)
- `iOS/New/Views/Settings/SettingsView.swift` (retirer l'entrée Profil)

**Nouveau Design de Profil**
```swift
struct UserProfileSheet: View {
    @StateObject var viewModel = UserProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header avec avatar et nom
                profileHeader

                // Statistiques en grille (style moderne)
                statsGrid

                // Manga favoris
                favoriteMangaSection

                // Rankings personnels
                personalRankingsSection

                // Activité récente
                recentActivitySection
            }
            .padding()
        }
        .navigationTitle("Profil")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Modifier") {
                    showEditProfile = true
                }
            }
        }
    }

    var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Chapitres lus",
                value: "\(viewModel.stats.totalChaptersRead)",
                icon: "book.fill",
                color: .blue
            )

            StatCard(
                title: "Mangas lus",
                value: "\(viewModel.stats.totalMangaRead)",
                icon: "books.vertical.fill",
                color: .purple
            )

            StatCard(
                title: "Favoris",
                value: "\(viewModel.stats.totalFavorites)",
                icon: "heart.fill",
                color: .red
            )

            StatCard(
                title: "Karma",
                value: "\(viewModel.stats.karma)",
                icon: "star.fill",
                color: .orange
            )

            StatCard(
                title: "Commentaires",
                value: "\(viewModel.stats.totalComments)",
                icon: "bubble.left.fill",
                color: .green
            )

            StatCard(
                title: "En cours",
                value: "\(viewModel.stats.totalReading)",
                icon: "clock.fill",
                color: .cyan
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title.bold())

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}
```

**Bouton Profil dans Discover**
```swift
// Dans DiscoverView.swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button {
            showProfile = true
        } label: {
            // Avatar de l'utilisateur ou icône par défaut
            if let avatarURL = viewModel.userAvatar {
                AsyncImage(url: URL(string: avatarURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
            }
        }
    }
}
.sheet(isPresented: $showProfile) {
    NavigationView {
        UserProfileSheet()
    }
}
```

---

## 📅 Ordre d'Implémentation Recommandé

### Sprint 1 : Corrections Critiques (1-2 semaines)
**Priorité** : 🔴 MAXIMALE

1. **Phase 0.1** : Corriger la synchronisation Library/Sources/History
   - Temps estimé : 3-5 jours
   - Bloquant pour toutes les autres features

2. **Phase 0.2** : Corriger le système de commentaires
   - Temps estimé : 2-3 jours
   - Important pour l'engagement utilisateur

**Critères de Succès**
- ✅ Library se synchronise correctement avec Supabase
- ✅ Sources installées sont sauvegardées
- ✅ Historique est synchronisé
- ✅ Commentaires s'affichent et se créent correctement
- ✅ Votes fonctionnent

---

### Sprint 2 : Améliorations UX Rapides (1 semaine)
**Priorité** : 🟡 HAUTE

3. **Phase 1** : Changement de couleur d'accent (bleu)
   - Temps estimé : 1 heure
   - Impact visuel immédiat

4. **Phase 2** : Préchargement du chapitre suivant
   - Temps estimé : 1-2 jours
   - Amélioration majeure de l'expérience de lecture

5. **Phase 7** : Téléchargement/Suppression par swipe
   - Temps estimé : 1 jour
   - UX moderne et intuitive

6. **Phase 8** : Affichage de la taille des mangas
   - Temps estimé : 1 jour
   - Utile pour gérer le stockage

**Critères de Succès**
- ✅ App utilise le bleu comme couleur principale
- ✅ Chapitres suivants se chargent automatiquement
- ✅ Swipe pour télécharger/supprimer fonctionne
- ✅ Taille des téléchargements affichée

---

### Sprint 3 : Nouvelles Features Majeures (2-3 semaines)
**Priorité** : 🟢 MOYENNE

7. **Phase 4** : Page Découvrir
   - Temps estimé : 5-7 jours
   - Feature majeure, nouvelle page d'accueil

8. **Phase 5** : Recherche globale multi-sources
   - Temps estimé : 2-3 jours
   - Améliore la découvrabilité

9. **Phase 6** : Système de notation (0-10)
   - Temps estimé : 2-3 jours
   - Engagement utilisateur

10. **Phase 11** : Refonte de la page Profil
    - Temps estimé : 3-4 jours
    - Meilleure présentation des stats

**Critères de Succès**
- ✅ Page Découvrir est la page par défaut
- ✅ Recherche fonctionne dans toutes les sources
- ✅ Notation 0-10 fonctionne et se sauvegarde
- ✅ Profil accessible depuis Discover
- ✅ Stats affichées en grille moderne

---

### Sprint 4 : Features Avancées (2-3 semaines)
**Priorité** : 🔵 BASSE

11. **Phase 3** : Long-term caching avec Supabase
    - Temps estimé : 7-10 jours
    - Feature complexe, nécessite backend

12. **Phase 9** : Navigation privée et historique
    - Temps estimé : 1-2 jours
    - Respect de la vie privée

13. **Phase 10** : Fusion historique local + Supabase
    - Temps estimé : 2-3 jours
    - Dépend de Phase 0.1

**Critères de Succès**
- ✅ Chapitres cachés sur Supabase
- ✅ Handshake de performance fonctionne
- ✅ Mode incognito respecté
- ✅ Historique fusionné sans doublons

---

## 🛠️ Guide de Build

### Prérequis

```bash
# Xcode 15.0+
xcode-select --version

# Vérifier que Xcode est installé
xcodebuild -version
```

### Étapes de Build

#### 1. Cloner le Repository

```bash
cd ~/Documents
git clone https://github.com/amintt2/scanio.git
cd scanio
```

#### 2. Vérifier la Structure

```bash
# Vérifier que tous les dossiers sont présents
ls -la

# Devrait afficher :
# - iOS/
# - macOS/
# - Shared/
# - TomoScanTests/
# - docs/
# - bdd/
# - scripts/
# - Aidoku.xcodeproj
```

#### 3. Ouvrir le Projet dans Xcode

```bash
open Aidoku.xcodeproj
```

#### 4. Configurer le Projet

**4.1 - Sélectionner le Scheme**
- En haut à gauche : Sélectionner "Aidoku (iOS)"
- Sélectionner un simulateur (ex: iPhone 15)

**4.2 - Vérifier les Signing & Capabilities**
- Cliquer sur le projet "Aidoku" dans le navigateur
- Sélectionner le target "Aidoku (iOS)"
- Onglet "Signing & Capabilities"
- Cocher "Automatically manage signing"
- Sélectionner votre Team

**4.3 - Configurer Supabase (si pas déjà fait)**
```swift
// Créer Shared/Managers/SupabaseConfig.swift
import Foundation

enum SupabaseConfig {
    static let url = "https://supabase.mciut.fr"
    static let anonKey = "VOTRE_ANON_KEY"
}
```

#### 5. Build le Projet

**Option A : Via Xcode (Recommandé)**
```
1. Appuyer sur Cmd + B (Build)
2. Attendre la fin de la compilation
3. Vérifier qu'il n'y a pas d'erreurs
```

**Option B : Via Terminal**
```bash
# Build pour iOS Simulator
xcodebuild \
  -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  build

# Vérifier le résultat
echo $?  # Devrait afficher 0 si succès
```

#### 6. Exécuter l'App

**Option A : Via Xcode**
```
1. Appuyer sur Cmd + R (Run)
2. L'app se lance dans le simulateur
```

**Option B : Via Terminal**
```bash
xcodebuild \
  -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  run
```

#### 7. Exécuter les Tests

```bash
# Configurer les tests (première fois seulement)
./scripts/setup_tests.sh

# Exécuter les tests via Xcode
# Appuyer sur Cmd + U

# Ou via terminal
xcodebuild test \
  -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

#### 8. Vérifier les Logs

**Dans Xcode**
```
1. Ouvrir la console : Cmd + Shift + Y
2. Filtrer par emoji :
   - 🔵 = Info
   - ✅ = Succès
   - ❌ = Erreur
   - 🔄 = Sync
   - 📚 = Library
   - 📊 = Stats
```

**Logs Importants à Surveiller**
```
✅ Session refreshed successfully!
✅ Sources sync completed
✅ Library sync completed
✅ History sync completed
🔴 No network connection available
❌ SyncManager: Full sync failed
```

---

## 🐛 Debugging

### Problèmes Courants

#### Build Failed - "Cannot find 'ErrorManager'"

```bash
# Solution
./scripts/add_error_manager.sh
# Suivre les instructions pour ajouter ErrorManager.swift au projet
```

#### Build Failed - "No such module 'AidokuRunner'"

```bash
# Solution : Clean build folder
# Dans Xcode : Product > Clean Build Folder (Cmd + Shift + K)
# Puis rebuild : Cmd + B
```

#### Sync Failed - "networkError"

```bash
# Vérifier la connexion Supabase
# 1. Ouvrir Shared/Managers/SupabaseConfig.swift
# 2. Vérifier que l'URL et la clé sont correctes
# 3. Tester la connexion :

curl https://supabase.mciut.fr/rest/v1/ \
  -H "apikey: VOTRE_ANON_KEY"

# Devrait retourner un JSON, pas une erreur
```

#### Tests Failed

```bash
# Reconfigurer les tests
./scripts/setup_tests.sh

# Vérifier que le target de tests existe
# Dans Xcode : Product > Scheme > Manage Schemes
# Vérifier que "TomoScanTests" est présent
```

---

## 📊 Métriques de Succès

### Phase 0 (Corrections)
- [ ] Taux de synchronisation : 100% (actuellement ~0%)
- [ ] Commentaires créés avec succès : 100%
- [ ] Votes enregistrés : 100%

### Phase 1-2 (UX Rapides)
- [ ] Temps de chargement chapitre suivant : < 1s (actuellement 3-5s)
- [ ] Satisfaction utilisateur : +30%

### Phase 3-4 (Features Majeures)
- [ ] Engagement page Découvrir : 60% des sessions
- [ ] Recherches multi-sources : 80% des recherches
- [ ] Taux de notation : 40% des mangas lus

### Phase 5 (Avancées)
- [ ] Utilisation du cache Supabase : 30% des lectures
- [ ] Réduction temps de chargement : -50%

---

## 📝 Notes pour l'IA qui Implémentera

### Conventions de Code

**Swift Style**
- Indentation : 4 espaces
- Accolades : Style K&R (même ligne)
- Nommage : camelCase pour variables/fonctions, PascalCase pour types

**Commits**
```bash
# Format : type(scope): description

# Exemples :
git commit -m "fix(sync): correct library upload to Supabase"
git commit -m "feat(discover): add discover page with popular manga"
git commit -m "refactor(profile): move profile out of settings"
git commit -m "test(sync): add tests for library sync"
```

**Logs**
```swift
// Utiliser les emojis pour faciliter le debugging
print("🔵 Info message")
print("✅ Success message")
print("❌ Error message")
print("🔄 Sync message")
print("📚 Library message")
print("📊 Stats message")
print("🔒 Privacy message")
```

**Tests**
```swift
// Nommage : test + WhatIsBeingTested + ExpectedBehavior
func testLibrarySync_WhenItemAdded_ShouldUploadToSupabase() async throws {
    // Arrange
    let item = createTestLibraryItem()

    // Act
    try await syncManager.uploadLibraryItemToSupabase(item)

    // Assert
    let supabaseItems = try await supabaseManager.getLibrary()
    XCTAssertTrue(supabaseItems.contains { $0.mangaId == item.mangaId })
}
```

### Fichiers Importants

**Ne PAS Modifier**
- `Shared/Sources/` - Sources WASM (sauf si absolument nécessaire)
- `iOS/UI/` - Vues UIKit legacy (sauf si spécifié)
- `Shared/Data/` - CoreData models (sauf si spécifié)

**Modifier avec Précaution**
- `Shared/Managers/CoreDataManager.swift` - Risque de perte de données
- `Shared/Managers/DownloadManager.swift` - Risque de corruption des téléchargements
- `bdd/*.sql` - Toujours tester en local avant de déployer

**Libre de Modifier**
- `iOS/New/Views/` - Nouvelles vues SwiftUI
- `Shared/Managers/SupabaseManager.swift` - Extensions OK
- `Shared/Managers/SyncManager.swift` - Améliorer la logique de sync

### Ressources

**Documentation**
- [Swift.org](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Supabase Docs](https://supabase.com/docs)
- [CoreData Guide](https://developer.apple.com/documentation/coredata)

**Outils**
- [SF Symbols](https://developer.apple.com/sf-symbols/) - Icônes système
- [Xcode Instruments](https://developer.apple.com/xcode/features/) - Profiling
- [Supabase Studio](https://supabase.com/dashboard) - Database management

---

## ✅ Checklist Finale

Avant de considérer une phase comme terminée :

- [ ] Code compilé sans warnings
- [ ] Tests unitaires passent (si applicable)
- [ ] Tests manuels effectués
- [ ] Logs de debug ajoutés
- [ ] Documentation mise à jour
- [ ] Commit avec message descriptif
- [ ] Build réussi sur simulateur
- [ ] Build réussi sur device (si possible)
- [ ] Pas de régression sur features existantes
- [ ] Performance acceptable (pas de lag)

---

**Dernière mise à jour** : 2025-11-06
**Version du plan** : 1.0
**Auteur** : Augment AI Assistant



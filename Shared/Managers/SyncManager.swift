//
//  SyncManager.swift
//  Aidoku
//
//  Manages synchronization between CoreData and Supabase
//

import Foundation
import CoreData
import AidokuRunner

/// Manages bidirectional synchronization between CoreData (local) and Supabase (cloud)
class SyncManager {
    
    static let shared = SyncManager()
    
    private let coreData = CoreDataManager.shared
    private let supabase = SupabaseManager.shared
    
    private init() {}
    
    // MARK: - Full Sync
    
    /// Synchronize all data (sources, library, history, categories, trackers)
    func syncAll() async throws {
        guard supabase.isAuthenticated else {
            print("⚠️ SyncManager: User not authenticated, skipping sync")
            return
        }

        print("🔄 SyncManager: Starting full sync...")

        do {
            // Sync in order: sources first, then library, then history
            try await syncSources()
            try await syncLibrary()
            try await syncHistory()
            try await syncCategories()
            try await syncTrackers()
            print("✅ SyncManager: Full sync completed successfully")

            // Notify UI to refresh
            await MainActor.run {
                NotificationCenter.default.post(name: .updateLibrary, object: nil)
                NotificationCenter.default.post(name: .updateHistory, object: nil)
            }
        } catch {
            print("❌ SyncManager: Full sync failed: \(error)")
            throw error
        }
    }

    // MARK: - Sources Sync

    /// Bidirectional sync: merge local sources and Supabase sources
    func syncSources() async throws {
        print("🔌 SyncManager: Syncing sources...")

        // 1. Fetch sources from Supabase
        let supabaseSources = try await supabase.fetchUserSources()
        print("🔌 Fetched \(supabaseSources.count) sources from Supabase")

        // 2. Get currently installed sources
        let installedSources = SourceManager.shared.sources
        let installedSourceIds = Set(installedSources.map { $0.id })
        let supabaseSourceIds = Set(supabaseSources.map { $0.sourceId })
        print("🔌 Found \(installedSources.count) installed sources locally")

        // 3. Upload local sources that are not in Supabase
        var uploadedCount = 0
        for source in installedSources {
            if !supabaseSourceIds.contains(source.id) {
                print("📤 Uploading source to Supabase: \(source.name) (\(source.id))")
                do {
                    // Note: We don't have the original download URL in CoreData
                    // Sources will be uploaded without URL (user must add manually on other devices)
                    try await supabase.addUserSource(
                        sourceId: source.id,
                        sourceName: source.name,
                        sourceLang: source.languages.first,
                        sourceUrl: nil
                    )
                    print("✅ Successfully uploaded source: \(source.id)")
                    uploadedCount += 1
                } catch {
                    print("❌ Failed to upload source \(source.id): \(error)")
                }
            } else {
                print("✅ Source already in Supabase: \(source.id)")
            }
        }

        // 4. Download sources from Supabase that are not installed locally
        var installedCount = 0
        var failedCount = 0

        for userSource in supabaseSources {
            if !installedSourceIds.contains(userSource.sourceId) {
                print("📥 Need to install source: \(userSource.sourceId)")

                // Try to install if we have the URL
                if let sourceUrlString = userSource.sourceUrl,
                   let sourceUrl = URL(string: sourceUrlString) {
                    do {
                        print("⬇️ Downloading source from: \(sourceUrlString)")
                        let installedSource = try await SourceManager.shared.importSource(from: sourceUrl)

                        if installedSource != nil {
                            print("✅ Successfully installed source: \(userSource.sourceId)")
                            installedCount += 1
                        } else {
                            print("⚠️ Failed to install source \(userSource.sourceId)")
                            failedCount += 1
                        }
                    } catch {
                        print("❌ Error installing source \(userSource.sourceId): \(error)")
                        failedCount += 1
                    }
                } else {
                    print("⚠️ No download URL for source \(userSource.sourceId) - user must add manually")
                    failedCount += 1
                }
            } else {
                print("✅ Source already installed: \(userSource.sourceId)")
            }
        }

        print("✅ Sources sync completed - Uploaded: \(uploadedCount), Installed: \(installedCount), Failed: \(failedCount)")
    }

    // MARK: - History Sync

    /// Sync reading history from Supabase to local CoreData
    func syncHistory() async throws {
        print("📖 SyncManager: Syncing reading history...")

        // Fetch history from Supabase
        let supabaseHistory = try await supabase.getReadingHistory(limit: 1000)
        print("📖 Fetched \(supabaseHistory.count) history items from Supabase")

        // Group history by manga to fetch metadata efficiently
        var mangaToFetch: Set<String> = []
        for item in supabaseHistory {
            let key = "\(item.sourceId)|\(item.mangaId)"
            mangaToFetch.insert(key)
        }

        // Fetch manga metadata for all history items
        print("📖 Need to fetch metadata for \(mangaToFetch.count) manga")
        for mangaKey in mangaToFetch {
            let parts = mangaKey.split(separator: "|")
            guard parts.count == 2 else { continue }
            let sourceId = String(parts[0])
            let mangaId = String(parts[1])

            // Check if manga already exists in CoreData
            let exists = await coreData.container.performBackgroundTask { context in
                self.coreData.getManga(sourceId: sourceId, mangaId: mangaId, context: context) != nil
            }

            if !exists {
                print("📖 Fetching manga metadata: \(sourceId)/\(mangaId)")
                await fetchMangaMetadata(sourceId: sourceId, mangaId: mangaId)
            }
        }

        // Download history to CoreData
        var restoredCount = 0
        for historyItem in supabaseHistory {
            let restored = await downloadHistoryItem(historyItem)
            if restored {
                restoredCount += 1
            }
        }

        print("✅ History sync completed - Restored: \(restoredCount)/\(supabaseHistory.count)")
    }

    /// Fetch manga metadata from source and save to CoreData
    private func fetchMangaMetadata(sourceId: String, mangaId: String) async {
        guard let source = SourceManager.shared.source(for: sourceId) else {
            print("⚠️ Source not found: \(sourceId)")
            return
        }

        do {
            // Create a basic manga object
            let basicManga = AidokuRunner.Manga(sourceKey: sourceId, key: mangaId, title: "")

            // Fetch full details with chapters
            let manga = try await source.getMangaUpdate(manga: basicManga, needsDetails: true, needsChapters: true)

            // Save to CoreData in the Cloud store
            await coreData.container.performBackgroundTask { context in
                let mangaObject = self.coreData.getOrCreateManga(manga, sourceId: sourceId, context: context)

                // Save chapters
                if let chapters = manga.chapters {
                    _ = self.coreData.setChapters(chapters, sourceId: sourceId, mangaId: mangaId, context: context)
                }

                do {
                    try context.save()
                    print("✅ Saved manga metadata: \(manga.title ?? mangaId)")
                } catch {
                    print("❌ Failed to save manga metadata: \(error)")
                }
            }
        } catch {
            print("❌ Failed to fetch manga metadata for \(sourceId)/\(mangaId): \(error)")
        }
    }

    /// Download a single history item to CoreData
    /// Returns true if successfully restored
    private func downloadHistoryItem(_ item: ReadingHistory) async -> Bool {
        return await coreData.container.performBackgroundTask { context in
            // Check if we have this manga in CoreData
            let manga = self.coreData.getManga(
                sourceId: item.sourceId,
                mangaId: item.mangaId,
                context: context
            )

            if manga == nil {
                print("⚠️ Cannot restore history for \(item.mangaId) - manga not in CoreData")
                return false
            }

            // Find chapter by chapter number (since we don't have chapterId in Supabase)
            let chapters = self.coreData.getChapters(
                sourceId: item.sourceId,
                mangaId: item.mangaId,
                context: context
            )

            // Try to find chapter by number
            guard let chapterNumber = Float(item.chapterNumber),
                  let chapter = chapters.first(where: { $0.chapter?.floatValue == chapterNumber }) else {
                print("⚠️ Cannot restore history for chapter \(item.chapterNumber) - chapter not in CoreData")
                return false
            }

            // Get or create history object
            let historyObject = self.coreData.getHistory(
                sourceId: item.sourceId,
                mangaId: item.mangaId,
                chapterId: chapter.id,
                context: context
            ) ?? {
                let newHistory = HistoryObject(context: context)
                newHistory.sourceId = item.sourceId
                newHistory.mangaId = item.mangaId
                newHistory.chapterId = chapter.id
                newHistory.chapter = chapter
                return newHistory
            }()

            // Update with Supabase data (use most recent)
            if historyObject.dateRead == nil || item.lastReadAt > historyObject.dateRead! {
                historyObject.dateRead = item.lastReadAt
            }

            // Update progress
            historyObject.progress = Int16(item.pageNumber)
            historyObject.total = Int16(item.totalPages)
            historyObject.completed = item.isCompleted

            do {
                try context.save()
                print("✅ Restored history for chapter \(item.chapterNumber)")
                return true
            } catch {
                print("❌ Failed to save history: \(error)")
                return false
            }
        }
    }
    
    // MARK: - Library Sync
    
    /// Bidirectional sync: merge CoreData and Supabase library
    func syncLibrary() async throws {
        print("📚 SyncManager: Syncing library...")
        
        // 1. Fetch library from Supabase
        let supabaseLibrary = try await fetchLibraryFromSupabase()
        print("📚 Fetched \(supabaseLibrary.count) items from Supabase")
        
        // 2. Get library from CoreData
        let coreDataLibrary = await getCoreDataLibrary()
        print("📚 Found \(coreDataLibrary.count) items in CoreData")
        
        // 3. Merge: Upload new items from CoreData to Supabase
        for item in coreDataLibrary {
            // Check if item exists in Supabase
            let existsInSupabase = supabaseLibrary.contains { $0.canonicalMangaId == item.canonicalMangaId }
            
            if !existsInSupabase {
                print("📤 Uploading to Supabase: \(item.mangaId)")
                try await uploadLibraryItemToSupabase(item)
            } else {
                // Item exists, check if we need to update timestamps
                if let supabaseItem = supabaseLibrary.first(where: { $0.canonicalMangaId == item.canonicalMangaId }) {
                    try await mergeLibraryItem(coreDataItem: item, supabaseItem: supabaseItem)
                }
            }
        }
        
        // 4. Download items from Supabase that don't exist in CoreData
        for item in supabaseLibrary {
            let existsInCoreData = coreDataLibrary.contains { $0.canonicalMangaId == item.canonicalMangaId }

            if !existsInCoreData {
                print("📥 Downloading from Supabase: \(item.mangaId)")
                await downloadLibraryItem(item)
            }
        }

        print("✅ Library sync completed")
    }

    /// Download a single library item from Supabase to CoreData
    private func downloadLibraryItem(_ item: SupabaseLibraryItem) async {
        // Check if source is installed
        guard let source = SourceManager.shared.source(for: item.sourceId) else {
            print("⚠️ Cannot restore \(item.mangaId) - source \(item.sourceId) not installed")
            return
        }

        // Check if manga already exists in library
        let alreadyInLibrary = await coreData.container.performBackgroundTask { context in
            self.coreData.hasLibraryManga(sourceId: item.sourceId, mangaId: item.mangaId, context: context)
        }

        if alreadyInLibrary {
            print("✅ Manga \(item.mangaId) already in library")
            return
        }

        // Fetch manga details from source
        print("🔍 Fetching manga details for \(item.mangaId) from source...")
        do {
            // Create a basic manga object
            let basicManga = AidokuRunner.Manga(sourceKey: item.sourceId, key: item.mangaId, title: "")

            // Fetch full details with chapters
            let manga = try await source.getMangaUpdate(manga: basicManga, needsDetails: true, needsChapters: true)

            // Add to library using CoreData
            await coreData.container.performBackgroundTask { context in
                // Add to library (creates manga and library objects)
                self.coreData.addToLibrary(
                    sourceId: item.sourceId,
                    manga: manga,
                    chapters: manga.chapters ?? [],
                    context: context
                )

                // Update timestamps from Supabase
                if let libraryManga = self.coreData.getLibraryManga(
                    sourceId: item.sourceId,
                    mangaId: item.mangaId,
                    context: context
                ) {
                    if let dateAdded = item.dateAdded?.iso8601Date {
                        libraryManga.dateAdded = dateAdded
                    }
                    if let lastOpened = item.lastOpened?.iso8601Date {
                        libraryManga.lastOpened = lastOpened
                    }
                    if let lastRead = item.lastRead?.iso8601Date {
                        libraryManga.lastRead = lastRead
                    }
                    if let lastUpdated = item.lastUpdated?.iso8601Date {
                        libraryManga.lastUpdated = lastUpdated
                    }
                }

                do {
                    try context.save()
                    print("✅ Restored manga \(item.mangaId) to library")
                } catch {
                    print("❌ Failed to save manga: \(error)")
                }
            }
        } catch {
            print("❌ Failed to fetch manga details: \(error)")
        }
    }
    
    /// Upload a single library item to Supabase
    func uploadLibraryItemToSupabase(_ item: CoreDataLibraryItem) async throws {
        guard let userId = supabase.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        print("📤 uploadLibraryItemToSupabase - Source: \(item.sourceId), Manga: \(item.mangaId)")
        print("📤 Canonical ID: \(item.canonicalMangaId)")

        let url = URL(string: "\(supabase.supabaseURL)/rest/v1/rpc/scanio_upsert_user_library")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabase.currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "p_user_id": userId,
            "p_canonical_manga_id": item.canonicalMangaId,
            "p_source_id": item.sourceId,
            "p_manga_id": item.mangaId,
            "p_date_added": item.dateAdded?.iso8601String ?? Date().iso8601String,
            "p_last_opened": item.lastOpened?.iso8601String as Any,
            "p_last_read": item.lastRead?.iso8601String as Any,
            "p_last_updated": item.lastUpdated?.iso8601String as Any
        ]

        print("📤 Request body: \(body)")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw SupabaseError.networkError
        }

        print("📤 HTTP Status: \(httpResponse.statusCode)")

        if !(200...299).contains(httpResponse.statusCode) {
            let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
            print("❌ Upload failed - Response: \(responseBody)")
            throw SupabaseError.networkError
        }

        print("✅ Successfully uploaded library item")
    }

    /// Remove a library item from Supabase
    func removeLibraryItemFromSupabase(canonicalMangaId: String) async throws {
        guard let userId = supabase.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        print("🗑️ Removing library item from Supabase - Canonical ID: \(canonicalMangaId)")

        let url = URL(string: "\(supabase.supabaseURL)/rest/v1/scanio_user_library?user_id=eq.\(userId)&canonical_manga_id=eq.\(canonicalMangaId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabase.currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw SupabaseError.networkError
        }

        print("🗑️ HTTP Status: \(httpResponse.statusCode)")

        if !(200...299).contains(httpResponse.statusCode) {
            let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
            print("❌ Delete failed - Response: \(responseBody)")
            throw SupabaseError.networkError
        }

        print("✅ Successfully removed library item from Supabase")
    }
    
    /// Merge library item: use most recent timestamps
    private func mergeLibraryItem(coreDataItem: CoreDataLibraryItem, supabaseItem: SupabaseLibraryItem) async throws {
        // Compare timestamps and update if needed
        var needsUpdate = false
        var lastOpened = coreDataItem.lastOpened
        var lastRead = coreDataItem.lastRead

        // Use most recent timestamps
        if let supabaseLastOpenedStr = supabaseItem.lastOpened,
           let supabaseLastOpened = supabaseLastOpenedStr.iso8601Date,
           let coreDataLastOpened = coreDataItem.lastOpened {
            if supabaseLastOpened > coreDataLastOpened {
                lastOpened = supabaseLastOpened
                needsUpdate = true
            }
        }

        if let supabaseLastReadStr = supabaseItem.lastRead,
           let supabaseLastRead = supabaseLastReadStr.iso8601Date,
           let coreDataLastRead = coreDataItem.lastRead {
            if supabaseLastRead > coreDataLastRead {
                lastRead = supabaseLastRead
                needsUpdate = true
            }
        }

        if needsUpdate {
            // Update CoreData with newer timestamps
            await updateCoreDataTimestamps(
                canonicalMangaId: coreDataItem.canonicalMangaId,
                lastOpened: lastOpened,
                lastRead: lastRead
            )
        }
    }
    
    /// Fetch library from Supabase
    private func fetchLibraryFromSupabase() async throws -> [SupabaseLibraryItem] {
        guard let userId = supabase.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let url = URL(string: "\(supabase.supabaseURL)/rest/v1/scanio_user_library?user_id=eq.\(userId)&select=*")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabase.currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }

        let items = try JSONDecoder().decode([SupabaseLibraryItem].self, from: data)
        return items
    }
    
    /// Get library from CoreData and fetch canonical IDs from Supabase
    private func getCoreDataLibrary() async -> [CoreDataLibraryItem] {
        // First, get all library mangas from CoreData
        let libraryMangas = await coreData.container.performBackgroundTask { context in
            self.coreData.getLibraryManga(context: context)
        }

        print("📚 getCoreDataLibrary - Found \(libraryMangas.count) library items")

        // Then, for each manga, get or create the canonical ID
        var items: [CoreDataLibraryItem] = []

        for libraryManga in libraryMangas {
            guard let manga = libraryManga.manga else {
                print("⚠️ Library manga has no manga object, skipping")
                continue
            }

            let sourceId = manga.sourceId
            let mangaId = manga.id
            let title = manga.title ?? "Unknown"

            do {
                // Get or create canonical manga ID from Supabase
                print("🔍 Getting canonical ID for: \(title) (\(sourceId)/\(mangaId))")
                let canonicalMangaId = try await supabase.getOrCreateCanonicalManga(
                    title: title,
                    sourceId: sourceId,
                    mangaId: mangaId
                )
                print("✅ Got canonical ID: \(canonicalMangaId)")

                let item = CoreDataLibraryItem(
                    canonicalMangaId: canonicalMangaId,
                    sourceId: sourceId,
                    mangaId: mangaId,
                    dateAdded: libraryManga.dateAdded,
                    lastOpened: libraryManga.lastOpened,
                    lastRead: libraryManga.lastRead,
                    lastUpdated: libraryManga.lastUpdated
                )
                items.append(item)
            } catch {
                print("❌ Failed to get canonical ID for \(title): \(error)")
                // Skip this item if we can't get the canonical ID
            }
        }

        print("📚 getCoreDataLibrary - Returning \(items.count) items with canonical IDs")
        return items
    }
    
    /// Update CoreData timestamps
    private func updateCoreDataTimestamps(
        canonicalMangaId: String,
        lastOpened: Date?,
        lastRead: Date?
    ) async {
        // TODO: Implement CoreData timestamp update
        print("⚠️ TODO: Update CoreData timestamps for \(canonicalMangaId)")
    }
    
    // MARK: - Category Sync
    
    /// Sync categories between CoreData and Supabase
    func syncCategories() async throws {
        print("📁 SyncManager: Syncing categories...")
        // TODO: Implement category sync
        print("⚠️ TODO: Implement category sync")
    }
    
    // MARK: - Tracker Sync
    
    /// Sync trackers between CoreData and Supabase
    func syncTrackers() async throws {
        print("🔗 SyncManager: Syncing trackers...")
        // TODO: Implement tracker sync
        print("⚠️ TODO: Implement tracker sync")
    }
}

// MARK: - Data Models

struct CoreDataLibraryItem {
    let canonicalMangaId: String
    let sourceId: String
    let mangaId: String
    let dateAdded: Date?
    let lastOpened: Date?
    let lastRead: Date?
    let lastUpdated: Date?
}

struct SupabaseLibraryItem: Codable {
    let id: String
    let userId: String
    let canonicalMangaId: String
    let sourceId: String
    let mangaId: String
    let dateAdded: String?
    let lastOpened: String?
    let lastRead: String?
    let lastUpdated: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case canonicalMangaId = "canonical_manga_id"
        case sourceId = "source_id"
        case mangaId = "manga_id"
        case dateAdded = "date_added"
        case lastOpened = "last_opened"
        case lastRead = "last_read"
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Date Extension

extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

extension String {
    var iso8601Date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self)
    }
}


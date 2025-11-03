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
        } catch {
            print("❌ SyncManager: Full sync failed: \(error)")
            throw error
        }
    }

    // MARK: - Sources Sync

    /// Sync user sources from Supabase to local
    func syncSources() async throws {
        print("🔌 SyncManager: Syncing sources...")

        // Fetch sources from Supabase
        let supabaseSources = try await supabase.fetchUserSources()
        print("🔌 Fetched \(supabaseSources.count) sources from Supabase")

        // Get currently installed sources
        let installedSources = SourceManager.shared.sources
        let installedSourceIds = Set(installedSources.map { $0.id })

        // Install missing sources
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

        print("✅ Sources sync completed - Installed: \(installedCount), Failed: \(failedCount)")
    }

    // MARK: - History Sync

    /// Sync reading history from Supabase to local CoreData
    func syncHistory() async throws {
        print("📖 SyncManager: Syncing reading history...")

        // Fetch history from Supabase
        let supabaseHistory = try await supabase.getReadingHistory(limit: 1000)
        print("📖 Fetched \(supabaseHistory.count) history items from Supabase")

        // Download history to CoreData
        for historyItem in supabaseHistory {
            await downloadHistoryItem(historyItem)
        }

        print("✅ History sync completed")
    }

    /// Download a single history item to CoreData
    private func downloadHistoryItem(_ item: ReadingHistory) async {
        await coreData.container.performBackgroundTask { context in
            // Check if we have this manga in CoreData
            let manga = self.coreData.getManga(
                sourceId: item.sourceId,
                mangaId: item.mangaId,
                context: context
            )

            if manga == nil {
                print("⚠️ Cannot restore history for \(item.mangaId) - manga not in CoreData")
                return
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
                return
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
            } catch {
                print("❌ Failed to save history: \(error)")
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

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
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
    
    /// Get library from CoreData
    private func getCoreDataLibrary() async -> [CoreDataLibraryItem] {
        return await coreData.container.performBackgroundTask { context in
            let libraryMangas = self.coreData.getLibraryManga(context: context)

            return libraryMangas.compactMap { libraryManga -> CoreDataLibraryItem? in
                guard let manga = libraryManga.manga else {
                    return nil
                }

                let sourceId = manga.sourceId
                let mangaId = manga.id

                // We need to get the canonical manga ID
                // For now, we'll use a placeholder - this needs to be implemented
                let canonicalMangaId = "placeholder-\(sourceId)-\(mangaId)"

                return CoreDataLibraryItem(
                    canonicalMangaId: canonicalMangaId,
                    sourceId: sourceId,
                    mangaId: mangaId,
                    dateAdded: libraryManga.dateAdded,
                    lastOpened: libraryManga.lastOpened,
                    lastRead: libraryManga.lastRead,
                    lastUpdated: libraryManga.lastUpdated
                )
            }
        }
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


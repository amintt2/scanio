//
//  SyncManager.swift
//  Aidoku
//
//  Manages synchronization between CoreData and Supabase
//

import Foundation
import CoreData

/// Manages bidirectional synchronization between CoreData (local) and Supabase (cloud)
class SyncManager {
    
    static let shared = SyncManager()
    
    private let coreData = CoreDataManager.shared
    private let supabase = SupabaseManager.shared
    
    private init() {}
    
    // MARK: - Full Sync
    
    /// Synchronize all data (library, categories, trackers)
    /// Reading history is already synced in HistoryManager
    func syncAll() async throws {
        guard supabase.isAuthenticated else {
            print("⚠️ SyncManager: User not authenticated, skipping sync")
            return
        }
        
        print("🔄 SyncManager: Starting full sync...")
        
        do {
            try await syncLibrary()
            try await syncCategories()
            try await syncTrackers()
            print("✅ SyncManager: Full sync completed successfully")
        } catch {
            print("❌ SyncManager: Full sync failed: \(error)")
            throw error
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
                // Note: We can't fully restore manga to CoreData without source data
                // This would require fetching manga details from the source
                // For now, we just log it
                print("⚠️ Cannot restore manga from Supabase without source data")
            }
        }
        
        print("✅ Library sync completed")
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


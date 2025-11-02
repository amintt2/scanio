//
//  UserProfile.swift
//  Scanio
//
//  Extended user profile with stats, privacy, and preferences
//

import Foundation

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: String
    var userName: String?
    var avatarUrl: String?
    var bio: String?
    var karma: Int
    var isPublic: Bool
    var totalChaptersRead: Int
    var totalMangaRead: Int
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userName = "user_name"
        case avatarUrl = "avatar_url"
        case bio
        case karma
        case isPublic = "is_public"
        case totalChaptersRead = "total_chapters_read"
        case totalMangaRead = "total_manga_read"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - User Statistics
struct UserStats: Codable {
    let totalChaptersRead: Int
    let totalMangaRead: Int
    let totalFavorites: Int
    let totalCompleted: Int
    let totalReading: Int
    let totalPlanToRead: Int
    let totalComments: Int  // Task 2.1: Added comments count
    let karma: Int
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case totalChaptersRead = "total_chapters_read"
        case totalMangaRead = "total_manga_read"
        case totalFavorites = "total_favorites"
        case totalCompleted = "total_completed"
        case totalReading = "total_reading"
        case totalPlanToRead = "total_plan_to_read"
        case totalComments = "total_comments"  // Task 2.1
        case karma
        case isPublic = "is_public"
    }
}

// MARK: - Reading History
struct ReadingHistory: Codable, Identifiable {
    let id: String
    let userId: String
    let canonicalMangaId: String
    let sourceId: String
    let mangaId: String
    let chapterNumber: String
    let chapterTitle: String?
    var pageNumber: Int
    var totalPages: Int
    var isCompleted: Bool
    let lastReadAt: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case canonicalMangaId = "canonical_manga_id"
        case sourceId = "source_id"
        case mangaId = "manga_id"
        case chapterNumber = "chapter_number"
        case chapterTitle = "chapter_title"
        case pageNumber = "page_number"
        case totalPages = "total_pages"
        case isCompleted = "is_completed"
        case lastReadAt = "last_read_at"
        case createdAt = "created_at"
    }
}

// MARK: - Reading History with Manga Info
struct ReadingHistoryWithManga: Codable, Identifiable {
    let id: String
    let userId: String
    let canonicalMangaId: String
    let mangaTitle: String
    let sourceId: String
    let mangaId: String
    let chapterNumber: String
    let chapterTitle: String?
    let pageNumber: Int
    let totalPages: Int
    let isCompleted: Bool
    let lastReadAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case canonicalMangaId = "canonical_manga_id"
        case mangaTitle = "manga_title"
        case sourceId = "source_id"
        case mangaId = "manga_id"
        case chapterNumber = "chapter_number"
        case chapterTitle = "chapter_title"
        case pageNumber = "page_number"
        case totalPages = "total_pages"
        case isCompleted = "is_completed"
        case lastReadAt = "last_read_at"
    }
}

// MARK: - Personal Ranking
enum ReadingStatus: String, Codable, CaseIterable {
    case reading = "reading"
    case completed = "completed"
    case onHold = "on_hold"
    case dropped = "dropped"
    case planToRead = "plan_to_read"
    
    var displayName: String {
        switch self {
        case .reading: return "En cours"
        case .completed: return "Terminé"
        case .onHold: return "En pause"
        case .dropped: return "Abandonné"
        case .planToRead: return "À lire"
        }
    }
}

struct PersonalRanking: Codable, Identifiable {
    let id: String
    let userId: String
    let canonicalMangaId: String
    var rankPosition: Int
    var personalRating: Int?
    var notes: String?
    var isFavorite: Bool
    var readingStatus: ReadingStatus
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case canonicalMangaId = "canonical_manga_id"
        case rankPosition = "rank_position"
        case personalRating = "personal_rating"
        case notes
        case isFavorite = "is_favorite"
        case readingStatus = "reading_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Personal Ranking with Manga Info
struct PersonalRankingWithManga: Codable, Identifiable {
    let id: String
    let userId: String
    let canonicalMangaId: String
    let mangaTitle: String
    let rankPosition: Int
    let personalRating: Int?
    let notes: String?
    let isFavorite: Bool
    let readingStatus: ReadingStatus
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case canonicalMangaId = "canonical_manga_id"
        case mangaTitle = "manga_title"
        case rankPosition = "rank_position"
        case personalRating = "personal_rating"
        case notes
        case isFavorite = "is_favorite"
        case readingStatus = "reading_status"
    }
}

// MARK: - Manga Progress
struct MangaProgress: Codable, Identifiable {
    let id: String
    let userId: String
    let canonicalMangaId: String
    var lastChapterRead: String?
    var totalChaptersRead: Int
    let startedAt: Date
    let lastReadAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case canonicalMangaId = "canonical_manga_id"
        case lastChapterRead = "last_chapter_read"
        case totalChaptersRead = "total_chapters_read"
        case startedAt = "started_at"
        case lastReadAt = "last_read_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Manga Progress with Manga Info
struct MangaProgressWithManga: Codable, Identifiable {
    let id: String
    let userId: String
    let canonicalMangaId: String
    let mangaTitle: String
    let lastChapterRead: String?
    let totalChaptersRead: Int
    let lastReadAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case canonicalMangaId = "canonical_manga_id"
        case mangaTitle = "manga_title"
        case lastChapterRead = "last_chapter_read"
        case totalChaptersRead = "total_chapters_read"
        case lastReadAt = "last_read_at"
    }
}

// MARK: - Update Profile Request
struct UpdateProfileRequest: Codable {
    let userName: String?
    let avatarUrl: String?
    let bio: String?
    let isPublic: Bool?
    
    enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case avatarUrl = "avatar_url"
        case bio
        case isPublic = "is_public"
    }
}

// MARK: - Create/Update Reading History Request
struct UpsertReadingHistoryRequest: Codable {
    let userId: String
    let canonicalMangaId: String
    let sourceId: String
    let mangaId: String
    let chapterId: String
    let chapterNumber: String
    let chapterTitle: String?
    let pageNumber: Int
    let totalPages: Int
    let isCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case canonicalMangaId = "canonical_manga_id"
        case sourceId = "source_id"
        case mangaId = "manga_id"
        case chapterId = "chapter_id"
        case chapterNumber = "chapter_number"
        case chapterTitle = "chapter_title"
        case pageNumber = "page_number"
        case totalPages = "total_pages"
        case isCompleted = "is_completed"
    }
}

// MARK: - Create/Update Personal Ranking Request
struct UpsertPersonalRankingRequest: Codable {
    let userId: String
    let canonicalMangaId: String
    let rankPosition: Int?
    let personalRating: Int?
    let notes: String?
    let isFavorite: Bool?
    let readingStatus: ReadingStatus?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case canonicalMangaId = "canonical_manga_id"
        case rankPosition = "rank_position"
        case personalRating = "personal_rating"
        case notes
        case isFavorite = "is_favorite"
        case readingStatus = "reading_status"
    }
}


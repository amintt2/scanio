//
//  UserProfileTests.swift
//  TomoScanTests
//
//  Tests pour les modèles UserProfile
//

import XCTest
@testable import Aidoku

final class UserProfileTests: XCTestCase {
    
    // MARK: - UserProfile Tests
    
    func testUserProfileDecoding() throws {
        let jsonString = """
        {
            "id": "test-id",
            "user_id": "user-123",
            "username": "testuser",
            "display_name": "Test User",
            "bio": "Test bio",
            "avatar_url": "https://example.com/avatar.jpg",
            "banner_url": "https://example.com/banner.jpg",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-02T00:00:00Z"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let profile = try decoder.decode(UserProfile.self, from: jsonData)
        
        XCTAssertEqual(profile.id, "test-id")
        XCTAssertEqual(profile.userId, "user-123")
        XCTAssertEqual(profile.username, "testuser")
        XCTAssertEqual(profile.displayName, "Test User")
        XCTAssertEqual(profile.bio, "Test bio")
    }
    
    func testUserProfileEncoding() throws {
        let profile = UserProfile(
            id: "test-id",
            userId: "user-123",
            username: "testuser",
            displayName: "Test User",
            bio: "Test bio",
            avatarUrl: "https://example.com/avatar.jpg",
            bannerUrl: "https://example.com/banner.jpg",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(profile)
        XCTAssertNotNil(jsonData)
        XCTAssertGreaterThan(jsonData.count, 0)
    }
    
    // MARK: - UserStats Tests
    
    func testUserStatsDecoding() throws {
        let jsonString = """
        {
            "user_id": "user-123",
            "total_manga_read": 50,
            "total_chapters_read": 500,
            "total_reading_time_minutes": 3000,
            "favorites_count": 10,
            "currently_reading_count": 5,
            "completed_count": 30,
            "plan_to_read_count": 15
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let stats = try decoder.decode(UserStats.self, from: jsonData)
        
        XCTAssertEqual(stats.userId, "user-123")
        XCTAssertEqual(stats.totalMangaRead, 50)
        XCTAssertEqual(stats.totalChaptersRead, 500)
        XCTAssertEqual(stats.totalReadingTimeMinutes, 3000)
        XCTAssertEqual(stats.favoritesCount, 10)
    }
    
    func testUserStatsDefaultValues() throws {
        let jsonString = """
        {
            "user_id": "user-123"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let stats = try decoder.decode(UserStats.self, from: jsonData)
        
        XCTAssertEqual(stats.userId, "user-123")
        XCTAssertEqual(stats.totalMangaRead, 0)
        XCTAssertEqual(stats.totalChaptersRead, 0)
    }
    
    // MARK: - ReadingStatus Tests
    
    func testReadingStatusValues() {
        let statuses: [ReadingStatus] = [
            .reading,
            .completed,
            .planToRead,
            .onHold,
            .dropped
        ]
        
        XCTAssertEqual(statuses.count, 5, "Should have 5 reading statuses")
    }
    
    func testReadingStatusRawValues() {
        XCTAssertEqual(ReadingStatus.reading.rawValue, "reading")
        XCTAssertEqual(ReadingStatus.completed.rawValue, "completed")
        XCTAssertEqual(ReadingStatus.planToRead.rawValue, "plan_to_read")
        XCTAssertEqual(ReadingStatus.onHold.rawValue, "on_hold")
        XCTAssertEqual(ReadingStatus.dropped.rawValue, "dropped")
    }
    
    // MARK: - PersonalRanking Tests
    
    func testPersonalRankingDecoding() throws {
        let jsonString = """
        {
            "id": "ranking-123",
            "user_id": "user-123",
            "manga_id": "manga-456",
            "rank_position": 1,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-02T00:00:00Z"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let ranking = try decoder.decode(PersonalRanking.self, from: jsonData)
        
        XCTAssertEqual(ranking.id, "ranking-123")
        XCTAssertEqual(ranking.userId, "user-123")
        XCTAssertEqual(ranking.mangaId, "manga-456")
        XCTAssertEqual(ranking.rankPosition, 1)
    }
    
    // MARK: - AuthSession Tests
    
    func testAuthSessionExpiresAtIsSaved() throws {
        let expiresAt = Date().addingTimeInterval(3600)
        let jsonString = """
        {
            "access_token": "test-token",
            "refresh_token": "refresh-token",
            "expires_in": 3600,
            "token_type": "bearer",
            "user": {
                "id": "user-123",
                "email": "test@example.com",
                "created_at": "2024-01-01T00:00:00Z"
            },
            "expires_at": \(expiresAt.timeIntervalSince1970)
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let session = try decoder.decode(AuthSession.self, from: jsonData)
        
        // Vérifier que expiresAt est sauvegardé et ne change pas
        let firstRead = session.expiresAt
        Thread.sleep(forTimeInterval: 0.1)
        let secondRead = session.expiresAt
        
        XCTAssertEqual(firstRead, secondRead, "expiresAt should be saved, not computed")
    }
    
    func testAuthSessionWithoutExpiresAt() throws {
        let jsonString = """
        {
            "access_token": "test-token",
            "refresh_token": "refresh-token",
            "expires_in": 3600,
            "token_type": "bearer",
            "user": {
                "id": "user-123",
                "email": "test@example.com",
                "created_at": "2024-01-01T00:00:00Z"
            }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let session = try decoder.decode(AuthSession.self, from: jsonData)
        
        // Vérifier que expiresAt est calculé depuis expiresIn
        XCTAssertNotNil(session.expiresAt)
        
        let expectedExpiration = Date().addingTimeInterval(3600)
        let timeDifference = abs(session.expiresAt.timeIntervalSince(expectedExpiration))
        XCTAssertLessThan(timeDifference, 2, "expiresAt should be calculated from expiresIn")
    }
}


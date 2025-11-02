//
//  SupabaseManager+Rankings.swift
//  Scanio
//
//  Extension for personal rankings and favorites
//

import Foundation

extension SupabaseManager {

    // MARK: - Personal Rankings API

    func upsertPersonalRanking(
        canonicalMangaId: String,
        rankPosition: Int? = nil,
        personalRating: Int? = nil,
        notes: String? = nil,
        isFavorite: Bool? = nil,
        readingStatus: ReadingStatus? = nil
    ) async throws -> PersonalRanking {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_personal_rankings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")

        let body = UpsertPersonalRankingRequest(
            userId: userId,
            canonicalMangaId: canonicalMangaId,
            rankPosition: rankPosition,
            personalRating: personalRating,
            notes: notes,
            isFavorite: isFavorite,
            readingStatus: readingStatus
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let rankings = try decoder.decode([PersonalRanking].self, from: data)
        guard let ranking = rankings.first else {
            throw SupabaseError.invalidResponse
        }
        return ranking
    }
    
    func fetchPersonalRankings(limit: Int = 50) async throws -> [PersonalRankingWithManga] {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_personal_rankings_with_manga?user_id=eq.\(userId)&order=rank_position.asc&limit=\(limit)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PersonalRankingWithManga].self, from: data)
    }
    
    func fetchFavorites() async throws -> [PersonalRankingWithManga] {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_personal_rankings_with_manga?user_id=eq.\(userId)&is_favorite=eq.true&order=rank_position.asc")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PersonalRankingWithManga].self, from: data)
    }
    
    func fetchByReadingStatus(_ status: ReadingStatus) async throws -> [PersonalRankingWithManga] {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_personal_rankings_with_manga?user_id=eq.\(userId)&reading_status=eq.\(status.rawValue)&order=rank_position.asc")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PersonalRankingWithManga].self, from: data)
    }
    
    func deletePersonalRanking(rankingId: String) async throws {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }
        
        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_personal_rankings?id=eq.\(rankingId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
    }
    
    // MARK: - Helper: Get or Create Canonical Manga
    
    func getOrCreateCanonicalManga(title: String, sourceId: String, mangaId: String) async throws -> String {
        print("🔵 getOrCreateCanonicalManga called")
        print("🔵 Title: \(title)")
        print("🔵 Source ID: \(sourceId)")
        print("🔵 Manga ID: \(mangaId)")
        print("🔵 Is authenticated: \(isAuthenticated)")

        guard isAuthenticated else {
            print("🔴 Not authenticated!")
            throw SupabaseError.notAuthenticated
        }

        let url = URL(string: "\(supabaseURL)/rest/v1/rpc/scanio_get_or_create_canonical_manga")!
        print("🔵 URL: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "p_title": title,
            "p_source_id": sourceId,
            "p_manga_id": mangaId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🔵 Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

        let (data, response) = try await URLSession.shared.data(for: request)

        print("🔵 Response data: \(String(data: data, encoding: .utf8) ?? "")")

        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔴 Invalid HTTP response")
            throw SupabaseError.networkError
        }

        print("🔵 HTTP Status code: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            print("🔴 HTTP error: \(httpResponse.statusCode)")
            throw SupabaseError.networkError
        }

        // The RPC returns a UUID string
        guard let canonicalId = String(data: data, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) else {
            print("🔴 Failed to parse canonical ID from response")
            throw SupabaseError.invalidResponse
        }

        print("🔵 Canonical ID: \(canonicalId)")
        return canonicalId
    }
}


//
//  SupabaseManager+Sources.swift
//  Scanio
//
//  Extension for user sources synchronization
//

import Foundation

extension SupabaseManager {
    
    // MARK: - Add User Source

    func addUserSource(sourceId: String, sourceName: String?, sourceLang: String?, sourceUrl: String?) async throws {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_user_sources")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any?] = [
            "user_id": userId,
            "source_id": sourceId,
            "source_name": sourceName,
            "source_lang": sourceLang,
            "source_url": sourceUrl
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
    }
    
    // MARK: - Fetch User Sources
    
    func fetchUserSources() async throws -> [UserSource] {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_user_sources?user_id=eq.\(userId)&order=added_at.desc")!
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
        return try decoder.decode([UserSource].self, from: data)
    }
    
    // MARK: - Remove User Source
    
    func removeUserSource(sourceId: String) async throws {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let urlString = "\(supabaseURL)/rest/v1/scanio_user_sources?user_id=eq.\(userId)&source_id=eq.\(sourceId)"
        guard let url = URL(string: urlString) else {
            throw SupabaseError.invalidResponse
        }
        
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
}

// MARK: - User Source Model

struct UserSource: Codable, Identifiable {
    let id: String
    let userId: String
    let sourceId: String
    let sourceName: String?
    let sourceLang: String?
    let sourceUrl: String?
    let addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sourceId = "source_id"
        case sourceName = "source_name"
        case sourceLang = "source_lang"
        case sourceUrl = "source_url"
        case addedAt = "added_at"
    }
}


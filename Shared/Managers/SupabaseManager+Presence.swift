//
//  SupabaseManager+Presence.swift
//  TomoScan
//
//  Manages user online/offline presence status
//

import Foundation

// MARK: - User Presence Models

struct UserPresence: Codable {
    let userId: String
    let isOnline: Bool
    let lastSeen: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case isOnline = "is_online"
        case lastSeen = "last_seen"
    }
}

// MARK: - Presence Management

extension SupabaseManager {
    
    /// Update current user's online status
    /// - Parameter isOnline: true for online, false for offline
    func updatePresence(isOnline: Bool) async throws {
        guard isAuthenticated else {
            print("⚠️ Cannot update presence: not authenticated")
            return
        }
        
        print("📡 Updating presence: \(isOnline ? "online" : "offline")")
        
        let url = URL(string: "\(supabaseURL)/rest/v1/rpc/scanio_update_user_presence")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let body = ["p_is_online": isOnline]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.networkError
        }
        
        print("📡 Presence update status: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.invalidResponse
        }

        print("✅ Presence updated successfully")
    }
    
    /// Get presence status for a specific user
    /// - Parameter userId: The user ID to check
    /// - Returns: UserPresence object or nil if not found
    func getUserPresence(userId: String) async throws -> UserPresence? {
        print("📡 Fetching presence for user: \(userId)")
        
        let url = URL(string: "\(supabaseURL)/rest/v1/rpc/scanio_get_user_presence")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let body = ["p_user_id": userId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .supabase

        let presences = try decoder.decode([UserPresence].self, from: data)
        return presences.first
    }
    
    /// Get presence status for multiple users
    /// - Parameter userIds: Array of user IDs to check
    /// - Returns: Array of UserPresence objects
    func getUsersPresence(userIds: [String]) async throws -> [UserPresence] {
        guard !userIds.isEmpty else { return [] }
        
        print("📡 Fetching presence for \(userIds.count) users")
        
        let url = URL(string: "\(supabaseURL)/rest/v1/rpc/scanio_get_users_presence")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let body = ["p_user_ids": userIds]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .supabase

        return try decoder.decode([UserPresence].self, from: data)
    }
    
    /// Set user online when signing in
    func setOnline() async {
        do {
            try await updatePresence(isOnline: true)
        } catch {
            print("❌ Failed to set online status: \(error)")
        }
    }
    
    /// Set user offline when signing out or app goes to background
    func setOffline() async {
        do {
            try await updatePresence(isOnline: false)
        } catch {
            print("❌ Failed to set offline status: \(error)")
        }
    }
    
    /// Keep presence alive (call periodically while app is active)
    /// This prevents the user from being marked as offline by the cleanup function
    func keepPresenceAlive() async {
        do {
            try await updatePresence(isOnline: true)
        } catch {
            print("❌ Failed to keep presence alive: \(error)")
        }
    }
}


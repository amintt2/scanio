//
//  SupabaseManager+ProfileVisibility.swift
//  Scanio
//
//  PHASE 5, Task 5.2: Profile visibility settings management
//

import Foundation

extension SupabaseManager {
    // MARK: - Profile Visibility Settings API
    
    /// Fetch profile visibility settings for a user
    func fetchProfileVisibilitySettings(userId: String? = nil) async throws -> ProfileVisibilitySettings {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }
        
        let targetUserId = userId ?? currentSession?.user.id ?? ""
        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_profile_visibility_settings?user_id=eq.\(targetUserId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ fetchProfileVisibilitySettings failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw SupabaseError.networkError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let settings = try decoder.decode([ProfileVisibilitySettings].self, from: data)
        
        // If no settings exist, return default settings
        if settings.isEmpty {
            return ProfileVisibilitySettings(
                userId: targetUserId,
                showHistory: true,
                showRankings: true,
                showStats: true,
                updatedAt: nil
            )
        }
        
        return settings[0]
    }
    
    /// Update profile visibility settings
    func updateProfileVisibilitySettings(
        showHistory: Bool? = nil,
        showRankings: Bool? = nil,
        showStats: Bool? = nil
    ) async throws -> ProfileVisibilitySettings {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        print("👁️ Updating visibility settings...")
        print("👁️ showHistory: \(showHistory?.description ?? "nil")")
        print("👁️ showRankings: \(showRankings?.description ?? "nil")")
        print("👁️ showStats: \(showStats?.description ?? "nil")")
        
        // First, try to fetch existing settings
        let existingSettings = try? await fetchProfileVisibilitySettings()
        
        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_profile_visibility_settings")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = ["user_id": userId]
        
        if let showHistory = showHistory {
            body["show_history"] = showHistory
        } else if let existing = existingSettings {
            body["show_history"] = existing.showHistory
        }
        
        if let showRankings = showRankings {
            body["show_rankings"] = showRankings
        } else if let existing = existingSettings {
            body["show_rankings"] = existing.showRankings
        }
        
        if let showStats = showStats {
            body["show_stats"] = showStats
        } else if let existing = existingSettings {
            body["show_stats"] = existing.showStats
        }
        
        if existingSettings == nil {
            // INSERT
            request.httpMethod = "POST"
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        } else {
            // UPDATE
            request.httpMethod = "PATCH"
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
            // Add filter for UPDATE
            let urlWithFilter = URL(string: "\(supabaseURL)/rest/v1/scanio_profile_visibility_settings?user_id=eq.\(userId)")!
            request.url = urlWithFilter
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ updateProfileVisibilitySettings failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw SupabaseError.networkError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let settings = try decoder.decode([ProfileVisibilitySettings].self, from: data)
        
        guard let updatedSettings = settings.first else {
            throw SupabaseError.networkError
        }
        
        print("✅ Visibility settings updated successfully")
        return updatedSettings
    }
}


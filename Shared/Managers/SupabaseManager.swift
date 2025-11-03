//
//  SupabaseManager.swift
//  Scanio
//
//  Manages Supabase authentication and API calls
//

import Foundation

class SupabaseManager {
    static let shared = SupabaseManager()

    internal let supabaseURL: String
    internal let supabaseAnonKey: String

    internal var currentSession: AuthSession?

    private init() {
        // Load from SupabaseConfig.swift (not committed to git)
        self.supabaseURL = SupabaseConfig.url
        self.supabaseAnonKey = SupabaseConfig.anonKey

        // Load saved session
        loadSession()
    }

    // MARK: - Session Management

    private func loadSession() {
        if let data = UserDefaults.standard.data(forKey: "supabase_session"),
           let session = try? JSONDecoder().decode(AuthSession.self, from: data) {
            currentSession = session
        }
    }

    private func saveSession(_ session: AuthSession) {
        currentSession = session
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: "supabase_session")
        }
    }

    private func clearSession() {
        currentSession = nil
        UserDefaults.standard.removeObject(forKey: "supabase_session")
    }

    var isAuthenticated: Bool {
        guard let session = currentSession else { return false }
        return session.expiresAt > Date()
    }

    var currentUser: SupabaseUser? {
        currentSession?.user
    }

    // MARK: - Authentication

    func signUp(email: String, password: String, userName: String?) async throws -> SupabaseUser {
        let url = URL(string: "\(supabaseURL)/auth/v1/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body = SignUpRequest(email: email, password: password, userName: userName)
        request.httpBody = try JSONEncoder().encode(body)

        print("🔵 SignUp URL: \(url)")
        print("🔵 SignUp Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

        let (data, response) = try await URLSession.shared.data(for: request)

        print("🔵 Response Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        print("🔵 Response: \(String(data: data, encoding: .utf8) ?? "")")

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ SignUp failed: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw SupabaseError.authenticationFailed
        }

        // SignUp returns only the user (no session until email is confirmed)
        let user = try JSONDecoder().decode(SupabaseUser.self, from: data)
        print("✅ SignUp successful! User: \(user.id), Email: \(user.email ?? "none")")
        return user
    }

    func signIn(email: String, password: String) async throws -> SupabaseUser {
        let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body = SignInRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.authenticationFailed
        }

        let session = try JSONDecoder().decode(AuthSession.self, from: data)
        saveSession(session)
        return session.user
    }

    func signOut() {
        clearSession()
    }

    func resendConfirmationEmail(email: String) async throws {
        let url = URL(string: "\(supabaseURL)/auth/v1/resend")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body = ["email": email, "type": "signup"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
    }

    // MARK: - Comments API
    // Moved to SupabaseManager+Comments.swift

    // MARK: - Profile API

    func createProfile() async throws {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_profiles")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "id": userId,
            "user_name": "User_\(userId.prefix(8))",
            "karma": 0,
            "is_public": true,
            "total_chapters_read": 0,
            "total_manga_read": 0
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
    }

    func fetchProfile(userId: String? = nil) async throws -> UserProfile {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let targetUserId = userId ?? currentSession?.user.id ?? ""
        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_profiles?id=eq.\(targetUserId)")!
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
        let profiles = try decoder.decode([UserProfile].self, from: data)
        guard let profile = profiles.first else {
            throw SupabaseError.profileNotFound
        }
        return profile
    }

    func updateProfile(userName: String? = nil, avatarUrl: String? = nil, bio: String? = nil, isPublic: Bool? = nil) async throws -> UserProfile {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_profiles?id=eq.\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        let body = UpdateProfileRequest(userName: userName, avatarUrl: avatarUrl, bio: bio, isPublic: isPublic)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profiles = try decoder.decode([UserProfile].self, from: data)
        guard let profile = profiles.first else {
            throw SupabaseError.invalidResponse
        }
        return profile
    }

    func fetchUserStats(userId: String? = nil) async throws -> UserStats {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let targetUserId = userId ?? currentSession?.user.id ?? ""
        let url = URL(string: "\(supabaseURL)/rest/v1/rpc/scanio_get_user_stats")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let body = ["p_user_id": targetUserId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📊 fetchUserStats - URL: \(url)")
        print("📊 fetchUserStats - User ID: \(targetUserId)")
        print("📊 fetchUserStats - Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

        let (data, response) = try await URLSession.shared.data(for: request)

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("📊 fetchUserStats - Status Code: \(statusCode)")
        print("📊 fetchUserStats - Response: \(String(data: data, encoding: .utf8) ?? "")")

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ fetchUserStats - Network error: HTTP \(statusCode)")
            throw SupabaseError.networkError
        }

        let decoder = JSONDecoder()
        // Note: UserStats already has explicit CodingKeys, so we don't use convertFromSnakeCase

        do {
            let stats = try decoder.decode([UserStats].self, from: data)
            print("📊 fetchUserStats - Decoded \(stats.count) stats")
            guard let stat = stats.first else {
                print("❌ fetchUserStats - No stats returned (empty array)")
                throw SupabaseError.invalidResponse
            }
            print("✅ fetchUserStats - Success! Chapters: \(stat.totalChaptersRead), Manga: \(stat.totalMangaRead)")
            return stat
        } catch {
            print("❌ fetchUserStats - Decoding error: \(error)")
            print("❌ fetchUserStats - Raw data: \(String(data: data, encoding: .utf8) ?? "")")
            throw error
        }
    }

    // MARK: - Reading History API

    // swiftlint:disable:next function_parameter_count
    func upsertReadingHistory(
        canonicalMangaId: String,
        sourceId: String,
        mangaId: String,
        chapterId: String,
        chapterNumber: String,
        chapterTitle: String?,
        pageNumber: Int,
        totalPages: Int,
        isCompleted: Bool
    ) async throws {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Use RPC function for proper UPSERT handling
        let url = URL(string: "\(supabaseURL)/rest/v1/rpc/scanio_upsert_reading_history")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "p_user_id": userId,
            "p_canonical_manga_id": canonicalMangaId,
            "p_source_id": sourceId,
            "p_manga_id": mangaId,
            "p_chapter_id": chapterId,
            "p_chapter_number": chapterNumber,
            "p_chapter_title": chapterTitle as Any,
            "p_page_number": pageNumber,
            "p_total_pages": totalPages,
            "p_is_completed": isCompleted
        ]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📚 upsertReadingHistory - URL: \(url)")
        print("📚 upsertReadingHistory - Chapter: \(chapterNumber), Page: \(pageNumber)/\(totalPages), Completed: \(isCompleted)")
        print("📚 upsertReadingHistory - Body: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "")")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("📚 upsertReadingHistory - Status Code: \(statusCode)")
        print("📚 upsertReadingHistory - Response: \(String(data: data, encoding: .utf8) ?? "")")

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ upsertReadingHistory - Network error: HTTP \(statusCode)")
            throw SupabaseError.networkError
        }

        print("✅ upsertReadingHistory - Success!")
    }

    // PHASE 5, Task 5.4: Fetch reading history for any user (for public profiles)
    func fetchReadingHistory(userId: String? = nil, limit: Int = 20) async throws -> [ReadingHistoryWithManga] {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        let targetUserId = userId ?? currentSession?.user.id ?? ""

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_reading_history_with_manga?user_id=eq.\(targetUserId)&order=last_read_at.desc&limit=\(limit)")!
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
        return try decoder.decode([ReadingHistoryWithManga].self, from: data)
    }

    /// Fetch raw reading history (for sync purposes)
    func getReadingHistory(userId: String? = nil, limit: Int = 1000) async throws -> [ReadingHistory] {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        let targetUserId = userId ?? currentSession?.user.id ?? ""

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_reading_history?user_id=eq.\(targetUserId)&order=last_read_at.desc&limit=\(limit)")!
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
        return try decoder.decode([ReadingHistory].self, from: data)
    }

    func fetchCurrentlyReading() async throws -> [MangaProgressWithManga] {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_manga_progress_with_manga?user_id=eq.\(userId)&order=last_read_at.desc")!
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
        return try decoder.decode([MangaProgressWithManga].self, from: data)
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case networkError
    case invalidResponse
    case profileNotFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials"
        case .networkError:
            return "Network error. Please try again"
        case .invalidResponse:
            return "Invalid response from server"
        case .profileNotFound:
            return "Profile not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

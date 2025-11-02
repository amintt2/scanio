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

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.authenticationFailed
        }

        let session = try JSONDecoder().decode(AuthSession.self, from: data)
        saveSession(session)
        return session.user
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

    func fetchComments(for chapterId: String, limit: Int = 50, offset: Int = 0) async throws -> [Comment] {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let url = URL(string: "\(supabaseURL)/rest/v1/comments?chapter_id=eq.\(chapterId)&order=created_at.desc&limit=\(limit)&offset=\(offset)")!
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
        return try decoder.decode([Comment].self, from: data)
    }

    func createComment(chapterId: String, content: String, parentCommentId: String? = nil) async throws -> Comment {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let url = URL(string: "\(supabaseURL)/rest/v1/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        let body = CreateCommentRequest(chapterId: chapterId, content: content, parentCommentId: parentCommentId)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let comments = try decoder.decode([Comment].self, from: data)
        guard let comment = comments.first else {
            throw SupabaseError.invalidResponse
        }
        return comment
    }

    func deleteComment(commentId: String) async throws {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let url = URL(string: "\(supabaseURL)/rest/v1/comments?id=eq.\(commentId)")!
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

    func likeComment(commentId: String) async throws {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let url = URL(string: "\(supabaseURL)/rest/v1/comment_likes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let body = ["comment_id": commentId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
    }

    func unlikeComment(commentId: String) async throws {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let url = URL(string: "\(supabaseURL)/rest/v1/comment_likes?comment_id=eq.\(commentId)")!
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

    // MARK: - Profile API

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

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let stats = try decoder.decode([UserStats].self, from: data)
        guard let stat = stats.first else {
            throw SupabaseError.invalidResponse
        }
        return stat
    }

    // MARK: - Reading History API

    func upsertReadingHistory(_ request: UpsertReadingHistoryRequest) async throws {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_reading_history")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (_, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
    }

    func fetchReadingHistory(limit: Int = 20) async throws -> [ReadingHistoryWithManga] {
        guard isAuthenticated, let userId = currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_reading_history_with_manga?user_id=eq.\(userId)&order=last_read_at.desc&limit=\(limit)")!
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

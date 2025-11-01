//
//  SupabaseManager.swift
//  Scanio
//
//  Manages Supabase authentication and API calls
//

import Foundation

class SupabaseManager {
    static let shared = SupabaseManager()

    private let supabaseURL: String
    private let supabaseAnonKey: String

    private var currentSession: AuthSession?

    private init() {
        // Load from environment or configuration
        // Pour l'instant, on utilise des valeurs par défaut
        // TODO: Charger depuis .env.local ou Info.plist
        self.supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        self.supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""

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

    var currentUser: User? {
        currentSession?.user
    }

    // MARK: - Authentication

    func signUp(email: String, password: String, userName: String?) async throws -> User {
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

    func signIn(email: String, password: String) async throws -> User {
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
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case networkError
    case invalidResponse

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
        }
    }
}

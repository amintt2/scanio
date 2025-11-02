//
//  SupabaseManager+Comments.swift
//  Scanio
//
//  Extension for comment-related functionality
//

import Foundation

extension SupabaseManager {

    // MARK: - Fetch Comments

    func fetchComments(
        canonicalMangaId: String,
        chapterNumber: String,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [Comment] {
        let urlString = """
        \(supabaseURL)/rest/v1/scanio_chapter_comments_with_users?\
        canonical_manga_id=eq.\(canonicalMangaId)&\
        chapter_number=eq.\(chapterNumber)&\
        order=score.desc,created_at.desc&\
        limit=\(limit)&\
        offset=\(offset)
        """

        guard let url = URL(string: urlString) else {
            throw SupabaseError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        if let token = currentSession?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        print("🔵 Fetching comments: \(url)")

        let (data, response) = try await URLSession.shared.data(for: request)

        print("🔵 Comments response: \(String(data: data, encoding: .utf8) ?? "")")

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Comment].self, from: data)
    }

    // MARK: - Create Comment

    func createComment(
        canonicalMangaId: String,
        chapterNumber: String,
        content: String,
        parentCommentId: String? = nil
    ) async throws -> Comment {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_chapter_comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        let body = CreateCommentRequest(
            canonicalMangaId: canonicalMangaId,
            chapterNumber: chapterNumber,
            content: content,
            parentCommentId: parentCommentId
        )
        request.httpBody = try JSONEncoder().encode(body)

        print("🔵 Creating comment: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

        let (data, response) = try await URLSession.shared.data(for: request)

        print("🔵 Create comment response: \(String(data: data, encoding: .utf8) ?? "")")

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }

        // Fetch the created comment with user info from the view
        let comments = try await fetchComments(
            canonicalMangaId: canonicalMangaId,
            chapterNumber: chapterNumber,
            limit: 1
        )

        guard let comment = comments.first else {
            throw SupabaseError.invalidResponse
        }

        return comment
    }

    // MARK: - Delete Comment

    func deleteComment(commentId: String) async throws {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_chapter_comments?id=eq.\(commentId)")!
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

    // MARK: - Vote on Comment

    func voteComment(commentId: String, voteType: Int) async throws {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }
        guard voteType == 1 || voteType == -1 else {
            throw SupabaseError.invalidResponse
        }

        let url = URL(string: "\(supabaseURL)/rest/v1/scanio_chapter_comment_votes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "comment_id": commentId,
            "vote_type": voteType
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError
        }
    }

    // MARK: - Remove Vote

    func removeVote(commentId: String) async throws {
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }

        let urlString = "\(supabaseURL)/rest/v1/scanio_chapter_comment_votes?comment_id=eq.\(commentId)"
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

    // MARK: - Get User Vote

    func getUserVote(commentId: String) async throws -> Int? {
        guard isAuthenticated else { return nil }

        let urlString = "\(supabaseURL)/rest/v1/scanio_chapter_comment_votes?comment_id=eq.\(commentId)&select=vote_type"
        guard let url = URL(string: urlString) else {
            throw SupabaseError.invalidResponse
        }

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

        struct VoteResponse: Codable {
            let voteType: Int
            enum CodingKeys: String, CodingKey {
                case voteType = "vote_type"
            }
        }

        let votes = try JSONDecoder().decode([VoteResponse].self, from: data)
        return votes.first?.voteType
    }
}


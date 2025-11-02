//
//  Comment.swift
//  Scanio
//
//  Created for comment system with Supabase
//

import Foundation

struct Comment: Codable, Identifiable, Equatable {
    let id: String
    let canonicalMangaId: String
    let chapterNumber: String
    let userId: String
    let userName: String?
    let userAvatar: String?
    let userKarma: Int?
    let content: String
    let createdAt: Date
    let updatedAt: Date?
    let upvotes: Int
    let downvotes: Int
    let score: Int
    let repliesCount: Int
    let parentCommentId: String?
    let depth: Int

    enum CodingKeys: String, CodingKey {
        case id
        case canonicalMangaId = "canonical_manga_id"
        case chapterNumber = "chapter_number"
        case userId = "user_id"
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case userKarma = "user_karma"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case upvotes
        case downvotes
        case score
        case repliesCount = "replies_count"
        case parentCommentId = "parent_comment_id"
        case depth
    }

    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
    }

    // Computed property for display
    var likesCount: Int {
        upvotes
    }
}

struct CommentVote: Codable, Identifiable {
    let id: String
    let commentId: String
    let userId: String
    let voteType: Int // -1 = downvote, 1 = upvote
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case commentId = "comment_id"
        case userId = "user_id"
        case voteType = "vote_type"
        case createdAt = "created_at"
    }
}

struct CreateCommentRequest: Codable {
    let canonicalMangaId: String
    let chapterNumber: String
    let content: String
    let parentCommentId: String?
    let userId: String

    enum CodingKeys: String, CodingKey {
        case canonicalMangaId = "canonical_manga_id"
        case chapterNumber = "chapter_number"
        case content
        case parentCommentId = "parent_comment_id"
        case userId = "user_id"
    }
}

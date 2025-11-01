//
//  Comment.swift
//  Scanio
//
//  Created for comment system with Supabase
//

import Foundation

struct Comment: Codable, Identifiable, Equatable {
    let id: String
    let chapterId: String
    let userId: String
    let userName: String?
    let userAvatar: String?
    let content: String
    let createdAt: Date
    let updatedAt: Date?
    let likesCount: Int
    let repliesCount: Int
    let parentCommentId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case userId = "user_id"
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case likesCount = "likes_count"
        case repliesCount = "replies_count"
        case parentCommentId = "parent_comment_id"
    }

    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
    }
}

struct CommentLike: Codable, Identifiable {
    let id: String
    let commentId: String
    let userId: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case commentId = "comment_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct CreateCommentRequest: Codable {
    let chapterId: String
    let content: String
    let parentCommentId: String?

    enum CodingKeys: String, CodingKey {
        case chapterId = "chapter_id"
        case content
        case parentCommentId = "parent_comment_id"
    }
}

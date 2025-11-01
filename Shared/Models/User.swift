//
//  User.swift
//  Scanio
//
//  Created for authentication system with Supabase
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let userName: String?
    let avatarUrl: String?
    let createdAt: Date
    let emailConfirmed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userName = "user_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case emailConfirmed = "email_confirmed"
    }
}

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let userName: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case userName = "user_name"
    }
}

struct SignInRequest: Codable {
    let email: String
    let password: String
}


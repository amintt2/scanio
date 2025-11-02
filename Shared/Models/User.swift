//
//  User.swift
//  Scanio
//
//  Created for authentication system with Supabase
//

import Foundation

struct SupabaseUser: Codable, Identifiable {
    let id: String
    let email: String?
    let emailConfirmedAt: String?
    let createdAt: String
    let userMetadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case emailConfirmedAt = "email_confirmed_at"
        case createdAt = "created_at"
        case userMetadata = "user_metadata"
    }

    var userName: String? {
        userMetadata?["user_name"]?.value as? String
    }
}

// Helper pour décoder Any dans JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }

    var expiresAt: Date {
        Date(timeIntervalSinceNow: TimeInterval(expiresIn))
    }
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let data: [String: String]?

    init(email: String, password: String, userName: String?) {
        self.email = email
        self.password = password
        if let userName = userName {
            self.data = ["user_name": userName]
        } else {
            self.data = nil
        }
    }
}

struct SignInRequest: Codable {
    let email: String
    let password: String
}

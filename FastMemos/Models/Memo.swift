import Foundation

/// Represents a memo from the Memos API
struct Memo: Codable, Identifiable {
    let id: Int?
    let name: String?
    let content: String
    let visibility: String
    let createTime: String?
    let updateTime: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case content
        case visibility
        case createTime
        case updateTime
    }
}

/// Request body for creating a new memo
struct CreateMemoRequest: Codable {
    let content: String
    let visibility: String
}

/// Response from login endpoint
struct LoginResponse: Codable {
    let accessToken: String?
    let user: UserInfo?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "accessToken"
        case user
    }
}

/// User info from login response
struct UserInfo: Codable {
    let id: Int?
    let name: String?
    let username: String?
}

/// Sign-in request body
struct SignInRequest: Codable {
    let username: String
    let password: String
    let neverExpire: Bool
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
        self.neverExpire = true
    }
}

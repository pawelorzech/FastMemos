import Foundation

/// Visibility options for a memo
enum MemoVisibility: String, CaseIterable, Codable {
    case `private` = "PRIVATE"
    case protected = "PROTECTED"
    case `public` = "PUBLIC"
    
    var displayName: String {
        switch self {
        case .private: return "Private"
        case .protected: return "Protected"
        case .public: return "Public"
        }
    }
    
    var icon: String {
        switch self {
        case .private: return "lock.fill"
        case .protected: return "link"
        case .public: return "globe"
        }
    }
    
    var description: String {
        switch self {
        case .private: return "Only you can see"
        case .protected: return "Anyone with link"
        case .public: return "Visible to everyone"
        }
    }
}

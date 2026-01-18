import Foundation

/// Service for interacting with the Memos API
class MemosAPIService {
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    /// Validate an access token by attempting to fetch user info
    func validateToken(serverURL: URL, token: String) async throws {
        // Try the v1 API endpoint to get current user
        let endpoint = serverURL.appendingPathComponent("/api/v1/auth/status")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }
        
        // Try different endpoints if status returns 404
        if httpResponse.statusCode == 404 {
            // Try /api/v1/user/me as alternative
            try await validateTokenAlternate(serverURL: serverURL, token: token)
            return
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AppError.authenticationFailed
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.serverError("Status \(httpResponse.statusCode): \(errorMessage)")
        }
    }
    
    /// Alternative token validation endpoint
    private func validateTokenAlternate(serverURL: URL, token: String) async throws {
        // Try the /api/v1/user/me endpoint
        let endpoint = serverURL.appendingPathComponent("/api/v1/user/me")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }
        
        // If still 404, just try creating a memo (will fail with auth error if token is bad)
        if httpResponse.statusCode == 404 {
            // Token format looks valid, we'll verify on first memo creation
            return
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AppError.authenticationFailed
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.serverError("Status \(httpResponse.statusCode): \(errorMessage)")
        }
    }
    
    /// Create a new memo on the server
    func createMemo(serverURL: URL, token: String, content: String, visibility: MemoVisibility) async throws {
        // First try the v1 API endpoint
        let endpoint = serverURL.appendingPathComponent("/api/v1/memos")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let memoRequest = CreateMemoRequest(content: content, visibility: visibility.rawValue)
        request.httpBody = try JSONEncoder().encode(memoRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }
        
        if httpResponse.statusCode == 401 {
            throw AppError.authenticationFailed
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.serverError("Status \(httpResponse.statusCode): \(errorMessage)")
        }
    }
}

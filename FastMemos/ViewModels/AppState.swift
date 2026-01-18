import Foundation
import SwiftUI
import ServiceManagement

/// Global app state that persists settings and manages authentication
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var serverURL: String = ""
    @Published var username: String = ""
    @Published var defaultVisibility: MemoVisibility = .private
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    
    @Published var launchAtLogin: Bool = false {
        didSet {
            if launchAtLogin {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }
    
    private let keychainService = KeychainService()
    private lazy var apiService = MemosAPIService()
    
    init() {
        loadSettings()
        // Check current launch at login status
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        username = keychainService.getUsername() ?? ""
        
        if let visibilityString = UserDefaults.standard.string(forKey: "defaultVisibility"),
           let visibility = MemoVisibility(rawValue: visibilityString) {
            defaultVisibility = visibility
        }
        
        // Check if we have a valid token
        isLoggedIn = keychainService.getAccessToken() != nil && !serverURL.isEmpty
    }
    
    func saveSettings() {
        UserDefaults.standard.set(serverURL, forKey: "serverURL")
        UserDefaults.standard.set(defaultVisibility.rawValue, forKey: "defaultVisibility")
    }
    
    // MARK: - Authentication
    
    /// Connect using an Access Token (recommended for Memos v0.18+)
    func connectWithToken(serverURL: String, accessToken: String) async throws {
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
        }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        // Normalize server URL
        var normalizedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedURL.hasPrefix("http://") && !normalizedURL.hasPrefix("https://") {
            normalizedURL = "https://" + normalizedURL
        }
        if normalizedURL.hasSuffix("/") {
            normalizedURL = String(normalizedURL.dropLast())
        }
        
        guard let url = URL(string: normalizedURL) else {
            throw AppError.invalidURL
        }
        
        // Validate the token by attempting to get user info
        try await apiService.validateToken(serverURL: url, token: accessToken)
        
        // Save credentials
        keychainService.saveAccessToken(accessToken)
        
        await MainActor.run {
            self.serverURL = normalizedURL
            self.isLoggedIn = true
            self.saveSettings()
        }
    }
    
    func logout() {
        keychainService.deleteAccessToken()
        keychainService.deleteUsername()
        
        isLoggedIn = false
        username = ""
        serverURL = ""
        
        UserDefaults.standard.removeObject(forKey: "serverURL")
    }
    
    // MARK: - Memo Creation
    
    func createMemo(content: String, visibility: MemoVisibility) async throws {
        guard let token = keychainService.getAccessToken(),
              let url = URL(string: serverURL) else {
            throw AppError.notLoggedIn
        }
        
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
        }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        try await apiService.createMemo(
            serverURL: url,
            token: token,
            content: content,
            visibility: visibility
        )
    }
}

enum AppError: LocalizedError {
    case invalidURL
    case notLoggedIn
    case networkError(String)
    case authenticationFailed
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .notLoggedIn:
            return "Please log in first"
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationFailed:
            return "Invalid username or password"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

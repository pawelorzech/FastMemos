import SwiftUI

/// Main menubar popover view
struct MenuBarView: View {
    @ObservedObject var appState: AppState
    let showNoteWindow: () -> Void
    
    @State private var showingSettings = false
    @State private var showingLogin = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "note.text")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("FastMemos")
                    .font(.headline)
                Spacer()
                
                // Connection status
                Circle()
                    .fill(appState.isLoggedIn ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Main content
            VStack(spacing: 12) {
                if appState.isLoggedIn {
                    // Quick Note Button
                    Button(action: showNoteWindow) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("New Note")
                            Spacer()
                            Text("⌘⇧M")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // Server info
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.secondary)
                        Text(appState.serverURL)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                    }
                } else {
                    // Not logged in state
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Not connected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Log In") {
                            showingLogin = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical)
                }
            }
            .padding()
            
            Divider()
            
            // Bottom actions
            VStack(spacing: 4) {
                Button(action: { showingSettings = true }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: openGitHub) {
                    HStack {
                        Image(systemName: "link")
                        Text("View on GitHub")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: sendFeedback) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("Send Feedback")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                
                Divider()
                    .padding(.vertical, 4)
                
                if appState.isLoggedIn {
                    Button(action: { appState.logout() }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                            Spacer()
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                
                // Version info
                HStack {
                    Text("v\(Bundle.main.appVersion)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
        }
        .frame(width: 280)
        .sheet(isPresented: $showingSettings) {
            SettingsView(appState: appState)
        }
        .sheet(isPresented: $showingLogin) {
            LoginView(appState: appState, isPresented: $showingLogin)
        }
    }
    
    private func openGitHub() {
        if let url = URL(string: "https://github.com/pawelorzech/FastMemos") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func sendFeedback() {
        let version = Bundle.main.appVersion
        let build = Bundle.main.buildNumber
        let macOSVersion = ProcessInfo.processInfo.operatingSystemVersionString
        
        let subject = "FastMemos Feedback - v\(version)"
        let body = """
        
        ---
        FastMemos v\(version) (\(build))
        macOS \(macOSVersion)
        """
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:pawel@orzech.me?subject=\(encodedSubject)&body=\(encodedBody)") {
            NSWorkspace.shared.open(url)
        }
    }
}

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

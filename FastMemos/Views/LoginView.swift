import SwiftUI

/// Login view for connecting to a Memos server using Access Token
struct LoginView: View {
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool
    
    @State private var serverURL: String = ""
    @State private var accessToken: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "server.rack")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                Text("Connect to Memos")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Enter your Memos server details")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server URL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("https://memos.example.com", text: $serverURL)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Access Token")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Link("How to get?", destination: URL(string: "https://www.usememos.com/docs/security/access-tokens")!)
                            .font(.caption)
                    }
                    SecureField("Paste your access token", text: $accessToken)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Help text
                VStack(alignment: .leading, spacing: 4) {
                    Text("To get your access token:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("1. Open Memos → Settings → My Account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("2. Click \"Create\" under Access Tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .padding(.horizontal)
            
            // Error message
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
            }
            
            // Buttons
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button(action: connect) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text("Connect")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || serverURL.isEmpty || accessToken.isEmpty)
                .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(width: 380, height: 420)
        .onAppear {
            serverURL = appState.serverURL
        }
    }
    
    private func connect() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await appState.connectWithToken(serverURL: serverURL, accessToken: accessToken)
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

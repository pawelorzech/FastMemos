import SwiftUI

/// Settings view for configuring the app
struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // General Section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("General", systemImage: "gearshape")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Toggle("Launch at login", isOn: $appState.launchAtLogin)
                            .toggleStyle(.switch)
                    }
                    
                    Divider()
                    
                    // Default Visibility Section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Default Visibility", systemImage: "eye")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        // Use Menu instead of segmented Picker for better appearance
                        Menu {
                            ForEach(MemoVisibility.allCases, id: \.self) { visibility in
                                Button(action: {
                                    appState.defaultVisibility = visibility
                                    appState.saveSettings()
                                }) {
                                    Label(visibility.displayName, systemImage: visibility.icon)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: appState.defaultVisibility.icon)
                                Text(appState.defaultVisibility.displayName)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Text(appState.defaultVisibility.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Keyboard Shortcut Section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Global Shortcut", systemImage: "keyboard")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("⌘⇧M")
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            
                            Spacer()
                            
                            Text("Press to open note window")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("About", systemImage: "info.circle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("macOS")
                            Spacer()
                            Text(ProcessInfo.processInfo.operatingSystemVersionString)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if appState.isLoggedIn {
                        Divider()
                        
                        // Connection Section
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Connection", systemImage: "server.rack")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Text("Server")
                                Spacer()
                                Text(appState.serverURL)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Connected")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 350, height: 400)
    }
}

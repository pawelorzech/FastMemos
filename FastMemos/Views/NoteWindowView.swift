import SwiftUI
import AppKit

/// Floating panel for quick note capture
class NotePanel: NSPanel {
    private var hostingView: NSHostingView<NoteWindowView>?
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 280),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.title = ""
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isFloatingPanel = true
        self.level = .floating
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        
        // Set minimum size
        self.minSize = NSSize(width: 400, height: 200)
        self.maxSize = NSSize(width: 800, height: 600)
        
        // Center on screen
        self.center()
        
        let contentView = NoteWindowView(appState: appState, closeWindow: { [weak self] in
            self?.orderOut(nil)
        })
        
        hostingView = NSHostingView(rootView: contentView)
        self.contentView = hostingView
    }
    
    func showWindow() {
        // Reset the view state
        let contentView = NoteWindowView(appState: appState, closeWindow: { [weak self] in
            self?.orderOut(nil)
        })
        hostingView?.rootView = contentView
        
        self.center()
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// Quick note capture view - Modern design
struct NoteWindowView: View {
    @ObservedObject var appState: AppState
    let closeWindow: () -> Void
    
    @State private var content: String = ""
    @State private var visibility: MemoVisibility = .private
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    @FocusState private var isTextEditorFocused: Bool
    
    private let placeholder = "What's on your mind?"
    
    var body: some View {
        VStack(spacing: 0) {
            // Main text area
            ZStack(alignment: .topLeading) {
                // Placeholder
                if content.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                
                // Text editor
                TextEditor(text: $content)
                    .font(.system(size: 15))
                    .focused($isTextEditorFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 150)
            }
            .padding(16)
            .background(Color(NSColor.textBackgroundColor).opacity(0.5))
            
            // Bottom bar
            HStack(spacing: 16) {
                // Visibility picker
                Menu {
                    ForEach(MemoVisibility.allCases, id: \.self) { vis in
                        Button(action: { visibility = vis }) {
                            Label(vis.displayName, systemImage: vis.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: visibility.icon)
                            .font(.system(size: 12))
                        Text(visibility.displayName)
                            .font(.system(size: 13))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .fixedSize()
                
                Spacer()
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .transition(.opacity)
                }
                
                // Success indicator
                if showSuccess {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Sent!")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Character/word count
                HStack(spacing: 6) {
                    Text("\(wordCount) words")
                    Text("•")
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("\(charCount) chars")
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                
                // Submit button
                Button(action: submitMemo) {
                    HStack(spacing: 6) {
                        if isSending {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 14, height: 14)
                        } else {
                            Text("Send")
                            Text("⌘↵")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSending || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .frame(minWidth: 400, minHeight: 200)
        .onAppear {
            visibility = appState.defaultVisibility
            isTextEditorFocused = true
        }
        .onExitCommand {
            closeWindow()
        }
        .animation(.easeInOut(duration: 0.2), value: showSuccess)
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }
    
    private var wordCount: Int {
        let words = content.split { $0.isWhitespace || $0.isNewline }
        return words.count
    }
    
    private var charCount: Int {
        content.count
    }
    
    private func submitMemo() {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSending = true
        errorMessage = nil
        showSuccess = false
        
        Task {
            do {
                try await appState.createMemo(content: content, visibility: visibility)
                await MainActor.run {
                    isSending = false
                    showSuccess = true
                    content = ""
                    
                    // Close after brief delay to show success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        closeWindow()
                    }
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

/// NSVisualEffectView wrapper for SwiftUI
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

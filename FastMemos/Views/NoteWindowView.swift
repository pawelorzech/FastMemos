import SwiftUI
import AppKit

/// Custom NSHostingView that never draws focus ring
class NoFocusRingHostingView<Content: View>: NSHostingView<Content> {
    override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }

    override func drawFocusRingMask() {
        // Don't draw focus ring
    }

    override var focusRingMaskBounds: NSRect {
        .zero
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Disable focus ring on all subviews after view hierarchy is set up
        DispatchQueue.main.async {
            self.disableFocusRingsRecursively(in: self)
        }
    }

    private func disableFocusRingsRecursively(in view: NSView) {
        view.focusRingType = .none
        for subview in view.subviews {
            disableFocusRingsRecursively(in: subview)
        }
    }
}

/// Floating panel for quick note capture
class NotePanel: NSPanel {
    private var hostingView: NoFocusRingHostingView<NoteWindowView>?
    private let appState: AppState
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    init(appState: AppState) {
        self.appState = appState
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 280),
            styleMask: [.borderless, .fullSizeContentView],
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
        self.hasShadow = true
        self.autorecalculatesKeyViewLoop = false

        // Set minimum size
        self.minSize = NSSize(width: 400, height: 200)
        self.maxSize = NSSize(width: 800, height: 600)
        
        // Center on screen
        self.center()
        
        let contentView = NoteWindowView(appState: appState, closeWindow: { [weak self] in
            self?.orderOut(nil)
        })
        
        hostingView = NoFocusRingHostingView(rootView: contentView)
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

        // Disable focus rings on all subviews
        DispatchQueue.main.async { [weak self] in
            if let contentView = self?.contentView {
                Self.disableFocusRingsRecursively(in: contentView)
            }
        }
    }

    private static func disableFocusRingsRecursively(in view: NSView) {
        view.focusRingType = .none
        for subview in view.subviews {
            disableFocusRingsRecursively(in: subview)
        }
    }
}

/// Custom NSTextView with placeholder support and no focus ring
struct PlaceholderTextView: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let font: NSFont
    var onSubmit: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NoFocusRingScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.focusRingType = .none
        scrollView.contentView.focusRingType = .none

        let textView = PlaceholderNSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = font
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.focusRingType = .none
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 0

        // Placeholder setup
        textView.placeholderString = placeholder
        textView.placeholderFont = font
        textView.placeholderColor = NSColor.secondaryLabelColor

        // Auto-resize
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView

        // Focus the text view and disable focus rings in hierarchy
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
            Self.disableFocusRingsRecursively(in: scrollView)
        }

        return scrollView
    }

    private static func disableFocusRingsRecursively(in view: NSView) {
        view.focusRingType = .none
        for subview in view.subviews {
            disableFocusRingsRecursively(in: subview)
        }
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PlaceholderNSTextView else { return }

        if textView.string != text {
            textView.string = text
        }
        textView.needsDisplay = true
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlaceholderTextView

        init(_ parent: PlaceholderTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle Cmd+Enter for submit
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if NSEvent.modifierFlags.contains(.command) {
                    parent.onSubmit?()
                    return true
                }
            }
            return false
        }
    }
}

/// Custom NSScrollView that never draws focus ring
class NoFocusRingScrollView: NSScrollView {
    override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }

    override func drawFocusRingMask() {
        // Don't draw focus ring
    }

    override var focusRingMaskBounds: NSRect {
        .zero
    }
}

/// Custom NSTextView that draws placeholder text
class PlaceholderNSTextView: NSTextView {
    var placeholderString: String = ""
    var placeholderFont: NSFont = NSFont.systemFont(ofSize: 15)
    var placeholderColor: NSColor = NSColor.secondaryLabelColor

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw placeholder if text is empty
        if string.isEmpty {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: placeholderFont,
                .foregroundColor: placeholderColor
            ]
            let placeholderRect = NSRect(
                x: textContainerInset.width + (textContainer?.lineFragmentPadding ?? 0),
                y: textContainerInset.height,
                width: bounds.width - textContainerInset.width * 2,
                height: bounds.height - textContainerInset.height * 2
            )
            placeholderString.draw(in: placeholderRect, withAttributes: attributes)
        }
    }

    override var needsPanelToBecomeKey: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }

    override func drawFocusRingMask() {
        // Don't draw focus ring
    }

    override var focusRingMaskBounds: NSRect {
        .zero
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

    private let placeholder = "What's on your mind?"

    var body: some View {
        VStack(spacing: 0) {
            // Main text area
            PlaceholderTextView(
                text: $content,
                placeholder: placeholder,
                font: NSFont.systemFont(ofSize: 15),
                onSubmit: submitMemo
            )
            .frame(minHeight: 150)
            .padding(16)
            
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
                    Text("·")
                        .foregroundColor(.secondary.opacity(0.4))
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
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .focusable(false)
        .focusEffectDisabled()
        .frame(minWidth: 400, minHeight: 200)
        .onAppear {
            visibility = appState.defaultVisibility
        }
        .onExitCommand {
            closeWindow()
        }
        .background(
            Button("") { closeWindow() }
                .keyboardShortcut("w", modifiers: .command)
                .hidden()
        )
        .animation(Animation.easeInOut(duration: 0.2), value: showSuccess)
        .animation(Animation.easeInOut(duration: 0.2), value: errorMessage)
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

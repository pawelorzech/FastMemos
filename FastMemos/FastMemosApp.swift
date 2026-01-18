import SwiftUI
import AppKit

@main
struct FastMemosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var notePanel: NotePanel?
    private var shortcutService: ShortcutService?
    
    @Published var appState = AppState()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupShortcut()
        
        // Hide dock icon - we're a menubar-only app
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "FastMemos")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 320)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(appState: appState, showNoteWindow: showNoteWindow)
        )
    }
    
    private func setupShortcut() {
        shortcutService = ShortcutService { [weak self] in
            self?.showNoteWindow()
        }
        shortcutService?.registerDefaultShortcut()
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func showNoteWindow() {
        if notePanel == nil {
            notePanel = NotePanel(appState: appState)
        }
        notePanel?.showWindow()
    }
}

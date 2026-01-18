import Foundation
import Carbon
import AppKit

/// Service for managing global keyboard shortcuts
class ShortcutService {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let callback: () -> Void
    
    // Default shortcut: Cmd+Shift+M
    private var currentKeyCode: UInt32 = UInt32(kVK_ANSI_M)
    private var currentModifiers: UInt32 = UInt32(cmdKey | shiftKey)
    
    init(callback: @escaping () -> Void) {
        self.callback = callback
    }
    
    deinit {
        unregisterShortcut()
    }
    
    /// Register the default global shortcut (Cmd+Shift+M)
    func registerDefaultShortcut() {
        // Load saved shortcut or use default
        if let savedKeyCode = UserDefaults.standard.object(forKey: "shortcutKeyCode") as? UInt32 {
            currentKeyCode = savedKeyCode
        }
        if let savedModifiers = UserDefaults.standard.object(forKey: "shortcutModifiers") as? UInt32 {
            currentModifiers = savedModifiers
        }
        
        registerShortcut(keyCode: currentKeyCode, modifiers: currentModifiers)
    }
    
    /// Register a global hotkey
    func registerShortcut(keyCode: UInt32, modifiers: UInt32) {
        unregisterShortcut()
        
        // Store the callback in a way accessible to the C callback
        let context = Unmanaged.passUnretained(self).toOpaque()
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handlerCallback: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let service = Unmanaged<ShortcutService>.fromOpaque(userData).takeUnretainedValue()
            
            DispatchQueue.main.async {
                service.callback()
            }
            
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerCallback,
            1,
            &eventType,
            context,
            &eventHandler
        )
        
        var hotKeyID = EventHotKeyID(signature: OSType(0x464D454D), id: 1) // "FMEM"
        
        RegisterEventHotKey(
            currentKeyCode,
            currentModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        // Save the shortcut
        UserDefaults.standard.set(keyCode, forKey: "shortcutKeyCode")
        UserDefaults.standard.set(modifiers, forKey: "shortcutModifiers")
    }
    
    /// Unregister the current global hotkey
    func unregisterShortcut() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    /// Get a human-readable representation of the current shortcut
    var shortcutDescription: String {
        var parts: [String] = []
        
        if currentModifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if currentModifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if currentModifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if currentModifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        
        // Map key code to character
        let keyChar = keyCodeToString(currentKeyCode)
        parts.append(keyChar)
        
        return parts.joined()
    }
    
    private func keyCodeToString(_ keyCode: UInt32) -> String {
        let keyMap: [UInt32: String] = [
            UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
            UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
            UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
            UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
            UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
            UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
            UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
            UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
            UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z"
        ]
        return keyMap[keyCode] ?? "?"
    }
}

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development

This is a native macOS SwiftUI app. Open `FastMemos.xcodeproj` in Xcode and build with `⌘B`.

From the command line:
```bash
xcodebuild -project FastMemos.xcodeproj -scheme FastMemos -configuration Debug build
```

To run:
```bash
xcodebuild -project FastMemos.xcodeproj -scheme FastMemos -configuration Debug build
open ./build/Debug/FastMemos.app
```

**Requirements:** macOS 13.0+ (Ventura), Xcode 15+

## Architecture

FastMemos is a menubar-only macOS app for quickly capturing notes to a self-hosted [Memos](https://github.com/usememos/memos) server.

### Key Components

**Entry Point (`FastMemosApp.swift`):**
- `AppDelegate` sets up the menubar status item and popover
- App runs as `.accessory` (no dock icon)
- Global hotkey (⌘⇧M) triggers `showNoteWindow()`
- `NotePanel` is a floating `NSPanel` for the note capture UI

**State Management:**
- `AppState` (in `ViewModels/`) is the single source of truth, passed to all views
- Publishes: `isLoggedIn`, `serverURL`, `defaultVisibility`, `isLoading`, `lastError`, `launchAtLogin`
- Handles authentication flow and memo creation

**Services (in `Services/`):**
- `MemosAPIService` - Communicates with Memos v1 API (`/api/v1/memos`, `/api/v1/auth/status`)
- `KeychainService` - Stores access tokens securely in macOS Keychain (service: `me.orzech.FastMemos`)
- `ShortcutService` - Registers global hotkey using Carbon Events API

**Views (in `Views/`):**
- `MenuBarView` - Main popover shown from menubar icon
- `NoteWindowView` - Floating note capture panel with visibility picker
- `LoginView` - Access token authentication flow
- `SettingsView` - App preferences (visibility, launch at login)

**Models (in `Models/`):**
- `Memo`, `CreateMemoRequest` - API request/response structures
- `MemoVisibility` - Enum: `.private`, `.protected`, `.public`

### Data Flow

1. User triggers hotkey → `AppDelegate.showNoteWindow()` → `NotePanel` appears
2. User writes note, selects visibility, presses ⌘Enter
3. `NoteWindowView.submitMemo()` → `AppState.createMemo()` → `MemosAPIService.createMemo()`
4. Token from `KeychainService` is used for Bearer auth

### Settings Storage

- `UserDefaults`: `serverURL`, `defaultVisibility`, `shortcutKeyCode`, `shortcutModifiers`
- Keychain: `accessToken`, `username`
- `SMAppService.mainApp` for launch at login

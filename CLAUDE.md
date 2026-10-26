# CLAUDE.md

Last verified: 28b0389 | 2026-10-26

Native macOS menubar-only SwiftUI app (macOS 13+, Xcode 15+) for quick note capture to a self-hosted [Memos](https://github.com/usememos/memos) server. Runs as `.accessory` (no dock icon). No test target; verify by building and running against a Memos instance.

## Build & run

```bash
xcodebuild -project FastMemos.xcodeproj -scheme FastMemos -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/FastMemos.app
```

(Without `-derivedDataPath` the product lands in Xcode DerivedData, not `./build`.)

## Architecture

- `FastMemosApp.swift`: `AppDelegate` owns the status item and popover; global hotkey (default Cmd+Shift+M, `ShortcutService`, Carbon Events) opens `NotePanel`, a floating `NSPanel` hosting `NoteWindowView`; Cmd+Enter submits.
- `ViewModels/AppState`: single source of truth passed to all views (login state, server URL, default visibility, memo creation).
- `Services/`: `MemosAPIService` (Memos v1 API: `/api/v1/memos`, token check via `/api/v1/auth/status` with `/api/v1/user/me` fallback), `KeychainService`, `ShortcutService`.
- Flow: hotkey -> `showNoteWindow()` -> `NoteWindowView.submitMemo()` -> `AppState.createMemo()` -> `MemosAPIService.createMemo()` with Bearer token.
- Visibility enum `MemoVisibility`: `PRIVATE` / `PROTECTED` / `PUBLIC`.

## Storage

- Keychain (service `me.orzech.FastMemos`): `accessToken`, `username`.
- `UserDefaults`: `serverURL`, `defaultVisibility`, `shortcutKeyCode`, `shortcutModifiers`.
- Launch at login via `SMAppService.mainApp`.

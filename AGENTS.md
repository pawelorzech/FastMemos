# AGENTS

Last verified: 28b0389 | 2026-10-26

Guidance lives in `CLAUDE.md` (build, run, architecture). Needs macOS 13+, Xcode 15+, and a self-hosted Memos instance for runtime testing.

```bash
xcodebuild -project FastMemos.xcodeproj -scheme FastMemos -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/FastMemos.app
```

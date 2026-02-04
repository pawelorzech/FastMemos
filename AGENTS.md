# AGENTS

## Requirements
- macOS 13.0+ (Ventura)
- Xcode 15+
- Access to a self-hosted Memos instance for runtime testing

## Build
- Open `FastMemos.xcodeproj` in Xcode and build with `⌘B`
- CLI build:
```bash
xcodebuild -project FastMemos.xcodeproj -scheme FastMemos -configuration Debug build
```

## Run
```bash
xcodebuild -project FastMemos.xcodeproj -scheme FastMemos -configuration Debug build
open ./build/Debug/FastMemos.app
```

## TODO
- Document any additional workflows or scripts not covered in README/CLAUDE.

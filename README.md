# Hum

A minimal macOS audio player. One file, basic controls, nothing else.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Features

- Open audio files via file picker (⌘O) or drag-and-drop
- Play / Pause (Space), Stop, Go to Beginning
- Scrubber with real-time position tracking
- Loop toggle (persists across sessions)
- Auto-plays on file load
- Supports MP3, AAC, WAV, AIFF, FLAC, M4A, CAF, and more

## Requirements

- macOS 13 Ventura or later
- Swift 5.9+

## Build & Run

```bash
# Debug
swift run

# Release
./build.sh
./deploy/release/Hum
```

## Zero Dependencies

Hum uses only Apple frameworks — SwiftUI, AVFoundation, and UniformTypeIdentifiers. No third-party packages.

## License

[MIT](LICENSE)

# Product Requirements Document: macOS Audio Player

**Project Name:** SimpleAudio  
**Platform:** macOS (Apple Silicon / M-series, minimum macOS 13 Ventura)  
**Language:** Swift 5.9+  
**UI Framework:** SwiftUI  
**Audio Framework:** AVFoundation (`AVAudioPlayer`)  
**Build Toolchain:** Xcode (CLI via `xcodebuild`) — no Xcode UI required  
**Third-party dependencies:** None  

---

## 1. Purpose

A minimal, single-window macOS desktop application that plays one audio file at a time. No playlists, no library, no metadata editing. The app's sole purpose is to open an audio file, play it, and give the user basic transport controls.

---

## 2. Scope

### In Scope
- Open a single audio file via the macOS file picker or drag-and-drop onto the window
- Play / Pause toggle
- Stop (resets position to beginning)
- Go to Beginning (seek to 0:00 without stopping)
- Seek via a scrubber / progress slider
- Loop toggle (loops the current file continuously when enabled)
- Display current playback position and total duration (MM:SS format)
- Display the filename of the loaded file
- Basic window that remembers its last size/position (standard macOS behavior)

### Out of Scope
- Playlists or queues
- Volume control (system volume is sufficient)
- Equalizer or audio effects
- Metadata display (artist, album art, etc.)
- Mini player or menu bar mode
- File format conversion
- Visualizations or waveform display
- Recent files list
- Keyboard media key support (nice to have, not required)

---

## 3. Supported Audio Formats

All formats natively supported by AVAudioPlayer / macOS, including but not limited to:
- MP3
- AAC / M4A
- WAV
- AIFF / AIF
- FLAC
- OGG (if supported by the OS at runtime)
- CAF

The file picker should filter for common audio file extensions. The app does not need to validate format manually — AVAudioPlayer will throw an error on unsupported files, and the app should display a user-friendly error alert in that case.

---

## 4. Project Structure

```
SimpleAudio/
├── SimpleAudio.xcodeproj/        ← Xcode project file
├── SimpleAudio/
│   ├── SimpleAudioApp.swift      ← @main entry point
│   ├── ContentView.swift         ← Main SwiftUI view
│   ├── AudioPlayerModel.swift    ← ObservableObject managing AVAudioPlayer
│   └── Assets.xcassets/          ← App icon placeholder
└── README.md
```

Use a clean MVC/MVVM split: SwiftUI views observe `AudioPlayerModel`, which is the sole owner of the `AVAudioPlayer` instance.

---

## 5. Architecture

### 5.1 `AudioPlayerModel` (ViewModel)

An `ObservableObject` class that wraps `AVAudioPlayer`. It owns all audio state and exposes `@Published` properties consumed by the SwiftUI view.

**Published properties:**
```swift
@Published var isPlaying: Bool
@Published var isLooping: Bool
@Published var currentTime: TimeInterval       // seconds
@Published var duration: TimeInterval          // seconds
@Published var fileName: String               // display name of loaded file
@Published var isFileLoaded: Bool
@Published var errorMessage: String?          // non-nil when an error should be shown
```

**Methods:**
```swift
func loadFile(url: URL)
func play()
func pause()
func stop()          // pauses + seeks to 0
func goToBeginning() // seeks to 0, preserves play/pause state
func seek(to time: TimeInterval)
func toggleLoop()
```

**Timer:** Use a `Timer` (or `CADisplayLink`-style approach) that fires every ~0.1–0.25 seconds while playing to update `currentTime`. The timer should be invalidated when playback stops or the app is backgrounded.

**AVAudioPlayerDelegate:** Implement `audioPlayerDidFinishPlaying(_:successfully:)` to handle end-of-file (reset position, update `isPlaying` to false if not looping — though `AVAudioPlayer.numberOfLoops` can handle loop natively).

### 5.2 Looping

Use `AVAudioPlayer.numberOfLoops`:
- Loop ON: set to `-1` (infinite loop)
- Loop OFF: set to `0` (play once)

### 5.3 `ContentView` (View)

A single SwiftUI `View` that reads from and writes to `AudioPlayerModel`. No audio logic in the view layer.

---

## 6. UI Layout

The window should be clean and functional. Approximate layout (top to bottom):

```
┌────────────────────────────────────────────────┐
│                                                │
│   [Open File Button]                           │
│                                                │
│   Filename: "example_track.mp3"                │
│                                                │
│   ──────────────────────────────────────────   │
│   [Scrubber Slider ████████░░░░░░░░░░░░░░░]    │
│   0:34                              3:12       │
│   ──────────────────────────────────────────   │
│                                                │
│   [|◀]  [▶/⏸]  [⏹]    [🔁 Loop]              │
│                                                │
└────────────────────────────────────────────────┘
```

**Controls:**
| Control | Label / Icon | Action |
|---|---|---|
| Open File | "Open File…" button | Opens NSOpenPanel filtered to audio files |
| Go to Beginning | `⏮` or `|◀` | `goToBeginning()` |
| Play/Pause | `▶` / `⏸` toggle | `play()` / `pause()` |
| Stop | `⏹` | `stop()` (pause + go to beginning) |
| Loop Toggle | `🔁` button, visually active when on | `toggleLoop()` |
| Scrubber | `Slider` bound to `currentTime` | `seek(to:)` on change |

**Time display:** Show `currentTime` on the left and `duration` on the right below the scrubber, formatted as `M:SS` (e.g., `0:34` / `3:12`).

**Disabled state:** All controls except "Open File" should be disabled (`isFileLoaded == false`). The scrubber should also be disabled when no file is loaded.

**Window size:** Minimum 400×200, default ~480×220. Non-resizable or with a sensible minimum constraint is fine.

---

## 7. File Opening

### Primary: Button
- "Open File…" button calls `NSOpenPanel` with:
  - `canChooseFiles = true`
  - `canChooseDirectories = false`
  - `allowsMultipleSelection = false`
  - `allowedContentTypes`: UTTypes for audio (`.mp3`, `.wav`, `.aiff`, `.m4a`, `.flac`, `.caf`)
- On selection, call `model.loadFile(url:)`

### Secondary: Drag and Drop
- The main window content area should accept drag-and-drop of a single audio file
- Use SwiftUI's `.onDrop(of:isTargeted:perform:)` modifier
- On drop, call `model.loadFile(url:)` with the dropped file URL
- Visual feedback (highlight border) when a file is dragged over the window

---

## 8. Error Handling

- If `AVAudioPlayer` fails to initialize (unsupported format, corrupt file, etc.), set `errorMessage` on the model
- Display errors as a SwiftUI `.alert` bound to `errorMessage`
- After dismissal, clear `errorMessage`
- Do not crash; always recover gracefully

---

## 9. App Entry Point & Lifecycle

```swift
@main
struct SimpleAudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AudioPlayerModel())
        }
        .windowResizability(.contentMinSize)
    }
}
```

- Use `@StateObject` or `@EnvironmentObject` for model injection (choose one consistently)
- On app quit, `AVAudioPlayer` stops automatically — no special cleanup needed
- The app does **not** need to request audio permissions on macOS (only iOS requires that)

---

## 10. Xcode Project Configuration

The agent should create an Xcode project that can be **built entirely from the CLI** without opening Xcode:

```bash
# Build
xcodebuild -project SimpleAudio.xcodeproj \
           -scheme SimpleAudio \
           -configuration Debug \
           build

# Run (after build)
open ./build/Debug/SimpleAudio.app
```

**Project settings:**
- Bundle Identifier: `com.local.SimpleAudio`
- Deployment Target: macOS 13.0
- Swift Language Version: 5.9
- Signing: Automatic (personal team) or `CODE_SIGN_IDENTITY=""` for local unsigned builds
- No entitlements file needed (no sandboxing required for local use)
- No App Sandbox (simplifies file access — no need for security-scoped bookmarks)

> **Note for the agent:** If generating the `.xcodeproj` from scratch is complex, it is acceptable to use `swift package init --type executable` and configure a `Package.swift` with a macOS executable target, then use `swift build` and `swift run` instead of `xcodebuild`. The SwiftUI/AVFoundation code itself remains identical either way. Choose whichever scaffolding approach produces a working build with the least friction.

---

## 11. Non-Requirements (Explicit Exclusions)

- No iOS/iPadOS target
- No iCloud sync or file bookmarks persistence
- No menu bar extras
- No preferences/settings window
- No localization (English only)
- No unit tests (out of scope for this version)
- No App Store submission (local/dev use only)

---

## 12. Acceptance Criteria

1. App builds successfully via `xcodebuild` or `swift build` with no errors
2. Clicking "Open File…" opens a file picker filtered to audio files
3. Dropping an audio file onto the window loads it
4. Play button starts playback; pressing again pauses it
5. Stop button pauses playback and resets position to 0:00
6. Go to Beginning resets position to 0:00 (play state unchanged)
7. Scrubber reflects current position in real time during playback
8. Dragging the scrubber seeks to the correct position
9. Loop toggle causes the file to repeat indefinitely when on
10. Time display shows `currentTime` and `duration` correctly in M:SS format
11. All controls are disabled before a file is loaded
12. Loading an unsupported file shows an error alert without crashing
13. App window is clean, functional, and resizes sensibly

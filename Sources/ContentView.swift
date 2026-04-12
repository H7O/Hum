import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var player: AudioPlayerModel
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            fileInfoSection
            scrubberSection
            transportSection
        }
        .padding(24)
        .frame(minWidth: 400, minHeight: 160)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .background(
                        Color.accentColor.opacity(0.08)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    )
            }
        }
        .alert("Error", isPresented: showErrorBinding) {
            Button("OK") { player.errorMessage = nil }
        } message: {
            Text(player.errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var fileInfoSection: some View {
        Text(player.isFileLoaded ? player.fileName : "Open or drop an audio file")
            .font(player.isFileLoaded ? .headline : .subheadline)
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(player.isFileLoaded ? .primary : .secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .help(player.fileName)
    }

    private var scrubberSection: some View {
        VStack(spacing: 2) {
            Slider(
                value: $player.currentTime,
                in: 0...max(player.duration, 1)
            ) { editing in
                player.isSeeking = editing
                if !editing {
                    player.seek(to: player.currentTime)
                }
            }
            .disabled(!player.isFileLoaded)

            HStack {
                Text(formatTime(player.currentTime))
                Spacer()
                Text(formatTime(player.duration))
            }
            .monospacedDigit()
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var transportSection: some View {
        HStack(spacing: 20) {
            Button(action: player.goToBeginning) {
                Image(systemName: "backward.end.fill")
                    .font(.title2)
            }
            .disabled(!player.isFileLoaded)

            Button(action: player.togglePlayPause) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 32)
            }
            .disabled(!player.isFileLoaded)
            .keyboardShortcut(" ", modifiers: [])

            Button(action: player.stop) {
                Image(systemName: "stop.fill")
                    .font(.title2)
            }
            .disabled(!player.isFileLoaded)

            Spacer()

            Button(action: player.toggleLoop) {
                Image(systemName: "repeat")
                    .font(.title3)
                    .foregroundColor(player.isLooping ? .accentColor : .secondary)
            }

            Button("Open File…", action: openFile)
                .keyboardShortcut("o", modifiers: .command)
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Actions

    private func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.audio]

        if panel.runModal() == .OK, let url = panel.url {
            player.loadFile(url: url)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            DispatchQueue.main.async {
                player.loadFile(url: url)
            }
        }

        return true
    }

    // MARK: - Helpers

    private var showErrorBinding: Binding<Bool> {
        Binding(
            get: { player.errorMessage != nil },
            set: { if !$0 { player.errorMessage = nil } }
        )
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let total = Int(max(0, time))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

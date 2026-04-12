import Foundation
import AVFoundation

final class AudioPlayerModel: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var isLooping = UserDefaults.standard.bool(forKey: "isLooping") {
        didSet { UserDefaults.standard.set(isLooping, forKey: "isLooping") }
    }
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var fileName = ""
    @Published var isFileLoaded = false
    @Published var errorMessage: String?

    /// Set by the view during scrubber drag to prevent timer from overwriting the slider position.
    var isSeeking = false

    private var player: AVAudioPlayer?
    private var timer: Timer?

    // MARK: - Public API

    func loadFile(url: URL) {
        stop()

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()

            player = audioPlayer
            duration = audioPlayer.duration
            currentTime = 0
            fileName = url.lastPathComponent
            isFileLoaded = true
            audioPlayer.numberOfLoops = isLooping ? -1 : 0
            errorMessage = nil

            play()
        } catch {
            player = nil
            isFileLoaded = false
            fileName = ""
            duration = 0
            currentTime = 0
            errorMessage = "Could not open file: \(error.localizedDescription)"
        }
    }

    func play() {
        guard player != nil else { return }
        player?.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopTimer()
    }

    func goToBeginning() {
        player?.currentTime = 0
        currentTime = 0
    }

    func seek(to time: TimeInterval) {
        let clamped = min(max(time, 0), duration)
        player?.currentTime = clamped
        currentTime = clamped
    }

    func toggleLoop() {
        isLooping.toggle()
        player?.numberOfLoops = isLooping ? -1 : 0
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let player = self.player, !self.isSeeking else { return }
            self.currentTime = player.currentTime
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !isLooping {
            isPlaying = false
            currentTime = 0
            stopTimer()
        }
    }
}

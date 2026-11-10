import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isBuffering = false
    @Published var volume: Float = 0.8
    @Published var playbackRate: Float = 1.0

    var onPlaybackFinished: (() -> Void)?

    private override init() {
        super.init()
        setupAudioSession()
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    // MARK: - Playback Controls
    func play(url: URL) {
        stop()

        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = volume

        // Observe buffering state via KVO using modern API
        statusObservation = playerItem?.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.isBuffering = item.isPlaybackBufferEmpty
            }
        }

        // Time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let duration = self.playerItem?.duration.seconds, !duration.isNaN, duration > 0 {
                self.duration = duration
            }
        }

        // Observe when playback ends
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // Observe playback failures
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlay),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem
        )

        player?.play()
        isPlaying = true
    }

    func playLocalFile(path: String) {
        // Handle iPod library or custom audio URI schemes directly
        if path.hasPrefix("ipod-library://"), let url = URL(string: path) {
            play(url: url)
            return
        }

        var filePath = path
        if filePath.hasPrefix("file://"), let url = URL(string: filePath) {
            filePath = url.path
        }

        if !FileManager.default.fileExists(atPath: filePath) {
            // Check Documents/Downloads for relocated sandbox containers
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            let candidate1 = docs.appendingPathComponent("Downloads").appendingPathComponent(fileName).path
            let candidate2 = docs.appendingPathComponent("ImportedMusic").appendingPathComponent(fileName).path

            if FileManager.default.fileExists(atPath: candidate1) {
                filePath = candidate1
            } else if FileManager.default.fileExists(atPath: candidate2) {
                filePath = candidate2
            }
        }
        let url = URL(fileURLWithPath: filePath)
        play(url: url)
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func stop() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        statusObservation?.invalidate()
        statusObservation = nil
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
        player?.pause()
        player = nil
        playerItem = nil
        isPlaying = false
        isBuffering = false
        currentTime = 0
        duration = 0
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setVolume(_ vol: Float) {
        volume = vol
        player?.volume = vol
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        player?.rate = rate
    }

    @objc private func playerDidFinishPlaying() {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.onPlaybackFinished?()
        }
    }

    @objc private func playerItemFailedToPlay() {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.isBuffering = false
        }
    }

    // MARK: - Equalizer
    func setupEqualizer(bands: [Float]) {
        // In a real implementation, this would use AVAudioEngine with AVAudioUnitEQ
        // For demonstration, we store the settings
        print("Equalizer bands set: \(bands)")
    }

    // MARK: - Now Playing Info
    func updateNowPlayingInfo(song: Song, artwork: UIImage? = nil) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = song.album
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = song.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        if let image = artwork {
            let artworkItem = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artworkItem
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

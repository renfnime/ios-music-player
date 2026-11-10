import Foundation
import Combine
import MediaPlayer
import AVFoundation
import UIKit

class PlayerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSong: Song?
    @Published var queue: [Song] = []
    @Published var playHistory: [Song] = []
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var showFullPlayer = false
    @Published var isShuffled = false
    @Published var repeatMode: RepeatMode = .off
    @Published var volume: Float = 0.8
    @Published var lyrics: String?
    @Published var isLoadingLyrics = false
    @Published var showLyrics = false
    @Published var youtubeVideoId: String?

    // Equalizer
    @Published var currentEQPreset: EqualizerPreset = .flat
    @Published var customBands: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    private let audioPlayer = AudioPlayerService.shared
    private let youtubePlayer = YouTubePlayerController.shared
    private var cancellables = Set<AnyCancellable>()
    private var originalQueue: [Song] = []

    init() {
        setupBindings()
    }

    // MARK: - Setup
    private func setupBindings() {
        audioPlayer.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playing in
                if self?.currentSong?.source != .youtube {
                    self?.isPlaying = playing
                }
            }
            .store(in: &cancellables)

        audioPlayer.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                if self?.currentSong?.source != .youtube {
                    self?.currentTime = time
                }
            }
            .store(in: &cancellables)

        audioPlayer.$duration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dur in
                if self?.currentSong?.source != .youtube {
                    self?.duration = dur
                }
            }
            .store(in: &cancellables)

        audioPlayer.onPlaybackFinished = { [weak self] in
            self?.playNext(userInitiated: false)
        }

        youtubePlayer.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playing in
                if self?.currentSong?.source == .youtube {
                    self?.isPlaying = playing
                }
            }
            .store(in: &cancellables)

        youtubePlayer.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                if self?.currentSong?.source == .youtube {
                    self?.currentTime = time
                }
            }
            .store(in: &cancellables)

        youtubePlayer.$duration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dur in
                if self?.currentSong?.source == .youtube && dur > 0 {
                    self?.duration = dur
                }
            }
            .store(in: &cancellables)

        youtubePlayer.onPlaybackFinished = { [weak self] in
            self?.playNext(userInitiated: false)
        }
    }

    func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    // MARK: - Playback Controls
    func play(song: Song, fromQueue: [Song]? = nil) {
        if let queue = fromQueue {
            self.originalQueue = queue
            self.queue = isShuffled ? queue.shuffled() : queue
        } else if !queue.contains(song) {
            queue.append(song)
        }

        currentSong = song
        playHistory.append(song)

        if song.source == .youtube {
            audioPlayer.stop()
            audioPlayer.activateAudioSession()
            self.youtubeVideoId = song.youtubeVideoId
            self.isPlaying = true
            if let vid = song.youtubeVideoId {
                youtubePlayer.load(videoId: vid)
            }
        } else {
            youtubePlayer.stop()
            self.youtubeVideoId = nil
            if let localPath = song.localFilePath, song.isDownloaded {
                audioPlayer.playLocalFile(path: localPath)
            } else if let streamURL = song.streamURL ?? song.previewURL,
                      let url = Self.parseURL(from: streamURL),
                      !streamURL.contains("last.fm") && !streamURL.contains("youtube.com") {
                audioPlayer.play(url: url)
            } else {
                Task {
                    let cleanedTitle = Self.cleanTitle(song.title)
                    let query = "\(song.artist) \(cleanedTitle)"
                    if let deezerTracks = try? await DeezerService.shared.search(query: query),
                       let match = deezerTracks.first(where: { ($0.previewURL ?? $0.streamURL) != nil }),
                       let stream = match.previewURL ?? match.streamURL,
                       let url = Self.parseURL(from: stream) {
                        await MainActor.run {
                            if self.currentSong?.id == song.id {
                                self.audioPlayer.play(url: url)
                            }
                        }
                    }
                }
            }
        }

        updateNowPlayingInfo()
        loadLyrics(for: song)
    }

    func togglePlayPause() {
        if currentSong?.source == .youtube {
            youtubePlayer.togglePlayPause()
            isPlaying = youtubePlayer.isPlaying
        } else {
            audioPlayer.togglePlayPause()
        }
        updateNowPlayingInfo()
    }

    func playNext(userInitiated: Bool = true) {
        guard let current = currentSong,
              let currentIndex = queue.firstIndex(of: current) else { return }

        // If playback finished naturally and repeat one is on, repeat the current song
        if !userInitiated && repeatMode == .one {
            play(song: current)
            return
        }

        let nextIndex = currentIndex + 1

        if nextIndex < queue.count {
            play(song: queue[nextIndex])
        } else {
            switch repeatMode {
            case .all:
                if !queue.isEmpty {
                    play(song: queue[0])
                }
            case .one:
                play(song: current)
            case .off:
                audioPlayer.stop()
                youtubePlayer.stop()
                isPlaying = false
            }
        }
    }

    func playPrevious() {
        if currentTime > 3 {
            seek(to: 0)
            return
        }

        guard let current = currentSong,
              let currentIndex = queue.firstIndex(of: current) else { return }

        let prevIndex = currentIndex - 1

        if prevIndex >= 0 {
            play(song: queue[prevIndex])
        } else if repeatMode == .all {
            play(song: queue[queue.count - 1])
        }
    }

    func seek(to time: TimeInterval) {
        if currentSong?.source == .youtube {
            youtubePlayer.seek(to: time)
            currentTime = time
        } else {
            audioPlayer.seek(to: time)
        }
    }

    func setVolume(_ vol: Float) {
        volume = vol
        audioPlayer.setVolume(vol)
    }

    // MARK: - Queue Management
    func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            queue = queue.shuffled()
        } else {
            queue = originalQueue
        }
    }

    func toggleRepeat() {
        repeatMode.toggle()
    }

    func addToQueue(_ song: Song) {
        queue.append(song)
    }

    func removeFromQueue(at index: Int) {
        queue.remove(at: index)
    }

    func moveInQueue(from source: IndexSet, to destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Equalizer
    func setEQPreset(_ preset: EqualizerPreset) {
        currentEQPreset = preset
        customBands = preset.bands
        audioPlayer.setupEqualizer(bands: preset.bands)
    }

    func setCustomBand(index: Int, value: Float) {
        guard index < customBands.count else { return }
        customBands[index] = value
        currentEQPreset = EqualizerPreset(id: "custom", name: "Custom", bands: customBands, isCustom: true)
        audioPlayer.setupEqualizer(bands: customBands)
    }

    // MARK: - Lyrics
    func loadLyrics(for song: Song) {
        lyrics = nil
        isLoadingLyrics = true

        Task {
            do {
                let fetchedLyrics = try await LyricsService.shared.getLyrics(
                    artist: song.artist,
                    title: song.title
                )
                await MainActor.run {
                    self.lyrics = fetchedLyrics
                    self.isLoadingLyrics = false
                }
            } catch {
                await MainActor.run {
                    self.lyrics = "Lyrics not available"
                    self.isLoadingLyrics = false
                }
            }
        }
    }

    // MARK: - Now Playing
    private func updateNowPlayingInfo() {
        guard let song = currentSong else { return }

        let curTime = currentTime
        let dur = duration > 0 ? duration : song.duration

        // Load artwork and update
        if let artworkURL = song.artworkURL, let url = Self.parseURL(from: artworkURL) {
            Task {
                do {
                    let data = try await NetworkService.shared.requestData(url: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            self.audioPlayer.updateNowPlayingInfo(
                                song: song,
                                artwork: image,
                                explicitCurrentTime: curTime,
                                explicitDuration: dur
                            )
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.audioPlayer.updateNowPlayingInfo(
                            song: song,
                            explicitCurrentTime: curTime,
                            explicitDuration: dur
                        )
                    }
                }
            }
        } else {
            audioPlayer.updateNowPlayingInfo(
                song: song,
                explicitCurrentTime: curTime,
                explicitDuration: dur
            )
        }
    }

    // MARK: - Helpers
    static func cleanTitle(_ title: String) -> String {
        var cleaned = title
        cleaned = cleaned.replacingOccurrences(of: "\\s*[\\[\\(].*?[\\]\\)]", with: "", options: .regularExpression)
        let noiseWords = ["ft.", "feat.", "official", "audio", "video", "lyrics", "remix", "4k", "hd"]
        for word in noiseWords {
            cleaned = cleaned.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func parseURL(from string: String) -> URL? {
        if let url = URL(string: string) {
            return url
        }
        if let encoded = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encoded) {
            return url
        }
        return nil
    }

    // MARK: - Computed Properties
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var currentTimeFormatted: String {
        formatTime(currentTime)
    }

    var durationFormatted: String {
        formatTime(duration)
    }

    var remainingTimeFormatted: String {
        formatTime(max(0, duration - currentTime))
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

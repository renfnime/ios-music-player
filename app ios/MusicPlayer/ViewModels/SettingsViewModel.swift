import Foundation

class SettingsViewModel: ObservableObject {
    @Published var audioQuality: AudioQuality {
        didSet { UserDefaults.standard.set(audioQuality.rawValue, forKey: "audioQuality") }
    }
    @Published var enabledSources: Set<MusicSource> {
        didSet {
            let rawValues = enabledSources.map { $0.rawValue }
            UserDefaults.standard.set(rawValues, forKey: "enabledSources")
        }
    }
    @Published var downloadOverWifiOnly: Bool {
        didSet { UserDefaults.standard.set(downloadOverWifiOnly, forKey: "downloadOverWifiOnly") }
    }
    @Published var crossfadeEnabled: Bool {
        didSet { UserDefaults.standard.set(crossfadeEnabled, forKey: "crossfadeEnabled") }
    }
    @Published var crossfadeDuration: Double {
        didSet { UserDefaults.standard.set(crossfadeDuration, forKey: "crossfadeDuration") }
    }
    @Published var normalizeAudio: Bool {
        didSet { UserDefaults.standard.set(normalizeAudio, forKey: "normalizeAudio") }
    }
    @Published var showLyricsAutomatically: Bool {
        didSet { UserDefaults.standard.set(showLyricsAutomatically, forKey: "showLyricsAutomatically") }
    }
    @Published var cacheSize: String = "0 MB"

    // API Keys (user-configurable)
    @Published var jamendoClientId: String {
        didSet { UserDefaults.standard.set(jamendoClientId, forKey: "jamendoClientId") }
    }
    @Published var lastfmApiKey: String {
        didSet { UserDefaults.standard.set(lastfmApiKey, forKey: "lastfmApiKey") }
    }
    @Published var youtubeApiKey: String {
        didSet { UserDefaults.standard.set(youtubeApiKey, forKey: "youtubeApiKey") }
    }
    @Published var soundcloudClientId: String {
        didSet { UserDefaults.standard.set(soundcloudClientId, forKey: "soundcloudClientId") }
    }

    init() {
        let savedQuality = UserDefaults.standard.string(forKey: "audioQuality") ?? AudioQuality.high.rawValue
        self.audioQuality = AudioQuality(rawValue: savedQuality) ?? .high

        if let savedSources = UserDefaults.standard.stringArray(forKey: "enabledSources") {
            self.enabledSources = Set(savedSources.compactMap { MusicSource(rawValue: $0) })
        } else {
            self.enabledSources = Set(MusicSource.allCases)
        }

        self.downloadOverWifiOnly = UserDefaults.standard.object(forKey: "downloadOverWifiOnly") as? Bool ?? true
        self.crossfadeEnabled = UserDefaults.standard.object(forKey: "crossfadeEnabled") as? Bool ?? false
        self.crossfadeDuration = UserDefaults.standard.object(forKey: "crossfadeDuration") as? Double ?? 5.0
        self.normalizeAudio = UserDefaults.standard.object(forKey: "normalizeAudio") as? Bool ?? true
        self.showLyricsAutomatically = UserDefaults.standard.object(forKey: "showLyricsAutomatically") as? Bool ?? true

        self.jamendoClientId = UserDefaults.standard.string(forKey: "jamendoClientId") ?? ""
        self.lastfmApiKey = UserDefaults.standard.string(forKey: "lastfmApiKey") ?? ""
        self.youtubeApiKey = UserDefaults.standard.string(forKey: "youtubeApiKey") ?? ""
        self.soundcloudClientId = UserDefaults.standard.string(forKey: "soundcloudClientId") ?? ""

        calculateCacheSize()
    }

    func clearCache() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Error clearing cache: \(error)")
        }
        calculateCacheSize()
    }

    func calculateCacheSize() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        var totalSize: Int64 = 0

        if let enumerator = FileManager.default.enumerator(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let url as URL in enumerator {
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        cacheSize = formatter.string(fromByteCount: totalSize)
    }

    func toggleSource(_ source: MusicSource) {
        if enabledSources.contains(source) {
            enabledSources.remove(source)
        } else {
            enabledSources.insert(source)
        }
    }
}

import Foundation

// MARK: - Song Model
struct Song: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var artworkURL: String?
    var streamURL: String?
    var previewURL: String?
    var source: MusicSource
    var isDownloaded: Bool = false
    var localFilePath: String?
    var lyrics: String?

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id && lhs.source == rhs.source
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(source)
    }

    var displayDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var youtubeVideoId: String? {
        if source == .youtube {
            return id.replacingOccurrences(of: "youtube_", with: "")
        }
        return nil
    }
}

// MARK: - Music Source
enum MusicSource: String, Codable, CaseIterable, Identifiable {
    case deezer = "Deezer"
    case jamendo = "Jamendo"
    case lastfm = "Last.fm"
    case youtube = "YouTube"
    case soundcloud = "SoundCloud"
    case local = "Local"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .deezer: return "d.circle.fill"
        case .jamendo: return "j.circle.fill"
        case .lastfm: return "l.circle.fill"
        case .youtube: return "play.rectangle.fill"
        case .soundcloud: return "cloud.fill"
        case .local: return "folder.fill"
        }
    }

    var color: String {
        switch self {
        case .deezer: return "#A238FF"
        case .jamendo: return "#2BC5B4"
        case .lastfm: return "#D51007"
        case .youtube: return "#FF0000"
        case .soundcloud: return "#FF5500"
        case .local: return "#1DB954"
        }
    }
}

// MARK: - Playlist Model
struct Playlist: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var description: String
    var songs: [Song]
    var artworkURL: String?
    var createdAt: Date
    var updatedAt: Date
    var isDefault: Bool

    init(id: String = UUID().uuidString, name: String, description: String = "",
         songs: [Song] = [], artworkURL: String? = nil,
         createdAt: Date = Date(), updatedAt: Date = Date(), isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.songs = songs
        self.artworkURL = artworkURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDefault = isDefault
    }

    var songCount: String {
        "\(songs.count) song\(songs.count == 1 ? "" : "s")"
    }

    var totalDuration: String {
        let total = songs.reduce(0) { $0 + $1.duration }
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }
}

// MARK: - Album Model
struct Album: Identifiable, Codable {
    let id: String
    var title: String
    var artist: String
    var artworkURL: String?
    var songs: [Song]
    var releaseDate: String?
    var source: MusicSource
}

// MARK: - Artist Model
struct Artist: Identifiable, Codable {
    let id: String
    var name: String
    var imageURL: String?
    var bio: String?
    var source: MusicSource
}

// MARK: - Search Result
struct SearchResult: Identifiable {
    let id = UUID().uuidString
    var songs: [Song]
    var albums: [Album]
    var artists: [Artist]
    var source: MusicSource

    static var empty: SearchResult {
        SearchResult(songs: [], albums: [], artists: [], source: .deezer)
    }
}

// MARK: - Equalizer Preset
struct EqualizerPreset: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var bands: [Float] // Gain values for each frequency band
    var isCustom: Bool

    static let flat = EqualizerPreset(id: "flat", name: "Flat", bands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], isCustom: false)
    static let bass = EqualizerPreset(id: "bass", name: "Bass Boost", bands: [6, 5, 4, 2, 1, 0, 0, 0, 0, 0], isCustom: false)
    static let treble = EqualizerPreset(id: "treble", name: "Treble Boost", bands: [0, 0, 0, 0, 0, 1, 2, 4, 5, 6], isCustom: false)
    static let vocal = EqualizerPreset(id: "vocal", name: "Vocal", bands: [-2, -1, 0, 2, 4, 4, 3, 1, 0, -1], isCustom: false)
    static let rock = EqualizerPreset(id: "rock", name: "Rock", bands: [5, 4, 3, 1, -1, -1, 0, 2, 3, 4], isCustom: false)
    static let pop = EqualizerPreset(id: "pop", name: "Pop", bands: [-1, 1, 3, 4, 3, 0, -1, -1, 1, 2], isCustom: false)
    static let jazz = EqualizerPreset(id: "jazz", name: "Jazz", bands: [3, 2, 1, 2, -1, -1, 0, 1, 2, 3], isCustom: false)
    static let electronic = EqualizerPreset(id: "electronic", name: "Electronic", bands: [4, 3, 1, 0, -1, 2, 1, 3, 4, 5], isCustom: false)
    static let classical = EqualizerPreset(id: "classical", name: "Classical", bands: [4, 3, 2, 1, -1, -1, 0, 2, 3, 4], isCustom: false)
    static let hiphop = EqualizerPreset(id: "hiphop", name: "Hip Hop", bands: [5, 4, 1, 3, -1, -1, 1, 0, 2, 3], isCustom: false)

    static let allPresets: [EqualizerPreset] = [flat, bass, treble, vocal, rock, pop, jazz, electronic, classical, hiphop]
}

// MARK: - Audio Quality
enum AudioQuality: String, Codable, CaseIterable {
    case low = "Low (96 kbps)"
    case medium = "Medium (160 kbps)"
    case high = "High (320 kbps)"
}

// MARK: - Repeat Mode
enum RepeatMode: String, Codable {
    case off
    case all
    case one

    var icon: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    mutating func toggle() {
        switch self {
        case .off: self = .all
        case .all: self = .one
        case .one: self = .off
        }
    }
}

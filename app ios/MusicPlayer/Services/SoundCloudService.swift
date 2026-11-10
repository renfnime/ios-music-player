import Foundation

// MARK: - SoundCloud Service
class SoundCloudService {
    static let shared = SoundCloudService()
    // Register at https://developers.soundcloud.com/
    var clientId: String {
        let custom = UserDefaults.standard.string(forKey: "soundcloudClientId") ?? ""
        if !custom.trimmingCharacters(in: .whitespaces).isEmpty {
            return custom
        }
        return "YOUR_SOUNDCLOUD_CLIENT_ID"
    }
    private let baseURL = "https://api.soundcloud.com"

    func search(query: String) async throws -> [Song] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/tracks?q=\(encodedQuery)&client_id=\(clientId)&limit=30&format=json") else {
            throw NetworkError.invalidURL
        }

        let response: [SoundCloudTrack] = try await NetworkService.shared.request(url: url, type: [SoundCloudTrack].self)

        return response.map { track in
            Song(
                id: "soundcloud_\(track.id)",
                title: track.title,
                artist: track.user.username,
                album: track.tagList ?? "SoundCloud",
                duration: TimeInterval(track.duration / 1000),
                artworkURL: track.artworkUrl?.replacingOccurrences(of: "large", with: "t500x500"),
                streamURL: track.streamUrl != nil ? "\(track.streamUrl!)?client_id=\(clientId)" : nil,
                previewURL: track.streamUrl != nil ? "\(track.streamUrl!)?client_id=\(clientId)" : nil,
                source: .soundcloud
            )
        }
    }

    func getTrending() async throws -> [Song] {
        guard let url = URL(string: "\(baseURL)/tracks?client_id=\(clientId)&limit=20&order=hotness&format=json") else {
            throw NetworkError.invalidURL
        }

        let response: [SoundCloudTrack] = try await NetworkService.shared.request(url: url, type: [SoundCloudTrack].self)

        return response.map { track in
            Song(
                id: "soundcloud_\(track.id)",
                title: track.title,
                artist: track.user.username,
                album: "SoundCloud",
                duration: TimeInterval(track.duration / 1000),
                artworkURL: track.artworkUrl?.replacingOccurrences(of: "large", with: "t500x500"),
                streamURL: track.streamUrl != nil ? "\(track.streamUrl!)?client_id=\(clientId)" : nil,
                previewURL: track.streamUrl != nil ? "\(track.streamUrl!)?client_id=\(clientId)" : nil,
                source: .soundcloud
            )
        }
    }
}

// MARK: - SoundCloud Response Models
struct SoundCloudTrack: Decodable {
    let id: Int
    let title: String
    let duration: Int
    let artworkUrl: String?
    let streamUrl: String?
    let user: SoundCloudUser
    let tagList: String?

    enum CodingKeys: String, CodingKey {
        case id, title, duration, user
        case artworkUrl = "artwork_url"
        case streamUrl = "stream_url"
        case tagList = "tag_list"
    }
}

struct SoundCloudUser: Decodable {
    let id: Int
    let username: String
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case avatarUrl = "avatar_url"
    }
}

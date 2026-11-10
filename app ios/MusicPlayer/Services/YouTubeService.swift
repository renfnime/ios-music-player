import Foundation

// MARK: - YouTube Service
class YouTubeService {
    static let shared = YouTubeService()
    // Register at https://console.cloud.google.com/ and enable YouTube Data API v3
    var apiKey: String {
        let custom = UserDefaults.standard.string(forKey: "youtubeApiKey") ?? ""
        if !custom.trimmingCharacters(in: .whitespaces).isEmpty {
            return custom
        }
        return "YOUR_YOUTUBE_API_KEY"
    }
    private let baseURL = "https://www.googleapis.com/youtube/v3"

    func search(query: String) async throws -> [Song] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?part=snippet&q=\(encodedQuery)&type=video&videoCategoryId=10&maxResults=20&key=\(apiKey)") else {
            throw NetworkError.invalidURL
        }

        let response: YouTubeSearchResponse = try await NetworkService.shared.request(url: url, type: YouTubeSearchResponse.self)

        return response.items.compactMap { item in
            guard let videoId = item.id.videoId else { return nil }
            return Song(
                id: "youtube_\(videoId)",
                title: item.snippet.title,
                artist: item.snippet.channelTitle,
                album: "YouTube",
                duration: 240,
                artworkURL: item.snippet.thumbnails.high?.url ?? item.snippet.thumbnails.medium?.url ?? item.snippet.thumbnails.defaultThumbnail?.url,
                streamURL: "https://www.youtube.com/watch?v=\(videoId)",
                previewURL: nil,
                source: .youtube
            )
        }
    }

    func getTrending() async throws -> [Song] {
        guard let url = URL(string: "\(baseURL)/videos?part=snippet,contentDetails&chart=mostPopular&videoCategoryId=10&maxResults=20&key=\(apiKey)") else {
            throw NetworkError.invalidURL
        }

        let response: YouTubeTrendingResponse = try await NetworkService.shared.request(url: url, type: YouTubeTrendingResponse.self)

        return response.items.map { item in
            Song(
                id: "youtube_\(item.id)",
                title: item.snippet.title,
                artist: item.snippet.channelTitle,
                album: "YouTube",
                duration: parseDuration(item.contentDetails?.duration ?? "PT4M"),
                artworkURL: item.snippet.thumbnails.high?.url ?? item.snippet.thumbnails.medium?.url,
                streamURL: "https://www.youtube.com/watch?v=\(item.id)",
                previewURL: nil,
                source: .youtube
            )
        }
    }

    private func parseDuration(_ iso: String) -> TimeInterval {
        var duration: TimeInterval = 0
        let str = iso.replacingOccurrences(of: "PT", with: "")

        if let hRange = str.range(of: "H") {
            let hours = str[str.startIndex..<hRange.lowerBound]
            duration += (Double(hours) ?? 0) * 3600
        }
        if let mRange = str.range(of: "M") {
            let start = str.range(of: "H")?.upperBound ?? str.startIndex
            let minutes = str[start..<mRange.lowerBound]
            duration += (Double(minutes) ?? 0) * 60
        }
        if let sRange = str.range(of: "S") {
            let start = str.range(of: "M")?.upperBound ?? str.range(of: "H")?.upperBound ?? str.startIndex
            let seconds = str[start..<sRange.lowerBound]
            duration += Double(seconds) ?? 0
        }

        return duration > 0 ? duration : 240
    }
}

// MARK: - YouTube Response Models
struct YouTubeSearchResponse: Decodable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Decodable {
    let id: YouTubeVideoId
    let snippet: YouTubeSnippet
}

struct YouTubeVideoId: Decodable {
    let videoId: String?
}

struct YouTubeSnippet: Decodable {
    let title: String
    let channelTitle: String
    let thumbnails: YouTubeThumbnails
}

struct YouTubeThumbnails: Decodable {
    let defaultThumbnail: YouTubeThumbnail?
    let medium: YouTubeThumbnail?
    let high: YouTubeThumbnail?

    enum CodingKeys: String, CodingKey {
        case defaultThumbnail = "default"
        case medium, high
    }
}

struct YouTubeThumbnail: Decodable {
    let url: String
    let width: Int?
    let height: Int?
}

struct YouTubeTrendingResponse: Decodable {
    let items: [YouTubeTrendingItem]
}

struct YouTubeTrendingItem: Decodable {
    let id: String
    let snippet: YouTubeSnippet
    let contentDetails: YouTubeContentDetails?
}

struct YouTubeContentDetails: Decodable {
    let duration: String?
}

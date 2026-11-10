import Foundation

// MARK: - Lyrics Service
class LyricsService {
    static let shared = LyricsService()
    // Uses lyrics.ovh - a free lyrics API
    private let baseURL = "https://api.lyrics.ovh/v1"

    func getLyrics(artist: String, title: String) async throws -> String {
        guard let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/\(encodedArtist)/\(encodedTitle)") else {
            throw NetworkError.invalidURL
        }

        do {
            let response: LyricsResponse = try await NetworkService.shared.request(url: url, type: LyricsResponse.self)
            return response.lyrics ?? "Lyrics not available"
        } catch {
            // Fallback: try alternative lyrics search
            return try await searchLyricsAlternative(artist: artist, title: title)
        }
    }

    private func searchLyricsAlternative(artist: String, title: String) async throws -> String {
        // Try with cleaned up title (remove extra info in parentheses/brackets)
        let cleanTitle = title
            .replacingOccurrences(of: "\\(.*?\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\[.*?\\]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanTitle != title {
            guard let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let encodedTitle = cleanTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let url = URL(string: "\(baseURL)/\(encodedArtist)/\(encodedTitle)") else {
                throw NetworkError.invalidURL
            }

            let response: LyricsResponse = try await NetworkService.shared.request(url: url, type: LyricsResponse.self)
            return response.lyrics ?? "Lyrics not available for this song"
        }

        return "Lyrics not available for this song"
    }
}

struct LyricsResponse: Decodable {
    let lyrics: String?
}

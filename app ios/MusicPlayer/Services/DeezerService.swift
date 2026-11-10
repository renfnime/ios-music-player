import Foundation

// MARK: - Deezer API Service
class DeezerService {
    static let shared = DeezerService()
    private let baseURL = "https://api.deezer.com"

    func search(query: String) async throws -> [Song] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&limit=30") else {
            throw NetworkError.invalidURL
        }

        let response: DeezerSearchResponse = try await NetworkService.shared.request(url: url, type: DeezerSearchResponse.self)

        return response.data.map { track in
            Song(
                id: "deezer_\(track.id)",
                title: track.title,
                artist: track.artist?.name ?? "Unknown Artist",
                album: track.album?.title ?? "Unknown Album",
                duration: TimeInterval(track.duration),
                artworkURL: track.album?.coverBig ?? track.album?.coverMedium,
                streamURL: track.preview,
                previewURL: track.preview,
                source: .deezer
            )
        }
    }

    func getChart() async throws -> [Song] {
        guard let url = URL(string: "\(baseURL)/chart/0/tracks?limit=20") else {
            throw NetworkError.invalidURL
        }

        let response: DeezerChartResponse = try await NetworkService.shared.request(url: url, type: DeezerChartResponse.self)

        return response.data.map { track in
            Song(
                id: "deezer_\(track.id)",
                title: track.title,
                artist: track.artist?.name ?? "Unknown Artist",
                album: track.album?.title ?? "Unknown Album",
                duration: TimeInterval(track.duration),
                artworkURL: track.album?.coverBig ?? track.album?.coverMedium,
                streamURL: track.preview,
                previewURL: track.preview,
                source: .deezer
            )
        }
    }

    func getTopArtists() async throws -> [Artist] {
        guard let url = URL(string: "\(baseURL)/chart/0/artists?limit=15") else {
            throw NetworkError.invalidURL
        }

        let response: DeezerArtistChartResponse = try await NetworkService.shared.request(url: url, type: DeezerArtistChartResponse.self)

        return response.data.map { artist in
            Artist(
                id: "deezer_\(artist.id)",
                name: artist.name,
                imageURL: artist.pictureBig ?? artist.pictureMedium,
                source: .deezer
            )
        }
    }
}

// MARK: - Deezer Response Models
struct DeezerSearchResponse: Decodable {
    let data: [DeezerTrack]
}

struct DeezerChartResponse: Decodable {
    let data: [DeezerTrack]
}

struct DeezerArtistChartResponse: Decodable {
    let data: [DeezerArtist]
}

struct DeezerTrack: Decodable {
    let id: Int
    let title: String
    let duration: Int
    let preview: String?
    let artist: DeezerArtistInfo?
    let album: DeezerAlbumInfo?
}

struct DeezerArtistInfo: Decodable {
    let id: Int
    let name: String
}

struct DeezerAlbumInfo: Decodable {
    let id: Int
    let title: String
    let coverMedium: String?
    let coverBig: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case coverMedium = "cover_medium"
        case coverBig = "cover_big"
    }
}

struct DeezerArtist: Decodable {
    let id: Int
    let name: String
    let pictureMedium: String?
    let pictureBig: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case pictureMedium = "picture_medium"
        case pictureBig = "picture_big"
    }
}

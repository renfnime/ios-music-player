import Foundation

// MARK: - Jamendo API Service
class JamendoService {
    static let shared = JamendoService()
    // Jamendo provides free API access with a client ID
    // Configurable via Settings; defaults to public developer client_id
    var clientId: String {
        let custom = UserDefaults.standard.string(forKey: "jamendoClientId") ?? ""
        if !custom.trimmingCharacters(in: .whitespaces).isEmpty {
            return custom
        }
        return "b6747d04"
    }
    private let baseURL = "https://api.jamendo.com/v3.0"

    func search(query: String) async throws -> [Song] {
        if let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "\(baseURL)/tracks/?client_id=\(clientId)&format=json&search=\(encodedQuery)&limit=30&include=musicinfo") {
            if let response = try? await NetworkService.shared.request(url: url, type: JamendoResponse.self),
               !response.results.isEmpty {
                return response.results.map { track in
                    Song(
                        id: "jamendo_\(track.id)",
                        title: track.name,
                        artist: track.artistName,
                        album: track.albumName ?? "Unknown Album",
                        duration: track.duration,
                        artworkURL: track.albumImage,
                        streamURL: track.audio,
                        previewURL: track.audiodownload ?? track.audio,
                        source: .jamendo
                    )
                }
            }
        }

        // Fallback to Deezer search tagged as Jamendo source when API limit is reached
        if let deezer = try? await DeezerService.shared.search(query: query), !deezer.isEmpty {
            return deezer.map { track in
                var s = track
                s.source = .jamendo
                return s
            }
        }
        return []
    }

    func getTrending() async throws -> [Song] {
        if let url = URL(string: "\(baseURL)/tracks/?client_id=\(clientId)&format=json&order=popularity_week&limit=20&include=musicinfo") {
            if let response = try? await NetworkService.shared.request(url: url, type: JamendoResponse.self),
               !response.results.isEmpty {
                return response.results.map { track in
                    Song(
                        id: "jamendo_\(track.id)",
                        title: track.name,
                        artist: track.artistName,
                        album: track.albumName ?? "Unknown Album",
                        duration: track.duration,
                        artworkURL: track.albumImage,
                        streamURL: track.audio,
                        previewURL: track.audiodownload ?? track.audio,
                        source: .jamendo
                    )
                }
            }
        }

        // Fallback to Deezer chart when Jamendo rate limit is reached
        if let deezer = try? await DeezerService.shared.getChart(), deezer.count > 5 {
            return Array(deezer.suffix(from: 5)).map { track in
                var s = track
                s.source = .jamendo
                return s
            }
        }
        return []
    }

    func getFeaturedAlbums() async throws -> [Album] {
        guard let url = URL(string: "\(baseURL)/albums/?client_id=\(clientId)&format=json&order=popularity_week&limit=10") else {
            throw NetworkError.invalidURL
        }

        let response: JamendoAlbumResponse = try await NetworkService.shared.request(url: url, type: JamendoAlbumResponse.self)

        return response.results.map { album in
            Album(
                id: "jamendo_\(album.id)",
                title: album.name,
                artist: album.artistName,
                artworkURL: album.image,
                songs: [],
                releaseDate: album.releasedate,
                source: .jamendo
            )
        }
    }
}

// MARK: - Jamendo Response Models
struct JamendoResponse: Decodable {
    let results: [JamendoTrack]
}

struct JamendoTrack: Decodable {
    let id: String
    let name: String
    let duration: TimeInterval
    let artistName: String
    let albumName: String?
    let albumImage: String?
    let audio: String?
    let audiodownload: String?

    enum CodingKeys: String, CodingKey {
        case id, name, duration, audio, audiodownload
        case artistName = "artist_name"
        case albumName = "album_name"
        case albumImage = "album_image"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id as String or Int
        if let idStr = try? container.decode(String.self, forKey: .id) {
            id = idStr
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            id = UUID().uuidString
        }

        name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown Track"

        // Handle duration as Int, Double, or String
        if let durInt = try? container.decode(Int.self, forKey: .duration) {
            duration = TimeInterval(durInt)
        } else if let durDouble = try? container.decode(Double.self, forKey: .duration) {
            duration = durDouble
        } else if let durStr = try? container.decode(String.self, forKey: .duration) {
            duration = TimeInterval(durStr) ?? 0
        } else {
            duration = 0
        }

        artistName = (try? container.decode(String.self, forKey: .artistName)) ?? "Unknown Artist"
        albumName = try? container.decodeIfPresent(String.self, forKey: .albumName)
        albumImage = try? container.decodeIfPresent(String.self, forKey: .albumImage)
        audio = try? container.decodeIfPresent(String.self, forKey: .audio)
        audiodownload = try? container.decodeIfPresent(String.self, forKey: .audiodownload)
    }
}

struct JamendoAlbumResponse: Decodable {
    let results: [JamendoAlbum]
}

struct JamendoAlbum: Decodable {
    let id: String
    let name: String
    let artistName: String
    let image: String?
    let releasedate: String?

    enum CodingKeys: String, CodingKey {
        case id, name, image, releasedate
        case artistName = "artist_name"
    }
}


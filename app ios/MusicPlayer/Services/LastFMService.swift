import Foundation

// MARK: - Last.fm API Service
class LastFMService {
    static let shared = LastFMService()
    // Register at https://www.last.fm/api/account/create
    var apiKey: String {
        let custom = UserDefaults.standard.string(forKey: "lastfmApiKey") ?? ""
        if !custom.trimmingCharacters(in: .whitespaces).isEmpty {
            return custom
        }
        return "YOUR_LASTFM_API_KEY"
    }
    private let baseURL = "https://ws.audioscrobbler.com/2.0/"

    func search(query: String) async throws -> [Song] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?method=track.search&track=\(encodedQuery)&api_key=\(apiKey)&format=json&limit=30") else {
            throw NetworkError.invalidURL
        }

        let response: LastFMSearchResponse = try await NetworkService.shared.request(url: url, type: LastFMSearchResponse.self)

        return response.results.trackmatches.track.map { track in
            let imageURL = track.image?.last(where: { $0.size == "extralarge" || $0.size == "large" })?.text
            return Song(
                id: "lastfm_\(track.name)_\(track.artist)",
                title: track.name,
                artist: track.artist,
                album: "",
                duration: TimeInterval(Int(track.listeners ?? "0") ?? 0) > 0 ? 240 : 180,
                artworkURL: imageURL,
                streamURL: track.url,
                previewURL: nil,
                source: .lastfm
            )
        }
    }

    func getTopTracks() async throws -> [Song] {
        guard let url = URL(string: "\(baseURL)?method=chart.gettoptracks&api_key=\(apiKey)&format=json&limit=20") else {
            throw NetworkError.invalidURL
        }

        let response: LastFMTopTracksResponse = try await NetworkService.shared.request(url: url, type: LastFMTopTracksResponse.self)

        return response.tracks.track.map { track in
            let imageURL = track.image?.last(where: { $0.size == "extralarge" || $0.size == "large" })?.text
            return Song(
                id: "lastfm_\(track.name)_\(track.artist.name)",
                title: track.name,
                artist: track.artist.name,
                album: "",
                duration: TimeInterval(Int(track.duration ?? "240") ?? 240),
                artworkURL: imageURL,
                streamURL: track.url,
                previewURL: nil,
                source: .lastfm
            )
        }
    }

    func getTrackInfo(artist: String, track: String) async throws -> String? {
        guard let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedTrack = track.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?method=track.getInfo&artist=\(encodedArtist)&track=\(encodedTrack)&api_key=\(apiKey)&format=json") else {
            throw NetworkError.invalidURL
        }

        let response: LastFMTrackInfoResponse = try await NetworkService.shared.request(url: url, type: LastFMTrackInfoResponse.self)
        return response.track?.wiki?.content
    }

    func getTopArtists() async throws -> [Artist] {
        guard let url = URL(string: "\(baseURL)?method=chart.gettopartists&api_key=\(apiKey)&format=json&limit=15") else {
            throw NetworkError.invalidURL
        }

        let response: LastFMTopArtistsResponse = try await NetworkService.shared.request(url: url, type: LastFMTopArtistsResponse.self)

        return response.artists.artist.map { artist in
            let imageURL = artist.image?.last(where: { $0.size == "extralarge" || $0.size == "large" })?.text
            return Artist(
                id: "lastfm_\(artist.name)",
                name: artist.name,
                imageURL: imageURL,
                source: .lastfm
            )
        }
    }
}

// MARK: - Last.fm Response Models
struct LastFMSearchResponse: Decodable {
    let results: LastFMResults
}

struct LastFMResults: Decodable {
    let trackmatches: LastFMTrackMatches
}

struct LastFMTrackMatches: Decodable {
    let track: [LastFMTrackSearch]
}

struct LastFMTrackSearch: Decodable {
    let name: String
    let artist: String
    let url: String?
    let listeners: String?
    let image: [LastFMImage]?

    enum CodingKeys: String, CodingKey {
        case name, artist, url, listeners, image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown"
        if let artistStr = try? container.decode(String.self, forKey: .artist) {
            artist = artistStr
        } else if let artistObj = try? container.decode(LastFMTopTrackArtist.self, forKey: .artist) {
            artist = artistObj.name
        } else {
            artist = "Unknown Artist"
        }
        url = try? container.decodeIfPresent(String.self, forKey: .url)
        if let lStr = try? container.decode(String.self, forKey: .listeners) {
            listeners = lStr
        } else if let lInt = try? container.decode(Int.self, forKey: .listeners) {
            listeners = String(lInt)
        } else {
            listeners = nil
        }
        image = try? container.decodeIfPresent([LastFMImage].self, forKey: .image)
    }
}

struct LastFMImage: Decodable {
    let text: String?
    let size: String

    enum CodingKeys: String, CodingKey {
        case text = "#text"
        case size
    }
}

struct LastFMTopTracksResponse: Decodable {
    let tracks: LastFMTopTracks
}

struct LastFMTopTracks: Decodable {
    let track: [LastFMTopTrack]
}

struct LastFMTopTrack: Decodable {
    let name: String
    let duration: String?
    let url: String?
    let artist: LastFMTopTrackArtist
    let image: [LastFMImage]?

    enum CodingKeys: String, CodingKey {
        case name, duration, url, artist, image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown"
        if let dStr = try? container.decode(String.self, forKey: .duration) {
            duration = dStr
        } else if let dInt = try? container.decode(Int.self, forKey: .duration) {
            duration = String(dInt)
        } else {
            duration = nil
        }
        url = try? container.decodeIfPresent(String.self, forKey: .url)
        artist = (try? container.decode(LastFMTopTrackArtist.self, forKey: .artist)) ?? LastFMTopTrackArtist(name: "Unknown Artist", url: nil)
        image = try? container.decodeIfPresent([LastFMImage].self, forKey: .image)
    }
}

struct LastFMTopTrackArtist: Decodable {
    let name: String
    let url: String?
}

struct LastFMTrackInfoResponse: Decodable {
    let track: LastFMTrackDetail?
}

struct LastFMTrackDetail: Decodable {
    let name: String?
    let wiki: LastFMWiki?
}

struct LastFMWiki: Decodable {
    let content: String?
}

struct LastFMTopArtistsResponse: Decodable {
    let artists: LastFMTopArtistsList
}

struct LastFMTopArtistsList: Decodable {
    let artist: [LastFMArtist]
}

struct LastFMArtist: Decodable {
    let name: String
    let url: String?
    let image: [LastFMImage]?
}

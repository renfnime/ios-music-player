import Foundation

// MARK: - Network Service
class NetworkService {
    static let shared = NetworkService()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    func request<T: Decodable>(url: URL, type: T.Type) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    func requestData(url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        return data
    }

    func downloadFile(from url: URL, to destination: URL) async throws {
        let (tempURL, response) = try await session.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
    }
}

// MARK: - Network Error
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code): return "HTTP Error: \(code)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .noData: return "No data received"
        }
    }
}

// MARK: - iTunes Search Service (Fallback Audio Stream Provider)
class iTunesSearchService {
    static let shared = iTunesSearchService()

    func searchTrack(query: String) async throws -> Song? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&media=music&limit=5") else {
            return nil
        }
        let data = try await NetworkService.shared.requestData(url: url)
        struct ITunesSearchResponse: Decodable {
            let results: [ITunesSearchItem]
        }
        struct ITunesSearchItem: Decodable {
            let trackId: Int?
            let trackName: String?
            let artistName: String?
            let collectionName: String?
            let previewUrl: String?
            let artworkUrl100: String?
        }
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        guard let first = response.results.first(where: { $0.previewUrl != nil }),
              let preview = first.previewUrl else {
            return nil
        }
        return Song(
            id: "itunes_\(first.trackId ?? 0)",
            title: first.trackName ?? query,
            artist: first.artistName ?? "Unknown Artist",
            album: first.collectionName ?? "",
            duration: 30,
            artworkURL: first.artworkUrl100?.replacingOccurrences(of: "100x100bb", with: "500x500bb"),
            streamURL: preview,
            previewURL: preview,
            source: .deezer
        )
    }
}


import Foundation
import CoreData

// MARK: - Download Manager
class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [String: DownloadProgress] = [:]
    @Published var downloadedSongs: [Song] = []

    private let fileManager = FileManager.default

    struct DownloadProgress {
        var songId: String
        var progress: Double
        var isCompleted: Bool
    }

    private var downloadsDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Downloads")
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func downloadSong(_ song: Song) async throws {
        guard let urlString = song.streamURL ?? song.previewURL,
              let url = URL(string: urlString) else {
            throw DownloadError.noStreamURL
        }

        let songId = song.id
        await MainActor.run {
            activeDownloads[songId] = DownloadProgress(songId: songId, progress: 0, isCompleted: false)
        }

        let fileName = "\(song.id.replacingOccurrences(of: "/", with: "_")).mp3"
        let destination = downloadsDirectory.appendingPathComponent(fileName)

        do {
            try await NetworkService.shared.downloadFile(from: url, to: destination)

            var downloadedSong = song
            downloadedSong.isDownloaded = true
            downloadedSong.localFilePath = destination.path

            // Save to Core Data
            await saveDownloadedSong(downloadedSong)

            await MainActor.run {
                activeDownloads[songId]?.progress = 1.0
                activeDownloads[songId]?.isCompleted = true
                if let idx = downloadedSongs.firstIndex(where: { $0.id == songId }) {
                    downloadedSongs[idx] = downloadedSong
                } else {
                    downloadedSongs.append(downloadedSong)
                }
            }

            // Clean up progress after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                activeDownloads.removeValue(forKey: songId)
            }
        } catch {
            await MainActor.run {
                activeDownloads.removeValue(forKey: songId)
            }
            throw error
        }
    }

    func deleteDownload(_ song: Song) {
        if let path = song.localFilePath {
            try? fileManager.removeItem(atPath: path)
        }

        // Remove from Core Data
        removeDownloadedSong(song.id)

        downloadedSongs.removeAll { $0.id == song.id }
    }

    func isDownloaded(_ songId: String) -> Bool {
        downloadedSongs.contains { $0.id == songId }
    }

    func loadDownloadedSongs() {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<DownloadedSongEntity>(entityName: "DownloadedSongEntity")

        do {
            let entities = try context.fetch(request)
            downloadedSongs = entities.map { $0.toSong() }
        } catch {
            print("Error loading downloaded songs: \(error)")
        }
    }

    private func saveDownloadedSong(_ song: Song) async {
        await MainActor.run {
            let context = PersistenceController.shared.container.viewContext
            let request = NSFetchRequest<DownloadedSongEntity>(entityName: "DownloadedSongEntity")
            request.predicate = NSPredicate(format: "id == %@", song.id)
            let entity = (try? context.fetch(request))?.first ?? DownloadedSongEntity(context: context)
            entity.update(from: song)
            PersistenceController.shared.save()
        }
    }

    private func removeDownloadedSong(_ id: String) {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<DownloadedSongEntity>(entityName: "DownloadedSongEntity")
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let results = try context.fetch(request)
            for entity in results {
                context.delete(entity)
            }
            PersistenceController.shared.save()
        } catch {
            print("Error deleting downloaded song: \(error)")
        }
    }
}

enum DownloadError: LocalizedError {
    case noStreamURL
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .noStreamURL: return "No download URL available"
        case .downloadFailed: return "Download failed"
        }
    }
}

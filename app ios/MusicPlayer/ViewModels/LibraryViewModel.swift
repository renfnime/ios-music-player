import Foundation
import CoreData

class LibraryViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var downloadedSongs: [Song] = []
    @Published var localSongs: [Song] = []
    @Published var recentlyPlayed: [Song] = []
    @Published var favorites: Playlist
    @Published var isLoading = false

    private let downloadManager = DownloadManager.shared

    init() {
        favorites = Playlist(id: "favorites", name: "Liked Songs", description: "Your favorite songs",
                            songs: [], isDefault: true)
        loadPlaylists()
        loadDownloadedSongs()
        loadLocalSongs()
        loadRecentlyPlayed()
    }

    // MARK: - Playlist Management
    func createPlaylist(name: String, description: String = "") {
        let playlist = Playlist(name: name, description: description)
        playlists.append(playlist)
        savePlaylist(playlist)
    }

    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        removePlaylistFromStore(playlist.id)
    }

    func renamePlaylist(_ playlist: Playlist, newName: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].name = newName
        playlists[index].updatedAt = Date()
        savePlaylist(playlists[index])
    }

    func addSongToPlaylist(_ song: Song, playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        if !playlists[index].songs.contains(song) {
            playlists[index].songs.append(song)
            playlists[index].updatedAt = Date()
            savePlaylist(playlists[index])
        }
    }

    func removeSongFromPlaylist(_ song: Song, playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].songs.removeAll { $0.id == song.id }
        playlists[index].updatedAt = Date()
        savePlaylist(playlists[index])
    }

    // MARK: - Favorites
    func toggleFavorite(_ song: Song) {
        if favorites.songs.contains(song) {
            favorites.songs.removeAll { $0.id == song.id }
        } else {
            favorites.songs.append(song)
        }
        favorites.updatedAt = Date()
        savePlaylist(favorites)
    }

    func isFavorite(_ song: Song) -> Bool {
        favorites.songs.contains(song)
    }

    // MARK: - Recently Played
    func addToRecentlyPlayed(_ song: Song) {
        recentlyPlayed.removeAll { $0.id == song.id }
        recentlyPlayed.insert(song, at: 0)
        if recentlyPlayed.count > 50 {
            recentlyPlayed = Array(recentlyPlayed.prefix(50))
        }
        saveRecentlyPlayed()
    }

    // MARK: - Downloads
    func downloadSong(_ song: Song) {
        Task {
            do {
                try await downloadManager.downloadSong(song)
                await MainActor.run {
                    loadDownloadedSongs()
                }
            } catch {
                print("Download error: \(error)")
            }
        }
    }

    func deleteDownload(_ song: Song) {
        downloadManager.deleteDownload(song)
        loadDownloadedSongs()
    }

    func isDownloaded(_ song: Song) -> Bool {
        downloadManager.isDownloaded(song.id)
    }

    // MARK: - Persistence
    private func loadPlaylists() {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<PlaylistEntity>(entityName: "PlaylistEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        do {
            let entities = try context.fetch(request)
            let loadedPlaylists = entities.map { $0.toPlaylist() }

            // Separate favorites from regular playlists
            if let favPlaylist = loadedPlaylists.first(where: { $0.id == "favorites" }) {
                favorites = favPlaylist
            }
            playlists = loadedPlaylists.filter { !$0.isDefault }
        } catch {
            print("Error loading playlists: \(error)")
        }
    }

    private func savePlaylist(_ playlist: Playlist) {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<PlaylistEntity>(entityName: "PlaylistEntity")
        request.predicate = NSPredicate(format: "id == %@", playlist.id)

        do {
            let results = try context.fetch(request)
            let entity = results.first ?? PlaylistEntity(context: context)
            entity.update(from: playlist)
            PersistenceController.shared.save()
        } catch {
            print("Error saving playlist: \(error)")
        }
    }

    private func removePlaylistFromStore(_ id: String) {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<PlaylistEntity>(entityName: "PlaylistEntity")
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            PersistenceController.shared.save()
        } catch {
            print("Error deleting playlist: \(error)")
        }
    }

    private func loadDownloadedSongs() {
        downloadManager.loadDownloadedSongs()
        downloadedSongs = downloadManager.downloadedSongs
    }

    private func loadLocalSongs() {
        localSongs = LocalMusicService.shared.getLocalSongs()
    }

    private func saveRecentlyPlayed() {
        if let data = try? JSONEncoder().encode(recentlyPlayed) {
            UserDefaults.standard.set(data, forKey: "recentlyPlayed")
        }
    }

    private func loadRecentlyPlayed() {
        if let data = UserDefaults.standard.data(forKey: "recentlyPlayed"),
           let songs = try? JSONDecoder().decode([Song].self, from: data) {
            recentlyPlayed = songs
        }
    }
}

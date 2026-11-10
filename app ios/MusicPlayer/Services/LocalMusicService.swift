import Foundation
import MediaPlayer
import AVFoundation

// MARK: - Local Music Service
class LocalMusicService {
    static let shared = LocalMusicService()

    func requestPermission(completion: @escaping (Bool) -> Void) {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    func getLocalSongs() -> [Song] {
        var songs: [Song] = []

        #if targetEnvironment(simulator)
        // Provide playable sample data for simulator testing
        let demoAudio = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        songs = [
            Song(id: "local_1", title: "My Local Song", artist: "Local Artist",
                 album: "My Album", duration: 210, artworkURL: nil,
                 streamURL: demoAudio, previewURL: demoAudio, source: .local,
                 isDownloaded: true, localFilePath: nil),
            Song(id: "local_2", title: "Another Track", artist: "Local Artist",
                 album: "My Album", duration: 185, artworkURL: nil,
                 streamURL: demoAudio, previewURL: demoAudio, source: .local,
                 isDownloaded: true, localFilePath: nil),
        ]
        #else
        // Access the device music library using MediaPlayer framework if authorized
        if MPMediaLibrary.authorizationStatus() == .authorized {
            let query = MPMediaQuery.songs()
            if let items = query.items {
                for item in items {
                    let song = Song(
                        id: "local_\(item.persistentID)",
                        title: item.title ?? "Unknown",
                        artist: item.artist ?? "Unknown Artist",
                        album: item.albumTitle ?? "Unknown Album",
                        duration: item.playbackDuration,
                        artworkURL: nil,
                        streamURL: item.assetURL?.absoluteString,
                        previewURL: nil,
                        source: .local,
                        isDownloaded: true,
                        localFilePath: item.assetURL?.absoluteString
                    )
                    songs.append(song)
                }
            }
        }
        #endif

        // Also include manually imported files from Documents/ImportedMusic
        songs.append(contentsOf: getImportedFiles())

        return songs
    }

    func getLocalAlbums() -> [Album] {
        var albums: [Album] = []

        #if targetEnvironment(simulator)
        albums = [
            Album(id: "local_album_1", title: "My Album", artist: "Local Artist",
                  songs: [], source: .local),
        ]
        #else
        let query = MPMediaQuery.albums()
        if let collections = query.collections {
            for collection in collections {
                if let representative = collection.representativeItem {
                    let album = Album(
                        id: "local_album_\(representative.albumPersistentID)",
                        title: representative.albumTitle ?? "Unknown Album",
                        artist: representative.albumArtist ?? representative.artist ?? "Unknown Artist",
                        songs: [],
                        source: .local
                    )
                    albums.append(album)
                }
            }
        }
        #endif

        return albums
    }

    func getImportedFiles() -> [Song] {
        var songs: [Song] = []
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let musicDir = documentsPath.appendingPathComponent("ImportedMusic")

        guard FileManager.default.fileExists(atPath: musicDir.path) else {
            try? FileManager.default.createDirectory(at: musicDir, withIntermediateDirectories: true)
            return songs
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(at: musicDir,
                                                                      includingPropertiesForKeys: nil)
            let audioExtensions = ["mp3", "m4a", "wav", "aac", "flac", "ogg"]

            for file in files where audioExtensions.contains(file.pathExtension.lowercased()) {
                let asset = AVURLAsset(url: file)
                let dur = asset.duration.seconds
                let songDuration: TimeInterval = (!dur.isNaN && dur > 0) ? dur : 0

                let song = Song(
                    id: "imported_\(file.lastPathComponent)",
                    title: file.deletingPathExtension().lastPathComponent,
                    artist: "Unknown Artist",
                    album: "Imported",
                    duration: songDuration,
                    artworkURL: nil,
                    streamURL: file.absoluteString,
                    previewURL: nil,
                    source: .local,
                    isDownloaded: true,
                    localFilePath: file.path
                )
                songs.append(song)
            }
        } catch {
            print("Error reading imported files: \(error)")
        }

        return songs
    }
}

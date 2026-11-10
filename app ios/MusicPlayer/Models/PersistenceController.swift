import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Create the managed object model programmatically
        let model = NSManagedObjectModel()

        // PlaylistEntity
        let playlistEntity = NSEntityDescription()
        playlistEntity.name = "PlaylistEntity"
        playlistEntity.managedObjectClassName = "PlaylistEntity"

        let playlistId = NSAttributeDescription()
        playlistId.name = "id"
        playlistId.attributeType = .stringAttributeType
        playlistId.isOptional = true

        let playlistName = NSAttributeDescription()
        playlistName.name = "name"
        playlistName.attributeType = .stringAttributeType
        playlistName.isOptional = true

        let playlistDesc = NSAttributeDescription()
        playlistDesc.name = "desc"
        playlistDesc.attributeType = .stringAttributeType
        playlistDesc.isOptional = true

        let playlistArtwork = NSAttributeDescription()
        playlistArtwork.name = "artworkURL"
        playlistArtwork.attributeType = .stringAttributeType
        playlistArtwork.isOptional = true

        let playlistCreated = NSAttributeDescription()
        playlistCreated.name = "createdAt"
        playlistCreated.attributeType = .dateAttributeType
        playlistCreated.isOptional = true

        let playlistUpdated = NSAttributeDescription()
        playlistUpdated.name = "updatedAt"
        playlistUpdated.attributeType = .dateAttributeType
        playlistUpdated.isOptional = true

        let playlistIsDefault = NSAttributeDescription()
        playlistIsDefault.name = "isDefault"
        playlistIsDefault.attributeType = .booleanAttributeType
        playlistIsDefault.defaultValue = false
        playlistIsDefault.isOptional = true

        let playlistSongsData = NSAttributeDescription()
        playlistSongsData.name = "songsData"
        playlistSongsData.attributeType = .binaryDataAttributeType
        playlistSongsData.isOptional = true

        playlistEntity.properties = [playlistId, playlistName, playlistDesc, playlistArtwork,
                                      playlistCreated, playlistUpdated, playlistIsDefault, playlistSongsData]

        // DownloadedSongEntity
        let songEntity = NSEntityDescription()
        songEntity.name = "DownloadedSongEntity"
        songEntity.managedObjectClassName = "DownloadedSongEntity"

        let songId = NSAttributeDescription()
        songId.name = "id"
        songId.attributeType = .stringAttributeType
        songId.isOptional = true

        let songTitle = NSAttributeDescription()
        songTitle.name = "title"
        songTitle.attributeType = .stringAttributeType
        songTitle.isOptional = true

        let songArtist = NSAttributeDescription()
        songArtist.name = "artist"
        songArtist.attributeType = .stringAttributeType
        songArtist.isOptional = true

        let songAlbum = NSAttributeDescription()
        songAlbum.name = "album"
        songAlbum.attributeType = .stringAttributeType
        songAlbum.isOptional = true

        let songDuration = NSAttributeDescription()
        songDuration.name = "duration"
        songDuration.attributeType = .doubleAttributeType
        songDuration.isOptional = true

        let songArtworkURL = NSAttributeDescription()
        songArtworkURL.name = "artworkURL"
        songArtworkURL.attributeType = .stringAttributeType
        songArtworkURL.isOptional = true

        let songLocalPath = NSAttributeDescription()
        songLocalPath.name = "localFilePath"
        songLocalPath.attributeType = .stringAttributeType
        songLocalPath.isOptional = true

        let songSource = NSAttributeDescription()
        songSource.name = "source"
        songSource.attributeType = .stringAttributeType
        songSource.isOptional = true

        let songDownloadedAt = NSAttributeDescription()
        songDownloadedAt.name = "downloadedAt"
        songDownloadedAt.attributeType = .dateAttributeType
        songDownloadedAt.isOptional = true

        let songLyrics = NSAttributeDescription()
        songLyrics.name = "lyrics"
        songLyrics.attributeType = .stringAttributeType
        songLyrics.isOptional = true

        songEntity.properties = [songId, songTitle, songArtist, songAlbum, songDuration,
                                  songArtworkURL, songLocalPath, songSource, songDownloadedAt, songLyrics]

        // SettingsEntity
        let settingsEntity = NSEntityDescription()
        settingsEntity.name = "SettingsEntity"
        settingsEntity.managedObjectClassName = "SettingsEntity"

        let settingsKey = NSAttributeDescription()
        settingsKey.name = "key"
        settingsKey.attributeType = .stringAttributeType
        settingsKey.isOptional = true

        let settingsValue = NSAttributeDescription()
        settingsValue.name = "value"
        settingsValue.attributeType = .stringAttributeType
        settingsValue.isOptional = true

        settingsEntity.properties = [settingsKey, settingsValue]

        model.entities = [playlistEntity, songEntity, settingsEntity]

        container = NSPersistentContainer(name: "MusicPlayer", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}

// MARK: - Core Data Managed Object Subclasses
@objc(PlaylistEntity)
public class PlaylistEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var desc: String?
    @NSManaged public var artworkURL: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var isDefault: Bool
    @NSManaged public var songsData: Data?

    func toPlaylist() -> Playlist {
        var songs: [Song] = []
        if let data = songsData {
            songs = (try? JSONDecoder().decode([Song].self, from: data)) ?? []
        }
        return Playlist(
            id: id ?? UUID().uuidString,
            name: name ?? "Untitled",
            description: desc ?? "",
            songs: songs,
            artworkURL: artworkURL,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            isDefault: isDefault
        )
    }

    func update(from playlist: Playlist) {
        id = playlist.id
        name = playlist.name
        desc = playlist.description
        artworkURL = playlist.artworkURL
        createdAt = playlist.createdAt
        updatedAt = Date()
        isDefault = playlist.isDefault
        songsData = try? JSONEncoder().encode(playlist.songs)
    }
}

@objc(DownloadedSongEntity)
public class DownloadedSongEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var artist: String?
    @NSManaged public var album: String?
    @NSManaged public var duration: Double
    @NSManaged public var artworkURL: String?
    @NSManaged public var localFilePath: String?
    @NSManaged public var source: String?
    @NSManaged public var downloadedAt: Date?
    @NSManaged public var lyrics: String?

    func toSong() -> Song {
        Song(
            id: id ?? UUID().uuidString,
            title: title ?? "Unknown",
            artist: artist ?? "Unknown",
            album: album ?? "Unknown",
            duration: duration,
            artworkURL: artworkURL,
            streamURL: nil,
            previewURL: nil,
            source: MusicSource(rawValue: source ?? "Local") ?? .local,
            isDownloaded: true,
            localFilePath: localFilePath,
            lyrics: lyrics
        )
    }

    func update(from song: Song) {
        id = song.id
        title = song.title
        artist = song.artist
        album = song.album
        duration = song.duration
        artworkURL = song.artworkURL
        localFilePath = song.localFilePath
        source = song.source.rawValue
        downloadedAt = Date()
        lyrics = song.lyrics
    }
}

@objc(SettingsEntity)
public class SettingsEntity: NSManagedObject {
    @NSManaged public var key: String?
    @NSManaged public var value: String?
}

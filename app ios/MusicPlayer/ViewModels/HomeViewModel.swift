import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var trendingSongs: [Song] = []
    @Published var newReleases: [Song] = []
    @Published var topArtists: [Artist] = []
    @Published var featuredAlbums: [Album] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadContent() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            async let deezerChart = loadDeezerChart()
            async let jamendoTrending = loadJamendoTrending()
            async let deezerArtists = loadDeezerArtists()
            async let jamendoAlbums = loadJamendoAlbums()

            let (chart, trending, artists, albums) = await (deezerChart, jamendoTrending, deezerArtists, jamendoAlbums)

            await MainActor.run {
                self.trendingSongs = chart
                self.newReleases = trending
                self.topArtists = artists
                self.featuredAlbums = albums
                self.isLoading = false
            }
        }
    }

    private func loadDeezerChart() async -> [Song] {
        (try? await DeezerService.shared.getChart()) ?? sampleSongs()
    }

    private func loadJamendoTrending() async -> [Song] {
        if let results = try? await JamendoService.shared.getTrending(), !results.isEmpty {
            return results
        }
        if let deezer = try? await DeezerService.shared.getChart(), deezer.count > 5 {
            return Array(deezer.suffix(from: 5))
        }
        return sampleSongs()
    }

    private func loadDeezerArtists() async -> [Artist] {
        (try? await DeezerService.shared.getTopArtists()) ?? sampleArtists()
    }

    private func loadJamendoAlbums() async -> [Album] {
        (try? await JamendoService.shared.getFeaturedAlbums()) ?? []
    }

    // MARK: - Sample Data (Fallback when APIs are unavailable)
    private func sampleSongs() -> [Song] {
        let sampleAudio = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        return [
            Song(id: "sample_1", title: "Blinding Lights", artist: "The Weeknd",
                 album: "After Hours", duration: 200,
                 artworkURL: "https://e-cdns-images.dzcdn.net/images/cover/fd131366113b2e59e3592ee5aeb575a2/500x500-000000-80-0-0.jpg",
                 streamURL: sampleAudio, previewURL: sampleAudio, source: .deezer),
            Song(id: "sample_2", title: "Shape of You", artist: "Ed Sheeran",
                 album: "÷ (Divide)", duration: 233,
                 artworkURL: "https://e-cdns-images.dzcdn.net/images/cover/a8385da380644b4eb4c02f74ae94d862/500x500-000000-80-0-0.jpg",
                 streamURL: sampleAudio, previewURL: sampleAudio, source: .deezer),
            Song(id: "sample_3", title: "Someone Like You", artist: "Adele",
                 album: "21", duration: 285,
                 artworkURL: "https://e-cdns-images.dzcdn.net/images/cover/0b840509b533f0b2f4f22c65859d0473/500x500-000000-80-0-0.jpg",
                 streamURL: sampleAudio, previewURL: sampleAudio, source: .deezer),
            Song(id: "sample_4", title: "Bohemian Rhapsody", artist: "Queen",
                 album: "A Night at the Opera", duration: 354,
                 artworkURL: "https://e-cdns-images.dzcdn.net/images/cover/672728f32c3f1f7caecce63f5333f282/500x500-000000-80-0-0.jpg",
                 streamURL: sampleAudio, previewURL: sampleAudio, source: .deezer),
            Song(id: "sample_5", title: "Dance Monkey", artist: "Tones and I",
                 album: "The Kids Are Coming", duration: 210,
                 artworkURL: "https://e-cdns-images.dzcdn.net/images/cover/3dc18055bf96dfc792193b22b1607ec4/500x500-000000-80-0-0.jpg",
                 streamURL: sampleAudio, previewURL: sampleAudio, source: .deezer),
            Song(id: "sample_6", title: "Levitating", artist: "Dua Lipa",
                 album: "Future Nostalgia", duration: 203,
                 artworkURL: "https://e-cdns-images.dzcdn.net/images/cover/f9479b12a829e248b1aa612f068595bf/500x500-000000-80-0-0.jpg",
                 streamURL: sampleAudio, previewURL: sampleAudio, source: .deezer),
            Song(id: "sample_7", title: "Watermelon Sugar", artist: "Harry Styles",
                 album: "Fine Line", duration: 174,
                 artworkURL: "https://e-cdns-images.dzcdn.net/images/cover/014f3b798e4f509ba0dae405f6393437/500x500-000000-80-0-0.jpg",
                 streamURL: sampleAudio, previewURL: sampleAudio, source: .deezer),
            Song(id: "sample_8", title: "Bad Guy", artist: "Billie Eilish",
                 album: "When We All Fall Asleep", duration: 194,
                 artworkURL: "https://e-cdns-images.dzcdn.net/images/cover/3b0a235338691f165a2d6a7aa87e5fd6/500x500-000000-80-0-0.jpg",
                 streamURL: sampleAudio, previewURL: sampleAudio, source: .deezer),
        ]
    }

    private func sampleArtists() -> [Artist] {
        [
            Artist(id: "artist_1", name: "The Weeknd", source: .deezer),
            Artist(id: "artist_2", name: "Ed Sheeran", source: .deezer),
            Artist(id: "artist_3", name: "Adele", source: .deezer),
            Artist(id: "artist_4", name: "Drake", source: .deezer),
            Artist(id: "artist_5", name: "Taylor Swift", source: .deezer),
        ]
    }
}

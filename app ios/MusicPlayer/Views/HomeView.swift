import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Quick Play Section
                    quickPlaySection

                    // Trending Songs
                    if !viewModel.trendingSongs.isEmpty {
                        sectionHeader("Trending Now", icon: "flame.fill", color: .orange)
                        trendingSongsSection
                    }

                    // Top Artists
                    if !viewModel.topArtists.isEmpty {
                        sectionHeader("Top Artists", icon: "star.fill", color: .yellow)
                        topArtistsSection
                    }

                    // New Releases
                    if !viewModel.newReleases.isEmpty {
                        sectionHeader("New Releases", icon: "sparkles", color: AppTheme.accentColor)
                        newReleasesSection
                    }

                    // Recently Played
                    if !libraryVM.recentlyPlayed.isEmpty {
                        sectionHeader("Recently Played", icon: "clock.fill", color: .blue)
                        recentlyPlayedSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadContent()
            }
            .refreshable {
                viewModel.loadContent()
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryText)
                Text("What do you want to listen to?")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "bell.fill")
                .font(.title3)
                .foregroundColor(AppTheme.secondaryText)
                .padding(10)
                .background(AppTheme.cardColor)
                .clipShape(Circle())
        }
        .padding(.top)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning ☀️"
        case 12..<17: return "Good Afternoon 🌤"
        case 17..<21: return "Good Evening 🌅"
        default: return "Good Night 🌙"
        }
    }

    // MARK: - Quick Play
    private var quickPlaySection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickPlayCard(title: "Liked Songs", icon: "heart.fill", color: .purple) {
                if let first = libraryVM.favorites.songs.first {
                    playerVM.play(song: first, fromQueue: libraryVM.favorites.songs)
                    libraryVM.addToRecentlyPlayed(first)
                }
            }
            QuickPlayCard(title: "Recently Played", icon: "clock.fill", color: .blue) {
                if let first = libraryVM.recentlyPlayed.first {
                    playerVM.play(song: first, fromQueue: libraryVM.recentlyPlayed)
                    libraryVM.addToRecentlyPlayed(first)
                }
            }
            QuickPlayCard(title: "Top Hits", icon: "chart.line.uptrend.xyaxis", color: .green) {
                if let first = viewModel.trendingSongs.first {
                    playerVM.play(song: first, fromQueue: viewModel.trendingSongs)
                    libraryVM.addToRecentlyPlayed(first)
                }
            }
            QuickPlayCard(title: "Discover", icon: "wand.and.stars", color: .orange) {
                if let first = viewModel.newReleases.first {
                    playerVM.play(song: first, fromQueue: viewModel.newReleases)
                    libraryVM.addToRecentlyPlayed(first)
                }
            }
        }
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            Spacer()
            Text("See All")
                .font(.caption)
                .foregroundColor(AppTheme.accentColor)
        }
    }

    // MARK: - Trending Songs
    private var trendingSongsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(viewModel.trendingSongs.prefix(10)) { song in
                    SongCard(song: song)
                        .onTapGesture {
                            playerVM.play(song: song, fromQueue: viewModel.trendingSongs)
                            libraryVM.addToRecentlyPlayed(song)
                        }
                }
            }
        }
    }

    // MARK: - Top Artists
    private var topArtistsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(viewModel.topArtists) { artist in
                    ArtistCard(artist: artist)
                }
            }
        }
    }

    // MARK: - New Releases
    private var newReleasesSection: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.newReleases.prefix(5)) { song in
                SongRow(song: song)
                    .onTapGesture {
                        playerVM.play(song: song, fromQueue: viewModel.newReleases)
                        libraryVM.addToRecentlyPlayed(song)
                    }
            }
        }
    }

    // MARK: - Recently Played
    private var recentlyPlayedSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(libraryVM.recentlyPlayed.prefix(10)) { song in
                    SongCard(song: song)
                        .onTapGesture {
                            playerVM.play(song: song, fromQueue: libraryVM.recentlyPlayed)
                            libraryVM.addToRecentlyPlayed(song)
                        }
                }
            }
        }
    }
}

// MARK: - Quick Play Card
struct QuickPlayCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(AppTheme.cardColor)
            .cornerRadius(8)
        }
    }
}

// MARK: - Song Card
struct SongCard: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: song.source.color).opacity(0.8), AppTheme.cardColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)

                if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure(_):
                            musicNotePlaceholder
                        case .empty:
                            ProgressView()
                                .frame(width: 150, height: 150)
                        @unknown default:
                            musicNotePlaceholder
                        }
                    }
                } else {
                    musicNotePlaceholder
                }
            }
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

            Text(song.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primaryText)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)

            Text(song.artist)
                .font(.caption2)
                .foregroundColor(AppTheme.secondaryText)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
        }
    }

    private var musicNotePlaceholder: some View {
        Image(systemName: "music.note")
            .font(.system(size: 40))
            .foregroundColor(AppTheme.secondaryText)
            .frame(width: 150, height: 150)
    }
}

// MARK: - Artist Card
struct ArtistCard: View {
    let artist: Artist

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: artist.source.color).opacity(0.8), AppTheme.cardColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                if let imageURL = artist.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        default:
                            Image(systemName: "person.fill")
                                .font(.system(size: 35))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 35))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

            Text(artist.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primaryText)
                .lineLimit(1)
                .frame(width: 120)
        }
    }
}

// MARK: - Song Row
struct SongRow: View {
    let song: Song
    var showSource: Bool = true
    var onMenu: ((Song) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: song.source.color).opacity(0.3))
                    .frame(width: 48, height: 48)

                if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            Image(systemName: "music.note")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                } else {
                    Image(systemName: "music.note")
                        .foregroundColor(AppTheme.secondaryText)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if song.isDownloaded {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(1)
                    if showSource {
                        Text("• \(song.source.rawValue)")
                            .font(.caption2)
                            .foregroundColor(Color(hex: song.source.color))
                    }
                }
            }

            Spacer()

            Text(song.displayDuration)
                .font(.caption)
                .foregroundColor(AppTheme.tertiaryText)

            if onMenu != nil {
                Button(action: { onMenu?(song) }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(8)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

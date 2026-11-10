import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @State private var selectedSection: LibrarySection = .playlists
    @State private var showCreatePlaylist = false
    @State private var newPlaylistName = ""
    @State private var newPlaylistDescription = ""

    enum LibrarySection: String, CaseIterable {
        case playlists = "Playlists"
        case downloads = "Downloads"
        case local = "Local"
        case favorites = "Favorites"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView

                // Section Tabs
                sectionTabs

                // Content
                ScrollView(showsIndicators: false) {
                    switch selectedSection {
                    case .playlists:
                        playlistsSection
                    case .downloads:
                        downloadsSection
                    case .local:
                        localMusicSection
                    case .favorites:
                        favoritesSection
                    }
                }
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreatePlaylist) {
                createPlaylistSheet
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Your Library")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            Spacer()
            Button(action: { showCreatePlaylist = true }) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundColor(AppTheme.primaryText)
                    .padding(8)
                    .background(AppTheme.cardColor)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    // MARK: - Section Tabs
    private var sectionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LibrarySection.allCases, id: \.self) { section in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSection = section
                        }
                    }) {
                        Text(section.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedSection == section ? .bold : .medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedSection == section ? AppTheme.accentColor : AppTheme.cardColor)
                            .foregroundColor(selectedSection == section ? .white : AppTheme.secondaryText)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Playlists Section
    private var playlistsSection: some View {
        LazyVStack(spacing: 12) {
            // Liked Songs Card
            likedSongsCard

            // User Playlists
            ForEach(libraryVM.playlists) { playlist in
                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                    PlaylistRow(playlist: playlist)
                }
                .contextMenu {
                    Button(role: .destructive) {
                        libraryVM.deletePlaylist(playlist)
                    } label: {
                        Label("Delete Playlist", systemImage: "trash")
                    }
                }
            }

            if libraryVM.playlists.isEmpty {
                emptyStateView(
                    icon: "music.note.list",
                    title: "No playlists yet",
                    subtitle: "Create your first playlist"
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 100)
    }

    private var likedSongsCard: some View {
        NavigationLink(destination: PlaylistDetailView(playlist: libraryVM.favorites)) {
            HStack(spacing: 16) {
                ZStack {
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)

                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Liked Songs")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    Text("\(libraryVM.favorites.songs.count) songs")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.tertiaryText)
            }
            .padding()
            .background(AppTheme.cardColor)
            .cornerRadius(12)
        }
    }

    // MARK: - Downloads Section
    private var downloadsSection: some View {
        LazyVStack(spacing: 0) {
            if libraryVM.downloadedSongs.isEmpty {
                emptyStateView(
                    icon: "arrow.down.circle",
                    title: "No downloads",
                    subtitle: "Download songs for offline listening"
                )
            } else {
                ForEach(libraryVM.downloadedSongs) { song in
                    SongRow(song: song, showSource: true)
                        .onTapGesture {
                            playerVM.play(song: song, fromQueue: libraryVM.downloadedSongs)
                            libraryVM.addToRecentlyPlayed(song)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                libraryVM.deleteDownload(song)
                            } label: {
                                Label("Delete Download", systemImage: "trash")
                            }
                        }
                        .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 100)
    }

    // MARK: - Local Music Section
    private var localMusicSection: some View {
        LazyVStack(spacing: 0) {
            if libraryVM.localSongs.isEmpty {
                emptyStateView(
                    icon: "folder.fill",
                    title: "No local music",
                    subtitle: "Import music files or sync from iTunes"
                )
            } else {
                ForEach(libraryVM.localSongs) { song in
                    SongRow(song: song, showSource: false)
                        .onTapGesture {
                            playerVM.play(song: song, fromQueue: libraryVM.localSongs)
                            libraryVM.addToRecentlyPlayed(song)
                        }
                        .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 100)
    }

    // MARK: - Favorites Section
    private var favoritesSection: some View {
        LazyVStack(spacing: 0) {
            if libraryVM.favorites.songs.isEmpty {
                emptyStateView(
                    icon: "heart",
                    title: "No favorites yet",
                    subtitle: "Like songs to add them here"
                )
            } else {
                ForEach(libraryVM.favorites.songs) { song in
                    SongRow(song: song)
                        .onTapGesture {
                            playerVM.play(song: song, fromQueue: libraryVM.favorites.songs)
                            libraryVM.addToRecentlyPlayed(song)
                        }
                        .padding(.horizontal)
                        .contextMenu {
                            Button(role: .destructive) {
                                libraryVM.toggleFavorite(song)
                            } label: {
                                Label("Unlike", systemImage: "heart.slash")
                            }
                        }
                }
            }
        }
        .padding(.bottom, 100)
    }

    // MARK: - Empty State
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(AppTheme.tertiaryText)
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.secondaryText)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(AppTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Create Playlist Sheet
    private var createPlaylistSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.vibrantGradient)
                        .frame(width: 120, height: 120)
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)

                TextField("Playlist Name", text: $newPlaylistName)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.primaryText)
                    .padding()
                    .background(AppTheme.cardColor)
                    .cornerRadius(12)
                    .padding(.horizontal)

                TextField("Description (optional)", text: $newPlaylistDescription)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.secondaryText)
                    .padding()
                    .background(AppTheme.cardColor)
                    .cornerRadius(12)
                    .padding(.horizontal)

                Spacer()
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCreatePlaylist = false
                        newPlaylistName = ""
                        newPlaylistDescription = ""
                    }
                    .foregroundColor(AppTheme.secondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if !newPlaylistName.isEmpty {
                            libraryVM.createPlaylist(
                                name: newPlaylistName,
                                description: newPlaylistDescription
                            )
                            showCreatePlaylist = false
                            newPlaylistName = ""
                            newPlaylistDescription = ""
                        }
                    }
                    .foregroundColor(AppTheme.accentColor)
                    .disabled(newPlaylistName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Playlist Row
struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.randomGradient())
                    .frame(width: 56, height: 56)

                if let artworkURL = playlist.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            Image(systemName: "music.note.list")
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.primaryText)

                Text(playlist.songCount)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.tertiaryText)
        }
        .padding()
        .background(AppTheme.cardColor)
        .cornerRadius(12)
    }
}

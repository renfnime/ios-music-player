import SwiftUI

struct PlaylistDetailView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    let playlist: Playlist
    @State private var showEditName = false
    @State private var editedName = ""

    private var currentPlaylist: Playlist {
        if playlist.isDefault {
            return libraryVM.favorites
        }
        return libraryVM.playlists.first(where: { $0.id == playlist.id }) ?? playlist
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                playlistHeader

                // Controls
                controlsBar

                // Songs
                if currentPlaylist.songs.isEmpty {
                    emptyPlaylist
                } else {
                    songsList
                }

                Spacer(minLength: 100)
            }
        }
        .background(
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: "#1DB954").opacity(0.4), AppTheme.backgroundColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 350)
                AppTheme.backgroundColor
            }
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        editedName = currentPlaylist.name
                        showEditName = true
                    }) {
                        Label("Rename", systemImage: "pencil")
                    }

                    if !currentPlaylist.isDefault {
                        Button(role: .destructive, action: {
                            libraryVM.deletePlaylist(currentPlaylist)
                            dismiss()
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppTheme.primaryText)
                }
            }
        }
        .alert("Rename Playlist", isPresented: $showEditName) {
            TextField("Playlist name", text: $editedName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if !editedName.isEmpty {
                    libraryVM.renamePlaylist(currentPlaylist, newName: editedName)
                }
            }
        }
    }

    // MARK: - Header
    private var playlistHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentColor, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .shadow(color: AppTheme.accentColor.opacity(0.5), radius: 20, x: 0, y: 10)

                if let firstSong = currentPlaylist.songs.first,
                   let artworkURL = firstSong.artworkURL,
                   let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 180, height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                } else {
                    Image(systemName: currentPlaylist.isDefault ? "heart.fill" : "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 20)

            Text(currentPlaylist.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)

            if !currentPlaylist.description.isEmpty {
                Text(currentPlaylist.description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
            }

            HStack(spacing: 12) {
                Text(currentPlaylist.songCount)
                Text("•")
                Text(currentPlaylist.totalDuration)
            }
            .font(.caption)
            .foregroundColor(AppTheme.tertiaryText)
        }
    }

    // MARK: - Controls
    private var controlsBar: some View {
        HStack(spacing: 20) {
            Spacer()

            Button(action: {
                if let song = currentPlaylist.songs.randomElement() {
                    playerVM.play(song: song, fromQueue: currentPlaylist.songs)
                    playerVM.isShuffled = true
                    libraryVM.addToRecentlyPlayed(song)
                }
            }) {
                Image(systemName: "shuffle")
                    .font(.title3)
                    .foregroundColor(AppTheme.secondaryText)
            }

            Button(action: {
                if let first = currentPlaylist.songs.first {
                    playerVM.play(song: first, fromQueue: currentPlaylist.songs)
                    libraryVM.addToRecentlyPlayed(first)
                }
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(AppTheme.accentColor)
                    .shadow(color: AppTheme.accentColor.opacity(0.5), radius: 10)
            }

            Button(action: {}) {
                Image(systemName: "arrow.down.circle")
                    .font(.title3)
                    .foregroundColor(AppTheme.secondaryText)
            }

            Spacer()
        }
        .padding(.vertical, 16)
    }

    // MARK: - Empty
    private var emptyPlaylist: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.tertiaryText)
            Text("No songs in this playlist")
                .font(.headline)
                .foregroundColor(AppTheme.secondaryText)
            Text("Search for songs and add them here")
                .font(.subheadline)
                .foregroundColor(AppTheme.tertiaryText)
        }
    }

    // MARK: - Songs List
    private var songsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(currentPlaylist.songs.enumerated()), id: \.offset) { index, song in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundColor(AppTheme.tertiaryText)
                        .frame(width: 24)

                    SongRow(song: song, showSource: true)
                }
                .onTapGesture {
                    playerVM.play(song: song, fromQueue: currentPlaylist.songs)
                    libraryVM.addToRecentlyPlayed(song)
                }
                .padding(.horizontal)
                .contextMenu {
                    Button(role: .destructive) {
                        libraryVM.removeSongFromPlaylist(song, playlist: currentPlaylist)
                    } label: {
                        Label("Remove from Playlist", systemImage: "minus.circle")
                    }

                    Button {
                        libraryVM.toggleFavorite(song)
                    } label: {
                        Label(
                            libraryVM.isFavorite(song) ? "Unlike" : "Like",
                            systemImage: libraryVM.isFavorite(song) ? "heart.fill" : "heart"
                        )
                    }
                }
            }
        }
    }
}


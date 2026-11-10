import SwiftUI
import AVKit

struct FullPlayerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var dragOffset: CGFloat = 0
    @State private var artworkScale: CGFloat = 1.0
    @State private var showQueue = false

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            VStack(spacing: 0) {
                // Drag Handle & Top Bar
                topBar

                Spacer()

                if playerVM.showLyrics {
                    lyricsView
                } else {
                    // Artwork
                    artworkSection
                }

                Spacer()

                // Song Info
                songInfoSection

                // Progress Bar
                progressSection

                // Controls
                controlsSection

                // Volume
                volumeSection

                // Bottom Actions
                bottomActions

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 24)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    }
                    dragOffset = 0
                }
        )
        .offset(y: dragOffset)
        .animation(.interactiveSpring(), value: dragOffset)
        .sheet(isPresented: $showQueue) {
            QueueView()
                .environmentObject(playerVM)
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        ZStack {
            if let song = playerVM.currentSong,
               let artworkURL = song.artworkURL,
               let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .blur(radius: 60)
                            .overlay(Color.black.opacity(0.6))
                    }
                }
            }
            AppTheme.backgroundColor.opacity(0.7)
        }
        .ignoresSafeArea()
    }

    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(AppTheme.tertiaryText)
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .foregroundColor(AppTheme.primaryText)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("PLAYING FROM")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.tertiaryText)
                    Text(playerVM.currentSong?.source.rawValue ?? "")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryText)
                }

                Spacer()

                Menu {
                    if let song = playerVM.currentSong {
                        Button(action: { libraryVM.toggleFavorite(song) }) {
                            Label(
                                libraryVM.isFavorite(song) ? "Unlike" : "Like",
                                systemImage: libraryVM.isFavorite(song) ? "heart.fill" : "heart"
                            )
                        }
                        Button(action: { showQueue = true }) {
                            Label("Queue", systemImage: "list.bullet")
                        }
                        Button(action: { libraryVM.downloadSong(song) }) {
                            Label("Download", systemImage: "arrow.down.circle")
                        }

                        Menu("Add to Playlist") {
                            ForEach(libraryVM.playlists) { playlist in
                                Button(playlist.name) {
                                    libraryVM.addSongToPlaylist(song, playlist: playlist)
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(AppTheme.primaryText)
                }
            }
        }
    }

    // MARK: - Artwork
    private var artworkSection: some View {
        ZStack {
            if let song = playerVM.currentSong {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: song.source.color).opacity(0.5), AppTheme.cardColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 300, height: 300)

                    if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 300, height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            case .failure(_):
                                albumPlaceholder
                            case .empty:
                                ProgressView()
                                    .frame(width: 300, height: 300)
                            @unknown default:
                                albumPlaceholder
                            }
                        }
                    } else {
                        albumPlaceholder
                    }
                }
                .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 15)
                .scaleEffect(playerVM.isPlaying ? 1.0 : 0.9)
                .animation(.easeInOut(duration: 0.5), value: playerVM.isPlaying)
            }
        }
    }

    private var albumPlaceholder: some View {
        VStack {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(width: 300, height: 300)
    }

    // MARK: - Lyrics View
    private var lyricsView: some View {
        VStack {
            if playerVM.isLoadingLyrics {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentColor))
                Text("Loading lyrics...")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            } else {
                ScrollView(showsIndicators: false) {
                    Text(playerVM.lyrics ?? "No lyrics available")
                        .font(.body)
                        .foregroundColor(AppTheme.primaryText.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .frame(height: 300)
        .background(AppTheme.cardColor.opacity(0.3))
        .cornerRadius(16)
    }

    // MARK: - Song Info
    private var songInfoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(playerVM.currentSong?.title ?? "Not Playing")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)

                Text(playerVM.currentSong?.artist ?? "")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            if let song = playerVM.currentSong {
                Button(action: { libraryVM.toggleFavorite(song) }) {
                    Image(systemName: libraryVM.isFavorite(song) ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(libraryVM.isFavorite(song) ? AppTheme.accentColor : AppTheme.secondaryText)
                        .scaleEffect(libraryVM.isFavorite(song) ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: libraryVM.isFavorite(song))
                }
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Progress
    private var progressSection: some View {
        VStack(spacing: 6) {
            // Slider
            Slider(
                value: Binding(
                    get: { playerVM.progress },
                    set: { newValue in
                        playerVM.seek(to: newValue * playerVM.duration)
                    }
                ),
                in: 0...1
            )
            .tint(AppTheme.accentColor)

            // Time labels
            HStack {
                Text(playerVM.currentTimeFormatted)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                Spacer()
                Text("-\(playerVM.remainingTimeFormatted)")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
    }

    // MARK: - Controls
    private var controlsSection: some View {
        HStack(spacing: 32) {
            // Shuffle
            Button(action: { playerVM.toggleShuffle() }) {
                Image(systemName: "shuffle")
                    .font(.title3)
                    .foregroundColor(playerVM.isShuffled ? AppTheme.accentColor : AppTheme.secondaryText)
            }

            // Previous
            Button(action: { playerVM.playPrevious() }) {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.primaryText)
            }

            // Play/Pause
            Button(action: { playerVM.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryText)
                        .frame(width: 64, height: 64)
                        .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 10)

                    Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(AppTheme.backgroundColor)
                }
            }

            // Next
            Button(action: { playerVM.playNext() }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.primaryText)
            }

            // Repeat
            Button(action: { playerVM.toggleRepeat() }) {
                Image(systemName: playerVM.repeatMode.icon)
                    .font(.title3)
                    .foregroundColor(playerVM.repeatMode == .off ? AppTheme.secondaryText : AppTheme.accentColor)
                    .overlay(
                        Group {
                            if playerVM.repeatMode == .one {
                                Text("1")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(AppTheme.accentColor)
                                    .offset(y: -1)
                            }
                        }
                    )
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Volume
    private var volumeSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundColor(AppTheme.tertiaryText)

            Slider(
                value: Binding(
                    get: { Double(playerVM.volume) },
                    set: { playerVM.setVolume(Float($0)) }
                ),
                in: 0...1
            )
            .tint(AppTheme.accentColor)

            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundColor(AppTheme.tertiaryText)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Bottom Actions
    private var bottomActions: some View {
        HStack {
            AirPlayView()
                .frame(width: 30, height: 30)

            Spacer()

            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    playerVM.showLyrics.toggle()
                }
            }) {
                Image(systemName: "text.quote")
                    .font(.body)
                    .foregroundColor(playerVM.showLyrics ? AppTheme.accentColor : AppTheme.secondaryText)
            }

            Spacer()

            Button(action: { showQueue = true }) {
                Image(systemName: "list.bullet")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 8)
    }
}

// MARK: - Native AirPlay Route Picker
struct AirPlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = UIColor(hex: "#B3B3B3")
        picker.activeTintColor = UIColor(hex: "#1DB954")
        picker.backgroundColor = .clear
        picker.prioritizesVideoDevices = false
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

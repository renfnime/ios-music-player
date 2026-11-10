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
        GeometryReader { geometry in
            let artworkSize = max(200, min(300, min(geometry.size.width - 48, geometry.size.height * 0.36)))

            ZStack {
                // Background
                backgroundGradient(screenSize: geometry.size)

                VStack(spacing: 0) {
                    // Drag Handle & Top Bar
                    topBar(topInset: geometry.safeAreaInsets.top)
                        .frame(maxWidth: .infinity)

                    Spacer(minLength: 8)

                    if playerVM.showLyrics {
                        lyricsView(maxHeight: artworkSize)
                            .frame(maxWidth: .infinity)
                    } else {
                        // Artwork
                        artworkSection(size: artworkSize)
                            .frame(maxWidth: .infinity)
                    }

                    Spacer(minLength: 8)

                    // Song Info
                    songInfoSection
                        .frame(maxWidth: .infinity)

                    // Progress Bar
                    progressSection
                        .frame(maxWidth: .infinity)

                    // Controls
                    controlsSection
                        .frame(maxWidth: .infinity)

                    // Volume
                    volumeSection
                        .frame(maxWidth: .infinity)

                    // Bottom Actions
                    bottomActions
                        .frame(maxWidth: .infinity)

                    Spacer().frame(height: max(20, geometry.safeAreaInsets.bottom))
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            playerVM.showFullPlayer = false
                        }
                    }
                    dragOffset = 0
                }
        )
        .offset(y: max(0, dragOffset))
        .animation(.interactiveSpring(), value: dragOffset)
        .sheet(isPresented: $showQueue) {
            QueueView()
                .environmentObject(playerVM)
        }
    }

    // MARK: - Background
    private func backgroundGradient(screenSize: CGSize) -> some View {
        ZStack {
            AppTheme.backgroundColor

            if let song = playerVM.currentSong,
               let artworkURL = song.artworkURL,
               let url = PlayerViewModel.parseURL(from: artworkURL) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: screenSize.width, height: screenSize.height)
                            .clipped()
                            .blur(radius: 60)
                            .overlay(Color.black.opacity(0.6))
                    }
                }
                .frame(width: screenSize.width, height: screenSize.height)
                .clipped()
            }
            AppTheme.backgroundColor.opacity(0.7)
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .clipped()
        .ignoresSafeArea()
    }

    // MARK: - Top Bar
    private func topBar(topInset: CGFloat) -> some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(AppTheme.tertiaryText)
                .frame(width: 36, height: 5)
                .padding(.top, max(12, topInset))

            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        playerVM.showFullPlayer = false
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 44, height: 44, alignment: .leading)
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
                        .frame(width: 44, height: 44, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Artwork
    private func artworkSection(size: CGFloat) -> some View {
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
                        .frame(width: size, height: size)

                    if let artworkURL = song.artworkURL, let url = PlayerViewModel.parseURL(from: artworkURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: size, height: size)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            case .failure(_):
                                albumPlaceholder(size: size)
                            case .empty:
                                ProgressView()
                                    .frame(width: size, height: size)
                            @unknown default:
                                albumPlaceholder(size: size)
                            }
                        }
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        albumPlaceholder(size: size)
                    }
                }
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 15)
                .scaleEffect(playerVM.isPlaying ? 1.0 : 0.9)
                .animation(.easeInOut(duration: 0.5), value: playerVM.isPlaying)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func albumPlaceholder(size: CGFloat) -> some View {
        VStack {
            Image(systemName: "music.note")
                .font(.system(size: size * 0.2))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Lyrics View
    private func lyricsView(maxHeight: CGFloat) -> some View {
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
        .frame(maxWidth: .infinity)
        .frame(height: maxHeight)
        .background(AppTheme.cardColor.opacity(0.3))
        .cornerRadius(16)
    }

    // MARK: - Song Info
    private var songInfoSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(playerVM.currentSong?.title ?? "Not Playing")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(playerVM.currentSong?.artist ?? "")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let song = playerVM.currentSong {
                Button(action: { libraryVM.toggleFavorite(song) }) {
                    Image(systemName: libraryVM.isFavorite(song) ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(libraryVM.isFavorite(song) ? AppTheme.accentColor : AppTheme.secondaryText)
                        .scaleEffect(libraryVM.isFavorite(song) ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: libraryVM.isFavorite(song))
                        .frame(width: 44, height: 44, alignment: .trailing)
                }
                .padding(.leading, 8)
            }
        }
        .frame(maxWidth: .infinity)
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
        .frame(maxWidth: .infinity)
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
        .frame(maxWidth: .infinity, alignment: .center)
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Bottom Actions
    private var bottomActions: some View {
        HStack {
            AirPlayView()
                .frame(width: 44, height: 44)

            Spacer()

            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    playerVM.showLyrics.toggle()
                }
            }) {
                Image(systemName: "text.quote")
                    .font(.body)
                    .foregroundColor(playerVM.showLyrics ? AppTheme.accentColor : AppTheme.secondaryText)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button(action: { showQueue = true }) {
                Image(systemName: "list.bullet")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(width: 44, height: 44)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
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

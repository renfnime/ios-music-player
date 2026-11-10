import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.elevatedColor)
                        .frame(height: 2)

                    Rectangle()
                        .fill(AppTheme.accentColor)
                        .frame(width: geometry.size.width * playerVM.progress, height: 2)
                }
            }
            .frame(height: 2)

            // Player Content
            HStack(spacing: 12) {
                if let song = playerVM.currentSong {
                    // Tappable track info area opens Full Player
                    HStack(spacing: 12) {
                        artworkView(for: song)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.primaryText)
                                .lineLimit(1)

                            Text(song.artist)
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        playerVM.showFullPlayer = true
                    }

                    // Playback Controls
                    HStack(spacing: 16) {
                        Button(action: { playerVM.togglePlayPause() }) {
                            Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundColor(AppTheme.primaryText)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { playerVM.playNext() }) {
                            Image(systemName: "forward.fill")
                                .font(.body)
                                .foregroundColor(AppTheme.primaryText)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            AppTheme.surfaceColor
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
    }

    // MARK: - Artwork
    @ViewBuilder
    private func artworkView(for song: Song) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: song.source.color).opacity(0.3))
                .frame(width: 44, height: 44)

            if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
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
    }
}

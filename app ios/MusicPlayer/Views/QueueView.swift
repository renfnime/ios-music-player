import SwiftUI

struct QueueView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Now Playing
                if let currentSong = playerVM.currentSong {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOW PLAYING")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.accentColor)

                        SongRow(song: currentSong, showSource: true)
                    }
                    .padding()
                    .background(AppTheme.cardColor)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                }

                // Queue
                if playerVM.queue.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "list.bullet")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.tertiaryText)
                        Text("Queue is empty")
                            .font(.headline)
                            .foregroundColor(AppTheme.secondaryText)
                        Text("Add songs to your queue")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.tertiaryText)
                        Spacer()
                    }
                } else {
                    List {
                        Section {
                            ForEach(Array(playerVM.queue.enumerated()), id: \.offset) { index, song in
                                SongRow(song: song, showSource: true)
                                    .listRowBackground(
                                        song == playerVM.currentSong ?
                                        AppTheme.accentColor.opacity(0.15) :
                                        AppTheme.backgroundColor
                                    )
                                    .onTapGesture {
                                        playerVM.play(song: song)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            playerVM.removeFromQueue(at: index)
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                            }
                            .onMove(perform: playerVM.moveInQueue)
                        } header: {
                            Text("NEXT IN QUEUE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
        }
    }
}

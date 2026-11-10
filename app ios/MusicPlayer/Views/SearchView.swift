import SwiftUI

struct SearchView: View {
    @EnvironmentObject var searchVM: SearchViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @State private var showSourceFilter = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Source Filter
                sourceFilterBar

                // Content
                if searchVM.searchText.isEmpty {
                    emptySearchView
                } else if searchVM.isSearching {
                    loadingView
                } else if searchVM.searchResults.isEmpty {
                    noResultsView
                } else {
                    searchResultsList
                }
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.secondaryText)
                TextField("Search songs, artists, albums...", text: $searchVM.searchText)
                    .foregroundColor(AppTheme.primaryText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                if !searchVM.searchText.isEmpty {
                    Button(action: { searchVM.clearSearch() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
            .padding(12)
            .background(AppTheme.cardColor)
            .cornerRadius(12)

            Button(action: { showSourceFilter.toggle() }) {
                Image(systemName: "line.3.horizontal.decrease.circle\(showSourceFilter ? ".fill" : "")")
                    .font(.title3)
                    .foregroundColor(showSourceFilter ? AppTheme.accentColor : AppTheme.secondaryText)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    // MARK: - Source Filter
    private var sourceFilterBar: some View {
        Group {
            if showSourceFilter {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MusicSource.allCases) { source in
                            SourceFilterChip(
                                source: source,
                                isSelected: searchVM.selectedSources.contains(source)
                            ) {
                                searchVM.toggleSource(source)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showSourceFilter)
            }
        }
    }

    // MARK: - Empty Search
    private var emptySearchView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !searchVM.recentSearches.isEmpty {
                    HStack {
                        Text("Recent Searches")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                        Button("Clear All") {
                            searchVM.clearRecentSearches()
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.accentColor)
                    }
                    .padding(.horizontal)

                    ForEach(searchVM.recentSearches, id: \.self) { query in
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(AppTheme.tertiaryText)
                            Text(query)
                                .foregroundColor(AppTheme.secondaryText)
                            Spacer()
                            Button(action: { searchVM.removeRecentSearch(query) }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.tertiaryText)
                            }
                        }
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            searchVM.searchText = query
                        }
                    }
                }

                // Browse Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Browse by Source")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(MusicSource.allCases) { source in
                            BrowseSourceCard(source: source) {
                                searchVM.selectedSources = [source]
                                searchVM.searchText = "top"
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            .padding(.top)
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentColor))
                .scaleEffect(1.5)
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .padding(.top, 12)
            Spacer()
        }
    }

    // MARK: - No Results
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.tertiaryText)
            Text("No results found")
                .font(.headline)
                .foregroundColor(AppTheme.secondaryText)
            Text("Try different keywords or change source filters")
                .font(.subheadline)
                .foregroundColor(AppTheme.tertiaryText)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: - Search Results
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                HStack {
                    Text("\(searchVM.searchResults.count) results")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                ForEach(searchVM.searchResults) { song in
                    SongRow(song: song, showSource: true)
                        .onTapGesture {
                            playerVM.play(song: song, fromQueue: searchVM.searchResults)
                            libraryVM.addToRecentlyPlayed(song)
                        }
                    .padding(.horizontal)
                    .contextMenu {
                        songContextMenu(song)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Context Menu
    @ViewBuilder
    private func songContextMenu(_ song: Song) -> some View {
        Button(action: {
            libraryVM.toggleFavorite(song)
        }) {
            Label(
                libraryVM.isFavorite(song) ? "Remove from Favorites" : "Add to Favorites",
                systemImage: libraryVM.isFavorite(song) ? "heart.fill" : "heart"
            )
        }

        Button(action: {
            playerVM.addToQueue(song)
        }) {
            Label("Add to Queue", systemImage: "text.badge.plus")
        }

        if !libraryVM.isDownloaded(song) {
            Button(action: {
                libraryVM.downloadSong(song)
            }) {
                Label("Download", systemImage: "arrow.down.circle")
            }
        }

        Menu("Add to Playlist") {
            ForEach(libraryVM.playlists) { playlist in
                Button(playlist.name) {
                    libraryVM.addSongToPlaylist(song, playlist: playlist)
                }
            }
        }
    }
}

// MARK: - Source Filter Chip
struct SourceFilterChip: View {
    let source: MusicSource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: source.icon)
                    .font(.system(size: 12))
                Text(source.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: source.color).opacity(0.3) : AppTheme.cardColor)
            .foregroundColor(isSelected ? Color(hex: source.color) : AppTheme.secondaryText)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color(hex: source.color).opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Browse Source Card
struct BrowseSourceCard: View {
    let source: MusicSource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: source.icon)
                    .font(.title3)
                Text(source.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color(hex: source.color), Color(hex: source.color).opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
}

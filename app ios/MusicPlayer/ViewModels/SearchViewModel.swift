import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [Song] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var selectedSources: Set<MusicSource> = Set(MusicSource.allCases)
    @Published var recentSearches: [String] = []

    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadRecentSearches()

        // Debounce search
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard !query.isEmpty else {
                    self?.searchResults = []
                    return
                }
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    func performSearch(query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        errorMessage = nil

        searchTask = Task {
            var allResults: [Song] = []

            await withTaskGroup(of: [Song].self) { group in
                if selectedSources.contains(.deezer) {
                    group.addTask {
                        (try? await DeezerService.shared.search(query: query)) ?? []
                    }
                }

                if selectedSources.contains(.jamendo) {
                    group.addTask {
                        (try? await JamendoService.shared.search(query: query)) ?? []
                    }
                }

                if selectedSources.contains(.lastfm) {
                    group.addTask {
                        (try? await LastFMService.shared.search(query: query)) ?? []
                    }
                }

                if selectedSources.contains(.youtube) {
                    group.addTask {
                        (try? await YouTubeService.shared.search(query: query)) ?? []
                    }
                }

                if selectedSources.contains(.soundcloud) {
                    group.addTask {
                        (try? await SoundCloudService.shared.search(query: query)) ?? []
                    }
                }

                if selectedSources.contains(.local) {
                    group.addTask {
                        let localSongs = LocalMusicService.shared.getLocalSongs()
                        return localSongs.filter {
                            $0.title.localizedCaseInsensitiveContains(query) ||
                            $0.artist.localizedCaseInsensitiveContains(query)
                        }
                    }
                }

                for await results in group {
                    allResults.append(contentsOf: results)
                }
            }

            guard !Task.isCancelled else { return }

            // Deduplicate search results by ID to prevent duplicate ID collisions in SwiftUI
            var seen = Set<String>()
            let uniqueResults = allResults.filter { seen.insert($0.id).inserted }

            await MainActor.run {
                self.searchResults = uniqueResults
                self.isSearching = false
                self.saveRecentSearch(query)
            }
        }
    }

    func toggleSource(_ source: MusicSource) {
        if selectedSources.contains(source) {
            selectedSources.remove(source)
        } else {
            selectedSources.insert(source)
        }

        if !searchText.isEmpty {
            performSearch(query: searchText)
        }
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
    }

    // MARK: - Recent Searches
    private func saveRecentSearch(_ query: String) {
        var searches = recentSearches
        searches.removeAll { $0.lowercased() == query.lowercased() }
        searches.insert(query, at: 0)
        if searches.count > 20 {
            searches = Array(searches.prefix(20))
        }
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "recentSearches")
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }

    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
}

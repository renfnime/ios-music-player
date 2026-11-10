import SwiftUI

struct ContentView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case search = "Search"
        case library = "Library"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .search: return "magnifyingglass"
            case .library: return "books.vertical.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                    .tabItem {
                        Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                    }

                SearchView()
                    .tag(Tab.search)
                    .tabItem {
                        Label(Tab.search.rawValue, systemImage: Tab.search.icon)
                    }

                LibraryView()
                    .tag(Tab.library)
                    .tabItem {
                        Label(Tab.library.rawValue, systemImage: Tab.library.icon)
                    }

                SettingsView()
                    .tag(Tab.settings)
                    .tabItem {
                        Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                    }
            }
            .accentColor(AppTheme.accentColor)

            // MiniPlayer positioned directly above the native UITabBar
            if playerVM.currentSong != nil && !playerVM.showFullPlayer {
                MiniPlayerView()
                    .padding(.bottom, 49)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }

            // Persistent YouTube background player host (keeps playback alive without WebKit throttling)
            if let videoId = playerVM.youtubeVideoId, !playerVM.showFullPlayer {
                YouTubePlayerView(videoId: videoId)
                    .frame(width: 320, height: 220)
                    .offset(x: -9999, y: -9999)
                    .allowsHitTesting(false)
                    .zIndex(-100)
            }

            // Full Screen Player Overlay (permanently preserves UITabBar and UINavigationBar across presentation)
            if playerVM.showFullPlayer {
                FullPlayerView()
                    .environmentObject(playerVM)
                    .environmentObject(libraryVM)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .bottom)
                    ))
                    .zIndex(100)
                    .ignoresSafeArea()
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: playerVM.showFullPlayer)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

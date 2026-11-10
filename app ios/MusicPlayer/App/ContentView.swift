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
        GeometryReader { geometry in
            let bottomSafeArea = geometry.safeAreaInsets.bottom
            let tabBarHeight: CGFloat = 49 + bottomSafeArea

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
                if playerVM.currentSong != nil {
                    MiniPlayerView()
                        .padding(.bottom, tabBarHeight)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Persistent YouTube background player host (keeps playback alive when full player is closed)
                if let videoId = playerVM.youtubeVideoId, !playerVM.showFullPlayer {
                    YouTubePlayerView(videoId: videoId)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .fullScreenCover(isPresented: $playerVM.showFullPlayer) {
            FullPlayerView()
                .environmentObject(playerVM)
                .environmentObject(libraryVM)
        }
    }
}

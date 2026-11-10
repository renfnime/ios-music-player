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
            .padding(.bottom, playerVM.currentSong != nil ? 64 : 0)

            if playerVM.currentSong != nil {
                VStack(spacing: 0) {
                    MiniPlayerView()
                        .padding(.bottom, 49)
                }
            }
        }
        .sheet(isPresented: $playerVM.showFullPlayer) {
            FullPlayerView()
                .environmentObject(playerVM)
                .environmentObject(libraryVM)
        }
    }
}

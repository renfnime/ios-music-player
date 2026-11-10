import SwiftUI

@main
struct MusicPlayerApp: App {
    @StateObject private var playerVM = PlayerViewModel()
    @StateObject private var libraryVM = LibraryViewModel()
    @StateObject private var searchVM = SearchViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerVM)
                .environmentObject(libraryVM)
                .environmentObject(searchVM)
                .environmentObject(settingsVM)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
                .onAppear {
                    playerVM.setupRemoteControls()
                }
        }
    }
}

import SwiftUI

struct FoliaRootView: View {
    @StateObject private var player = PlayerViewModel()
    @StateObject private var settings = PlayerSettings()

    var body: some View {
        TabView {
            LibraryView(player: player)
                .tabItem {
                    Label("音乐", systemImage: "music.note.list")
                }

            NavidromeView()
                .tabItem {
                    Label("Navidrome", systemImage: "server.rack")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "slider.horizontal.3")
                }
        }
        .environmentObject(settings)
        .tint(.primary)
    }
}

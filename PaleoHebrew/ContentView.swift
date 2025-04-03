import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CheatSheetView()
                .tabItem {
                    Label("Learn", systemImage: "book")
                }
                .tag(0)
            
            
            GameView()
                .tabItem {
                    Label("Play", systemImage: "play.circle")
                }
                .tag(1)
            
            // Add the new Converter tab here
            ConverterView()
                .tabItem {
                    Label("Convert", systemImage: "arrow.left.arrow.right")
                }
                .tag(2)
             
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}

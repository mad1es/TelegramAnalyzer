import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .analyze
    
    enum Tab {
        case analyze, settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AnalyzeView()
                .tabItem {
                    Label("Analyze", systemImage: "chart.bar")
                }
                .tag(Tab.analyze)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PreviewEnvironment())
    }
}

class PreviewEnvironment: ObservableObject {
    @Published var sampleChat = Chat.sampleChat
} 
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .analyze
    @EnvironmentObject var localizationManager: LocalizationManager
    
    enum Tab {
        case analyze, settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AnalyzeView()
                .tabItem {
                    Label("app.name".localized, systemImage: "chart.bar")
                }
                .tag(Tab.analyze)
            
            SettingsView()
                .tabItem {
                    Label("navigation.settings".localized, systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
    }
}

    // MARK: - preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PreviewEnvironment())
            .environmentObject(LocalizationManager.shared)
    }
}

class PreviewEnvironment: ObservableObject {
    @Published var sampleChat = Chat.sampleChat
} 
import SwiftUI
// add dark theme

struct SettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var showClearConfirmation = false
    @State private var showClearSuccess = false
    @EnvironmentObject var localizationManager: LocalizationManager
    
    private let chatsKey = "savedChats"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("settings.theme".localized) {
                    Picker("settings.theme".localized, selection: $selectedTheme) {
                        Label("settings.themeSystem".localized, systemImage: "gear")
                            .tag("system")
                        Label("settings.themeLight".localized, systemImage: "sun.max")
                            .tag("light")
                        Label("settings.themeDark".localized, systemImage: "moon")
                            .tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("settings.language".localized) {
                    Picker("settings.language".localized, selection: Binding(
                        get: { localizationManager.currentLanguage },
                        set: { localizationManager.setLanguage($0) }
                    )) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Data Management") {
                    Button(action: {
                        showClearConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear All Saved Chats")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: {
                        localizationManager.resetToSystemLanguage()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.blue)
                            Text("Reset Language to Default")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section("settings.about".localized) {
                    HStack {
                        Text("settings.version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("settings.developer".localized)
                        Spacer()
                        Text("Madi Baizhuman")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Chats?", isPresented: $showClearConfirmation) {
                Button("action.cancel".localized, role: .cancel) {}
                Button("action.delete".localized, role: .destructive) {
                    clearAllChats()
                }
            } message: {
                Text("This will remove all imported chats. This action cannot be undone.")
            }
            .alert("import.success".localized, isPresented: $showClearSuccess) {
                Button("action.confirm".localized) {}
            } message: {
                Text("All chats have been cleared.")
            }
        }
    }
    
    private func clearAllChats() {
        UserDefaults.standard.removeObject(forKey: chatsKey)
        showClearSuccess = true
    }
} 
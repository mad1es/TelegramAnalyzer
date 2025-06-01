//
//  analApp.swift
//  anal
//
//  Created by Madi Baizhuman on 02.04.2025.
//

import SwiftUI

@main
struct analApp: App {
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(getColorScheme())
                .environmentObject(localizationManager)
                .environment(\.locale, localizationManager.currentLanguage.locale)
                .environment(\.layoutDirection, localizationManager.currentLanguage.layoutDirection)
                .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                    // Force UI refresh when language changes
                }
        }
    }
    
    private func getColorScheme() -> ColorScheme? {
        switch selectedTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System default
        }
    }
}

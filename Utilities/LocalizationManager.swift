import SwiftUI
import Foundation

// MARK: - Language Support
enum AppLanguage: String, CaseIterable {
    case english = "en"
    case russian = "ru"
    case kazakh = "kk"
    case uyghur = "ug"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        case .kazakh: return "Қазақша"
        case .uyghur: return "Уйғурчә"
        }
    }
    
    var locale: Locale {
        switch self {
        case .english: return Locale(identifier: "en")
        case .russian: return Locale(identifier: "ru")
        case .kazakh: return Locale(identifier: "kk")
        case .uyghur: return Locale(identifier: "ug-Cyrl") // Explicitly Cyrillic Uyghur
        }
    }
    
    var layoutDirection: LayoutDirection {
        // Explicitly set all languages to LTR
        return .leftToRight
    }
}

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @AppStorage("selectedLanguage") private var selectedLanguageRaw: String = AppLanguage.english.rawValue
    @Published var currentLanguage: AppLanguage
    
    private init() {
        // Read directly from UserDefaults to avoid using self before initialization
        let storedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? AppLanguage.english.rawValue
        self.currentLanguage = AppLanguage(rawValue: storedLanguage) ?? .english
        
        // Apply the language after initialization
        applyLanguage(currentLanguage)
    }
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        selectedLanguageRaw = language.rawValue
        applyLanguage(language)
        
        // Notify the app to refresh
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    private func applyLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Update bundle for immediate effect
        Bundle.setLanguage(language.rawValue)
    }
    
    func resetToSystemLanguage() {
        // Clear the language preference
        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        currentLanguage = .english
        selectedLanguageRaw = AppLanguage.english.rawValue
    }
}

// MARK: - Bundle Extension for Language Switching
private var bundleKey: UInt8 = 0

extension Bundle {
    class func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, AnyLanguageBundle.self)
        }
        objc_setAssociatedObject(Bundle.main, &bundleKey, Bundle(path: Bundle.main.path(forResource: language, ofType: "lproj") ?? Bundle.main.bundlePath), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    static var currentLanguageBundle: Bundle? {
        return objc_getAssociatedObject(Bundle.main, &bundleKey) as? Bundle
    }
}

private class AnyLanguageBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = Bundle.currentLanguageBundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}

// MARK: - String Extension for Localization
extension String {
    var localized: String {
        if let bundle = Bundle.currentLanguageBundle {
            return NSLocalizedString(self, bundle: bundle, comment: "")
        }
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        let localizedString = self.localized
        return String(format: localizedString, arguments: arguments)
    }
} 
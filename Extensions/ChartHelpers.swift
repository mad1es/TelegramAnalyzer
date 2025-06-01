import Foundation
import SwiftUI

// MARK: - Date Formatting Helpers
func formatMonthForChart(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    formatter.locale = LocalizationManager.shared.currentLanguage.locale
    return formatter.string(from: date)
} 
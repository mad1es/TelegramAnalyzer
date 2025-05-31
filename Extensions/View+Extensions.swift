import SwiftUI

extension View {
    func sectionHeader() -> some View {
        self
            .font(.headline)
            .foregroundColor(.blue)
            .padding(.vertical, 8)
    }
    
    func dataBlock() -> some View {
        self
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.1)))
            .padding(.horizontal)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Helper method for time formatting  
    func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }
}

// MARK: - Global Color Management

/// Обеспечивает консистентные цвета для пользователей во всем приложении
func colorForUser(_ username: String) -> Color {
    // Нормализуем имя пользователя (убираем пробелы, приводим к нижнему регистру)
    let normalizedName = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Фиксированные цвета для конкретных пользователей
    switch normalizedName {
    case "madie", "мади", "мэди":
        return .pink
    case "roxa", "рокса", "рокс":
        return .blue
    default:
        // Для других пользователей используем хеш-функцию для консистентности
        let hash = abs(normalizedName.hashValue)
        let colors: [Color] = [.green, .orange, .purple, .red, .indigo, .mint, .teal]
        return colors[hash % colors.count]
    }
}

/// Создает массив цветов для SwiftUI Charts в том же порядке что и senders
func chartColorsArray(for senders: [String]) -> [Color] {
    return senders.map { colorForUser($0) }
}

/// Создает KeyValuePairs цветов для SwiftUI Charts
func chartColorPairs(for senders: [String]) -> KeyValuePairs<String, Color> {
    switch senders.count {
    case 1:
        return [senders[0]: colorForUser(senders[0])]
    case 2:
        return [senders[0]: colorForUser(senders[0]), senders[1]: colorForUser(senders[1])]
    default:
        // Fallback для более чем 2 пользователей
        return [senders[0]: colorForUser(senders[0]), senders[1]: colorForUser(senders[1])]
    }
} 
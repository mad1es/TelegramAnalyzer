import Foundation

struct Message: Identifiable, Codable {
    let id: Int
    let type: String
    let date: Date
    let date_unixtime: String
    let from: String
    let from_id: String
    let text: String
    
    var sender: String { from }
    
    var wordCount: Int {
        text.split(separator: " ").count
    }
    
    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isSystemMessage: Bool {
        type == "service" || from == "System"
    }
} 
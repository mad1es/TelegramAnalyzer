import SwiftUI
import UniformTypeIdentifiers

// MARK: - Telegram Chat Data Models
struct TelegramChat: Codable {
    let name: String
    let type: String
    let id: Int
    let messages: [TelegramMessage]
}

struct TelegramMessage: Codable {
    let id: Int
    let type: String
    let date: String
    let date_unixtime: String
    var from: String
    var from_id: String
    var text: String
    let text_entities: [TextEntity]?
    
    enum CodingKeys: String, CodingKey {
        case id, type, date, date_unixtime, from, from_id, text, text_entities
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        date = try container.decode(String.self, forKey: .date)
        date_unixtime = try container.decode(String.self, forKey: .date_unixtime)
        
        // В некоторых типах сообщений может отсутствовать отправитель
        from = try container.decodeIfPresent(String.self, forKey: .from) ?? "System"
        from_id = try container.decodeIfPresent(String.self, forKey: .from_id) ?? "0"
        
        text_entities = try container.decodeIfPresent([TextEntity].self, forKey: .text_entities)
        
        // Handle both string and array text formats
        if let textString = try? container.decode(String.self, forKey: .text) {
            text = textString
        } else if let textArray = try? container.decode([String: String].self, forKey: .text) {
            // If it's a dictionary, use a default or combine values
            text = textArray.values.joined()
        } else if let textEntities = text_entities, !textEntities.isEmpty {
            // If we have text entities, use those instead
            text = textEntities.map { $0.text }.joined()
        } else {
            // Default empty text if we can't decode it any other way
            text = ""
        }
    }
}

struct TextEntity: Codable {
    let type: String
    let text: String
}

// MARK: - DocumentPicker: Выбор JSON файла
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var chats: [Chat]
    @Environment(\.presentationMode) var presentationMode
    @State private var errorMessage: String?
    @State private var showError = false
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                
                // Custom date formatter for Telegram date format
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                
                // Parse the Telegram chat JSON
                let telegramChat = try decoder.decode(TelegramChat.self, from: data)
                
                // Validate chat data
                guard !telegramChat.messages.isEmpty else {
                    throw NSError(domain: "ChatImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Chat contains no messages"])
                }
                
                // Convert TelegramChat to our Chat model
                let parsedMessages = telegramChat.messages.compactMap { telegramMessage -> Message? in
                    // Skip empty messages
                    guard !telegramMessage.text.isEmpty else { return nil }
                    
                    // Parse date
                    let date: Date
                    if let unixTime = Double(telegramMessage.date_unixtime) {
                        date = Date(timeIntervalSince1970: unixTime)
                    } else if let parsedDate = dateFormatter.date(from: telegramMessage.date) {
                        date = parsedDate
                    } else {
                        // Try alternative date formats
                        let alternativeFormatter = DateFormatter()
                        alternativeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        guard let altDate = alternativeFormatter.date(from: telegramMessage.date) else {
                            return nil // Skip messages with invalid dates
                        }
                        date = altDate
                    }
                    
                    return Message(
                        id: telegramMessage.id,
                        type: telegramMessage.type,
                        date: date,
                        date_unixtime: telegramMessage.date_unixtime,
                        from: telegramMessage.from,
                        from_id: telegramMessage.from_id,
                        text: telegramMessage.text
                    )
                }
                
                // Validate parsed messages
                guard !parsedMessages.isEmpty else {
                    throw NSError(domain: "ChatImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "No valid messages found in chat"])
                }
                
                let chat = Chat(
                    id: telegramChat.id,
                    name: telegramChat.name,
                    type: telegramChat.type,
                    messages: parsedMessages
                )
                
                // Add the new chat to the list
                DispatchQueue.main.async {
                    self.parent.chats.append(chat)
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Error reading JSON file: \(error)")
                DispatchQueue.main.async {
                    self.parent.errorMessage = error.localizedDescription
                    self.parent.showError = true
                }
            }
        }
    }
} 
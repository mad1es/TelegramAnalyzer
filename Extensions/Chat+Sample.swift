import Foundation

extension Chat {
    static var sampleChat: Chat {
        let calendar = Calendar.current
        let today = Date()
        
        let dates = [
            calendar.date(byAdding: .day, value: -60, to: today)!,
            calendar.date(byAdding: .day, value: -45, to: today)!,
            calendar.date(byAdding: .day, value: -30, to: today)!,
            calendar.date(byAdding: .day, value: -15, to: today)!,
            calendar.date(byAdding: .day, value: -7, to: today)!,
            calendar.date(byAdding: .day, value: -3, to: today)!,
            calendar.date(byAdding: .day, value: -1, to: today)!
        ]
        
        var messages: [Message] = []
        var id = 1
        
        for date in dates {
            messages.append(Message(
                id: id,
                type: "message",
                date: date,
                date_unixtime: "\(Int(date.timeIntervalSince1970))",
                from: "You",
                from_id: "user1",
                text: "Hello, how are you doing today? I hope everything is going well with your project."
            ))
            id += 1
            
            messages.append(Message(
                id: id,
                type: "message",
                date: date.addingTimeInterval(300),
                date_unixtime: "\(Int(date.timeIntervalSince1970) + 300)",
                from: "Friend",
                from_id: "user2",
                text: "I'm doing great, thanks for asking! The project is coming along nicely. How about yours?"
            ))
            id += 1
        }
        
        return Chat(
            id: 1,
            name: "Sample Chat",
            type: "personal",
            messages: messages
        )
    }
} 

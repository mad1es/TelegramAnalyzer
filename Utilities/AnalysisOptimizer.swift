import Foundation

/// Утилиты для оптимизации анализа чатов
class AnalysisOptimizer {
    
    /// Batch processing для больших наборов данных
    static func processBatches<T, R>(
        items: [T],
        batchSize: Int = 1000,
        processor: ([T]) -> [R]
    ) -> [R] {
        var results: [R] = []
        
        for i in stride(from: 0, to: items.count, by: batchSize) {
            let endIndex = min(i + batchSize, items.count)
            let batch = Array(items[i..<endIndex])
            results.append(contentsOf: processor(batch))
        }
        
        return results
    }
    
    /// Async batch processing для UI responsiveness
    static func processAsyncBatches<T, R>(
        items: [T],
        batchSize: Int = 1000,
        processor: @escaping ([T]) async -> [R]
    ) async -> [R] {
        var results: [R] = []
        
        for i in stride(from: 0, to: items.count, by: batchSize) {
            let endIndex = min(i + batchSize, items.count)
            let batch = Array(items[i..<endIndex])
            let batchResults = await processor(batch)
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
    
    /// Оптимизированный подсчет слов для больших текстов
    static func optimizedWordCount(text: String) -> Int {
        // Используем более быстрый алгоритм
        return text.lazy
            .split(separator: " ")
            .count
    }
    
    /// Оптимизированная фильтрация сообщений по отправителю
    static func fastFilterMessages(messages: [Message], by sender: String) -> [Message] {
        // Используем lazy evaluation для оптимизации
        return messages.lazy
            .filter { $0.sender == sender }
            .map { $0 }
    }
    
    /// Предварительная обработка данных для анализа
    static func preprocessMessages(_ messages: [Message]) -> PreprocessedData {
        let sortedMessages = messages.sorted { $0.date < $1.date }
        let senderMap = Dictionary(grouping: messages, by: { $0.sender })
        
        return PreprocessedData(
            sortedMessages: sortedMessages,
            senderGroups: senderMap,
            totalWords: messages.reduce(0) { $0 + $1.wordCount },
            dateRange: (messages.first?.date, messages.last?.date)
        )
    }
}

/// Предварительно обработанные данные для оптимизации анализа
struct PreprocessedData {
    let sortedMessages: [Message]
    let senderGroups: [String: [Message]]
    let totalWords: Int
    let dateRange: (start: Date?, end: Date?)
}

/// Memory-efficient итератор для больших чатов
struct MessageIterator: IteratorProtocol {
    private let messages: [Message]
    private var currentIndex = 0
    
    init(messages: [Message]) {
        self.messages = messages
    }
    
    mutating func next() -> Message? {
        guard currentIndex < messages.count else { return nil }
        let message = messages[currentIndex]
        currentIndex += 1
        return message
    }
}

/// Lazy sequence для memory-efficient обработки
struct LazyMessageProcessor: Sequence {
    let messages: [Message]
    
    func makeIterator() -> MessageIterator {
        return MessageIterator(messages: messages)
    }
}

/// Performance monitoring утилита
class PerformanceMonitor {
    private static var timers: [String: Date] = [:]
    
    static func startTimer(for operation: String) {
        timers[operation] = Date()
    }
    
    static func endTimer(for operation: String) -> TimeInterval? {
        guard let startTime = timers[operation] else { return nil }
        let duration = Date().timeIntervalSince(startTime)
        timers.removeValue(forKey: operation)
        print("⏱️ \(operation) took \(String(format: "%.2f", duration))s")
        return duration
    }
    
    static func measureTime<T>(operation: String, block: () throws -> T) rethrows -> T {
        startTimer(for: operation)
        defer { endTimer(for: operation) }
        return try block()
    }
    
    static func measureAsyncTime<T>(operation: String, block: () async throws -> T) async rethrows -> T {
        startTimer(for: operation)
        defer { endTimer(for: operation) }
        return try await block()
    }
} 
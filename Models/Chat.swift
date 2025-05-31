import Foundation

// MARK: - Analysis Cache Manager
class AnalysisCache {
    private var cache: [String: Any] = [:]
    private let queue = DispatchQueue(label: "analysis.cache", attributes: .concurrent)
    
    func getCachedResult<T>(for key: String, compute: () -> T) -> T {
        return queue.sync {
            if let cached = cache[key] as? T {
                return cached
            }
            let result = compute()
            queue.async(flags: .barrier) {
                self.cache[key] = result
            }
            return result
        }
    }
    
    func clearCache() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}

struct Chat: Identifiable, Codable {
    let id: Int
    let name: String
    let type: String
    let messages: [Message]
    
    // MARK: - Analysis Cache
    private static let analysisCache = AnalysisCache()
    
    private var cacheKey: String {
        return "chat_\(id)"
    }
    
    // MARK: - Basic Statistics
    
    var totalMessages: Int {
        messages.count
    }
    
    var totalWords: Int {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_totalWords") {
            messages.reduce(0) { $0 + $1.wordCount }
        }
    }
    
    var averageMessageLength: Double {
        guard !messages.isEmpty else { return 0 }
        return Double(totalWords) / Double(totalMessages)
    }
    
    // MARK: - Time Analysis
    
    var firstMessageDate: Date? {
        messages.first?.date
    }
    
    var lastMessageDate: Date? {
        messages.last?.date
    }
    
    var duration: TimeInterval? {
        guard let first = firstMessageDate, let last = lastMessageDate else { return nil }
        return last.timeIntervalSince(first)
    }
    
    // MARK: - Message Analysis
    
    func messages(from sender: String) -> [Message] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_messages_\(sender)") {
            messages.filter { $0.sender == sender }
        }
    }
    
    func messages(in dateRange: ClosedRange<Date>) -> [Message] {
        messages.filter { dateRange.contains($0.date) }
    }
    
    func messages(in hour: Int) -> [Message] {
        let calendar = Calendar.current
        return messages.filter { calendar.component(.hour, from: $0.date) == hour }
    }
    
    // MARK: - Advanced Analysis
    
    // Анализ активности по времени суток
    func hourlyActivity(for sender: String) -> [Int: Int] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_hourlyActivity_\(sender)") {
            var activity: [Int: Int] = [:]
            let calendar = Calendar.current
            
            for message in messages(from: sender) {
                let hour = calendar.component(.hour, from: message.date)
                activity[hour, default: 0] += 1
            }
            
            return activity
        }
    }
    
    // Анализ длины сообщений
    func messageLengthStats(for sender: String) -> (min: Int, max: Int, average: Double) {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_messageLengthStats_\(sender)") {
            let lengths = messages(from: sender).map { $0.wordCount }
            guard !lengths.isEmpty else { return (0, 0, 0) }
            
            return (
                min: lengths.min() ?? 0,
                max: lengths.max() ?? 0,
                average: Double(lengths.reduce(0, +)) / Double(lengths.count)
            )
        }
    }
    
    // Анализ времени ответа
    func responseTimeAnalysis() -> [(sender: String, average: TimeInterval, min: TimeInterval, max: TimeInterval)] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_responseTimeAnalysis") {
            var responseTimes: [String: [TimeInterval]] = [:]
            let sortedMessages = messages.sorted { $0.date < $1.date }
            
            for i in 1..<sortedMessages.count {
                let currentMessage = sortedMessages[i]
                let previousMessage = sortedMessages[i-1]
                
                if currentMessage.sender != previousMessage.sender {
                    let timeInterval = currentMessage.date.timeIntervalSince(previousMessage.date)
                    responseTimes[currentMessage.sender, default: []].append(timeInterval)
                }
            }
            
            return responseTimes.map { sender, times in
                (
                    sender: sender,
                    average: times.reduce(0, +) / Double(times.count),
                    min: times.min() ?? 0,
                    max: times.max() ?? 0
                )
            }
        }
    }
    
    // Анализ инициации разговора
    func conversationInitiationAnalysis() -> [(sender: String, count: Int, percentage: Double)] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_conversationInitiationAnalysis") {
            var initiations: [String: Int] = [:]
            let sortedMessages = messages.sorted { $0.date < $1.date }
            
            // Определяем инициацию разговора как первое сообщение после паузы более 2 часов
            let twoHours: TimeInterval = 2 * 60 * 60
            
            for i in 1..<sortedMessages.count {
                let currentMessage = sortedMessages[i]
                let previousMessage = sortedMessages[i-1]
                
                if currentMessage.date.timeIntervalSince(previousMessage.date) > twoHours {
                    initiations[currentMessage.sender, default: 0] += 1
                }
            }
            
            let total = initiations.values.reduce(0, +)
            
            return initiations.map { sender, count in
                (
                    sender: sender,
                    count: count,
                    percentage: total > 0 ? Double(count) / Double(total) * 100 : 0
                )
            }
        }
    }
    
    // Анализ "ghosting" (отсутствие ответа)
    func ghostingAnalysis() -> [(sender: String, count: Int, totalTime: TimeInterval)] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_ghostingAnalysis") {
            var ghosting: [String: (count: Int, totalTime: TimeInterval)] = [:]
            let sortedMessages = messages.sorted { $0.date < $1.date }
            
            // Считаем ghosting как отсутствие ответа более 24 часов
            let oneDay: TimeInterval = 24 * 60 * 60
            
            for i in 1..<sortedMessages.count {
                let currentMessage = sortedMessages[i]
                let previousMessage = sortedMessages[i-1]
                
                if currentMessage.sender != previousMessage.sender {
                    let timeInterval = currentMessage.date.timeIntervalSince(previousMessage.date)
                    if timeInterval > oneDay {
                        ghosting[previousMessage.sender, default: (0, 0)].count += 1
                        ghosting[previousMessage.sender, default: (0, 0)].totalTime += timeInterval
                    }
                }
            }
            
            return ghosting.map { sender, data in
                (sender: sender, count: data.count, totalTime: data.totalTime)
            }
        }
    }
    
    // Анализ активности по дням недели
    func weekdayActivity() -> [Int: Int] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_weekdayActivity") {
            var activity: [Int: Int] = [:]
            let calendar = Calendar.current
            
            for message in messages {
                let weekday = calendar.component(.weekday, from: message.date)
                activity[weekday, default: 0] += 1
            }
            
            return activity
        }
    }
    
    // Анализ эмодзи и стикеров
    func emojiAnalysis() -> [(emoji: String, count: Int)] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_emojiAnalysis") {
            var emojiCount: [String: Int] = [:]
            
            for message in messages {
                message.text.enumerateSubstrings(in: message.text.startIndex..<message.text.endIndex, 
                                               options: [.byComposedCharacterSequences]) { substring, _, _, _ in
                    guard let substring = substring else { return }
                    
                    // Проверяем, содержит ли подстрока эмодзи
                    let containsEmoji = substring.unicodeScalars.contains { scalar in
                        scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
                    }
                    
                    // Дополнительная проверка для эмодзи с текстовым представлением
                    let isEmojiSequence = substring.unicodeScalars.count > 1 && 
                                        substring.unicodeScalars.contains { $0.properties.isEmoji }
                    
                    if containsEmoji || isEmojiSequence {
                        // Исключаем простые цифры без эмодзи-селекторов
                        if substring.count == 1 && substring.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil {
                            return // Пропускаем простые цифры
                        }
                        
                        emojiCount[substring, default: 0] += 1
                    }
                    
                    return
                }
            }
            
            return emojiCount.map { (emoji: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
        }
    }
    
    // Группировка сообщений по месяцам для оси X графиков
    var monthBuckets: [Date] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_monthBuckets") {
            let calendar = Calendar.current
            let months = Set(messages.compactMap {
                calendar.date(from: calendar.dateComponents([.year, .month], from: $0.date))
            })
            return Array(months).sorted()
        }
    }
    
    // Уникальные отправители
    var senders: [String] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_senders") {
            Array(Set(messages.map { $0.sender })).sorted()
        }
    }
    
    // Calculate response times between messages
    func calculateResponseTimes() -> [(Message, TimeInterval)] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_calculateResponseTimes") {
            var responseTimes: [(Message, TimeInterval)] = []
            let sortedMessages = messages.sorted { $0.date < $1.date }
            
            for i in 1..<sortedMessages.count {
                let currentMessage = sortedMessages[i]
                let previousMessage = sortedMessages[i-1]
                
                // Only calculate response time if messages are from different senders
                if currentMessage.sender != previousMessage.sender {
                    let timeInterval = currentMessage.date.timeIntervalSince(previousMessage.date)
                    responseTimes.append((currentMessage, timeInterval))
                }
            }
            
            return responseTimes
        }
    }
    
    // Get average response time for a specific sender
    func averageResponseTime(for sender: String) -> TimeInterval {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_averageResponseTime_\(sender)") {
            let responseTimes = calculateResponseTimes()
            let senderResponses = responseTimes.filter { $0.0.sender == sender }
            
            guard !senderResponses.isEmpty else { return 0 }
            
            let totalTime = senderResponses.reduce(0) { $0 + $1.1 }
            return totalTime / Double(senderResponses.count)
        }
    }
    
    // Get response time statistics
    func responseTimeStats() -> (min: TimeInterval, max: TimeInterval, average: TimeInterval) {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_responseTimeStats") {
            let responseTimes = calculateResponseTimes()
            guard !responseTimes.isEmpty else { return (0, 0, 0) }
            
            let times = responseTimes.map { $0.1 }
            return (
                min: times.min() ?? 0,
                max: times.max() ?? 0,
                average: times.reduce(0, +) / Double(times.count)
            )
        }
    }
    
    // MARK: - Enhanced Analysis Methods
    
    // 1. Enhanced Word Count Over Time Analysis
    func wordCountByMonth(for sender: String? = nil) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        var monthlyWords: [Date: Int] = [:]
        
        let messagesToAnalyze = sender != nil ? messages(from: sender!) : messages
        
        for message in messagesToAnalyze {
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: message.date)) else { continue }
            monthlyWords[monthStart, default: 0] += message.wordCount
        }
        
        return monthlyWords.map { (date: $0.key, count: $0.value) }.sorted { $0.date < $1.date }
    }
    
    func wordsPerDay(for sender: String) -> Double {
        guard let first = firstMessageDate, let last = lastMessageDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: first, to: last).day ?? 1
        let totalWords = messages(from: sender).reduce(0) { $0 + $1.wordCount }
        return Double(totalWords) / Double(max(days, 1))
    }
    
    // 2. Enhanced Message Length Analysis
    func maxMessageLengthByMonth(for sender: String) -> [(date: Date, maxLength: Int)] {
        let calendar = Calendar.current
        var monthlyMaxLength: [Date: Int] = [:]
        
        for message in messages(from: sender) {
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: message.date)) else { continue }
            let currentMax = monthlyMaxLength[monthStart] ?? 0
            monthlyMaxLength[monthStart] = max(currentMax, message.wordCount)
        }
        
        return monthlyMaxLength.map { (date: $0.key, maxLength: $0.value) }.sorted { $0.date < $1.date }
    }
    
    func top10LongestMessages(for sender: String) -> [Message] {
        return messages(from: sender)
            .sorted { $0.wordCount > $1.wordCount }
            .prefix(10)
            .map { $0 }
    }
    
    func averageTop10MessageLength(for sender: String) -> Double {
        let top10 = top10LongestMessages(for: sender)
        guard !top10.isEmpty else { return 0 }
        return Double(top10.reduce(0) { $0 + $1.wordCount }) / Double(top10.count)
    }
    
    // 3. Enhanced Ghosting Analysis (3+ hours within same day)
    func enhancedGhostingAnalysis() -> [(sender: String, ghostingEvents: [(date: Date, duration: TimeInterval)])] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_enhancedGhostingAnalysis") {
            var ghostingBySender: [String: [(date: Date, duration: TimeInterval)]] = [:]
            let sortedMessages = messages.sorted { $0.date < $1.date }
            let calendar = Calendar.current
            let threeHours: TimeInterval = 3 * 60 * 60
            
            for i in 1..<sortedMessages.count {
                let currentMessage = sortedMessages[i]
                let previousMessage = sortedMessages[i-1]
                
                if currentMessage.sender != previousMessage.sender {
                    let timeInterval = currentMessage.date.timeIntervalSince(previousMessage.date)
                    
                    // Check if both messages are on the same day and gap is more than 3 hours
                    if timeInterval > threeHours && 
                       calendar.isDate(currentMessage.date, inSameDayAs: previousMessage.date) {
                        ghostingBySender[previousMessage.sender, default: []].append((
                            date: previousMessage.date,
                            duration: timeInterval
                        ))
                    }
                }
            }
            
            return ghostingBySender.map { (sender: $0.key, ghostingEvents: $0.value) }
        }
    }
    
    func ghostingByMonth() -> [(date: Date, sender: String, count: Int)] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_ghostingByMonth") {
            let calendar = Calendar.current
            var monthlyGhosting: [Date: [String: Int]] = [:]
            
            for ghostingData in enhancedGhostingAnalysis() {
                for event in ghostingData.ghostingEvents {
                    guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: event.date)) else { continue }
                    monthlyGhosting[monthStart, default: [:]][ghostingData.sender, default: 0] += 1
                }
            }
            
            var result: [(date: Date, sender: String, count: Int)] = []
            for (date, senderCounts) in monthlyGhosting {
                for (sender, count) in senderCounts {
                    result.append((date: date, sender: sender, count: count))
                }
            }
            
            return result.sorted { $0.date < $1.date }
        }
    }
    
    func topGhoster() -> (sender: String, totalEvents: Int, totalTime: TimeInterval)? {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_topGhoster") {
            let ghostingData = enhancedGhostingAnalysis()
            guard !ghostingData.isEmpty else { return nil }
            
            let totals = ghostingData.map { data in
                (
                    sender: data.sender,
                    totalEvents: data.ghostingEvents.count,
                    totalTime: data.ghostingEvents.reduce(0) { $0 + $1.duration }
                )
            }
            
            return totals.max { $0.totalEvents < $1.totalEvents }
        }
    }
    
    // 4. Enhanced Conversation Initiation (6+ hours gap)
    func enhancedConversationInitiation() -> [(sender: String, initiationsByMonth: [(date: Date, count: Int)])] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_enhancedConversationInitiation") {
            let calendar = Calendar.current
            var initiationsBySender: [String: [Date: Int]] = [:]
            let sortedMessages = messages.sorted { $0.date < $1.date }
            let sixHours: TimeInterval = 6 * 60 * 60
            
            for i in 1..<sortedMessages.count {
                let currentMessage = sortedMessages[i]
                let previousMessage = sortedMessages[i-1]
                
                if currentMessage.date.timeIntervalSince(previousMessage.date) > sixHours {
                    guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMessage.date)) else { continue }
                    initiationsBySender[currentMessage.sender, default: [:]][monthStart, default: 0] += 1
                }
            }
            
            return initiationsBySender.map { (sender, monthlyData) in
                let sortedMonthly = monthlyData.map { (date: $0.key, count: $0.value) }.sorted { $0.date < $1.date }
                return (sender: sender, initiationsByMonth: sortedMonthly)
            }
        }
    }
    
    // 5. Enhanced Response Time Analysis
    func responseTimeByMonth(for sender: String) -> [(date: Date, averageTime: TimeInterval)] {
        let calendar = Calendar.current
        var monthlyResponseTimes: [Date: [TimeInterval]] = [:]
        let responseTimes = calculateResponseTimes()
        
        for (message, responseTime) in responseTimes {
            if message.sender == sender {
                guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: message.date)) else { continue }
                monthlyResponseTimes[monthStart, default: []].append(responseTime)
            }
        }
        
        return monthlyResponseTimes.compactMap { (date, times) in
            guard !times.isEmpty else { return nil }
            let averageTime = times.reduce(0, +) / Double(times.count)
            return (date: date, averageTime: averageTime)
        }.sorted { $0.date < $1.date }
    }
    
    func rapidExchanges(under seconds: TimeInterval = 60) -> [(sender: String, count: Int)] {
        let responseTimes = calculateResponseTimes()
        var rapidCounts: [String: Int] = [:]
        
        for (message, responseTime) in responseTimes {
            if responseTime < seconds {
                rapidCounts[message.sender, default: 0] += 1
            }
        }
        
        return rapidCounts.map { (sender: $0.key, count: $0.value) }
    }
    
    // 6. Double Texting Analysis (1-6 hours without reply)
    func doubleTextingAnalysis() -> [(sender: String, doubleTextsByMonth: [(date: Date, count: Int)])] {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_doubleTextingAnalysis") {
            let calendar = Calendar.current
            var doubleTextsBySender: [String: [Date: Int]] = [:]
            let sortedMessages = messages.sorted { $0.date < $1.date }
            let oneHour: TimeInterval = 60 * 60
            let sixHours: TimeInterval = 6 * 60 * 60
            
            for i in 1..<sortedMessages.count {
                let currentMessage = sortedMessages[i]
                let previousMessage = sortedMessages[i-1]
                
                // Check if same sender and time gap is between 1-6 hours
                if currentMessage.sender == previousMessage.sender {
                    let timeInterval = currentMessage.date.timeIntervalSince(previousMessage.date)
                    if timeInterval >= oneHour && timeInterval <= sixHours {
                        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMessage.date)) else { continue }
                        doubleTextsBySender[currentMessage.sender, default: [:]][monthStart, default: 0] += 1
                    }
                }
            }
            
            return doubleTextsBySender.map { (sender, monthlyData) in
                let sortedMonthly = monthlyData.map { (date: $0.key, count: $0.value) }.sorted { $0.date < $1.date }
                return (sender: sender, doubleTextsByMonth: sortedMonthly)
            }
        }
    }
    
    func dayWithMostDoubleTexts() -> (date: Date, sender: String, count: Int)? {
        let calendar = Calendar.current
        var dailyDoubleTexts: [Date: [String: Int]] = [:]
        let sortedMessages = messages.sorted { $0.date < $1.date }
        let oneHour: TimeInterval = 60 * 60
        let sixHours: TimeInterval = 6 * 60 * 60
        
        for i in 1..<sortedMessages.count {
            let currentMessage = sortedMessages[i]
            let previousMessage = sortedMessages[i-1]
            
            if currentMessage.sender == previousMessage.sender {
                let timeInterval = currentMessage.date.timeIntervalSince(previousMessage.date)
                if timeInterval >= oneHour && timeInterval <= sixHours {
                    guard let dayStart = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: currentMessage.date)) else { continue }
                    dailyDoubleTexts[dayStart, default: [:]][currentMessage.sender, default: 0] += 1
                }
            }
        }
        
        var maxCount = 0
        var maxDate: Date?
        var maxSender: String?
        
        for (date, senderCounts) in dailyDoubleTexts {
            for (sender, count) in senderCounts {
                if count > maxCount {
                    maxCount = count
                    maxDate = date
                    maxSender = sender
                }
            }
        }
        
        guard let date = maxDate, let sender = maxSender else { return nil }
        return (date: date, sender: sender, count: maxCount)
    }
    
    // 7. Most Used Words Analysis
    func mostUsedWords(for sender: String? = nil, limit: Int = 50) -> [(word: String, count: Int)] {
        let fullCacheKey = "\(cacheKey)_mostUsedWords_\(sender ?? "all")_\(limit)"
        return Self.analysisCache.getCachedResult(for: fullCacheKey) {
            let stopwordsEnglish = Set(["the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "can", "a", "an", "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them", "my", "your", "his", "her", "its", "our", "their"])
            
            let stopwordsRussian = Set(["и", "в", "не", "на", "я", "быть", "он", "с", "что", "а", "по", "это", "она", "этот", "к", "но", "они", "мы", "как", "из", "у", "который", "то", "за", "свой", "что", "ее", "так", "же", "все", "себя", "ну", "ты", "от", "мой", "еще", "нет", "о", "из", "его", "да", "их", "для", "или", "же", "бы", "уже", "если", "только", "может", "тут", "там", "этой", "один", "два", "три", "где", "ну", "да", "нет", "вот", "при", "над", "под", "до", "после", "во", "про"])
            
            var wordCount: [String: Int] = [:]
            let messagesToAnalyze = sender != nil ? messages(from: sender!) : messages
            
            for message in messagesToAnalyze {
                let words = message.text.lowercased()
                    .components(separatedBy: .whitespacesAndNewlines)
                    .flatMap { $0.components(separatedBy: .punctuationCharacters) }
                    .filter { !$0.isEmpty && !stopwordsEnglish.contains($0) && !stopwordsRussian.contains($0) }
                
                for word in words {
                    wordCount[word, default: 0] += 1
                }
            }
            
            return wordCount.map { (word: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
                .prefix(limit)
                .map { $0 }
        }
    }
    
    // 8. Enhanced Emoji Analysis
    func enhancedEmojiAnalysis(for sender: String? = nil) -> [(emoji: String, count: Int)] {
        let fullCacheKey = "\(cacheKey)_enhancedEmojiAnalysis_\(sender ?? "all")"
        return Self.analysisCache.getCachedResult(for: fullCacheKey) {
            var emojiCount: [String: Int] = [:]
            let messagesToAnalyze = sender != nil ? messages(from: sender!) : messages
            
            for message in messagesToAnalyze {
                // Используем enumerateSubstrings для правильного извлечения эмодзи
                message.text.enumerateSubstrings(in: message.text.startIndex..<message.text.endIndex, 
                                               options: [.byComposedCharacterSequences]) { substring, _, _, _ in
                    guard let substring = substring else { return }
                    
                    // Проверяем, содержит ли подстрока эмодзи
                    let containsEmoji = substring.unicodeScalars.contains { scalar in
                        scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
                    }
                    
                    // Дополнительная проверка для эмодзи с текстовым представлением
                    let isEmojiSequence = substring.unicodeScalars.count > 1 && 
                                        substring.unicodeScalars.contains { $0.properties.isEmoji }
                    
                    if containsEmoji || isEmojiSequence {
                        // Исключаем простые цифры без эмодзи-селекторов
                        if substring.count == 1 && substring.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil {
                            return // Пропускаем простые цифры
                        }
                        
                        emojiCount[substring, default: 0] += 1
                    }
                    
                    return
                }
            }
            
            return emojiCount.map { (emoji: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
        }
    }
    
    func emojiUsageByMonth(for sender: String) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        var monthlyEmojis: [Date: Int] = [:]
        
        for message in messages(from: sender) {
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: message.date)) else { continue }
            
            var emojiCount = 0
            message.text.enumerateSubstrings(in: message.text.startIndex..<message.text.endIndex, 
                                           options: [.byComposedCharacterSequences]) { substring, _, _, _ in
                guard let substring = substring else { return }
                
                // Проверяем, содержит ли подстрока эмодзи
                let containsEmoji = substring.unicodeScalars.contains { scalar in
                    scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
                }
                
                // Дополнительная проверка для эмодзи с текстовым представлением
                let isEmojiSequence = substring.unicodeScalars.count > 1 && 
                                    substring.unicodeScalars.contains { $0.properties.isEmoji }
                
                if containsEmoji || isEmojiSequence {
                    // Исключаем простые цифры без эмодзи-селекторов
                    if substring.count == 1 && substring.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil {
                        return // Пропускаем простые цифры
                    }
                    
                    emojiCount += 1
                }
                
                return
            }
            
            monthlyEmojis[monthStart, default: 0] += emojiCount
        }
        
        return monthlyEmojis.map { (date: $0.key, count: $0.value) }.sorted { $0.date < $1.date }
    }
    
    // 9. Enhanced Hourly Activity Analysis
    func hourlyActivityPyramid() -> [(hour: Int, sender1Count: Int, sender2Count: Int)] {
        guard senders.count >= 2 else { return [] }
        let sender1 = senders[0]
        let sender2 = senders[1]
        
        var hourlyData: [(hour: Int, sender1Count: Int, sender2Count: Int)] = []
        
        for hour in 0...23 {
            let sender1Count = messages(from: sender1).filter { 
                Calendar.current.component(.hour, from: $0.date) == hour 
            }.count
            
            let sender2Count = messages(from: sender2).filter { 
                Calendar.current.component(.hour, from: $0.date) == hour 
            }.count
            
            hourlyData.append((hour: hour, sender1Count: sender1Count, sender2Count: sender2Count))
        }
        
        return hourlyData
    }
    
    func mostActiveHour(for sender: String) -> (hour: Int, count: Int)? {
        return Self.analysisCache.getCachedResult(for: "\(cacheKey)_mostActiveHour_\(sender)") {
            var hourlyActivity: [Int: Int] = [:]
            
            for message in messages(from: sender) {
                let hour = Calendar.current.component(.hour, from: message.date)
                hourlyActivity[hour, default: 0] += 1
            }
            
            guard let maxHour = hourlyActivity.max(by: { $0.value < $1.value }) else { return nil }
            return (hour: maxHour.key, count: maxHour.value)
        }
    }
} 
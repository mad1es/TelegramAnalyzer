import SwiftUI

struct ChatAnalysisView: View {
    var chat: Chat
    
    // MARK: - Analysis State
    @State private var analysisResults = AnalysisResults()
    @State private var isLoading = true
    @State private var loadingProgress: Double = 0
    
    struct AnalysisResults {
        var totalWords: Int = 0
        var whoTextedLessResult: (String, String) = ("", "0")
        var yourLongestMessage: Int = 0
        var theirLongestMessage: Int = 0
        var ghostingData: [(sender: String, ghostingEvents: [(date: Date, duration: TimeInterval)])] = []
        var initiationData: [(sender: String, initiationsByMonth: [(date: Date, count: Int)])] = []
        var responseTimeStats: (min: TimeInterval, max: TimeInterval, average: TimeInterval) = (0, 0, 0)
        var mostActiveHours: [(sender: String, hour: Int, count: Int)] = []
        var doubleTexts: [(sender: String, doubleTextsByMonth: [(date: Date, count: Int)])] = []
        var mostUsedWords: [(word: String, count: Int)] = []
        var emojiAnalysis: [(emoji: String, count: Int)] = []
    }
    
    enum AnalysisCard: String, CaseIterable, Identifiable {
        case whoTextedMore = "WHO TEXTED MORE"
        case longestMessage = "LONGEST MESSAGE"
        case ghosting = "GHOSTING"
        case conversationInitiation = "CONVERSATION INITIATION"
        case responseTime = "RESPONSE TIME"
        case hourlyActivity = "HOURLY ACTIVITY"
        case doubleTexting = "DOUBLE TEXTING"
        case mostUsedWords = "MOST USED WORDS"
        case emojiUsage = "EMOJI USAGE"
        
        var id: String { self.rawValue }
        
        var systemImage: String {
            switch self {
            case .whoTextedMore: return "text.bubble.fill"
            case .longestMessage: return "arrow.up.right"
            case .ghosting: return "person.fill.questionmark"
            case .conversationInitiation: return "arrow.right.circle.fill"
            case .responseTime: return "clock.fill"
            case .hourlyActivity: return "chart.bar.fill"
            case .doubleTexting: return "message.badge.fill"
            case .mostUsedWords: return "textformat.abc"
            case .emojiUsage: return "face.smiling.fill"
            }
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else {
                analysisContentView
            }
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "eye")
                        .font(.system(size: 18))
                }
            }
        }
        .task {
            await loadAnalysisResults()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView("Analyzing chat data...", value: loadingProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(maxWidth: 200)
            
            Text("Processing \(chat.totalMessages) messages")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var analysisContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    Text("Summary")
                        .font(.system(size: 36, weight: .bold))
                        .padding(.top, 10)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Analysis Cards
                VStack(spacing: 16) {
                    // Who texted more card
                    NavigationLink(destination: DetailView(chat: chat, card: .whoTextedMore)) {
                        AnalysisCardView(
                            title: AnalysisCard.whoTextedMore.rawValue,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("This chat is")
                                        .font(.subheadline)
                                    
                                    Text("\(analysisResults.totalWords) words")
                                        .font(.system(size: 32, weight: .bold))
                                    
                                    Text("\(analysisResults.whoTextedLessResult.0) texted less")
                                        .font(.subheadline)
                                    
                                    Text("by \(analysisResults.whoTextedLessResult.1)%")
                                        .font(.system(size: 32, weight: .bold))
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Longest message card
                    NavigationLink(destination: DetailView(chat: chat, card: .longestMessage)) {
                        AnalysisCardView(
                            title: AnalysisCard.longestMessage.rawValue,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Your longest message")
                                        .font(.subheadline)
                                    
                                    Text("\(analysisResults.yourLongestMessage) words")
                                        .font(.system(size: 32, weight: .bold))
                                    
                                    Text("\(otherPersonName())'s longest message")
                                        .font(.subheadline)
                                    
                                    Text("\(analysisResults.theirLongestMessage) words")
                                        .font(.system(size: 32, weight: .bold))
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Ghosting card
                    NavigationLink(destination: DetailView(chat: chat, card: .ghosting)) {
                        AnalysisCardView(
                            title: AnalysisCard.ghosting.rawValue,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let you = analysisResults.ghostingData.first {
                                        Text("You 'ghosted'")
                                            .font(.subheadline)
                                        
                                        Text("\(you.ghostingEvents.count) times")
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                    
                                    if analysisResults.ghostingData.count > 1 {
                                        Text("\(otherPersonName()) 'ghosted' you")
                                            .font(.subheadline)
                                        
                                        Text("\(analysisResults.ghostingData[1].ghostingEvents.count) times")
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                }
                            },
                            chart: {
                                HStack {
                                    Spacer()
                                        .frame(width: 120, height: 100)
                                        .padding(.trailing)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Conversation Initiation card
                    NavigationLink(destination: DetailView(chat: chat, card: .conversationInitiation)) {
                        AnalysisCardView(
                            title: AnalysisCard.conversationInitiation.rawValue,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let you = analysisResults.initiationData.first {
                                        let yourTotal = you.initiationsByMonth.reduce(0) { $0 + $1.count }
                                        Text("You initiated")
                                            .font(.subheadline)
                                        
                                        Text("\(yourTotal) times")
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                    
                                    if analysisResults.initiationData.count > 1 {
                                        let theirTotal = analysisResults.initiationData[1].initiationsByMonth.reduce(0) { $0 + $1.count }
                                        Text("\(otherPersonName()) initiated")
                                            .font(.subheadline)
                                        
                                        Text("\(theirTotal) times")
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                }
                            },
                            chart: {
                                HStack {
                                    Spacer()
                                        .frame(width: 120, height: 100)
                                        .padding(.trailing)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Response Time card
                    NavigationLink(destination: DetailView(chat: chat, card: .responseTime)) {
                        AnalysisCardView(
                            title: AnalysisCard.responseTime.rawValue,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Average response time")
                                        .font(.subheadline)
                                    
                                    Text(formatTime(analysisResults.responseTimeStats.average))
                                        .font(.system(size: 32, weight: .bold))
                                    
                                    Text("Fastest response")
                                        .font(.subheadline)
                                    
                                    Text(formatTime(analysisResults.responseTimeStats.min))
                                        .font(.system(size: 24, weight: .bold))
                                }
                            },
                            chart: {
                                HStack {
                                    Spacer()
                                        .frame(width: 120, height: 100)
                                        .padding(.trailing)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Hourly Activity card
                    NavigationLink(destination: DetailView(chat: chat, card: .hourlyActivity)) {
                        AnalysisCardView(
                            title: AnalysisCard.hourlyActivity.rawValue,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let yourActive = analysisResults.mostActiveHours.first {
                                        Text("Your most active hour")
                                            .font(.subheadline)
                                        
                                        Text(String(format: "%02d:00", yourActive.hour))
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                    
                                    if analysisResults.mostActiveHours.count > 1 {
                                        Text("\(otherPersonName())'s most active hour")
                                            .font(.subheadline)
                                        
                                        Text(String(format: "%02d:00", analysisResults.mostActiveHours[1].hour))
                                            .font(.system(size: 24, weight: .bold))
                                    }
                                }
                            },
                            chart: {
                                HStack {
                                    Spacer()
                                        .frame(width: 120, height: 100)
                                        .padding(.trailing)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Double Texting card
                    NavigationLink(destination: DetailView(chat: chat, card: .doubleTexting)) {
                        AnalysisCardView(
                            title: AnalysisCard.doubleTexting.rawValue,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let you = analysisResults.doubleTexts.first {
                                        let yourTotal = you.doubleTextsByMonth.reduce(0) { $0 + $1.count }
                                        Text("You double texted")
                                            .font(.subheadline)
                                        
                                        Text("\(yourTotal) times")
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                    
                                    if analysisResults.doubleTexts.count > 1 {
                                        let theirTotal = analysisResults.doubleTexts[1].doubleTextsByMonth.reduce(0) { $0 + $1.count }
                                        Text("\(otherPersonName()) double texted")
                                            .font(.subheadline)
                                        
                                        Text("\(theirTotal) times")
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                }
                            },
                            chart: {
                                HStack {
                                    Spacer()
                                        .frame(width: 120, height: 100)
                                        .padding(.trailing)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Most Used Words card
                    NavigationLink(destination: DetailView(chat: chat, card: .mostUsedWords)) {
                        AnalysisCardView(
                            title: AnalysisCard.mostUsedWords.rawValue,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let topWord = analysisResults.mostUsedWords.first {
                                        Text("Most used word")
                                            .font(.subheadline)
                                        
                                        Text("\"\(topWord.word)\"")
                                            .font(.system(size: 24, weight: .bold))
                                        
                                        Text("Used \(topWord.count) times")
                                            .font(.subheadline)
                                        
                                        Text("\(analysisResults.mostUsedWords.count) unique words")
                                            .font(.system(size: 20, weight: .bold))
                                    }
                                }
                            },
                            chart: {
                                HStack {
                                    Spacer()
                                        .frame(width: 120, height: 100)
                                        .padding(.trailing)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Emoji Usage card
                    NavigationLink(destination: DetailView(chat: chat, card: .emojiUsage)) {
                        AnalysisCardView(
                            title: AnalysisCard.emojiUsage.rawValue,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    let totalEmojis = analysisResults.emojiAnalysis.reduce(0) { $0 + $1.count }
                                    
                                    if let topEmoji = analysisResults.emojiAnalysis.first {
                                        Text("Most used emoji")
                                            .font(.subheadline)
                                        
                                        Text(topEmoji.emoji)
                                            .font(.system(size: 40))
                                        
                                        Text("Used \(topEmoji.count) times")
                                            .font(.subheadline)
                                    }
                                    
                                    Text("\(totalEmojis) total emojis")
                                        .font(.system(size: 20, weight: .bold))
                                }
                            },
                            chart: {
                                HStack {
                                    Spacer()
                                    // Show top 3 emojis
                                    VStack(spacing: 4) {
                                        ForEach(Array(analysisResults.emojiAnalysis.prefix(3).enumerated()), id: \.element.emoji) { index, emoji in
                                            Text(emoji.emoji)
                                                .font(.system(size: 20))
                                        }
                                    }
                                    .frame(width: 120, height: 100)
                                    .padding(.trailing)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Async Analysis Loading
    
    private func loadAnalysisResults() async {
        await PerformanceMonitor.measureAsyncTime(operation: "Total Analysis Loading") {
            // Предварительная обработка данных один раз
            let preprocessedData = AnalysisOptimizer.preprocessMessages(chat.messages)
            
            await withTaskGroup(of: Void.self) { group in
                var mutableChat = chat
                
                // Load basic stats - самые быстрые операции первыми
                group.addTask {
                    await PerformanceMonitor.measureAsyncTime(operation: "Basic Stats") {
                        await MainActor.run {
                            analysisResults.totalWords = preprocessedData.totalWords
                            loadingProgress = 0.1
                        }
                    }
                }
                
                // Load who texted less - используем предобработанные данные
                group.addTask {
                    let result = await PerformanceMonitor.measureAsyncTime(operation: "Who Texted Less") {
                        return await Task.detached {
                            return whoTextedLess(mutableChat, preprocessedData: preprocessedData)
                        }.value
                    }
                    await MainActor.run {
                        analysisResults.whoTextedLessResult = result
                        loadingProgress = 0.2
                    }
                }
                
                // Load longest messages - batch processing
                group.addTask {
                    let (yours, theirs) = await PerformanceMonitor.measureAsyncTime(operation: "Longest Messages") {
                        return await Task.detached {
                            return (
                                yourLongestMessage(mutableChat, preprocessedData: preprocessedData),
                                theirLongestMessage(mutableChat, preprocessedData: preprocessedData)
                            )
                        }.value
                    }
                    await MainActor.run {
                        analysisResults.yourLongestMessage = yours
                        analysisResults.theirLongestMessage = theirs
                        loadingProgress = 0.3
                    }
                }
                
                // Load ghosting analysis - async processing
                group.addTask {
                    let result = await PerformanceMonitor.measureAsyncTime(operation: "Ghosting Analysis") {
                        return await Task.detached {
                            return mutableChat.enhancedGhostingAnalysis()
                        }.value
                    }
                    await MainActor.run {
                        analysisResults.ghostingData = result
                        loadingProgress = 0.4
                    }
                }
                
                // Load conversation initiation
                group.addTask {
                    let result = await PerformanceMonitor.measureAsyncTime(operation: "Conversation Initiation") {
                        return await Task.detached {
                            return mutableChat.enhancedConversationInitiation()
                        }.value
                    }
                    await MainActor.run {
                        analysisResults.initiationData = result
                        loadingProgress = 0.5
                    }
                }
                
                // Load response time stats
                group.addTask {
                    let result = await PerformanceMonitor.measureAsyncTime(operation: "Response Time Stats") {
                        return await Task.detached {
                            return mutableChat.responseTimeStats()
                        }.value
                    }
                    await MainActor.run {
                        analysisResults.responseTimeStats = result
                        loadingProgress = 0.6
                    }
                }
                
                // Load most active hours - optimized
                group.addTask {
                    let result = await PerformanceMonitor.measureAsyncTime(operation: "Most Active Hours") {
                        return await Task.detached {
                            var hours: [(sender: String, hour: Int, count: Int)] = []
                            for sender in mutableChat.senders {
                                if let activeHour = mutableChat.mostActiveHour(for: sender) {
                                    hours.append((sender: sender, hour: activeHour.hour, count: activeHour.count))
                                }
                            }
                            return hours
                        }.value
                    }
                    await MainActor.run {
                        analysisResults.mostActiveHours = result
                        loadingProgress = 0.7
                    }
                }
                
                // Load double texting - batch processing
                group.addTask {
                    let result = await PerformanceMonitor.measureAsyncTime(operation: "Double Texting Analysis") {
                        return await Task.detached {
                            return mutableChat.doubleTextingAnalysis()
                        }.value
                    }
                    await MainActor.run {
                        analysisResults.doubleTexts = result
                        loadingProgress = 0.8
                    }
                }
                
                // Load most used words - heavy operation, optimized
                group.addTask {
                    let result = await PerformanceMonitor.measureAsyncTime(operation: "Most Used Words") {
                        return await Task.detached {
                            return mutableChat.mostUsedWords(for: nil, limit: 10)
                        }.value
                    }
                    await MainActor.run {
                        analysisResults.mostUsedWords = result
                        loadingProgress = 0.9
                    }
                }
                
                // Load emoji analysis - heaviest operation last
                group.addTask {
                    let result = await PerformanceMonitor.measureAsyncTime(operation: "Emoji Analysis") {
                        return await Task.detached {
                            return mutableChat.enhancedEmojiAnalysis(for: nil)
                        }.value
                    }
                    await MainActor.run {
                        analysisResults.emojiAnalysis = result
                        loadingProgress = 1.0
                    }
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    // MARK: - Optimized Helper methods
    
    // Optimized version using preprocessed data
    private func whoTextedLess(_ chat: Chat, preprocessedData: PreprocessedData) -> (String, String) {
        let senderCounts = preprocessedData.senderGroups.mapValues { messages in
            messages.reduce(0) { total, message in
                total + AnalysisOptimizer.optimizedWordCount(text: message.text)
            }
            }
        
        guard senderCounts.count >= 2,
              let maxSender = senderCounts.max(by: { $0.value < $1.value }),
              let minSender = senderCounts.min(by: { $0.value < $1.value })
        else {
            return ("Unknown", "0")
        }
        
        let percentage = maxSender.value > 0
            ? Int(100 - (Double(minSender.value) / Double(maxSender.value) * 100))
            : 0
        
        return (minSender.key, "\(percentage)")
    }
    
    // Optimized longest message calculation
    private func yourLongestMessage(_ chat: Chat, preprocessedData: PreprocessedData) -> Int {
        guard let you = chat.senders.first,
              let yourMessages = preprocessedData.senderGroups[you] else { return 0 }
        
        return AnalysisOptimizer.processBatches(items: yourMessages, batchSize: 500) { batch in
            return batch.map { AnalysisOptimizer.optimizedWordCount(text: $0.text) }
        }.max() ?? 0
    }
    
    // Optimized their longest message calculation  
    private func theirLongestMessage(_ chat: Chat, preprocessedData: PreprocessedData) -> Int {
        guard chat.senders.count > 1,
              let them = chat.senders.last,
              let theirMessages = preprocessedData.senderGroups[them] else { return 0 }
        
        return AnalysisOptimizer.processBatches(items: theirMessages, batchSize: 500) { batch in
            return batch.map { AnalysisOptimizer.optimizedWordCount(text: $0.text) }
        }.max() ?? 0
    }
    
    // Returns the name of the other person in the chat
    private func otherPersonName() -> String {
        guard chat.senders.count > 1 else { return "Other" }
        return chat.senders[1]
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: time) ?? "00:00"
    }
}

// MARK: - Preview
struct ChatAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        ChatAnalysisView(chat: Chat.sampleChat)
            .previewDevice("iPhone 16 Pro")
    }
} 

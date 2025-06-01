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
        .navigationTitle("navigation.summary".localized)
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
            ProgressView("common.loading".localized, value: loadingProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(maxWidth: 200)
            
            Text("import.processing".localized + " \(chat.totalMessages) " + "common.messages".localized.lowercased())
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
                    Text("navigation.summary".localized)
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
                            title: "analysis.whoTextedMore".localized,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("analysis.thisChat".localized)
                                        .font(.subheadline)
                                    
                                    Text("\(analysisResults.totalWords) " + "common.words".localized.lowercased())
                                        .font(.system(size: 32, weight: .bold))
                                    
                                    Text("\(analysisResults.whoTextedLessResult.0) " + "analysis.textedLess".localized)
                                        .font(.subheadline)
                                    
                                    Text("by \(analysisResults.whoTextedLessResult.1)%")
                                        .font(.system(size: 32, weight: .bold))
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // longest message card
                    NavigationLink(destination: DetailView(chat: chat, card: .longestMessage)) {
                        AnalysisCardView(
                            title: "analysis.longestMessage".localized,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("longest.yourLongest".localized)
                                        .font(.subheadline)
                                    
                                    Text("longest.words".localized(with: analysisResults.yourLongestMessage))
                                        .font(.system(size: 32, weight: .bold))
                                    
                                    Text("analysis.theirLongestMessage".localized(with: otherPersonName()))
                                        .font(.subheadline)
                                    
                                    Text("longest.words".localized(with: analysisResults.theirLongestMessage))
                                        .font(.system(size: 32, weight: .bold))
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    
                    // ghosting card
                    NavigationLink(destination: DetailView(chat: chat, card: .ghosting)) {
                        AnalysisCardView(
                            title: "analysis.ghosting".localized,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let you = analysisResults.ghostingData.first {
                                        Text("ghosting.youGhosted".localized)
                                            .font(.subheadline)
                                        
                                        Text("ghosting.times".localized(with: you.ghostingEvents.count))
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                    
                                    if analysisResults.ghostingData.count > 1 {
                                        Text("ghosting.theyGhostedYou".localized(with: otherPersonName()))
                                            .font(.subheadline)
                                        
                                        Text("ghosting.times".localized(with: analysisResults.ghostingData[1].ghostingEvents.count))
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
                    
                    // conversation initiation card
                    NavigationLink(destination: DetailView(chat: chat, card: .conversationInitiation)) {
                        AnalysisCardView(
                            title: "analysis.conversationInitiation".localized,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let you = analysisResults.initiationData.first {
                                        let yourTotal = you.initiationsByMonth.reduce(0) { $0 + $1.count }
                                        Text("initiation.youInitiated".localized)
                                            .font(.subheadline)
                                        
                                        Text("initiation.times".localized(with: yourTotal))
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                    
                                    if analysisResults.initiationData.count > 1 {
                                        let theirTotal = analysisResults.initiationData[1].initiationsByMonth.reduce(0) { $0 + $1.count }
                                        Text("initiation.theyInitiated".localized(with: otherPersonName()))
                                            .font(.subheadline)
                                        
                                        Text("initiation.times".localized(with: theirTotal))
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
                    
                    // response time card
                    NavigationLink(destination: DetailView(chat: chat, card: .responseTime)) {
                        AnalysisCardView(
                            title: "analysis.responseTime".localized,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("response.average".localized + " " + "response.title".localized.lowercased())
                                        .font(.subheadline)
                                    
                                    Text(formatTime(analysisResults.responseTimeStats.average))
                                        .font(.system(size: 32, weight: .bold))
                                    
                                    Text("response.fastestResponse".localized)
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
                    
                    // hourly activity card
                    NavigationLink(destination: DetailView(chat: chat, card: .hourlyActivity)) {
                        AnalysisCardView(
                            title: "analysis.hourlyActivity".localized,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let yourActive = analysisResults.mostActiveHours.first {
                                        Text("hourly.yourMostActiveHour".localized)
                                            .font(.subheadline)
                                        
                                        Text(String(format: "%02d:00", yourActive.hour))
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                    
                                    if analysisResults.mostActiveHours.count > 1 {
                                        Text("hourly.theirMostActiveHour".localized(with: otherPersonName()))
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
                    
                    // double texting card
                    NavigationLink(destination: DetailView(chat: chat, card: .doubleTexting)) {
                        AnalysisCardView(
                            title: "analysis.doubleTexting".localized,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let you = analysisResults.doubleTexts.first {
                                        let yourTotal = you.doubleTextsByMonth.reduce(0) { $0 + $1.count }
                                        Text("double.youDoubleTexted".localized)
                                            .font(.subheadline)
                                        
                                        Text("double.times".localized(with: yourTotal))
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                    
                                    if analysisResults.doubleTexts.count > 1 {
                                        let theirTotal = analysisResults.doubleTexts[1].doubleTextsByMonth.reduce(0) { $0 + $1.count }
                                        Text("double.theyDoubleTexted".localized(with: otherPersonName()))
                                            .font(.subheadline)
                                        
                                        Text("double.times".localized(with: theirTotal))
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
                    
                    // most used words card
                    NavigationLink(destination: DetailView(chat: chat, card: .mostUsedWords)) {
                        AnalysisCardView(
                            title: "analysis.mostUsedWords".localized,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let topWord = analysisResults.mostUsedWords.first {
                                        Text("words.mostPopular".localized)
                                            .font(.subheadline)
                                        
                                        Text("\"\(topWord.word)\"")
                                            .font(.system(size: 24, weight: .bold))
                                        
                                        Text("words.used".localized(with: topWord.count))
                                            .font(.subheadline)
                                        
                                        Text("words.uniqueWords".localized(with: analysisResults.mostUsedWords.count))
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
                    
                    // emoji usage card
                    NavigationLink(destination: DetailView(chat: chat, card: .emojiUsage)) {
                        AnalysisCardView(
                            title: "analysis.emojiUsage".localized,
                            content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    let totalEmojis = analysisResults.emojiAnalysis.reduce(0) { $0 + $1.count }
                                    
                                    if let topEmoji = analysisResults.emojiAnalysis.first {
                                        Text("emoji.mostUsedEmoji".localized)
                                            .font(.subheadline)
                                        
                                        Text(topEmoji.emoji)
                                            .font(.system(size: 40))
                                        
                                        Text("emoji.used".localized(with: topEmoji.count))
                                            .font(.subheadline)
                                    }
                                    
                                    Text("\(totalEmojis) " + "emoji.totalEmojis".localized.lowercased())
                                        .font(.system(size: 20, weight: .bold))
                                }
                            },
                            chart: {
                                HStack {
                                    Spacer()
                                    // show top 3 emojis
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
            // preprocess data once
            let preprocessedData = AnalysisOptimizer.preprocessMessages(chat.messages)
            
            await withTaskGroup(of: Void.self) { group in
                var mutableChat = chat
                
                // load basic stats / fastest operations first
                group.addTask {
                    await PerformanceMonitor.measureAsyncTime(operation: "Basic Stats") {
                        await MainActor.run {
                            analysisResults.totalWords = preprocessedData.totalWords
                            loadingProgress = 0.1
                        }
                    }
                }
                
                // load who texted less / use preprocessed data
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
                
                // load longest messages / batch processing
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
                
                // load ghosting analysis / async processing
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
                
                // load conversation initiation
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
                
                // load response time stats
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
                
                // load most active hours / optimized
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
                
                // load double texting / batch processing
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
                
                // load most used words / heavy operation, optimized
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
                
                // load emoji analysis / heaviest operation last
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
    
    // MARK: - optimized helper methods
    
    // optimized version using preprocessed data
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
    
    // optimized longest message calculation
    private func yourLongestMessage(_ chat: Chat, preprocessedData: PreprocessedData) -> Int {
        guard let you = chat.senders.first,
              let yourMessages = preprocessedData.senderGroups[you] else { return 0 }
        
        return AnalysisOptimizer.processBatches(items: yourMessages, batchSize: 500) { batch in
            return batch.map { AnalysisOptimizer.optimizedWordCount(text: $0.text) }
        }.max() ?? 0
    }
    
    // optimized their longest message calculation  
    private func theirLongestMessage(_ chat: Chat, preprocessedData: PreprocessedData) -> Int {
        guard chat.senders.count > 1,
              let them = chat.senders.last,
              let theirMessages = preprocessedData.senderGroups[them] else { return 0 }
        
        return AnalysisOptimizer.processBatches(items: theirMessages, batchSize: 500) { batch in
            return batch.map { AnalysisOptimizer.optimizedWordCount(text: $0.text) }
        }.max() ?? 0
    }
    
    // returns the name of the other person in the chat
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

// MARK: - preview
struct ChatAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        ChatAnalysisView(chat: Chat.sampleChat)
            .previewDevice("iPhone 16 Pro")
    }
} 

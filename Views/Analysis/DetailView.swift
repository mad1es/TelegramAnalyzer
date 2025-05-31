import SwiftUI

struct DetailView: View {
    var chat: Chat
    var card: ChatAnalysisView.AnalysisCard
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch card {
                case .whoTextedMore:
                    WhoTextedMoreView(chat: chat)
                case .longestMessage:
                    LongestMessageView(chat: chat)
                case .ghosting:
                    GhostingView(chat: chat)
                case .conversationInitiation:
                    ConversationInitiationView(chat: chat)
                case .responseTime:
                    ResponseTimeView(chat: chat)
                case .hourlyActivity:
                    HourlyActivityView(chat: chat)
                case .doubleTexting:
                    DoubleTextingView(chat: chat)
                case .mostUsedWords:
                    MostUsedWordsView(chat: chat)
                case .emojiUsage:
                    EmojiUsageView(chat: chat)
                }
            }
            .padding()
        }
        .navigationBarTitle(card.rawValue, displayMode: .inline)
    }
} 
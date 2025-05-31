import SwiftUI
import Charts

struct EmojiUsageView: View {
    var chat: Chat
    @State private var selectedSender: String? = nil
    
    var body: some View {
        // Calculate data once at the top level
        let emojiData = chat.enhancedEmojiAnalysis(for: selectedSender)
        let totalEmojis = emojiData.reduce(0) { $0 + $1.count }
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Sender selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select User")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 0) {
                        Button(action: {
                            selectedSender = nil
                        }) {
                            Text("all users")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedSender == nil ? Color.white : Color.clear)
                                )
                                .foregroundColor(selectedSender == nil ? .black : .white.opacity(0.7))
                        }
                        
                        ForEach(chat.senders, id: \.self) { sender in
                            Button(action: {
                                selectedSender = sender
                            }) {
                                Text(sender.lowercased())
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedSender == sender ? Color.white : Color.clear)
                                    )
                                    .foregroundColor(selectedSender == sender ? .black : .white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gray.opacity(0.3))
                    )
                    .padding(.horizontal)
                }
                
                // Emoji usage chart (only if specific sender is selected)
                if let selectedSender = selectedSender {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Emoji usage over time")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        let chartData = chat.emojiUsageByMonth(for: selectedSender)
                        if !chartData.isEmpty {
                            Chart {
                                ForEach(chartData, id: \.date) { dataPoint in
                                    BarMark(
                                        x: .value("Month", dataPoint.date, unit: .month),
                                        y: .value("Count", dataPoint.count)
                                    )
                                    .foregroundStyle(.blue)
                                    .cornerRadius(4)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .month)) { value in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 200)
                            .padding(.horizontal)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                            .padding(.horizontal)
                        } else {
                            Text("No emoji usage data for \(selectedSender)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .padding(.horizontal)
                        }
                    }
                }
                
                // Top emojis
                VStack(alignment: .leading, spacing: 16) {
                    Text("Most Used Emojis")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if emojiData.isEmpty {
                        VStack(spacing: 12) {
                            Text("😶")
                                .font(.system(size: 48))
                            Text("No emojis found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Try selecting a different user")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Top 15 emojis grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                            ForEach(Array(emojiData.prefix(15).enumerated()), id: \.element.emoji) { index, emojiInfo in
                                EmojiCard(
                                    rank: index + 1,
                                    emoji: emojiInfo.emoji,
                                    count: emojiInfo.count,
                                    percentage: Double(emojiInfo.count) / Double(totalEmojis) * 100
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Detailed list for top 10
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top 10 Detailed")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(emojiData.prefix(10).enumerated()), id: \.element.emoji) { index, emojiInfo in
                                EmojiRowView(
                                    rank: index + 1,
                                    emoji: emojiInfo.emoji,
                                    count: emojiInfo.count,
                                    percentage: Double(emojiInfo.count) / Double(totalEmojis) * 100
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                // Statistics
                if !emojiData.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Emoji Statistics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            StatCard(
                                icon: "face.smiling",
                                value: "\(emojiData.count)",
                                title: "Unique Emojis",
                                color: .yellow
                            )
                            
                            StatCard(
                                icon: "sum",
                                value: "\(totalEmojis)",
                                title: "Total Count",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)
                        
                        if let topEmoji = emojiData.first {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Most Popular Emoji")
                                    .font(.headline)
                                
                                HStack {
                                    Text(topEmoji.emoji)
                                        .font(.system(size: 40))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Used \(topEmoji.count) times")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        
                                        Text(String(format: "%.1f%% of all emojis", Double(topEmoji.count) / Double(totalEmojis) * 100))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Per sender comparison (only when all users selected)
                if selectedSender == nil && !chat.senders.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Emoji Usage by Person")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(chat.senders, id: \.self) { sender in
                            let senderEmojis = chat.enhancedEmojiAnalysis(for: sender)
                            let senderTotal = senderEmojis.reduce(0) { $0 + $1.count }
                            
                            SenderEmojiCard(
                                sender: sender,
                                totalEmojis: senderTotal,
                                uniqueEmojis: senderEmojis.count,
                                topEmoji: senderEmojis.first?.emoji ?? "😶",
                                color: colorForUser(sender)
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emoji Analysis")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("All Unicode emoji characters are counted. Each emoji is counted separately, even when used in sequences or combinations.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Emoji Usage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "eye")
                }
            }
        }
    }
}

struct EmojiCard: View {
    let rank: Int
    let emoji: String
    let count: Int
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text("#\(rank)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Text(emoji)
                .font(.system(size: 32))
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(String(format: "%.1f%%", percentage))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct EmojiRowView: View {
    let rank: Int
    let emoji: String
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 16) {
            Text("#\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            Text(emoji)
                .font(.system(size: 28))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Used \(count) times")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(String(format: "%.1f%% of all emojis", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct SenderEmojiCard: View {
    let sender: String
    let totalEmojis: Int
    let uniqueEmojis: Int
    let topEmoji: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                Text(sender)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalEmojis)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Emojis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text(topEmoji)
                        .font(.system(size: 32))
                    Text("Favorite")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(uniqueEmojis)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Unique")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
} 

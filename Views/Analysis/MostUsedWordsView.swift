import SwiftUI

struct MostUsedWordsView: View {
    var chat: Chat
    @State private var selectedSender: String? = nil
    
    var body: some View {
        let wordsData = chat.mostUsedWords(for: selectedSender, limit: 50)
        let totalWords = wordsData.reduce(0) { $0 + $1.count }
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("words.selectUser".localized)
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 0) {
                        Button(action: {
                            selectedSender = nil
                        }) {
                            Text("words.allUsers".localized)
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
                
                // words list
                VStack(alignment: .leading, spacing: 16) {
                    Text("words.mostUsedWords".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if wordsData.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("words.noWordsFound".localized)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("words.tryDifferentUser".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // top 10 words grid
                        VStack(alignment: .leading, spacing: 12) {
                            Text("words.top10Words".localized)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(Array(wordsData.prefix(10).enumerated()), id: \.element.word) { index, wordData in
                                    WordCard(
                                        rank: index + 1,
                                        word: wordData.word,
                                        count: wordData.count,
                                        percentage: Double(wordData.count) / Double(totalWords) * 100,
                                        color: colorForRank(index)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // complete list
                        VStack(alignment: .leading, spacing: 12) {
                            Text("words.completeWordList".localized)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(wordsData.enumerated()), id: \.element.word) { index, wordData in
                                WordRowView(
                                    rank: index + 1,
                                    word: wordData.word,
                                    count: wordData.count,
                                    percentage: Double(wordData.count) / Double(totalWords) * 100,
                                    color: colorForRank(index)
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                // stats
                if !wordsData.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("words.wordStatistics".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            StatCard(
                                icon: "textformat",
                                value: "\(wordsData.count)",
                                title: "words.uniqueWordsTitle".localized,
                                color: .purple
                            )
                            
                            StatCard(
                                icon: "sum",
                                value: "\(totalWords)",
                                title: "words.totalCount".localized,
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                        
                        if let topWord = wordsData.first {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("words.mostPopular".localized)
                                    .font(.headline)
                                
                                HStack {
                                    Text("\"\(topWord.word)\"")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(topWord.count) " + "words.times".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
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
                
                // filter explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("words.filterInformation".localized)
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("words.filterDescriptionDetail".localized)
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
        .navigationTitle("words.mostUsedWords".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "eye")
                }
            }
        }
    }
    
    private func colorForRank(_ rank: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        return colors[rank % colors.count]
    }
}

struct WordCard: View {
    let rank: Int
    let word: String
    let count: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("#\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            Text(word)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(String(format: "%.1f%%", percentage))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct WordRowView: View {
    let rank: Int
    let word: String
    let count: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(word)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
} 
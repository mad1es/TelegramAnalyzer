import SwiftUI
import Charts

struct WhoTextedMoreView: View {
    var chat: Chat
    @State private var selectedTimeRange: TimeRange = .year
    
    enum TimeRange: String, CaseIterable {
        case week = "week"
        case month = "month"
        case year = "year"
        case all = "all"
        
        var displayName: String {
            switch self {
            case .week: return "whoTexted.week".localized
            case .month: return "whoTexted.month".localized
            case .year: return "whoTexted.year".localized
            case .all: return "whoTexted.all".localized
            }
        }
    }
    
    private var chartData: [(date: Date, data: [String: Int])] {
        getChartData()
    }
    
    private var averageWordsPerDay: Double {
        calculateAverageWordsPerDay()
    }
    
    private var dateRangeText: String {
        guard let firstDate = chat.firstMessageDate, 
              let lastDate = chat.lastMessageDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM"
        formatter.locale = Locale.current
        return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                timeRangeSection
                chartSection
                highlightsSection
            }
        }
        .navigationTitle("whoTexted.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "eye")
                }
            }
        }
    }
    
    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !dateRangeText.isEmpty {
                Text(dateRangeText)
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.horizontal)
            }
            
            // Time range selector
            HStack(spacing: 0) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedTimeRange = range
                    }) {
                        Text(range.displayName.lowercased())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTimeRange == range ? Color.white : Color.clear)
                            )
                            .foregroundColor(selectedTimeRange == range ? .black : .white.opacity(0.7))
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
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("whoTexted.numberOfWordsPerMonth".localized)
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(chat.senders, id: \.self) { sender in
                    ForEach(chartData, id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Month", dataPoint.date, unit: .month),
                            y: .value("Words", dataPoint.data[sender] ?? 0)
                        )
                        .foregroundStyle(by: .value("Sender", sender))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        .symbolSize(50)
                    }
                }
            }
            .chartForegroundStyleScale(chartColorPairs(for: chat.senders))
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatMonthForChart(date))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .bottom, alignment: .center) {
                HStack(spacing: 20) {
                    ForEach(chat.senders, id: \.self) { sender in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorForUser(sender))
                                .frame(width: 12, height: 12)
                            Text(sender)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .frame(height: 300)
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal)
        }
    }
    
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("whoTexted.highlights".localized)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Stats cards
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    StatCard(
                        icon: "bubble.left.and.bubble.right",
                        value: "\(chat.totalWords)",
                        title: "whoTexted.totalWordsTitle".localized,
                        color: .blue
                    )
                    
                    StatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        value: "\(Int(averageWordsPerDay))",
                        title: "whoTexted.averageWordsPerDay".localized,
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Per sender breakdown
                ForEach(chat.senders, id: \.self) { sender in
                    SenderStatsCard(
                        sender: sender,
                        totalWords: chat.messages(from: sender).reduce(0) { $0 + $1.wordCount },
                        averagePerDay: Int(chat.wordsPerDay(for: sender)),
                        color: colorForUser(sender)
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func getChartData() -> [(date: Date, data: [String: Int])] {
        var result: [(date: Date, data: [String: Int])] = []
        
        let allMonths = Set(chat.messages.compactMap { message in
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: message.date))
        }).sorted()
        
        for month in allMonths {
            var monthData: [String: Int] = [:]
            for sender in chat.senders {
                let wordCount = chat.wordCountByMonth(for: sender)
                    .first { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }?.count ?? 0
                monthData[sender] = wordCount
            }
            result.append((date: month, data: monthData))
        }
        
        return result
    }
    
    private func calculateAverageWordsPerDay() -> Double {
        guard let first = chat.firstMessageDate, let last = chat.lastMessageDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: first, to: last).day ?? 1
        return Double(chat.totalWords) / Double(max(days, 1))
    }
    
    private func colorForUser(_ user: String) -> Color {
        return user == chat.senders.first ? .pink : .orange
    }
    
    private func formatMonthForChart(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = LocalizationManager.shared.currentLanguage.locale
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct SenderStatsCard: View {
    let sender: String
    let totalWords: Int
    let averagePerDay: Int
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
                    Text("\(totalWords)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("whoTexted.totalWordsTitle".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(averagePerDay)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("whoTexted.avgPerDay".localized)
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
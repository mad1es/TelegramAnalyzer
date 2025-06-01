import SwiftUI
import Charts

struct LongestMessageView: View {
    var chat: Chat
    @State private var selectedTimeRange: TimeRange = .year
    
    enum TimeRange: String, CaseIterable {
        case week = "week"
        case month = "month"
        case year = "year"
        case all = "all"
        
        var displayName: String {
            switch self {
            case .week: return "longest.week".localized
            case .month: return "longest.month".localized
            case .year: return "longest.year".localized
            case .all: return "longest.all".localized
            }
        }
    }
    
    private var chartData: [(date: Date, data: [String: Int])] {
        getChartData()
    }
    
    private var dateRangeText: String {
        guard let firstDate = chat.firstMessageDate, 
              let lastDate = chat.lastMessageDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM"
        return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
    }
    
    private var overallMaxLength: Int {
        chat.senders.compactMap { sender in
            chat.top10LongestMessages(for: sender).first?.wordCount
        }.max() ?? 0
    }
    
    private var overallAvgMaxLength: Int {
        let total = chat.senders.map { sender in
            Int(chat.averageTop10MessageLength(for: sender))
        }.reduce(0, +)
        return total / max(chat.senders.count, 1)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                timeRangeSection
                chartSection
                highlightsSection
                longestMessagesSection
            }
        }
        .navigationTitle("Message Length")
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
            Text("longest.maxLengthPerMonth".localized)
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(chat.senders, id: \.self) { sender in
                    ForEach(chartData, id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Month", dataPoint.date, unit: .month),
                            y: .value("Max Length", dataPoint.data[sender] ?? 0)
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
            Text("longest.highlights".localized)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            HStack(spacing: 16) {
                StatCard(
                    icon: "text.alignleft",
                    value: "\(overallMaxLength)",
                    title: "longest.maximumLength".localized,
                    color: .blue
                )
                
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(overallAvgMaxLength)",
                    title: "longest.averageMaxLength".localized,
                    color: .orange
                )
            }
            .padding(.horizontal)
            
            // per sender breakdown
            ForEach(chat.senders, id: \.self) { sender in
                MessageLengthCard(
                    sender: sender,
                    maxLength: chat.top10LongestMessages(for: sender).first?.wordCount ?? 0,
                    averageTop10: Int(chat.averageTop10MessageLength(for: sender)),
                    color: colorForUser(sender),
                    longestMessage: chat.top10LongestMessages(for: sender).first
                )
                .padding(.horizontal)
            }
        }
    }
    
    private var longestMessagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("longest.longestMessages".localized)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(chat.senders, id: \.self) { sender in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(colorForUser(sender))
                            .frame(width: 12, height: 12)
                        Text("\(sender)'s " + "longest.topMessages".localized(with: sender))
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    ForEach(Array(chat.top10LongestMessages(for: sender).prefix(3).enumerated()), id: \.element.id) { index, message in
                        MessagePreviewCard(
                            message: message,
                            rank: index + 1,
                            color: colorForUser(sender)
                        )
                        .padding(.horizontal)
                    }
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
                let maxLength = chat.maxMessageLengthByMonth(for: sender)
                    .first { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }?.maxLength ?? 0
                monthData[sender] = maxLength
            }
            result.append((date: month, data: monthData))
        }
        
        return result
    }
    
    private func formatMonthForChart(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

struct MessageLengthCard: View {
    let sender: String
    let maxLength: Int
    let averageTop10: Int
    let color: Color
    let longestMessage: Message?
    
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
                    Text("\(maxLength)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("longest.maxLength".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(averageTop10)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("longest.avgTop10".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let longestMessage = longestMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("longest.longestMessage".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(longestMessage.text.prefix(100)) + (longestMessage.text.count > 100 ? "..." : ""))
                        .font(.caption)
                        .lineLimit(3)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color.opacity(0.1))
                        )
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

struct MessagePreviewCard: View {
    let message: Message
    let rank: Int
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("#\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(message.wordCount) words")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Text(message.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(String(message.text.prefix(150)) + (message.text.count > 150 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
} 
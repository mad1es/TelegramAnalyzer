import SwiftUI
import Charts

struct ConversationInitiationView: View {
    var chat: Chat
    
    private var chartData: [(date: Date, sender: String, count: Int)] {
        let data: [(date: Date, sender: String, count: Int)] = getChartData()
        return data
    }
    
    private var initiationData: [(sender: String, initiationsByMonth: [(date: Date, count: Int)])] {
        chat.enhancedConversationInitiation()
    }
    
    private var totalInitiations: Int {
        initiationData.reduce(0) { total, data in
            total + data.initiationsByMonth.reduce(0) { $0 + $1.count }
        }
    }
    
    private var mostActiveMonth: (date: Date, count: Int)? {
        getMostActiveMonth()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                chartSection
                statisticsSection
                mostActiveMonthSection
                definitionSection
            }
        }
        .navigationTitle("Conversation Initiation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "eye")
                }
            }
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("initiation.conversationsPerMonth".localized)
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(chartData, id: \.date) { dataPoint in
                    BarMark(
                        x: .value("Month", dataPoint.date, unit: .month),
                        y: .value("Count", dataPoint.count)
                    )
                    .foregroundStyle(by: .value("Sender", dataPoint.sender))
                    .cornerRadius(4)
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
                            RoundedRectangle(cornerRadius: 2)
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
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("initiation.initiationStatistics".localized)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // overall stats
            HStack(spacing: 16) {
                StatCard(
                    icon: "bubble.left",
                    value: "\(totalInitiations)",
                    title: "initiation.totalInitiations".localized,
                    color: .blue
                )
                
                StatCard(
                    icon: "chart.pie",
                    value: "\(chat.senders.count)",
                    title: "initiation.participants".localized,
                    color: .green
                )
            }
            .padding(.horizontal)
            
            // per sender breakdown
            ForEach(initiationData, id: \.sender) { data in
                let senderTotal = data.initiationsByMonth.reduce(0) { $0 + $1.count }
                let percentage = totalInitiations > 0 ? Double(senderTotal) / Double(totalInitiations) * 100 : 0
                
                InitiationStatCard(
                    sender: data.sender,
                    totalInitiations: senderTotal,
                    percentage: percentage,
                    color: colorForUser(data.sender),
                    isTopInitiator: isTopInitiator(sender: data.sender, allData: initiationData)
                )
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private var mostActiveMonthSection: some View {
        if let mostActiveMonth = mostActiveMonth {
            VStack(alignment: .leading, spacing: 8) {
                Text("initiation.mostActiveMonth".localized)
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(formatDate(mostActiveMonth.date))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("initiation.conversationsStartedCount".localized(with: mostActiveMonth.count))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            }
        }
    }
    
    private var definitionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("initiation.initiationDefinition".localized)
                .font(.headline)
                .padding(.horizontal)
            
            Text("initiation.definitionText".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func getChartData() -> [(date: Date, sender: String, count: Int)] {
        let initiationData = chat.enhancedConversationInitiation()
        var result: [(date: Date, sender: String, count: Int)] = []
        
        for data in initiationData {
            for monthData in data.initiationsByMonth {
                result.append((date: monthData.date, sender: data.sender, count: monthData.count))
            }
        }
        
        return result.sorted { $0.date < $1.date }
    }

    
    private func isTopInitiator(sender: String, allData: [(sender: String, initiationsByMonth: [(date: Date, count: Int)])]) -> Bool {
        let senderTotal = allData.first { $0.sender == sender }?.initiationsByMonth.reduce(0) { $0 + $1.count } ?? 0
        let maxTotal = allData.map { $0.initiationsByMonth.reduce(0) { $0 + $1.count } }.max() ?? 0
        return senderTotal == maxTotal && maxTotal > 0
    }
    
    private func getMostActiveMonth() -> (date: Date, count: Int)? {
        let chartData = getChartData()
        var monthTotals: [Date: Int] = [:]
        
        for data in chartData {
            monthTotals[data.date, default: 0] += data.count
        }
        
        return monthTotals.max { $0.value < $1.value }.map { (date: $0.key, count: $0.value) }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    private func formatDateForMonthView(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    private func formatMonthForChart(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

struct InitiationStatCard: View {
    let sender: String
    let totalInitiations: Int
    let percentage: Double
    let color: Color
    let isTopInitiator: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                Text(sender)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if isTopInitiator {
                    Text("🚀 " + "initiation.topInitiator".localized)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color.opacity(0.2))
                        )
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalInitiations)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("initiation.initiations".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f%%", percentage))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("initiation.ofTotal".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isTopInitiator ? color.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
    }
} 

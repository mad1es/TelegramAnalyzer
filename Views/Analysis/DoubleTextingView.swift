import SwiftUI
import Charts

struct DoubleTextingView: View {
    var chat: Chat
    
    private var chartData: [(date: Date, sender: String, count: Int)] {
        getChartData()
    }
    
    private var doubleTextingData: [(sender: String, doubleTextsByMonth: [(date: Date, count: Int)])] {
        chat.doubleTextingAnalysis()
    }
    
    private var totalDoubleTexts: Int {
        doubleTextingData.reduce(0) { total, data in
            total + data.doubleTextsByMonth.reduce(0) { $0 + $1.count }
        }
    }
    
    private var peakDay: (date: Date, sender: String, count: Int)? {
        chat.dayWithMostDoubleTexts()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                chartSection
                peakDaySection
                statisticsSection
                definitionSection
            }
        }
        .navigationTitle("Double Texting")
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
            Text("Double texting per month")
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
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
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
    
    @ViewBuilder
    private var peakDaySection: some View {
        if let peakDay = peakDay {
            VStack(alignment: .leading, spacing: 12) {
                Text("📱 Peak Double Texting Day")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(formatFullDate(peakDay.date))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Circle()
                            .fill(colorForUser(peakDay.sender))
                            .frame(width: 12, height: 12)
                        
                        Text("\(peakDay.sender) sent \(peakDay.count) double texts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorForUser(peakDay.sender).opacity(0.1))
                )
                .padding(.horizontal)
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Double Texting Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Overall stats
            HStack(spacing: 16) {
                StatCard(
                    icon: "message.badge",
                    value: "\(totalDoubleTexts)",
                    title: "Total Double Texts",
                    color: .blue
                )
                
                StatCard(
                    icon: "person.2",
                    value: "\(chat.senders.count)",
                    title: "Participants",
                    color: .green
                )
            }
            .padding(.horizontal)
            
            // Per sender breakdown
            ForEach(doubleTextingData, id: \.sender) { data in
                let senderTotal = data.doubleTextsByMonth.reduce(0) { $0 + $1.count }
                let percentage = totalDoubleTexts > 0 ? Double(senderTotal) / Double(totalDoubleTexts) * 100 : 0
                
                DoubleTextingCard(
                    sender: data.sender,
                    totalDoubleTexts: senderTotal,
                    percentage: percentage,
                    color: colorForUser(data.sender),
                    isTopDoubleTexter: isTopDoubleTexter(sender: data.sender, allData: doubleTextingData)
                )
                .padding(.horizontal)
            }
        }
    }
    
    private var definitionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Double Texting Definition")
                .font(.headline)
                .padding(.horizontal)
            
            Text("Double texting occurs when a person sends a second message between 1 to 6 hours after the previous one, without receiving a reply.")
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
        let doubleTextingData = chat.doubleTextingAnalysis()
        var result: [(date: Date, sender: String, count: Int)] = []
        
        for data in doubleTextingData {
            for monthData in data.doubleTextsByMonth {
                result.append((date: monthData.date, sender: data.sender, count: monthData.count))
            }
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
    // private func colorForUser(_ sender: String) -> Color {
    //     // Call global function directly to avoid recursion
    //     return Extensions.colorForUser(sender)
    // }
    
    private func isTopDoubleTexter(sender: String, allData: [(sender: String, doubleTextsByMonth: [(date: Date, count: Int)])]) -> Bool {
        let senderTotal = allData.first { $0.sender == sender }?.doubleTextsByMonth.reduce(0) { $0 + $1.count } ?? 0
        let maxTotal = allData.map { $0.doubleTextsByMonth.reduce(0) { $0 + $1.count } }.max() ?? 0
        return senderTotal == maxTotal && maxTotal > 0
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct DoubleTextingCard: View {
    let sender: String
    let totalDoubleTexts: Int
    let percentage: Double
    let color: Color
    let isTopDoubleTexter: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                Text(sender)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if isTopDoubleTexter {
                    Text("📱 Top Double Texter")
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
                    Text("\(totalDoubleTexts)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Double Texts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f%%", percentage))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("of Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
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
                        .stroke(isTopDoubleTexter ? color.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
    }
} 
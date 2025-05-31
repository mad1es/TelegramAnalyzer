import SwiftUI
import Charts

struct ResponseTimeView: View {
    var chat: Chat
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Average response time per month")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    let chartData = getChartData()
                    Chart {
                        ForEach(chat.senders, id: \.self) { sender in
                            ForEach(chartData.filter { $0.sender == sender }, id: \.date) { dataPoint in
                                LineMark(
                                    x: .value("Month", dataPoint.date, unit: .month),
                                    y: .value("Response Time", dataPoint.averageTime / 60) // Convert to minutes
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
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let minutes = value.as(Double.self) {
                                    Text("\(Int(minutes))m")
                                }
                            }
                        }
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
                
                // Quick stats overview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Response Time Statistics")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Overall stats
                    let overallStats = chat.responseTimeStats()
                    HStack(spacing: 12) {
                        StatCard(
                            icon: "speedometer",
                            value: formatTime(overallStats.average),
                            title: "Average",
                            color: .blue
                        )
                        
                        StatCard(
                            icon: "bolt.fill",
                            value: formatTime(overallStats.min),
                            title: "Fastest",
                            color: .green
                        )
                        
                        StatCard(
                            icon: "clock.fill",
                            value: formatTime(overallStats.max),
                            title: "Longest",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                    
                    // Per sender breakdown
                    ForEach(chat.senders, id: \.self) { sender in
                        ResponseTimeCard(
                            sender: sender,
                            averageTime: chat.averageResponseTime(for: sender),
                            rapidCount: chat.rapidExchanges(under: 60).first { $0.sender == sender }?.count ?? 0,
                            color: colorForUser(sender),
                            isFastest: isFastestResponder(sender: sender)
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Rapid exchanges highlight
                VStack(alignment: .leading, spacing: 12) {
                    Text("⚡ Rapid Exchanges")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Text("Replies under 1 minute")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    let rapidExchanges = chat.rapidExchanges(under: 60)
                    ForEach(rapidExchanges, id: \.sender) { rapid in
                        HStack {
                            Circle()
                                .fill(colorForUser(rapid.sender))
                                .frame(width: 12, height: 12)
                            
                            Text(rapid.sender)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(rapid.count) rapid replies")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorForUser(rapid.sender).opacity(0.1))
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Longest wait times
                VStack(alignment: .leading, spacing: 12) {
                    Text("⏰ Longest Wait Times")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    let longestWaits = getLongestWaitTimes()
                    ForEach(Array(longestWaits.prefix(5).enumerated()), id: \.element.message.id) { index, wait in
                        LongestWaitCard(
                            rank: index + 1,
                            message: wait.message,
                            waitTime: wait.waitTime,
                            color: colorForUser(wait.message.sender)
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Definition
                VStack(alignment: .leading, spacing: 8) {
                    Text("Response Time Definition")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("Response time is calculated as the time between receiving a message and sending a reply. Only consecutive messages from different senders are considered.")
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
        .navigationTitle("Response Time")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "eye")
                }
            }
        }
    }
    
    private func getChartData() -> [(date: Date, sender: String, averageTime: TimeInterval)] {
        var result: [(date: Date, sender: String, averageTime: TimeInterval)] = []
        
        for sender in chat.senders {
            let responseData = chat.responseTimeByMonth(for: sender)
            for data in responseData {
                result.append((date: data.date, sender: sender, averageTime: data.averageTime))
            }
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
    // private func colorForUser(_ sender: String) -> Color {
    //     // Using global colorForUser function from View+Extensions.swift
    //     return colorForUser(sender)
    // }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d"
        }
    }
    
    private func isFastestResponder(sender: String) -> Bool {
        let averageTimes = chat.senders.map { chat.averageResponseTime(for: $0) }
        let senderTime = chat.averageResponseTime(for: sender)
        return senderTime == averageTimes.min() && senderTime > 0
    }
    
    private func getLongestWaitTimes() -> [(message: Message, waitTime: TimeInterval)] {
        return chat.calculateResponseTimes()
            .sorted { $0.1 > $1.1 }
            .map { (message: $0.0, waitTime: $0.1) }
    }
}

struct ResponseTimeCard: View {
    let sender: String
    let averageTime: TimeInterval
    let rapidCount: Int
    let color: Color
    let isFastest: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                Text(sender)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if isFastest {
                    Text("⚡ Fastest")
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
                    Text(formatTime(averageTime))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Avg Response")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(rapidCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Rapid Replies")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFastest ? color.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d"
        }
    }
}

struct LongestWaitCard: View {
    let rank: Int
    let message: Message
    let waitTime: TimeInterval
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
                    Text(message.sender)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Text(formatTime(waitTime))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Text(message.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(message.text.prefix(100)) + (message.text.count > 100 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d"
        }
    }
} 
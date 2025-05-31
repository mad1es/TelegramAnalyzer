import SwiftUI
import Charts

struct HourlyActivityView: View {
    var chat: Chat
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Pyramid chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hourly Activity Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    let pyramidData = chat.hourlyActivityPyramid()
                    let maxCount = pyramidData.map { max($0.sender1Count, $0.sender2Count) }.max() ?? 1
                    
                    VStack(spacing: 2) {
                        ForEach(Array(pyramidData.enumerated()), id: \.element.hour) { index, data in
                            HourlyPyramidRow(
                                hour: data.hour,
                                sender1: chat.senders.count > 0 ? chat.senders[0] : "User 1",
                                sender1Count: data.sender1Count,
                                sender2: chat.senders.count > 1 ? chat.senders[1] : "User 2",
                                sender2Count: data.sender2Count,
                                maxCount: maxCount,
                                sender1Color: colorForUser(chat.senders.count > 0 ? chat.senders[0] : "User 1"),
                                sender2Color: colorForUser(chat.senders.count > 1 ? chat.senders[1] : "User 2")
                            )
                        }
                    }
                    .padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.horizontal)
                }
                
                // Most active hours
                VStack(alignment: .leading, spacing: 16) {
                    Text("Most Active Hours")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(chat.senders, id: \.self) { sender in
                        if let mostActive = chat.mostActiveHour(for: sender) {
                            MostActiveHourCard(
                                sender: sender,
                                hour: mostActive.hour,
                                messageCount: mostActive.count,
                                color: colorForUser(sender)
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Hourly breakdown chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Messages per hour")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(chat.senders, id: \.self) { sender in
                            ForEach(0..<24, id: \.self) { hour in
                                let count = chat.messages(in: hour).filter { $0.sender == sender }.count
                                BarMark(
                                    x: .value("Hour", hour),
                                    y: .value("Messages", count)
                                )
                                .foregroundStyle(by: .value("Sender", sender))
                                .cornerRadius(2)
                            }
                        }
                    }
                    .chartForegroundStyleScale(chartColorPairs(for: chat.senders))
                    .chartXAxis {
                        AxisMarks(values: Array(stride(from: 0, through: 23, by: 3))) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let hour = value.as(Int.self) {
                                    Text("\(hour):00")
                                        .font(.caption)
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
                    .frame(height: 200)
                    .padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.horizontal)
                }
                
                // Time period insights
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity Patterns")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    let insights = generateTimeInsights()
                    ForEach(insights, id: \.period) { insight in
                        ActivityInsightCard(
                            period: insight.period,
                            description: insight.description,
                            color: insight.color
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Definition
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Analysis")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("The pyramid chart shows message distribution across 24 hours. Each side represents one person, with longer bars indicating more activity during that hour.")
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
        .navigationTitle("Hourly Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "eye")
                }
            }
        }
    }
    
    // private func colorForUser(_ sender: String) -> Color {
    //     // Using global colorForUser function from View+Extensions.swift
    //     return colorForUser(sender)
    // }
    
    private func generateTimeInsights() -> [(period: String, description: String, color: Color)] {
        var insights: [(period: String, description: String, color: Color)] = []
        
        // Morning (6-11)
        let morningMessages = (6...11).map { hour in
            chat.messages(in: hour).count
        }.reduce(0, +)
        
        // Afternoon (12-17)
        let afternoonMessages = (12...17).map { hour in
            chat.messages(in: hour).count
        }.reduce(0, +)
        
        // Evening (18-22)
        let eveningMessages = (18...22).map { hour in
            chat.messages(in: hour).count
        }.reduce(0, +)
        
        // Night (23-5)
        let nightMessages = ([23] + Array(0...5)).map { hour in
            chat.messages(in: hour).count
        }.reduce(0, +)
        
        let periods = [
            ("Morning (6-11)", morningMessages, Color.yellow),
            ("Afternoon (12-17)", afternoonMessages, Color.orange),
            ("Evening (18-22)", eveningMessages, Color.purple),
            ("Night (23-5)", nightMessages, Color.blue)
        ]
        
        let maxPeriod = periods.max { $0.1 < $1.1 }
        
        for (period, count, color) in periods {
            let isMax = period == maxPeriod?.0
            let description = isMax ? "Most active period with \(count) messages" : "\(count) messages"
            insights.append((period: period, description: description, color: color))
        }
        
        return insights
    }
}

struct HourlyPyramidRow: View {
    let hour: Int
    let sender1: String
    let sender1Count: Int
    let sender2: String
    let sender2Count: Int
    let maxCount: Int
    let sender1Color: Color
    let sender2Color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            // Left side (sender1)
            HStack {
                Spacer()
                Text("\(sender1Count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 25)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(sender1Color)
                    .frame(width: barWidth(for: sender1Count), height: 16)
            }
            .frame(maxWidth: .infinity)
            
            // Hour label in center
            Text(String(format: "%02d:00", hour))
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 50)
                .foregroundColor(.primary)
            
            // Right side (sender2)
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(sender2Color)
                    .frame(width: barWidth(for: sender2Count), height: 16)
                
                Text("\(sender2Count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 25)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 1)
    }
    
    private func barWidth(for count: Int) -> CGFloat {
        let maxWidth: CGFloat = 80
        guard maxCount > 0 else { return 0 }
        return CGFloat(count) / CGFloat(maxCount) * maxWidth
    }
}

struct MostActiveHourCard: View {
    let sender: String
    let hour: Int
    let messageCount: Int
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
                
                Text("🕐 Most Active")
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
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%02d:00", hour))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Peak Hour")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(messageCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Time period description
            Text(timeDescription(for: hour))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.1))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func timeDescription(for hour: Int) -> String {
        switch hour {
        case 6..<12: return "Morning person 🌅"
        case 12..<18: return "Afternoon chatter ☀️"
        case 18..<23: return "Evening communicator 🌆"
        default: return "Night owl 🦉"
        }
    }
}

struct ActivityInsightCard: View {
    let period: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 8, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(period)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
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
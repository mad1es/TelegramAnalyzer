import SwiftUI
import Charts

struct GhostingView: View {
    var chat: Chat
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // summary card
                if let topGhoster = chat.topGhoster() {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ghosting.theVanishingAct".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        let totalDays = chat.enhancedGhostingAnalysis().flatMap { $0.ghostingEvents }.count
                        let totalEvents = chat.enhancedGhostingAnalysis().reduce(0) { $0 + $1.ghostingEvents.count }
                        
                        Text(generateGhostingSummary(totalDays: totalDays, totalEvents: totalEvents))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                }
                
                // chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("ghosting.ghostingInstancesPerMonth".localized)
                        .font(.headline)
                        .padding(.horizontal)
                    
                    let chartData = chat.ghostingByMonth()
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
                
                // individual stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("ghosting.ghostingStatistics".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(chat.enhancedGhostingAnalysis(), id: \.sender) { ghostingData in
                        GhostingStatCard(
                            sender: ghostingData.sender,
                            ghostingEvents: ghostingData.ghostingEvents,
                            color: colorForUser(ghostingData.sender),
                            isTopGhoster: chat.topGhoster()?.sender == ghostingData.sender
                        )
                        .padding(.horizontal)
                    }
                }
                
                // definition
                VStack(alignment: .leading, spacing: 8) {
                    Text("ghosting.ghostingDefinition".localized)
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("ghosting.definitionDetailText".localized)
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
        .navigationTitle("Ghosting Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "eye")
                }
            }
        }
    }
    

    
    private func generateGhostingSummary(totalDays: Int, totalEvents: Int) -> String {
        let ghostingData = chat.enhancedGhostingAnalysis()
        
        var summary = "Over \(totalDays) days, there were \(totalEvents) ghosting instances. "
        
        for data in ghostingData {
            let totalHours = data.ghostingEvents.reduce(0) { $0 + $1.duration } / 3600
            let hours = Int(totalHours)
            let minutes = Int((totalHours - Double(hours)) * 60)
            
            let otherSender = chat.senders.first { $0 != data.sender } ?? "other person"
            summary += "\(data.sender) left \(otherSender)'s messages unanswered for \(hours) hours and \(minutes) minutes"
            
            if data.sender != ghostingData.last?.sender {
                summary += ", while "
            } else {
                summary += "."
            }
        }
        
        return summary
    }
}

struct GhostingStatCard: View {
    let sender: String
    let ghostingEvents: [(date: Date, duration: TimeInterval)]
    let color: Color
    let isTopGhoster: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                Text(sender)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if isTopGhoster {
                    Text("ghosting.topGhoster".localized)
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
                    Text("\(ghostingEvents.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("ghosting.ghostEvents".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let totalHours = ghostingEvents.reduce(0) { $0 + $1.duration } / 3600
                    Text(String(format: "%.1f", totalHours))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("ghosting.totalHours".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !ghostingEvents.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ghosting.longestGhost".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let longestGhost = ghostingEvents.max { $0.duration < $1.duration }
                    if let longest = longestGhost {
                        let hours = Int(longest.duration / 3600)
                        let minutes = Int((longest.duration.truncatingRemainder(dividingBy: 3600)) / 60)
                        
                        HStack {
                            Text("\(hours)h \(minutes)m")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(color)
                            
                            Spacer()
                            
                            Text(longest.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color.opacity(0.1))
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isTopGhoster ? color.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
    }
} 

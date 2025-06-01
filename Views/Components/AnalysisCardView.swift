import SwiftUI

struct AnalysisCardView<Content: View>: View {
    let title: String
    let content: () -> Content
    let chart: AnyView
    
    init<ChartContent: View>(title: String, content: @escaping () -> Content, chart: @escaping () -> ChartContent) {
        self.title = title
        self.content = content
        self.chart = AnyView(chart())
    }
    
    init(title: String, content: @escaping () -> Content) {
        self.title = title
        self.content = content
        self.chart = AnyView(EmptyView())
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 16)
                .padding(.horizontal, 16)
            
            if content() is EmptyView == false {
                HStack(alignment: .top) {
                    content()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    
                    chart  
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: Color(.label).opacity(0.05), radius: 5, x: 0, y: 2)
    }
} 
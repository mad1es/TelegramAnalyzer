import SwiftUI

struct HelpView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("How to Export Chat")
                    .font(.title)
                    .bold()

                VStack(alignment: .leading, spacing: 5) {
                    Text("1. Open Telegram")
                    Text("Use only Desktop version of Telegram!")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Text("2. Export chat history as JSON")
                Image("help2")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                Text("3. Use the 'Import Chat' button in this app to select the JSON file")
                
                Spacer()
            }
            .padding()
            .navigationTitle("Help")
        }
    }
} 
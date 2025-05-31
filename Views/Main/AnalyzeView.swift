import SwiftUI

struct AnalyzeView: View {
    @State private var chats: [Chat] = []
    @State private var isShowingPicker = false
    @State private var isShowingHelp = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                // Header
                HStack {
                    Text("Your Chats")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 50)
                        .padding(.leading, 30)
                    Spacer()
                    Button(action: {
                        isShowingHelp = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title)
                    }
                    .padding(.trailing, 20)
                }
                
                // Import Button
                Button(action: {
                    isShowingPicker = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Chat")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 90)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)
                
                if chats.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Chats Imported")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("Import your Telegram chat history to start analyzing your conversations")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    // Chat list
                    List(chats) { chat in
                        NavigationLink(destination: ChatAnalysisView(chat: chat)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chat.name)
                                    .font(.headline)
                                
                                Text("\(chat.totalMessages) messages • \(chat.totalWords) words")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingPicker) {
                DocumentPicker(chats: $chats)
            }
            .sheet(isPresented: $isShowingHelp) {
                HelpView()
            }
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
} 
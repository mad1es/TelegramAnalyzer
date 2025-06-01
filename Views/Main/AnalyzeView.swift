import SwiftUI

struct AnalyzeView: View {
    @State private var chats: [Chat] = []
    @State private var isShowingPicker = false
    @State private var isShowingHelp = false
    @State private var errorMessage: String?
    @State private var showError = false
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // UserDefaults key для сохранения чатов
    private let chatsKey = "savedChats"
    
    // Computed properties to simplify expressions
    private var exportChatText: String {
        return "main.exportChat".localized + " " + "main.telegram".localized
    }
    
    private func chatInfoText(for chat: Chat) -> String {
        let messages = "common.messages".localized.lowercased()
        let words = "common.words".localized.lowercased()
        return "\(chat.totalMessages) \(messages) • \(chat.totalWords) \(words)"
    }
    
    var body: some View {
        NavigationStack {
            mainContent
        }
        .onAppear {
            loadSavedChats()
        }
        .onChange(of: chats) { newValue in
            saveChats()
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(alignment: .leading) {
            headerView
            importButton
            
            if chats.isEmpty {
                emptyStateView
            } else {
                chatListView
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isShowingPicker) {
            DocumentPicker(chats: $chats)
        }
        .sheet(isPresented: $isShowingHelp) {
            HelpView()
        }
        .alert("common.error".localized, isPresented: $showError, presenting: errorMessage) { _ in
            Button("action.confirm".localized, role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("main.selectChat".localized)
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
    }
    
    private var importButton: some View {
        Button(action: {
            isShowingPicker = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("import.selectFile".localized)
                    .font(.title3)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 90)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color("AccentGradientStart"), Color("AccentGradientEnd")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("main.noChats".localized)
                .font(.title2)
                .foregroundColor(.primary)
            
            Text(exportChatText)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var chatListView: some View {
        List {
            ForEach(chats) { chat in
                NavigationLink(destination: ChatAnalysisView(chat: chat)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chat.name)
                            .font(.headline)
                        
                        Text(chatInfoText(for: chat))
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            .onDelete(perform: deleteChat)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Сохранение и загрузка чатов
    
    private func saveChats() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(chats)
            UserDefaults.standard.set(data, forKey: chatsKey)
        } catch {
            print("Failed to save chats: \(error)")
        }
    }
    
    private func loadSavedChats() {
        guard let data = UserDefaults.standard.data(forKey: chatsKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            chats = try decoder.decode([Chat].self, from: data)
        } catch {
            print("Failed to load saved chats: \(error)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func deleteChat(at offsets: IndexSet) {
        chats.remove(atOffsets: offsets)
        saveChats()
    }
} 
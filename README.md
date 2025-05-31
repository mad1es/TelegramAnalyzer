# Telegram Chat Analyzer 📱

An app for analyzing Telegram chats. Helps you understand your communication patterns, who texts more, who responds faster, and much more!

## What can the app do? 

- 📊 Shows who sends more messages
- ⏱️ Analyzes response times
- 👻 Finds "ghosting" moments (when someone didn't respond for a long time)
- 📈 Shows activity by time of day
- 📝 Analyzes message length
- 🎯 Shows who starts conversations more often
- 😊 Counts emoji usage

## How to get started? 🚀

1. Download your chat history from Telegram:
   - Open the chat
   - Click the three dots in the top right corner
   - Select "Export chat"
   - Choose JSON format
   - Save the file

2. Open the app and import the file

3. Select a chat to analyze

4. Check out the cool graphs and stats! 📊

## Technical details for developers 👨‍💻

The app is written in Swift using SwiftUI. Here are the main parts:

### Main files:
- `Models/Chat.swift` - all chat analysis logic
- `Models/Message.swift` - message structure
- `Views/Analysis/` - all screens with graphs and analysis
- `Views/Main/` - main app screens

### How to add new analysis:
1. Create a new file in the `Views/Analysis/` folder
2. Add needed methods to `Chat.swift`
3. Create a nice interface with graphs

## Installation and running 🛠️

1. Clone the repository:
```bash
git clone https://github.com/mad1es/TelegramAnalyzer.git
```

2. Open the project in Xcode

3. Run the app (⌘R)

## What can be improved? 💡

- Add more graphs
- Improve design
- Add sticker analysis
- Add dark theme
- Add results export

## Author 👨‍💻

Made with ❤️ by a student for students

## License 📄

MIT License - do whatever you want with this code! 
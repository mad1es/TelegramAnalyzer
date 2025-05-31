Telegram Chat Analyzer

A lightweight iOS app to analyze Telegram chat exports. Built for curiosity and occasional ego checks.

Features
	•	Message count per participant
	•	Average response time & ghosting detection
	•	Activity heatmap by time of day
	•	Message length stats
	•	Conversation starter tracking
	•	Emoji usage breakdown

How it works
	1.	Export a chat from Telegram (JSON format). Only on Desktop version!!!
	2.	Open the app, import the file
	3.	Select a chat → get stats

That’s it. No setup, no accounts, no BS.

Stack
	•	Swift + SwiftUI
	•	Swift Charts for visualizations
	•	Basic MVVM-ish structure

Project structure

Models/
  Chat.swift         // analysis logic
  Message.swift      // message structure

Views/
  Main/              // app navigation & file import
  Analysis/          // charts and data views

Adding new analysis
	•	Write a new method in Chat.swift
	•	Create a corresponding view in Views/Analysis/
	•	Hook it up in the main screen

Run locally

git clone https://github.com/mad1es/TelegramAnalyzer.git
open TelegramAnalyzer.xcodeproj

TODO (maybe)
	•	Export results (PDF/CSV)
	•	Sticker/sticker pack usage
	•	Dark mode (low priority) // added
	•	Semantic analysis. By using AI
 	

Author

Built by @mad1es.
Student project, but written like it’s not.

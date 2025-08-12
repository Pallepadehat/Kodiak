# 🐻 Kodiak

> Your Personal AI Chat Companion

Kodiak is an elegant, native macOS chat application that brings the power of AI conversation to your desktop. Built with SwiftUI and powered by FoundationModels, Kodiak delivers a seamless, intuitive chat experience with advanced features like weather integration, smart title generation, and a beautiful, animated interface.

## ✨ Features

### 🚀 Core Functionality
- **Intelligent Chat Interface**: Beautiful, responsive chat UI with smooth animations
- **Smart Title Generation**: Automatically generates meaningful titles for your conversations
- **Persistent Chat History**: All your conversations are saved using SwiftData
- **Multiple Chat Management**: Create, organize, and manage multiple chat sessions
- **Real-time Streaming**: Experience fluid, real-time AI responses

### 🌤️ Weather Integration
- **WeatherKit Integration**: Get accurate weather information powered by Apple's WeatherKit
- **Location-based Weather**: Search weather by city name with automatic geocoding
- **Beautiful Weather Cards**: Elegant weather display with condition icons and detailed metrics
- **Smart Caching**: Efficient weather data caching for optimal performance

### 🎨 User Experience
- **Native macOS Design**: Crafted with SwiftUI for perfect macOS integration
- **Animated Typewriter Effect**: Watch chat titles appear with a delightful typewriter animation
- **Haptic Feedback**: Subtle haptic responses for enhanced interaction (configurable)
- **Glass Effect UI**: Modern, translucent interface elements
- **Responsive Design**: Adapts beautifully to different window sizes

### ⚙️ Customization
- **System Prompt Configuration**: Customize AI behavior with personalized system prompts
- **Animation Controls**: Toggle title animations and adjust typing speed
- **Haptic Preferences**: Enable/disable haptic feedback
- **Welcome Suggestions**: Smart conversation starters to get you going

## 🏗️ Architecture

### 📁 Project Structure
```
Kodiak/
├── KodiakApp.swift           # Main app entry point with SwiftData configuration
├── ContentView.swift         # Primary chat interface
├── Models/
│   └── ChatModels.swift      # SwiftData models for Chat and ChatMessage
├── Services/
│   ├── ChatManager.swift     # Core chat management and persistence
│   ├── ModelService.swift    # AI model communication
│   ├── TitleGenerationService.swift  # Intelligent title generation
│   ├── WeatherManager.swift  # Weather data management
│   ├── WeatherTool.swift     # Weather functionality integration
│   ├── WeatherCache.swift    # Weather data caching
│   └── WelcomeSuggestionService.swift  # Smart conversation starters
└── View/
    ├── ChatHistorySheet.swift    # Chat history sidebar
    ├── MarkdownTextView.swift    # Rich text rendering
    ├── MessageView.swift         # Individual message display
    ├── SettingsView.swift        # App preferences
    ├── ToolsSheetView.swift      # Tools and utilities panel
    └── WeatherCardView.swift     # Weather information display
```

### 🔧 Technical Stack
- **Framework**: SwiftUI for native macOS UI
- **Data Persistence**: SwiftData for modern Core Data functionality
- **AI Integration**: FoundationModels for AI communication
- **Weather**: WeatherKit for accurate weather data
- **Location**: CoreLocation for geocoding services
- **Architecture**: MVVM with Observable pattern

## 🚀 Getting Started

### Prerequisites
- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Apple Developer Account (for WeatherKit entitlements)

### Installation
1. Clone or download the project
2. Open `Kodiak.xcodeproj` in Xcode
3. Configure your development team in project settings
4. Ensure WeatherKit entitlement is properly configured
5. Build and run the project

### Configuration
The app uses several configurable settings stored in UserDefaults:
- `systemPrompt`: Customize AI behavior
- `hapticsEnabled`: Toggle haptic feedback
- `animateTitle`: Enable/disable title animations
- `titleTypeSpeed`: Control animation speed

## 🌟 Key Features Deep Dive

### Smart Chat Management
- **Automatic Title Generation**: After the second message, Kodiak intelligently generates descriptive titles for your conversations
- **Persistent Storage**: All chats and messages are automatically saved using SwiftData
- **Chat Organization**: Easy navigation between multiple chat sessions via the sidebar

### Weather Integration
The weather system leverages Apple's WeatherKit for accurate, real-time weather data:
- City-based searches with intelligent geocoding
- Current conditions with detailed metrics (temperature, humidity, condition)
- Beautiful weather cards with Apple's SF Symbols weather icons
- Efficient caching to minimize API calls

### User Interface Excellence
- **Smooth Animations**: Every interaction is carefully animated for delightful UX
- **Typewriter Effect**: Watch chat titles appear character by character
- **Glass Effects**: Modern translucent UI elements throughout
- **Responsive Layout**: Adapts to different window sizes and orientations

## 🛠️ Development

### Code Style
- Swift 5.9+ with modern concurrency (async/await)
- SwiftUI declarative UI patterns
- MVVM architecture with @Observable
- Comprehensive error handling
- Clean, well-documented code

### Key Components
- **LMModel**: Handles AI communication and session management
- **ChatManager**: Manages chat persistence and organization
- **WeatherManager**: Handles all weather-related functionality
- **TitleGenerationService**: Generates intelligent chat titles

## 🔐 Privacy & Security

Kodiak is designed with privacy in mind:
- All chat data is stored locally on your device
- No data is transmitted to third parties (except for AI and weather services)
- Weather data includes location services usage with user consent
- Open source codebase for complete transparency

## 🎯 Future Roadmap

- [ ] Enhanced markdown rendering with syntax highlighting
- [ ] Export conversations to various formats
- [ ] Plugin system for extended functionality
- [ ] Custom themes and appearance options
- [ ] Integration with additional AI models
- [ ] Advanced search across chat history

## 📄 License

This project is closed source and proprietary. All rights reserved.

---

Built with ❤️ by Patrick Jakobsen using SwiftUI and the power of modern Apple frameworks.

*Kodiak - Where conversations come alive.*
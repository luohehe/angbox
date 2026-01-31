# CLAUDE.md

This file provides guidance for AI assistants working with this repository.

## Project Overview

**angbox** is a personal playground repository for experimentation and testing. It contains the following projects:

### GolfSwingAnalyzer
An iOS app that helps golfers record, analyze, and improve their swings using AI-powered pose detection with Apple's Vision framework.

## Repository Structure

```
angbox/
├── README.md                      # Repository description
├── CLAUDE.md                      # AI assistant guidance (this file)
└── GolfSwingAnalyzer/             # iOS Golf Swing Analysis App
    ├── README.md                  # Project documentation
    └── GolfSwingAnalyzer/
        ├── GolfSwingAnalyzerApp.swift    # App entry point
        ├── ContentView.swift              # Main tab view
        ├── Info.plist                     # App configuration
        ├── Assets.xcassets/               # App icons and colors
        ├── Models/
        │   ├── SwingData.swift            # Data models
        │   └── SwingStore.swift           # State management
        ├── Services/
        │   ├── CameraService.swift        # Video recording
        │   └── SwingAnalysisService.swift # AI analysis
        └── Views/
            ├── Recording/RecordingView.swift
            ├── Analysis/AnalysisView.swift
            ├── History/HistoryView.swift
            └── SettingsView.swift
```

## Projects

### GolfSwingAnalyzer (iOS)

**Language:** Swift 5.9+ with SwiftUI
**Platform:** iOS 17.0+
**Frameworks:** AVFoundation, Vision, AVKit

#### Key Features
- Video recording of golf swings
- AI-powered pose detection and analysis
- Swing phase scoring (address, backswing, top, downswing, impact, follow-through)
- Detailed metrics (hip/shoulder rotation, tempo, swing plane, balance)
- Actionable feedback and improvement suggestions
- Swing history with progress tracking

#### Architecture
- **MVVM pattern** with SwiftUI
- **Models**: `SwingData`, `SwingAnalysis`, `SwingPhases`, `SwingMetrics`, `SwingFeedback`
- **Services**: `CameraService` (AVFoundation), `SwingAnalysisService` (Vision framework)
- **Views**: Tab-based navigation (Record, History, Settings)

#### Commands
```bash
# Open in Xcode
open GolfSwingAnalyzer.xcodeproj

# Build from command line (after creating Xcode project)
xcodebuild -scheme GolfSwingAnalyzer -destination 'platform=iOS Simulator,name=iPhone 15'
```

#### Setup Instructions
1. Open Xcode and create new iOS App project named "GolfSwingAnalyzer"
2. Copy all Swift files from `GolfSwingAnalyzer/GolfSwingAnalyzer/` into the project
3. Add `Assets.xcassets` contents
4. Update `Info.plist` with camera/microphone usage descriptions
5. Build and run on physical device (camera required)

## Development Guidelines

### General Conventions
- Keep experiments self-contained in dedicated directories
- Include a README for each project
- Document any new tools or frameworks added

### Git Workflow
- Create feature branches for new experiments
- Write clear commit messages describing changes
- The main branch should remain stable

### Swift/iOS Conventions (for GolfSwingAnalyzer)
- Use SwiftUI for all UI components
- Follow MVVM architecture pattern
- Use `@MainActor` for UI-bound classes
- Use Swift concurrency (`async/await`) for asynchronous operations
- Keep Views focused; extract components when complexity grows

## Notes for AI Assistants

- This is a playground repository - experimentation is encouraged
- When adding code, follow best practices for the language being used
- Keep changes focused and well-documented
- If introducing new tools or frameworks, update this file accordingly
- For iOS projects, ensure proper permission descriptions in Info.plist
- Test on physical devices when camera/sensors are involved

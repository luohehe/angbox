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
├── .github/
│   └── workflows/
│       └── ios-ci.yml             # CI/CD pipeline
└── GolfSwingAnalyzer/             # iOS Golf Swing Analysis App
    ├── README.md                  # Project documentation
    ├── .swiftlint.yml             # SwiftLint configuration
    ├── GolfSwingAnalyzer/
    │   ├── GolfSwingAnalyzerApp.swift    # App entry point
    │   ├── ContentView.swift              # Main tab view
    │   ├── Info.plist                     # App configuration
    │   ├── Assets.xcassets/               # App icons and colors
    │   ├── Models/
    │   │   ├── SwingData.swift            # Data models
    │   │   └── SwingStore.swift           # State management
    │   ├── Services/
    │   │   ├── CameraService.swift        # Video recording
    │   │   └── SwingAnalysisService.swift # AI analysis
    │   └── Views/
    │       ├── Recording/RecordingView.swift
    │       ├── Analysis/AnalysisView.swift
    │       ├── History/HistoryView.swift
    │       └── SettingsView.swift
    └── GolfSwingAnalyzerTests/
        ├── SwingDataTests.swift           # Model unit tests
        ├── SwingStoreTests.swift          # Store unit tests
        └── SwingAnalysisServiceTests.swift # Service unit tests
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
open GolfSwingAnalyzer/GolfSwingAnalyzer.xcodeproj

# Build from command line
xcodebuild build \
  -project GolfSwingAnalyzer/GolfSwingAnalyzer.xcodeproj \
  -scheme GolfSwingAnalyzer \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run unit tests
xcodebuild test \
  -project GolfSwingAnalyzer/GolfSwingAnalyzer.xcodeproj \
  -scheme GolfSwingAnalyzer \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run SwiftLint
cd GolfSwingAnalyzer && swiftlint lint
```

#### Setup Instructions
1. Open Xcode and create new iOS App project named "GolfSwingAnalyzer"
2. Copy all Swift files from `GolfSwingAnalyzer/GolfSwingAnalyzer/` into the project
3. Add test files from `GolfSwingAnalyzer/GolfSwingAnalyzerTests/` to test target
4. Add `Assets.xcassets` contents
5. Update `Info.plist` with camera/microphone usage descriptions
6. Build and run on physical device (camera required)

## Testing

### Unit Tests

The project includes comprehensive unit tests in `GolfSwingAnalyzerTests/`:

| Test File | Coverage |
|-----------|----------|
| `SwingDataTests.swift` | Model structs, Codable conformance, score grades/colors |
| `SwingStoreTests.swift` | CRUD operations, persistence, statistics calculations |
| `SwingAnalysisServiceTests.swift` | Constants, error types, ScoreColorHelper |

#### Running Tests

```bash
# Via Xcode
# Press Cmd+U or Product > Test

# Via command line
xcodebuild test \
  -project GolfSwingAnalyzer/GolfSwingAnalyzer.xcodeproj \
  -scheme GolfSwingAnalyzer \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -resultBundlePath TestResults.xcresult
```

#### Test Coverage Areas
- **Models**: Initialization, encoding/decoding, computed properties
- **SwingStore**: Add/update/delete swings, persistence, statistics
- **SwingAnalysisService**: Error handling, constants validation
- **ScoreColorHelper**: Color mapping for all score ranges

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/ios-ci.yml`) runs on every commit:

### Pipeline Jobs

| Job | Description |
|-----|-------------|
| `build-and-test` | Builds the app and runs all unit tests |
| `lint` | Runs SwiftLint for code style checks |
| `code-analysis` | Checks for common issues (force unwraps, TODOs, print statements) |

### Triggers
- Push to `main` or `master` branches
- Pull requests targeting `main` or `master`
- Only runs when `GolfSwingAnalyzer/**` files change

### Artifacts
- Test results are uploaded as artifacts (retained 7 days)

## Code Quality

### SwiftLint
Configuration in `GolfSwingAnalyzer/.swiftlint.yml`:
- Enforces consistent code style
- Warns on force unwraps, force casts, force try
- Checks for unused code and imports
- Custom rule to discourage print statements

### Best Practices Enforced
- Use constants for magic numbers (`AnalysisConstants`)
- Consolidate shared logic (`ScoreColorHelper`)
- Proper error handling with custom error types
- Static formatters for performance
- MainActor isolation for UI code
- Proper memory management (weak references, cleanup methods)

## Development Guidelines

### General Conventions
- Keep experiments self-contained in dedicated directories
- Include a README for each project
- Document any new tools or frameworks added

### Git Workflow
- Create feature branches for new experiments
- Write clear commit messages describing changes
- The main branch should remain stable
- **All commits trigger CI/CD tests**

### Swift/iOS Conventions (for GolfSwingAnalyzer)
- Use SwiftUI for all UI components
- Follow MVVM architecture pattern
- Use `@MainActor` for UI-bound classes
- Use Swift concurrency (`async/await`) for asynchronous operations
- Keep Views focused; extract components when complexity grows
- Write unit tests for new functionality
- Use constants instead of magic numbers

## Notes for AI Assistants

- This is a playground repository - experimentation is encouraged
- When adding code, follow best practices for the language being used
- Keep changes focused and well-documented
- If introducing new tools or frameworks, update this file accordingly
- For iOS projects, ensure proper permission descriptions in Info.plist
- Test on physical devices when camera/sensors are involved
- **Always run tests before committing changes**
- **Add unit tests for new functionality**
- Follow the existing code style (see `.swiftlint.yml`)

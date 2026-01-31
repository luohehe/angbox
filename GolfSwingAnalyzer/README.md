# Golf Swing Analyzer

An iOS app that helps golfers record, analyze, and improve their swings using AI-powered pose detection.

## Features

- **Video Recording**: Record your golf swing with the device camera
- **AI Analysis**: Automatic swing analysis using Apple's Vision framework for human body pose detection
- **Swing Scoring**: Get an overall score (0-100) with detailed phase-by-phase breakdown
- **Detailed Feedback**: Receive actionable feedback and suggestions for improvement
- **Swing History**: Track your progress over time with historical analysis

## Screenshots

The app includes three main screens:
1. **Record** - Capture your golf swing with on-screen tips
2. **History** - View all recorded swings with scores and trends
3. **Settings** - Configure recording and analysis preferences

## Requirements

- iOS 17.0+
- iPhone with camera
- Xcode 15.0+

## Installation

1. Clone the repository
2. Open `GolfSwingAnalyzer.xcodeproj` in Xcode (create via File > New > Project)
3. Add all Swift files to the project
4. Build and run on your device (camera requires physical device)

## Project Structure

```
GolfSwingAnalyzer/
├── GolfSwingAnalyzerApp.swift    # App entry point
├── ContentView.swift              # Main tab view
├── Models/
│   ├── SwingData.swift           # Data models for swing analysis
│   └── SwingStore.swift          # State management for swings
├── Services/
│   ├── CameraService.swift       # Camera and video recording
│   └── SwingAnalysisService.swift # AI-powered swing analysis
├── Views/
│   ├── Recording/
│   │   └── RecordingView.swift   # Camera recording interface
│   ├── Analysis/
│   │   └── AnalysisView.swift    # Swing analysis results
│   ├── History/
│   │   └── HistoryView.swift     # Swing history list
│   └── SettingsView.swift        # App settings
├── Assets.xcassets/              # App icons and colors
└── Info.plist                    # App configuration
```

## How It Works

### Recording
The app uses AVFoundation to capture video of your golf swing. Position your phone at hip height to capture your full body during the swing.

### Analysis
The app uses Apple's Vision framework (`VNDetectHumanBodyPoseRequest`) to:
1. Extract body pose keypoints from each video frame
2. Track body position throughout the swing phases
3. Calculate metrics like hip rotation, shoulder rotation, and tempo
4. Generate scores for each swing phase

### Swing Phases Analyzed
1. **Address** - Setup position and posture
2. **Backswing** - Takeaway and rotation
3. **Top** - Position at the top of the swing
4. **Downswing** - Transition and sequencing
5. **Impact** - Contact position
6. **Follow Through** - Finish position

### Metrics Tracked
- Hip rotation (degrees)
- Shoulder rotation (degrees)
- Spine angle (degrees)
- Tempo (backswing:downswing ratio)
- Swing plane quality
- Balance assessment

## Privacy

- All video processing happens on-device
- Videos are stored locally in the app's documents directory
- No data is sent to external servers

## Future Enhancements

- [ ] Import videos from photo library
- [ ] Slow-motion playback with frame-by-frame analysis
- [ ] Side-by-side comparison with professional swings
- [ ] Export analysis reports
- [ ] Club detection and swing type classification
- [ ] Integration with Apple Watch for additional metrics

## License

This project is for personal/educational use.

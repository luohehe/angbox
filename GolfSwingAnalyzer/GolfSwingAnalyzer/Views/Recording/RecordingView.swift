import SwiftUI
import AVFoundation

struct RecordingView: View {
    @EnvironmentObject var swingStore: SwingStore
    @StateObject private var cameraService = CameraService()
    @State private var showAnalysis = false
    @State private var currentSwing: SwingData?
    @State private var permissionGranted = false
    @State private var showPermissionAlert = false
    @State private var showGuideOverlay = true

    var body: some View {
        NavigationStack {
            ZStack {
                if permissionGranted {
                    // Camera Preview
                    CameraPreviewView(cameraService: cameraService)
                        .ignoresSafeArea()

                    // Guide Overlay
                    if showGuideOverlay && !cameraService.isRecording {
                        SwingGuideOverlay()
                    }

                    // Recording Controls
                    VStack {
                        // Top Bar
                        RecordingTopBar(
                            showGuide: $showGuideOverlay,
                            isRecording: cameraService.isRecording
                        )

                        Spacer()

                        // Recording Status
                        if cameraService.isRecording {
                            RecordingStatusBadge(duration: cameraService.recordingDuration)
                                .padding(.bottom, AppSpacing.lg)
                                .transition(.scale.combined(with: .opacity))
                        }

                        // Bottom Controls
                        RecordingControlsBar(
                            isRecording: cameraService.isRecording,
                            onRecord: {
                                withAnimation(.spring(response: 0.3)) {
                                    if cameraService.isRecording {
                                        cameraService.stopRecording()
                                    } else {
                                        cameraService.startRecording()
                                    }
                                }
                            }
                        )
                        .padding(.bottom, AppSpacing.xl)
                    }
                } else {
                    CameraPermissionView {
                        Task {
                            permissionGranted = await cameraService.requestPermissions()
                            if permissionGranted {
                                try? await cameraService.setupCamera()
                                cameraService.startSession()
                            } else {
                                showPermissionAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Record Swing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: cameraService.recordedVideoURL) { _, newURL in
                if let url = newURL {
                    let swing = SwingData(videoURL: url, duration: cameraService.recordingDuration)
                    currentSwing = swing
                    swingStore.addSwing(swing)
                    showAnalysis = true
                }
            }
            .sheet(isPresented: $showAnalysis) {
                if let swing = currentSwing {
                    AnalysisView(swing: swing)
                        .environmentObject(swingStore)
                }
            }
            .alert("Camera Permission Required", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable camera access in Settings to record your golf swing.")
            }
            .task {
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                if status == .authorized {
                    permissionGranted = true
                    try? await cameraService.setupCamera()
                    cameraService.startSession()
                }
            }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        if let previewLayer = cameraService.getPreviewLayer() {
            previewLayer.frame = UIScreen.main.bounds
            view.layer.addSublayer(previewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraService.getPreviewLayer() {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Top Bar
struct RecordingTopBar: View {
    @Binding var showGuide: Bool
    let isRecording: Bool

    var body: some View {
        HStack {
            // Guide Toggle
            Button(action: { showGuide.toggle() }) {
                Image(systemName: showGuide ? "person.fill.viewfinder" : "person.viewfinder")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .padding(AppSpacing.sm)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .disabled(isRecording)
            .opacity(isRecording ? 0.5 : 1)

            Spacer()

            // Tips Button
            TipsButton()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }
}

// MARK: - Swing Guide Overlay
struct SwingGuideOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Vertical center line
                Rectangle()
                    .fill(Color.golfGreen.opacity(0.5))
                    .frame(width: 2)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                // Body outline guide
                Image(systemName: "figure.golf")
                    .font(.system(size: 200, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.2))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 40)

                // Guide text
                VStack {
                    Spacer()
                    Text("Align your stance with the guide")
                        .font(AppTypography.caption1)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(.ultraThinMaterial)
                        .cornerRadius(AppCornerRadius.small)
                        .padding(.bottom, 140)
                }
            }
        }
    }
}

// MARK: - Recording Status Badge
struct RecordingStatusBadge: View {
    let duration: TimeInterval
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)

            Text("REC")
                .font(AppTypography.caption1)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(formatDuration(duration))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(Color.red.opacity(0.9))
        .cornerRadius(AppCornerRadius.circular)
        .onAppear { isAnimating = true }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Recording Controls Bar
struct RecordingControlsBar: View {
    let isRecording: Bool
    let onRecord: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.xxl) {
            // Gallery Button
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 24))
                    Text("Gallery")
                        .font(AppTypography.caption2)
                }
                .foregroundColor(.white)
            }
            .opacity(isRecording ? 0.3 : 1)
            .disabled(isRecording)

            // Record Button
            RecordButtonPro(isRecording: isRecording, action: onRecord)

            // Flip Camera Button
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "camera.rotate")
                        .font(.system(size: 24))
                    Text("Flip")
                        .font(AppTypography.caption2)
                }
                .foregroundColor(.white)
            }
            .opacity(isRecording ? 0.3 : 1)
            .disabled(isRecording)
        }
    }
}

// MARK: - Professional Record Button
struct RecordButtonPro: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 84, height: 84)

                // Inner shape
                Group {
                    if isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 32, height: 32)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 68, height: 68)
                    }
                }
                .animation(.spring(response: 0.3), value: isRecording)
            }
        }
        .scaleEffect(isRecording ? 0.95 : 1.0)
        .animation(.spring(response: 0.2), value: isRecording)
    }
}

// MARK: - Tips Button
struct TipsButton: View {
    @State private var showTips = false

    var body: some View {
        Button(action: { showTips.toggle() }) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.yellow)
                .padding(AppSpacing.sm)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .popover(isPresented: $showTips) {
            RecordingTipsPopover()
                .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Tips Popover
struct RecordingTipsPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recording Tips")
                    .font(AppTypography.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                TipItemRow(icon: "camera.viewfinder", text: "Position camera at hip height", color: .golfGreen)
                TipItemRow(icon: "figure.stand", text: "Ensure full body is visible", color: .golfGreen)
                TipItemRow(icon: "sun.max.fill", text: "Use good lighting conditions", color: .orange)
                TipItemRow(icon: "arrow.left.and.right", text: "Film from down-the-line or face-on", color: .blue)
                TipItemRow(icon: "timer", text: "Record 3-5 second swings", color: .purple)
            }
        }
        .padding(AppSpacing.md)
        .frame(width: 280)
    }
}

struct TipItemRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(AppTypography.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Permission View
struct CameraPermissionView: View {
    let onRequest: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.golfGreen.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "video.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.golfGreen)
            }

            // Text
            VStack(spacing: AppSpacing.sm) {
                Text("Camera Access Required")
                    .font(AppTypography.title2)
                    .foregroundColor(.primary)

                Text("To record and analyze your golf swing, we need access to your camera and microphone.")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            // Button
            Button(action: onRequest) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Enable Camera Access")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            // Privacy note
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 12))
                Text("Videos are stored locally and never uploaded")
                    .font(AppTypography.caption2)
            }
            .foregroundColor(.secondary)
            .padding(.bottom, AppSpacing.lg)
        }
        .background(Color.backgroundPrimary)
    }
}

#Preview {
    RecordingView()
        .environmentObject(SwingStore())
}

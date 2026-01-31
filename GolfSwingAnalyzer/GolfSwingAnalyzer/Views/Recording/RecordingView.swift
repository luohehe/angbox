import SwiftUI
import AVFoundation

struct RecordingView: View {
    @EnvironmentObject var swingStore: SwingStore
    @StateObject private var cameraService = CameraService()
    @State private var showAnalysis = false
    @State private var currentSwing: SwingData?
    @State private var permissionGranted = false
    @State private var showPermissionAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                if permissionGranted {
                    CameraPreviewView(cameraService: cameraService)
                        .ignoresSafeArea()

                    VStack {
                        Spacer()

                        if cameraService.isRecording {
                            RecordingIndicator(duration: cameraService.recordingDuration)
                                .padding(.bottom, 20)
                        }

                        HStack(spacing: 60) {
                            Button(action: {}) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }

                            RecordButton(isRecording: cameraService.isRecording) {
                                if cameraService.isRecording {
                                    cameraService.stopRecording()
                                } else {
                                    cameraService.startRecording()
                                }
                            }

                            Button(action: {}) {
                                Image(systemName: "arrow.triangle.2.circlepath.camera")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.bottom, 40)
                    }

                    VStack {
                        HStack {
                            Spacer()
                            TipsOverlay()
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    PermissionRequestView {
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

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)

                if isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red)
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 64, height: 64)
                }
            }
        }
    }
}

struct RecordingIndicator: View {
    let duration: TimeInterval

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)

            Text(formatDuration(duration))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

struct TipsOverlay: View {
    @State private var showTips = false

    var body: some View {
        Button(action: { showTips.toggle() }) {
            Image(systemName: "questionmark.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
        }
        .popover(isPresented: $showTips) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recording Tips")
                    .font(.headline)

                TipRow(icon: "camera.viewfinder", text: "Position camera at hip height")
                TipRow(icon: "figure.stand", text: "Ensure full body is visible")
                TipRow(icon: "sun.max", text: "Use good lighting")
                TipRow(icon: "arrow.left.and.right", text: "Record from down-the-line or face-on")
            }
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct PermissionRequestView: View {
    let onRequest: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("To record and analyze your golf swing, we need access to your camera.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onRequest) {
                Text("Enable Camera")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    RecordingView()
        .environmentObject(SwingStore())
}

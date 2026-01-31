import AVFoundation
import SwiftUI
import Combine

// MARK: - Camera Constants
private enum CameraConstants {
    static let timerInterval: TimeInterval = 0.1
    static let preferredFrameRate: Int32 = 30
}

@MainActor
class CameraService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordedVideoURL: URL?
    @Published var error: CameraError?
    @Published var recordingDuration: TimeInterval = 0

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var recordingTimer: Timer?
    private let sessionQueue = DispatchQueue(label: "com.golfswing.camera.session")

    enum CameraError: LocalizedError {
        case cameraUnavailable
        case cannotAddInput
        case cannotAddOutput
        case recordingFailed(String)
        case audioSessionFailed(String)

        var errorDescription: String? {
            switch self {
            case .cameraUnavailable:
                return "Camera is not available"
            case .cannotAddInput:
                return "Cannot add camera input"
            case .cannotAddOutput:
                return "Cannot add video output"
            case .recordingFailed(let message):
                return "Recording failed: \(message)"
            case .audioSessionFailed(let message):
                return "Audio session failed: \(message)"
            }
        }
    }

    override init() {
        super.init()
    }

    func setupCamera() async throws {
        // Configure audio session first
        try configureAudioSession()

        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.cameraUnavailable
        }

        do {
            // Configure camera device
            try configureCamera(camera)

            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                throw CameraError.cannotAddInput
            }

            if let microphone = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: microphone),
               session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }

            let output = AVCaptureMovieFileOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.videoOutput = output
            } else {
                throw CameraError.cannotAddOutput
            }

            self.captureSession = session
        } catch let error as CameraError {
            throw error
        } catch {
            throw CameraError.recordingFailed(error.localizedDescription)
        }
    }

    private func configureAudioSession() throws {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw CameraError.audioSessionFailed(error.localizedDescription)
        }
    }

    private func configureCamera(_ camera: AVCaptureDevice) throws {
        try camera.lockForConfiguration()
        defer { camera.unlockForConfiguration() }

        // Set frame rate
        if let range = camera.activeFormat.videoSupportedFrameRateRanges.first {
            let targetFrameRate = min(Double(CameraConstants.preferredFrameRate), range.maxFrameRate)
            camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFrameRate))
            camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFrameRate))
        }

        // Enable continuous autofocus and auto exposure
        if camera.isFocusModeSupported(.continuousAutoFocus) {
            camera.focusMode = .continuousAutoFocus
        }
        if camera.isExposureModeSupported(.continuousAutoExposure) {
            camera.exposureMode = .continuousAutoExposure
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    func cleanup() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        stopSession()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }

        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            previewLayer = layer
        }

        return previewLayer
    }

    func startRecording() {
        guard let output = videoOutput, !output.isRecording else { return }

        let outputURL = generateOutputURL()
        output.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
        recordingDuration = 0

        recordingTimer = Timer.scheduledTimer(withTimeInterval: CameraConstants.timerInterval, repeats: true) { [weak self] _ in
            self?.recordingDuration += CameraConstants.timerInterval
        }
    }

    func stopRecording() {
        guard let output = videoOutput, output.isRecording else { return }

        output.stopRecording()
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func generateOutputURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "swing_\(Date().timeIntervalSince1970).mov"
        return documentsPath.appendingPathComponent(fileName)
    }

    func requestPermissions() async -> Bool {
        let videoStatus = await AVCaptureDevice.requestAccess(for: .video)
        let audioStatus = await AVCaptureDevice.requestAccess(for: .audio)
        return videoStatus && audioStatus
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task { @MainActor in
            self.isRecording = false

            if let error = error {
                self.error = .recordingFailed(error.localizedDescription)
            } else {
                self.recordedVideoURL = outputFileURL
            }
        }
    }

    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        Task { @MainActor in
            self.isRecording = true
        }
    }
}

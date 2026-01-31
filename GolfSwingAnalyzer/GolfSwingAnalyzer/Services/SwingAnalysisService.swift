import Vision
import AVFoundation
import CoreImage
import UIKit

// MARK: - Analysis Constants
enum AnalysisConstants {
    static let minPoseConfidence: Float = 0.3
    static let analysisFrameRate: Double = 15 // Reduced from 30 for better performance
    static let shoulderLevelTolerance: CGFloat = 0.05
    static let hipLevelTolerance: CGFloat = 0.05
    static let hipOverAnkleTolerance: CGFloat = 0.1
    static let shoulderOverHipTolerance: CGFloat = 0.15
    static let minShoulderRotationGood: Double = 20
    static let minShoulderRotationExcellent: Double = 30
    static let hipRotationFollow: CGFloat = 0.05
    static let minFramesRequired = 10
    static let defaultPhaseScore = 70
    static let basePhaseScore = 75
}

// MARK: - Analysis Errors
enum SwingAnalysisError: LocalizedError {
    case videoFileNotFound
    case invalidVideoDuration
    case insufficientPoseData
    case analysisTimeout

    var errorDescription: String? {
        switch self {
        case .videoFileNotFound:
            return "Video file not found"
        case .invalidVideoDuration:
            return "Invalid video duration"
        case .insufficientPoseData:
            return "Could not detect enough pose data"
        case .analysisTimeout:
            return "Analysis took too long"
        }
    }
}

actor SwingAnalysisService {
    private lazy var poseRequest = VNDetectHumanBodyPoseRequest()
    private var framesPoses: [FramePose] = []

    func analyzeSwing(
        videoURL: URL,
        progressHandler: @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> SwingAnalysis {
        // Validate file exists
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw SwingAnalysisError.videoFileNotFound
        }

        framesPoses = []

        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        guard durationSeconds > 0 else {
            throw SwingAnalysisError.invalidVideoDuration
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let frameRate = AnalysisConstants.analysisFrameRate
        let totalFrames = Int(durationSeconds * frameRate)

        for frameIndex in 0..<totalFrames {
            let time = CMTime(seconds: Double(frameIndex) / frameRate, preferredTimescale: 600)

            do {
                let (image, _) = try await generator.image(at: time)
                let ciImage = CIImage(cgImage: image)

                if let pose = try await detectPose(in: ciImage) {
                    let framePose = FramePose(
                        timestamp: CMTimeGetSeconds(time),
                        keypoints: pose
                    )
                    framesPoses.append(framePose)
                }
            } catch {
                // Log but continue - some frames may fail
                continue
            }

            let progress = Double(frameIndex + 1) / Double(totalFrames)
            await progressHandler(progress)
        }

        guard framesPoses.count >= AnalysisConstants.minFramesRequired else {
            throw SwingAnalysisError.insufficientPoseData
        }

        return generateAnalysis()
    }

    private func detectPose(in image: CIImage) async throws -> [PoseKeypoint]? {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform([poseRequest])

        guard let observation = poseRequest.results?.first else { return nil }

        var keypoints: [PoseKeypoint] = []

        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .neck,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]

        for jointName in jointNames {
            if let point = try? observation.recognizedPoint(jointName),
               point.confidence > AnalysisConstants.minPoseConfidence {
                let keypoint = PoseKeypoint(
                    name: jointName.rawValue.rawValue,
                    position: CGPoint(x: point.location.x, y: 1 - point.location.y),
                    confidence: point.confidence
                )
                keypoints.append(keypoint)
            }
        }

        return keypoints.isEmpty ? nil : keypoints
    }

    private func generateAnalysis() -> SwingAnalysis {
        let phases = analyzePhases()
        let metrics = calculateMetrics()
        let feedback = generateFeedback(phases: phases, metrics: metrics)

        let phaseScores = [
            phases.addressScore,
            phases.backswingScore,
            phases.topScore,
            phases.downswingScore,
            phases.impactScore,
            phases.followThroughScore
        ]
        let overallScore = phaseScores.reduce(0, +) / phaseScores.count

        return SwingAnalysis(
            overallScore: overallScore,
            phases: phases,
            feedback: feedback,
            keyMetrics: metrics
        )
    }

    // MARK: - Helper for Keypoint Lookup
    private func keypointMap(from pose: FramePose) -> [String: PoseKeypoint] {
        Dictionary(uniqueKeysWithValues: pose.keypoints.map { ($0.name, $0) })
    }

    private func analyzePhases() -> SwingPhases {
        guard framesPoses.count > AnalysisConstants.minFramesRequired else {
            return SwingPhases(
                addressScore: AnalysisConstants.defaultPhaseScore,
                backswingScore: AnalysisConstants.defaultPhaseScore,
                topScore: AnalysisConstants.defaultPhaseScore,
                downswingScore: AnalysisConstants.defaultPhaseScore,
                impactScore: AnalysisConstants.defaultPhaseScore,
                followThroughScore: AnalysisConstants.defaultPhaseScore
            )
        }

        return SwingPhases(
            addressScore: analyzeAddress(),
            backswingScore: analyzeBackswing(),
            topScore: analyzeTopPosition(),
            downswingScore: analyzeDownswing(),
            impactScore: analyzeImpact(),
            followThroughScore: analyzeFollowThrough()
        )
    }

    private func analyzeAddress() -> Int {
        guard let firstPose = framesPoses.first else {
            return AnalysisConstants.defaultPhaseScore
        }

        let kp = keypointMap(from: firstPose)
        var score = AnalysisConstants.basePhaseScore

        // Check shoulder level
        if let leftShoulder = kp["left_shoulder_1_joint"],
           let rightShoulder = kp["right_shoulder_1_joint"] {
            let shoulderLevel = abs(leftShoulder.position.y - rightShoulder.position.y)
            if shoulderLevel < AnalysisConstants.shoulderLevelTolerance {
                score += 10
            }
        }

        // Check hip level
        if let leftHip = kp["left_upLeg_joint"],
           let rightHip = kp["right_upLeg_joint"] {
            let hipLevel = abs(leftHip.position.y - rightHip.position.y)
            if hipLevel < AnalysisConstants.hipLevelTolerance {
                score += 10
            }
        }

        return min(100, max(0, score))
    }

    private func analyzeBackswing() -> Int {
        let backswingFrames = framesPoses.prefix(framesPoses.count / 3)
        guard backswingFrames.count > 3 else {
            return AnalysisConstants.defaultPhaseScore
        }

        var score = AnalysisConstants.basePhaseScore
        var maxShoulderRotation: Double = 0

        for frame in backswingFrames {
            let kp = keypointMap(from: frame)
            if let leftShoulder = kp["left_shoulder_1_joint"],
               let rightShoulder = kp["right_shoulder_1_joint"] {
                let dx = rightShoulder.position.x - leftShoulder.position.x
                let dy = rightShoulder.position.y - leftShoulder.position.y
                let angle = abs(atan2(dy, dx) * 180 / .pi)
                maxShoulderRotation = max(maxShoulderRotation, angle)
            }
        }

        if maxShoulderRotation > AnalysisConstants.minShoulderRotationExcellent {
            score += 15
        } else if maxShoulderRotation > AnalysisConstants.minShoulderRotationGood {
            score += 10
        }

        return min(100, max(0, score))
    }

    private func analyzeTopPosition() -> Int {
        let topIndex = framesPoses.count / 3
        guard topIndex < framesPoses.count else {
            return AnalysisConstants.defaultPhaseScore
        }

        let kp = keypointMap(from: framesPoses[topIndex])
        var score = AnalysisConstants.basePhaseScore

        if let leftWrist = kp["left_hand_joint"],
           let leftShoulder = kp["left_shoulder_1_joint"] {
            if leftWrist.position.y < leftShoulder.position.y {
                score += 15
            }
        }

        return min(100, max(0, score))
    }

    private func analyzeDownswing() -> Int {
        let startIndex = framesPoses.count / 3
        let endIndex = 2 * framesPoses.count / 3
        guard startIndex < endIndex, endIndex < framesPoses.count else {
            return AnalysisConstants.defaultPhaseScore
        }

        var score = AnalysisConstants.basePhaseScore
        let downswingFrames = Array(framesPoses[startIndex..<endIndex])
        var hipLeadsShoulders = 0

        for frame in downswingFrames {
            let kp = keypointMap(from: frame)
            if let leftHip = kp["left_upLeg_joint"],
               let rightHip = kp["right_upLeg_joint"],
               let leftShoulder = kp["left_shoulder_1_joint"],
               let rightShoulder = kp["right_shoulder_1_joint"] {

                let hipAngle = atan2(
                    rightHip.position.y - leftHip.position.y,
                    rightHip.position.x - leftHip.position.x
                )
                let shoulderAngle = atan2(
                    rightShoulder.position.y - leftShoulder.position.y,
                    rightShoulder.position.x - leftShoulder.position.x
                )

                if abs(hipAngle) > abs(shoulderAngle) {
                    hipLeadsShoulders += 1
                }
            }
        }

        if hipLeadsShoulders > downswingFrames.count / 2 {
            score += 15
        }

        return min(100, max(0, score))
    }

    private func analyzeImpact() -> Int {
        let impactIndex = 2 * framesPoses.count / 3
        guard impactIndex < framesPoses.count else {
            return AnalysisConstants.defaultPhaseScore
        }

        let kp = keypointMap(from: framesPoses[impactIndex])
        var score = AnalysisConstants.basePhaseScore

        if let leftHip = kp["left_upLeg_joint"],
           let leftShoulder = kp["left_shoulder_1_joint"],
           let leftAnkle = kp["left_foot_joint"] {

            let hipOverAnkle = abs(leftHip.position.x - leftAnkle.position.x) < AnalysisConstants.hipOverAnkleTolerance
            if hipOverAnkle {
                score += 10
            }

            let shoulderOverHip = abs(leftShoulder.position.x - leftHip.position.x) < AnalysisConstants.shoulderOverHipTolerance
            if shoulderOverHip {
                score += 10
            }
        }

        return min(100, max(0, score))
    }

    private func analyzeFollowThrough() -> Int {
        let followThroughFrames = framesPoses.suffix(framesPoses.count / 4)
        guard followThroughFrames.count > 2 else {
            return AnalysisConstants.defaultPhaseScore
        }

        var score = AnalysisConstants.basePhaseScore

        if let lastPose = followThroughFrames.last {
            let kp = keypointMap(from: lastPose)
            if let leftHip = kp["left_upLeg_joint"],
               let rightHip = kp["right_upLeg_joint"] {
                let hipRotation = rightHip.position.x - leftHip.position.x
                if hipRotation > AnalysisConstants.hipRotationFollow {
                    score += 15
                }
            }
        }

        return min(100, max(0, score))
    }

    private func calculateMetrics() -> SwingMetrics {
        var hipRotation: Double = 0
        var shoulderRotation: Double = 0
        var spineAngle: Double = 0

        if let firstPose = framesPoses.first,
           let midPose = framesPoses.count > 2 ? framesPoses[framesPoses.count / 3] : nil {

            let kp1 = keypointMap(from: firstPose)
            let kp2 = keypointMap(from: midPose)

            // Calculate hip rotation
            if let leftHip1 = kp1["left_upLeg_joint"],
               let rightHip1 = kp1["right_upLeg_joint"],
               let leftHip2 = kp2["left_upLeg_joint"],
               let rightHip2 = kp2["right_upLeg_joint"] {

                let angle1 = atan2(
                    rightHip1.position.y - leftHip1.position.y,
                    rightHip1.position.x - leftHip1.position.x
                )
                let angle2 = atan2(
                    rightHip2.position.y - leftHip2.position.y,
                    rightHip2.position.x - leftHip2.position.x
                )
                hipRotation = abs(angle2 - angle1) * 180 / .pi
            }

            // Calculate shoulder rotation
            if let leftShoulder1 = kp1["left_shoulder_1_joint"],
               let rightShoulder1 = kp1["right_shoulder_1_joint"],
               let leftShoulder2 = kp2["left_shoulder_1_joint"],
               let rightShoulder2 = kp2["right_shoulder_1_joint"] {

                let angle1 = atan2(
                    rightShoulder1.position.y - leftShoulder1.position.y,
                    rightShoulder1.position.x - leftShoulder1.position.x
                )
                let angle2 = atan2(
                    rightShoulder2.position.y - leftShoulder2.position.y,
                    rightShoulder2.position.x - leftShoulder2.position.x
                )
                shoulderRotation = abs(angle2 - angle1) * 180 / .pi
            }

            // Calculate spine angle
            if let hip = kp1["left_upLeg_joint"],
               let shoulder = kp1["left_shoulder_1_joint"] {
                let dx = shoulder.position.x - hip.position.x
                let dy = shoulder.position.y - hip.position.y
                spineAngle = abs(atan2(dx, dy) * 180 / .pi)
            }
        }

        let backswingDuration = Double(framesPoses.count / 3)
        let downswingDuration = Double(framesPoses.count / 3)
        let tempo = backswingDuration > 0 ? backswingDuration / max(1, downswingDuration) : 3.0

        let swingPlane: SwingPlaneQuality = shoulderRotation > 80 ? .slightlyOver :
                                            shoulderRotation < 60 ? .slightlyUnder : .onPlane

        let balance: BalanceQuality = hipRotation > 30 ? .excellent :
                                      hipRotation > 20 ? .good :
                                      hipRotation > 10 ? .fair : .poor

        return SwingMetrics(
            hipRotation: hipRotation,
            shoulderRotation: shoulderRotation,
            spineAngle: spineAngle,
            tempo: tempo,
            swingPlane: swingPlane,
            balance: balance
        )
    }

    private func generateFeedback(phases: SwingPhases, metrics: SwingMetrics) -> [SwingFeedback] {
        var feedback: [SwingFeedback] = []

        // Address feedback
        if phases.addressScore >= 85 {
            feedback.append(SwingFeedback(
                category: .posture,
                severity: .positive,
                title: "Great Setup Position",
                description: "Your address position shows good posture and alignment.",
                suggestion: "Keep maintaining this solid foundation for your swing."
            ))
        } else if phases.addressScore < 70 {
            feedback.append(SwingFeedback(
                category: .posture,
                severity: .warning,
                title: "Address Position Needs Work",
                description: "Your setup position could be improved for better consistency.",
                suggestion: "Focus on leveling your shoulders and hips at address. Bend from the hips, not the waist."
            ))
        }

        // Backswing feedback
        if phases.backswingScore >= 85 {
            feedback.append(SwingFeedback(
                category: .backswing,
                severity: .positive,
                title: "Solid Backswing",
                description: "Your backswing shows good rotation and tempo.",
                suggestion: "Continue focusing on a smooth takeaway."
            ))
        } else if phases.backswingScore < 70 {
            feedback.append(SwingFeedback(
                category: .backswing,
                severity: .suggestion,
                title: "Improve Backswing Rotation",
                description: "Your shoulder turn could be fuller for more power.",
                suggestion: "Try to rotate your shoulders at least 90 degrees while keeping your lower body stable."
            ))
        }

        // Downswing feedback
        if phases.downswingScore >= 85 {
            feedback.append(SwingFeedback(
                category: .downswing,
                severity: .positive,
                title: "Excellent Downswing Sequence",
                description: "Your hips are leading the downswing properly.",
                suggestion: "This proper sequencing generates maximum power."
            ))
        } else if phases.downswingScore < 70 {
            feedback.append(SwingFeedback(
                category: .downswing,
                severity: .warning,
                title: "Downswing Sequence Issue",
                description: "Your upper body may be starting the downswing before your lower body.",
                suggestion: "Focus on starting the downswing with your hips rotating toward the target."
            ))
        }

        // Tempo feedback
        if metrics.tempo < 2.5 || metrics.tempo > 4.0 {
            feedback.append(SwingFeedback(
                category: .tempo,
                severity: .suggestion,
                title: "Adjust Your Tempo",
                description: "Your swing tempo ratio is \(String(format: "%.1f", metrics.tempo)):1.",
                suggestion: "Ideal tempo is around 3:1 (backswing to downswing). Practice with a metronome."
            ))
        } else {
            feedback.append(SwingFeedback(
                category: .tempo,
                severity: .positive,
                title: "Good Swing Tempo",
                description: "Your backswing to downswing ratio is well balanced.",
                suggestion: "Maintain this rhythmic tempo for consistent ball striking."
            ))
        }

        // Balance feedback
        if metrics.balance == .poor || metrics.balance == .fair {
            feedback.append(SwingFeedback(
                category: .balance,
                severity: .warning,
                title: "Balance Needs Improvement",
                description: "You may be swaying or losing balance during the swing.",
                suggestion: "Practice swinging with your feet closer together to improve balance."
            ))
        }

        // Impact feedback
        if phases.impactScore >= 85 {
            feedback.append(SwingFeedback(
                category: .impact,
                severity: .positive,
                title: "Strong Impact Position",
                description: "Your body position at impact is well aligned.",
                suggestion: "This solid impact position leads to consistent ball striking."
            ))
        }

        // Follow through feedback
        if phases.followThroughScore < 70 {
            feedback.append(SwingFeedback(
                category: .followThrough,
                severity: .suggestion,
                title: "Complete Your Follow Through",
                description: "Your follow through appears to be cut short.",
                suggestion: "Finish with your belt buckle facing the target and weight on your front foot."
            ))
        }

        return feedback
    }
}

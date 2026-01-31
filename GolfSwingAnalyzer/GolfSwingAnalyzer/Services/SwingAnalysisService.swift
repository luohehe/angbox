import Vision
import AVFoundation
import CoreImage
import UIKit

actor SwingAnalysisService {
    private var poseRequest: VNDetectHumanBodyPoseRequest?
    private var framesPoses: [FramePose] = []

    init() {
        poseRequest = VNDetectHumanBodyPoseRequest()
    }

    func analyzeSwing(videoURL: URL, progressHandler: @escaping (Double) -> Void) async throws -> SwingAnalysis {
        framesPoses = []

        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let frameRate: Double = 30
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
                continue
            }

            let progress = Double(frameIndex + 1) / Double(totalFrames)
            progressHandler(progress)
        }

        return generateAnalysis()
    }

    private func detectPose(in image: CIImage) async throws -> [PoseKeypoint]? {
        guard let request = poseRequest else { return nil }

        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else { return nil }

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
            if let point = try? observation.recognizedPoint(jointName), point.confidence > 0.3 {
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

    private func analyzePhases() -> SwingPhases {
        guard framesPoses.count > 10 else {
            return SwingPhases(
                addressScore: 70,
                backswingScore: 70,
                topScore: 70,
                downswingScore: 70,
                impactScore: 70,
                followThroughScore: 70
            )
        }

        let addressScore = analyzeAddress()
        let backswingScore = analyzeBackswing()
        let topScore = analyzeTopPosition()
        let downswingScore = analyzeDownswing()
        let impactScore = analyzeImpact()
        let followThroughScore = analyzeFollowThrough()

        return SwingPhases(
            addressScore: addressScore,
            backswingScore: backswingScore,
            topScore: topScore,
            downswingScore: downswingScore,
            impactScore: impactScore,
            followThroughScore: followThroughScore
        )
    }

    private func analyzeAddress() -> Int {
        guard let firstPose = framesPoses.first else { return 70 }

        var score = 75

        if let leftShoulder = firstPose.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("left") }),
           let rightShoulder = firstPose.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("right") }) {
            let shoulderLevel = abs(leftShoulder.position.y - rightShoulder.position.y)
            if shoulderLevel < 0.05 {
                score += 10
            }
        }

        if let leftHip = firstPose.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("left") }),
           let rightHip = firstPose.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("right") }) {
            let hipLevel = abs(leftHip.position.y - rightHip.position.y)
            if hipLevel < 0.05 {
                score += 10
            }
        }

        return min(100, max(0, score))
    }

    private func analyzeBackswing() -> Int {
        let backswingFrames = framesPoses.prefix(framesPoses.count / 3)
        guard backswingFrames.count > 3 else { return 70 }

        var score = 75

        var shoulderRotation: Double = 0
        for frame in backswingFrames {
            if let leftShoulder = frame.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("left") }),
               let rightShoulder = frame.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("right") }) {
                let dx = rightShoulder.position.x - leftShoulder.position.x
                let dy = rightShoulder.position.y - leftShoulder.position.y
                let angle = atan2(dy, dx) * 180 / .pi
                shoulderRotation = max(shoulderRotation, abs(angle))
            }
        }

        if shoulderRotation > 30 {
            score += 15
        } else if shoulderRotation > 20 {
            score += 10
        }

        return min(100, max(0, score))
    }

    private func analyzeTopPosition() -> Int {
        let topIndex = framesPoses.count / 3
        guard topIndex < framesPoses.count else { return 70 }

        let topPose = framesPoses[topIndex]
        var score = 75

        if let leftWrist = topPose.keypoints.first(where: { $0.name.contains("wrist") && $0.name.contains("left") }),
           let leftShoulder = topPose.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("left") }) {
            if leftWrist.position.y < leftShoulder.position.y {
                score += 15
            }
        }

        return min(100, max(0, score))
    }

    private func analyzeDownswing() -> Int {
        let startIndex = framesPoses.count / 3
        let endIndex = 2 * framesPoses.count / 3
        guard startIndex < endIndex, endIndex < framesPoses.count else { return 70 }

        var score = 75

        let downswingFrames = Array(framesPoses[startIndex..<endIndex])
        var hipLeadsShoulders = 0

        for frame in downswingFrames {
            if let leftHip = frame.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("left") }),
               let rightHip = frame.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("right") }),
               let leftShoulder = frame.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("left") }),
               let rightShoulder = frame.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("right") }) {

                let hipAngle = atan2(rightHip.position.y - leftHip.position.y, rightHip.position.x - leftHip.position.x)
                let shoulderAngle = atan2(rightShoulder.position.y - leftShoulder.position.y, rightShoulder.position.x - leftShoulder.position.x)

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
        guard impactIndex < framesPoses.count else { return 70 }

        let impactPose = framesPoses[impactIndex]
        var score = 75

        if let leftHip = impactPose.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("left") }),
           let leftShoulder = impactPose.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("left") }),
           let leftAnkle = impactPose.keypoints.first(where: { $0.name.contains("ankle") && $0.name.contains("left") }) {

            let hipOverAnkle = abs(leftHip.position.x - leftAnkle.position.x) < 0.1
            if hipOverAnkle {
                score += 10
            }

            let shoulderOverHip = abs(leftShoulder.position.x - leftHip.position.x) < 0.15
            if shoulderOverHip {
                score += 10
            }
        }

        return min(100, max(0, score))
    }

    private func analyzeFollowThrough() -> Int {
        let followThroughFrames = framesPoses.suffix(framesPoses.count / 4)
        guard followThroughFrames.count > 2 else { return 70 }

        var score = 75

        if let lastPose = followThroughFrames.last {
            if let leftHip = lastPose.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("left") }),
               let rightHip = lastPose.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("right") }) {
                let hipRotation = rightHip.position.x - leftHip.position.x
                if hipRotation > 0.05 {
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

            if let leftHip1 = firstPose.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("left") }),
               let rightHip1 = firstPose.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("right") }),
               let leftHip2 = midPose.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("left") }),
               let rightHip2 = midPose.keypoints.first(where: { $0.name.contains("hip") && $0.name.contains("right") }) {

                let angle1 = atan2(rightHip1.position.y - leftHip1.position.y, rightHip1.position.x - leftHip1.position.x)
                let angle2 = atan2(rightHip2.position.y - leftHip2.position.y, rightHip2.position.x - leftHip2.position.x)
                hipRotation = abs(angle2 - angle1) * 180 / .pi
            }

            if let leftShoulder1 = firstPose.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("left") }),
               let rightShoulder1 = firstPose.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("right") }),
               let leftShoulder2 = midPose.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("left") }),
               let rightShoulder2 = midPose.keypoints.first(where: { $0.name.contains("shoulder") && $0.name.contains("right") }) {

                let angle1 = atan2(rightShoulder1.position.y - leftShoulder1.position.y, rightShoulder1.position.x - leftShoulder1.position.x)
                let angle2 = atan2(rightShoulder2.position.y - leftShoulder2.position.y, rightShoulder2.position.x - leftShoulder2.position.x)
                shoulderRotation = abs(angle2 - angle1) * 180 / .pi
            }

            if let hip = firstPose.keypoints.first(where: { $0.name.contains("hip") }),
               let shoulder = firstPose.keypoints.first(where: { $0.name.contains("shoulder") }) {
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

        if metrics.balance == .poor || metrics.balance == .fair {
            feedback.append(SwingFeedback(
                category: .balance,
                severity: .warning,
                title: "Balance Needs Improvement",
                description: "You may be swaying or losing balance during the swing.",
                suggestion: "Practice swinging with your feet closer together to improve balance."
            ))
        }

        if phases.impactScore >= 85 {
            feedback.append(SwingFeedback(
                category: .impact,
                severity: .positive,
                title: "Strong Impact Position",
                description: "Your body position at impact is well aligned.",
                suggestion: "This solid impact position leads to consistent ball striking."
            ))
        }

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

import Foundation
import CoreGraphics

struct SwingData: Identifiable, Codable {
    let id: UUID
    let recordedAt: Date
    let videoURL: URL?
    let duration: TimeInterval
    var analysis: SwingAnalysis?

    init(id: UUID = UUID(), recordedAt: Date = Date(), videoURL: URL? = nil, duration: TimeInterval = 0, analysis: SwingAnalysis? = nil) {
        self.id = id
        self.recordedAt = recordedAt
        self.videoURL = videoURL
        self.duration = duration
        self.analysis = analysis
    }
}

struct SwingAnalysis: Codable {
    let overallScore: Int // 0-100
    let phases: SwingPhases
    let feedback: [SwingFeedback]
    let keyMetrics: SwingMetrics

    var scoreGrade: String {
        switch overallScore {
        case 90...100: return "Excellent"
        case 80..<90: return "Great"
        case 70..<80: return "Good"
        case 60..<70: return "Fair"
        default: return "Needs Work"
        }
    }

    var scoreColor: String {
        switch overallScore {
        case 90...100: return "green"
        case 80..<90: return "blue"
        case 70..<80: return "yellow"
        case 60..<70: return "orange"
        default: return "red"
        }
    }
}

struct SwingPhases: Codable {
    let addressScore: Int
    let backswingScore: Int
    let topScore: Int
    let downswingScore: Int
    let impactScore: Int
    let followThroughScore: Int
}

struct SwingMetrics: Codable {
    let hipRotation: Double // degrees
    let shoulderRotation: Double // degrees
    let spineAngle: Double // degrees
    let tempo: Double // backswing:downswing ratio
    let swingPlane: SwingPlaneQuality
    let balance: BalanceQuality
}

enum SwingPlaneQuality: String, Codable {
    case onPlane = "On Plane"
    case slightlyOver = "Slightly Over"
    case slightlyUnder = "Slightly Under"
    case over = "Over the Top"
    case under = "Too Flat"
}

enum BalanceQuality: String, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
}

struct SwingFeedback: Identifiable, Codable {
    let id: UUID
    let category: FeedbackCategory
    let severity: FeedbackSeverity
    let title: String
    let description: String
    let suggestion: String

    init(id: UUID = UUID(), category: FeedbackCategory, severity: FeedbackSeverity, title: String, description: String, suggestion: String) {
        self.id = id
        self.category = category
        self.severity = severity
        self.title = title
        self.description = description
        self.suggestion = suggestion
    }
}

enum FeedbackCategory: String, Codable {
    case posture = "Posture"
    case grip = "Grip"
    case backswing = "Backswing"
    case downswing = "Downswing"
    case impact = "Impact"
    case followThrough = "Follow Through"
    case tempo = "Tempo"
    case balance = "Balance"
}

enum FeedbackSeverity: String, Codable {
    case positive = "positive"
    case suggestion = "suggestion"
    case warning = "warning"
    case critical = "critical"
}

struct PoseKeypoint: Codable {
    let name: String
    let position: CGPoint
    let confidence: Float
}

struct FramePose: Codable {
    let timestamp: TimeInterval
    let keypoints: [PoseKeypoint]
}

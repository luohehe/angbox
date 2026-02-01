import Foundation
import CoreGraphics

// MARK: - Club Types
enum ClubType: String, Codable, CaseIterable, Identifiable {
    case driver = "Driver"
    case wood3 = "3 Wood"
    case wood5 = "5 Wood"
    case hybrid = "Hybrid"
    case iron3 = "3 Iron"
    case iron4 = "4 Iron"
    case iron5 = "5 Iron"
    case iron6 = "6 Iron"
    case iron7 = "7 Iron"
    case iron8 = "8 Iron"
    case iron9 = "9 Iron"
    case pitchingWedge = "PW"
    case gapWedge = "GW"
    case sandWedge = "SW"
    case lobWedge = "LW"
    case putter = "Putter"

    var id: String { rawValue }

    var category: ClubCategory {
        switch self {
        case .driver:
            return .driver
        case .wood3, .wood5:
            return .fairwayWood
        case .hybrid:
            return .hybrid
        case .iron3, .iron4, .iron5, .iron6, .iron7, .iron8, .iron9:
            return .iron
        case .pitchingWedge, .gapWedge, .sandWedge, .lobWedge:
            return .wedge
        case .putter:
            return .putter
        }
    }

    var icon: String {
        switch category {
        case .driver: return "figure.golf"
        case .fairwayWood: return "leaf.fill"
        case .hybrid: return "arrow.up.right"
        case .iron: return "lineweight"
        case .wedge: return "arrow.up.forward"
        case .putter: return "arrow.down"
        }
    }

    var displayName: String { rawValue }
}

enum ClubCategory: String, Codable, CaseIterable {
    case driver = "Driver"
    case fairwayWood = "Fairway Wood"
    case hybrid = "Hybrid"
    case iron = "Iron"
    case wedge = "Wedge"
    case putter = "Putter"

    var clubs: [ClubType] {
        ClubType.allCases.filter { $0.category == self }
    }
}

// MARK: - Swing Data
struct SwingData: Identifiable, Codable {
    let id: UUID
    let recordedAt: Date
    let videoURL: URL?
    let duration: TimeInterval
    let clubType: ClubType
    var analysis: SwingAnalysis?
    var cloudSynced: Bool
    var userId: String?

    init(
        id: UUID = UUID(),
        recordedAt: Date = Date(),
        videoURL: URL? = nil,
        duration: TimeInterval = 0,
        clubType: ClubType = .iron7,
        analysis: SwingAnalysis? = nil,
        cloudSynced: Bool = false,
        userId: String? = nil
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.videoURL = videoURL
        self.duration = duration
        self.clubType = clubType
        self.analysis = analysis
        self.cloudSynced = cloudSynced
        self.userId = userId
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

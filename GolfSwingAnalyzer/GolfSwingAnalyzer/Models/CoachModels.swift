import Foundation

// MARK: - Coach Profile
struct Coach: Identifiable, Codable {
    let id: String
    let name: String
    let title: String
    let avatarName: String
    let personality: CoachPersonality
    let specialties: [String]

    static let pj = Coach(
        id: "coach-pj",
        name: "PJ",
        title: "Virtual Golf Coach",
        avatarName: "pj-avatar",
        personality: CoachPersonality(
            greeting: "Hey there! I'm PJ, your personal golf coach.",
            encouragement: ["Great effort!", "You're improving!", "Keep at it!", "Nice swing!"],
            style: .friendly
        ),
        specialties: ["Swing Mechanics", "Tempo", "Balance", "Mental Game"]
    )
}

struct CoachPersonality: Codable {
    let greeting: String
    let encouragement: [String]
    let style: CoachingStyle
}

enum CoachingStyle: String, Codable {
    case friendly = "friendly"
    case technical = "technical"
    case motivational = "motivational"
}

// MARK: - Coach Message
struct CoachMessage: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: MessageType
    let content: String
    let swingId: UUID?
    let priority: MessagePriority

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: MessageType,
        content: String,
        swingId: UUID? = nil,
        priority: MessagePriority = .normal
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.content = content
        self.swingId = swingId
        self.priority = priority
    }

    enum MessageType: String, Codable {
        case greeting
        case analysis
        case tip
        case question
        case encouragement
        case drill
        case summary
    }

    enum MessagePriority: String, Codable {
        case low
        case normal
        case high
        case critical
    }
}

// MARK: - Coaching Session
struct CoachingSession: Identifiable, Codable {
    let id: UUID
    let startedAt: Date
    var messages: [CoachMessage]
    let swingId: UUID?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        messages: [CoachMessage] = [],
        swingId: UUID? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.startedAt = startedAt
        self.messages = messages
        self.swingId = swingId
        self.isActive = isActive
    }

    mutating func addMessage(_ message: CoachMessage) {
        messages.append(message)
    }
}

// MARK: - Swing Improvement
struct SwingImprovement: Identifiable, Codable {
    let id: UUID
    let category: ImprovementCategory
    let title: String
    let description: String
    let priority: Int // 1-5, 5 being highest priority
    let drills: [PracticeDrill]

    init(
        id: UUID = UUID(),
        category: ImprovementCategory,
        title: String,
        description: String,
        priority: Int,
        drills: [PracticeDrill] = []
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.priority = priority
        self.drills = drills
    }
}

enum ImprovementCategory: String, Codable, CaseIterable {
    case posture = "Posture"
    case grip = "Grip"
    case backswing = "Backswing"
    case downswing = "Downswing"
    case impact = "Impact"
    case followThrough = "Follow Through"
    case tempo = "Tempo"
    case balance = "Balance"
    case rotation = "Rotation"
    case alignment = "Alignment"

    var icon: String {
        switch self {
        case .posture: return "figure.stand"
        case .grip: return "hand.raised.fill"
        case .backswing: return "arrow.up.backward"
        case .downswing: return "arrow.down.forward"
        case .impact: return "bolt.fill"
        case .followThrough: return "arrow.up.forward"
        case .tempo: return "metronome.fill"
        case .balance: return "scale.3d"
        case .rotation: return "arrow.triangle.2.circlepath"
        case .alignment: return "arrow.left.and.right"
        }
    }
}

// MARK: - Practice Drill
struct PracticeDrill: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let duration: String
    let difficulty: DrillDifficulty
    let steps: [String]

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        duration: String,
        difficulty: DrillDifficulty,
        steps: [String]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.duration = duration
        self.difficulty = difficulty
        self.steps = steps
    }
}

enum DrillDifficulty: String, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "yellow"
        case .advanced: return "red"
        }
    }
}

// MARK: - Coach Feedback
struct CoachFeedback: Identifiable, Codable {
    let id: UUID
    let swingId: UUID
    let overallComment: String
    let improvements: [SwingImprovement]
    let strengths: [String]
    let focusArea: ImprovementCategory
    let nextSessionTip: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        swingId: UUID,
        overallComment: String,
        improvements: [SwingImprovement],
        strengths: [String],
        focusArea: ImprovementCategory,
        nextSessionTip: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.swingId = swingId
        self.overallComment = overallComment
        self.improvements = improvements
        self.strengths = strengths
        self.focusArea = focusArea
        self.nextSessionTip = nextSessionTip
        self.createdAt = createdAt
    }
}

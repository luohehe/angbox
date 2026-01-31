import SwiftUI

// MARK: - Design System
// Inspired by professional golf apps like 18Birdies
// Features: Dark mode support, golf-themed colors, semantic tokens

// MARK: - Color Palette
extension Color {
    // Primary Brand Colors (Golf Green Theme)
    static let golfGreen = Color(red: 0.13, green: 0.55, blue: 0.33)      // #218754
    static let golfGreenLight = Color(red: 0.20, green: 0.65, blue: 0.43) // #33A66E
    static let golfGreenDark = Color(red: 0.08, green: 0.40, blue: 0.24)  // #14663D

    // Secondary Colors
    static let fairwayGreen = Color(red: 0.56, green: 0.74, blue: 0.56)   // #8FBC8F
    static let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.92)        // #87CEEB
    static let sandBunker = Color(red: 0.96, green: 0.87, blue: 0.70)     // #F5DEB3

    // Score Colors
    static let scoreExcellent = Color(red: 0.13, green: 0.55, blue: 0.33) // Green
    static let scoreGreat = Color(red: 0.20, green: 0.60, blue: 0.86)     // Blue
    static let scoreGood = Color(red: 0.95, green: 0.77, blue: 0.06)      // Yellow/Gold
    static let scoreFair = Color(red: 0.95, green: 0.55, blue: 0.15)      // Orange
    static let scoreNeedsWork = Color(red: 0.86, green: 0.25, blue: 0.25) // Red

    // Semantic Colors - Light Mode
    static let backgroundPrimary = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)

    // Card Colors
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let cardBorder = Color(UIColor.separator)
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("useSystemTheme") var useSystemTheme: Bool = true

    var colorScheme: ColorScheme? {
        if useSystemTheme { return nil }
        return isDarkMode ? .dark : .light
    }
}

// MARK: - Typography
struct AppTypography {
    // Headers
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    // Body
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)

    // Small
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption1 = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)

    // Score Display
    static let scoreDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
    static let scoreMedium = Font.system(size: 32, weight: .bold, design: .rounded)
    static let scoreSmall = Font.system(size: 24, weight: .bold, design: .rounded)
}

// MARK: - Spacing
struct AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 24
    static let circular: CGFloat = 9999
}

// MARK: - Shadows
extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    func subtleShadow() -> some View {
        self.shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    func elevatedShadow() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(isEnabled ? Color.golfGreen : Color.gray)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(.golfGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(Color.golfGreen, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.subheadline)
            .foregroundColor(.golfGreen)
            .padding(.vertical, AppSpacing.xs)
            .padding(.horizontal, AppSpacing.sm)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Card Components
struct GolfCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.md)
            .background(Color.cardBackground)
            .cornerRadius(AppCornerRadius.large)
            .cardShadow()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color

    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color = .golfGreen) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(AppTypography.caption1)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(AppTypography.scoreMedium)
                .foregroundColor(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppTypography.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - Score Ring
struct ScoreRing: View {
    let score: Int
    let size: CGFloat
    let lineWidth: CGFloat

    init(score: Int, size: CGFloat = 120, lineWidth: CGFloat = 10) {
        self.score = score
        self.size = size
        self.lineWidth = lineWidth
    }

    private var scoreColor: Color {
        switch score {
        case 90...100: return .scoreExcellent
        case 80..<90: return .scoreGreat
        case 70..<80: return .scoreGood
        case 60..<70: return .scoreFair
        default: return .scoreNeedsWork
        }
    }

    private var gradeText: String {
        switch score {
        case 90...100: return "Excellent"
        case 80..<90: return "Great"
        case 70..<80: return "Good"
        case 60..<70: return "Fair"
        default: return "Keep Practicing"
        }
    }

    var body: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Progress Ring
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: score)

            // Score Text
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(size > 100 ? AppTypography.scoreDisplay : AppTypography.scoreMedium)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)

                Text(gradeText)
                    .font(size > 100 ? AppTypography.caption1 : AppTypography.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Progress Bar
struct GolfProgressBar: View {
    let value: Double
    let color: Color
    let height: CGFloat

    init(value: Double, color: Color = .golfGreen, height: CGFloat = 8) {
        self.value = value
        self.color = color
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(value))
                    .animation(.easeOut(duration: 0.5), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Tab Bar Item
struct GolfTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .golfGreen : .secondary)

            Text(title)
                .font(AppTypography.caption2)
                .foregroundColor(isSelected ? .golfGreen : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.golfGreen.opacity(0.6))

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(.primary)

                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppSpacing.xxl)
            }
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let action: String?
    let onAction: (() -> Void)?

    init(_ title: String, action: String? = nil, onAction: (() -> Void)? = nil) {
        self.title = title
        self.action = action
        self.onAction = onAction
    }

    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(.primary)

            Spacer()

            if let action = action, let onAction = onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(AppTypography.subheadline)
                        .foregroundColor(.golfGreen)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Badge
struct GolfBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppTypography.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(AppCornerRadius.small)
    }
}

// MARK: - Metric Row
struct MetricDisplayRow: View {
    let icon: String
    let title: String
    let value: String
    let trend: Double?

    init(icon: String, title: String, value: String, trend: Double? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.trend = trend
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.golfGreen)
                .frame(width: 32)

            Text(title)
                .font(AppTypography.body)
                .foregroundColor(.primary)

            Spacer()

            HStack(spacing: AppSpacing.xxs) {
                Text(value)
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)

                if let trend = trend {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(trend >= 0 ? .scoreExcellent : .scoreNeedsWork)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
    }
}

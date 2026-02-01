import SwiftUI

// MARK: - NeverOB Logo Design
// A modern, tech-forward golf app logo

/// Logo Design Concept for NeverOB
///
/// # Design Philosophy
/// - **Name Meaning**: "Never Out of Bounds" - helping golfers stay in play
/// - **Style**: Modern, minimalist, tech-forward with golf DNA
/// - **Primary Color**: Electric Golf Green (#00D26A) with dark accents
///
/// # Visual Elements
/// 1. **Golf Ball with Tech Circuit Pattern** - A stylized golf ball where the
///    dimples form a circuit board pattern, representing AI/tech analysis
/// 2. **Boundary Line** - A subtle "safe zone" indicator showing "in bounds"
/// 3. **Typography**: Clean sans-serif, "Never" in lighter weight, "OB" bold
///
/// # Color Palette
/// - Primary: Electric Green (#00D26A) - Tech + Golf
/// - Secondary: Deep Navy (#0A1628) - Premium feel
/// - Accent: White/Light gray for contrast
/// - Gradient option: Green to Teal for depth

// MARK: - Logo Colors
extension Color {
    // NeverOB Brand Colors
    static let neverOBGreen = Color(red: 0.0, green: 0.82, blue: 0.42)      // #00D26A
    static let neverOBDark = Color(red: 0.04, green: 0.09, blue: 0.16)      // #0A1628
    static let neverOBTeal = Color(red: 0.0, green: 0.75, blue: 0.65)       // #00BFA5
    static let neverOBGradientStart = Color(red: 0.0, green: 0.82, blue: 0.42)
    static let neverOBGradientEnd = Color(red: 0.0, green: 0.65, blue: 0.55)
}

// MARK: - App Icon View (Reference Design)
struct NeverOBAppIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background - Dark with subtle gradient
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [Color.neverOBDark, Color.neverOBDark.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Tech Grid Pattern (subtle background)
            TechGridPattern(size: size)
                .opacity(0.1)

            // Main Logo Element
            VStack(spacing: size * 0.02) {
                // Golf Ball with Tech Design
                TechGolfBall(size: size * 0.5)

                // App Name
                HStack(spacing: 2) {
                    Text("Never")
                        .font(.system(size: size * 0.12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))

                    Text("OB")
                        .font(.system(size: size * 0.12, weight: .bold, design: .rounded))
                        .foregroundColor(.neverOBGreen)
                }
            }

            // Boundary Indicator (corner accent)
            BoundaryAccent(size: size)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

// MARK: - Tech Golf Ball
struct TechGolfBall: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.neverOBGreen.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)

            // Main ball
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.neverOBGreen, Color.neverOBTeal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Circuit pattern overlay
            CircuitPattern(size: size)
                .foregroundColor(.white.opacity(0.3))

            // Highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.4), Color.clear],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size, height: size)

            // Swing path indicator
            SwingPathArc(size: size)
        }
    }
}

// MARK: - Circuit Pattern
struct CircuitPattern: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = size / 2

            // Draw circuit-like dimple pattern
            let dimpleCount = 6
            let rings = 3

            for ring in 0..<rings {
                let ringRadius = radius * (0.3 + Double(ring) * 0.25)
                let dimples = dimpleCount + ring * 2

                for i in 0..<dimples {
                    let angle = (Double(i) / Double(dimples)) * 2 * .pi - .pi / 2
                    let x = center.x + cos(angle) * ringRadius
                    let y = center.y + sin(angle) * ringRadius

                    // Dimple dot
                    let dotRect = CGRect(x: x - 2, y: y - 2, width: 4, height: 4)
                    context.fill(Circle().path(in: dotRect), with: .color(.white.opacity(0.5)))

                    // Connection line (every other)
                    if i % 2 == 0 && ring < rings - 1 {
                        let nextRingRadius = radius * (0.3 + Double(ring + 1) * 0.25)
                        let nextX = center.x + cos(angle) * nextRingRadius
                        let nextY = center.y + sin(angle) * nextRingRadius

                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: nextX, y: nextY))
                        context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 1)
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Swing Path Arc
struct SwingPathArc: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .trim(from: 0.1, to: 0.4)
            .stroke(
                Color.white.opacity(0.6),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4])
            )
            .frame(width: size * 1.3, height: size * 1.3)
            .rotationEffect(.degrees(-30))
    }
}

// MARK: - Tech Grid Pattern
struct TechGridPattern: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let spacing: CGFloat = size / 8

            // Vertical lines
            for x in stride(from: 0, to: canvasSize.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                context.stroke(path, with: .color(.neverOBGreen), lineWidth: 0.5)
            }

            // Horizontal lines
            for y in stride(from: 0, to: canvasSize.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                context.stroke(path, with: .color(.neverOBGreen), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - Boundary Accent
struct BoundaryAccent: View {
    let size: CGFloat

    var body: some View {
        VStack {
            HStack {
                Spacer()
                // Top right corner accent - represents "in bounds"
                ZStack {
                    // Corner boundary lines
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: size * 0.15))
                        path.addLine(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: size * 0.15, y: 0))
                    }
                    .stroke(Color.neverOBGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: size * 0.15, height: size * 0.15)

                    // Check mark (in bounds indicator)
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.06, weight: .bold))
                        .foregroundColor(.neverOBGreen)
                        .offset(x: -size * 0.02, y: size * 0.02)
                }
                .padding(size * 0.08)
            }
            Spacer()
        }
    }
}

// MARK: - Logo Variations

/// Horizontal Logo (for headers, splash screens)
struct NeverOBLogoHorizontal: View {
    let height: CGFloat

    var body: some View {
        HStack(spacing: height * 0.2) {
            // Icon
            TechGolfBall(size: height)

            // Text
            HStack(spacing: 4) {
                Text("Never")
                    .font(.system(size: height * 0.5, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Text("OB")
                    .font(.system(size: height * 0.5, weight: .bold, design: .rounded))
                    .foregroundColor(.neverOBGreen)
            }
        }
    }
}

/// Minimal Icon (for tab bars, small spaces)
struct NeverOBIconMinimal: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.neverOBGreen, Color.neverOBTeal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Simple "N" with boundary accent
            Text("N")
                .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview
#Preview("App Icon") {
    VStack(spacing: 40) {
        // Large icon
        NeverOBAppIcon(size: 200)

        // Standard iOS sizes
        HStack(spacing: 20) {
            NeverOBAppIcon(size: 60)
            NeverOBAppIcon(size: 40)
            NeverOBAppIcon(size: 29)
        }

        // Horizontal logo
        NeverOBLogoHorizontal(height: 50)

        // Minimal icons
        HStack(spacing: 20) {
            NeverOBIconMinimal(size: 44)
            NeverOBIconMinimal(size: 32)
            NeverOBIconMinimal(size: 24)
        }
    }
    .padding(40)
    .background(Color(.systemBackground))
}

#Preview("Dark Mode") {
    VStack(spacing: 40) {
        NeverOBAppIcon(size: 200)
        NeverOBLogoHorizontal(height: 50)
    }
    .padding(40)
    .background(Color.black)
    .preferredColorScheme(.dark)
}

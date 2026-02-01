import SwiftUI

@main
struct NeverOBApp: App {
    @StateObject private var swingStore = SwingStore()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(swingStore)

                // Splash Screen
                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // Dismiss splash after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

// MARK: - Splash Screen
struct SplashScreen: View {
    @State private var isAnimating = false
    @State private var showTagline = false

    var body: some View {
        ZStack {
            // Background
            Color.neverOBDark
                .ignoresSafeArea()

            // Tech grid pattern
            TechGridPattern(size: UIScreen.main.bounds.width)
                .opacity(0.05)
                .ignoresSafeArea()

            // Logo Content
            VStack(spacing: 24) {
                // Animated Golf Ball
                TechGolfBall(size: 120)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)

                // App Name
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Never")
                            .font(.system(size: 36, weight: .medium, design: .rounded))
                            .foregroundColor(.white)

                        Text("OB")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.neverOBGreen)
                    }
                    .opacity(isAnimating ? 1.0 : 0.0)

                    // Tagline
                    Text("Stay In Play")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .opacity(showTagline ? 1.0 : 0.0)
                }
            }
        }
        .onAppear {
            // Start animations
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                showTagline = true
            }
        }
    }
}

#Preview {
    SplashScreen()
}

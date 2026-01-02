import SwiftUI
import NimbleViews

@available(iOS 17.0, *)
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var animateContent = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#667eea"),
                    Color(hex: "#764ba2"),
                    Color(hex: "#f093fb"),
                    Color(hex: "#667eea")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(animateContent ? 30 : 0))
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    animateContent = true
                }
            }
            
            // Floating particles effect
            GeometryReader { geometry in
                ForEach(0..<15) { index in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: CGFloat.random(in: 20...60))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 10)
                        .offset(
                            x: animateContent ? CGFloat.random(in: -50...50) : 0,
                            y: animateContent ? CGFloat.random(in: -50...50) : 0
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...8))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animateContent
                        )
                }
            }
            
            // Glassmorphic content container
            VStack(spacing: 0) {
                Spacer()
                
                // Main content card with glass effect
                VStack(spacing: 32) {
                    // App Icon with glow effect
                    Image(uiImage: AppIconView.altImage(nil))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(28)
                        .shadow(color: Color.white.opacity(0.3), radius: 20, x: 0, y: 10)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    VStack(spacing: 16) {
                        // Title
                        Text("Welcome to Feather")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        // Subtitle
                        Text("Your all-in-one iOS app sideloading solution")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.horizontal, 32)
                    
                    // Feature highlights with glass cards
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "square.stack.3d.up.fill",
                            title: "Browse Sources",
                            description: "Discover thousands of apps",
                            delay: 0.2
                        )
                        
                        FeatureRow(
                            icon: "signature",
                            title: "Sign Apps",
                            description: "Easy certificate management",
                            delay: 0.3
                        )
                        
                        FeatureRow(
                            icon: "arrow.down.circle.fill",
                            title: "Install Anywhere",
                            description: "Seamless installation process",
                            delay: 0.4
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1.0 : 0.0)
                    
                    // Get Started Button
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            hasCompletedOnboarding = true
                        }
                        HapticsManager.shared.success()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Get Started")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                        }
                        .foregroundColor(Color(hex: "#667eea"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(color: Color.white.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                    }
                    .padding(.horizontal, 24)
                    .scaleEffect(animateButton ? 1.0 : 0.9)
                    .opacity(animateButton ? 1.0 : 0.0)
                }
                .padding(.vertical, 48)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 15)
                )
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                animateButton = true
            }
        }
    }
}

@available(iOS 17.0, *)
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container with glass effect
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.15))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    OnboardingView()
}

// MARK: - Legacy iOS 16 Support
struct OnboardingViewLegacy: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var animateContent = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#667eea"),
                    Color(hex: "#764ba2"),
                    Color(hex: "#f093fb"),
                    Color(hex: "#667eea")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(animateContent ? 30 : 0))
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    animateContent = true
                }
            }
            
            // Floating particles effect
            GeometryReader { geometry in
                ForEach(0..<15) { index in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: CGFloat.random(in: 20...60))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 10)
                        .offset(
                            x: animateContent ? CGFloat.random(in: -50...50) : 0,
                            y: animateContent ? CGFloat.random(in: -50...50) : 0
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...8))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animateContent
                        )
                }
            }
            
            // Glassmorphic content container
            VStack(spacing: 0) {
                Spacer()
                
                // Main content card with glass effect
                VStack(spacing: 32) {
                    // App Icon with glow effect
                    Image(uiImage: AppIconView.altImage(nil))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(28)
                        .shadow(color: Color.white.opacity(0.3), radius: 20, x: 0, y: 10)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    VStack(spacing: 16) {
                        // Title
                        Text("Welcome to Feather")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        // Subtitle
                        Text("Your all-in-one iOS app sideloading solution")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.horizontal, 32)
                    
                    // Feature highlights with glass cards
                    VStack(spacing: 16) {
                        FeatureRowLegacy(
                            icon: "square.stack.3d.up.fill",
                            title: "Browse Sources",
                            description: "Discover thousands of apps",
                            delay: 0.2
                        )
                        
                        FeatureRowLegacy(
                            icon: "signature",
                            title: "Sign Apps",
                            description: "Easy certificate management",
                            delay: 0.3
                        )
                        
                        FeatureRowLegacy(
                            icon: "arrow.down.circle.fill",
                            title: "Install Anywhere",
                            description: "Seamless installation process",
                            delay: 0.4
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1.0 : 0.0)
                    
                    // Get Started Button
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            hasCompletedOnboarding = true
                        }
                        HapticsManager.shared.success()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Get Started")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                        }
                        .foregroundColor(Color(hex: "#667eea"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.white.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                    }
                    .padding(.horizontal, 24)
                    .scaleEffect(animateButton ? 1.0 : 0.9)
                    .opacity(animateButton ? 1.0 : 0.0)
                }
                .padding(.vertical, 48)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 15)
                )
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                animateButton = true
            }
        }
    }
}

struct FeatureRowLegacy: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container with glass effect
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

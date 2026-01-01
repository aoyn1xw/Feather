import SwiftUI
import NimbleViews

@available(iOS 17.0, *)
struct SigningProcessView: View {
    @Environment(\.dismiss) var dismiss
    @State private var progress: Double = 0.0
    @State private var logs: [String] = []
    @State private var currentStep: String = "Initializing..."
    @State private var isFinished = false
    
    var appName: String
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    Color.accentColor.opacity(0.05),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header with enhanced icon
                VStack(spacing: 16) {
                    ZStack {
                        // Animated glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.3),
                                        Color.accentColor.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(isFinished ? 1.2 : 1.0)
                            .opacity(isFinished ? 0.8 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isFinished)
                        
                        // Main icon with depth
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.1))
                                .frame(width: 70, height: 70)
                                .blur(radius: 5)
                                .offset(y: 5)
                            
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: isFinished ? "checkmark.seal.fill" : "signature")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, value: progress)
                        }
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    
                    VStack(spacing: 8) {
                        Text(isFinished ? "Signing Complete!" : "Signing \(appName)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                        
                        Text(currentStep)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 60)
                
                // Enhanced Progress with glass effect
                VStack(spacing: 12) {
                    ZStack(alignment: .leading) {
                        // Background track with depth
                        Capsule()
                            .fill(Color(UIColor.secondarySystemFill))
                            .frame(height: 8)
                        
                        // Progress fill with gradient and glow
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.9),
                                        Color.accentColor,
                                        Color.accentColor.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.8 * progress, height: 8)
                            .shadow(color: Color.accentColor.opacity(0.5), radius: 6, x: 0, y: 2)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.8)
                    
                    HStack {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                        Spacer()
                        if !isFinished {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.accentColor)
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.8)
                }
                .padding(.horizontal, 40)
                
                // Enhanced Logs with glass morphism
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "terminal.fill")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                        Text("Logs")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(logs, id: \.self) { log in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 4, height: 4)
                                    
                                    Text(log)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                if isFinished {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Done")
                                .font(.headline)
                                .fontWeight(.bold)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                // Shadow layer
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.3))
                                    .blur(radius: 4)
                                    .offset(y: 3)
                                
                                // Main gradient
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.accentColor,
                                                Color.accentColor.opacity(0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startSigningSimulation()
        }
    }
    
    func startSigningSimulation() {
        // Simulate signing process
        let steps = [
            "Extracting IPA...",
            "Verifying entitlements...",
            "Patching binary...",
            "Signing frameworks...",
            "Signing application...",
            "Packaging...",
            "Done!"
        ]
        
        Task {
            for (index, step) in steps.enumerated() {
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s delay
                await MainActor.run {
                    currentStep = step
                    logs.append("[\(Date().formatted(date: .omitted, time: .standard))] \(step)")
                    withAnimation {
                        progress = Double(index + 1) / Double(steps.count)
                    }
                }
            }
            await MainActor.run {
                isFinished = true
            }
        }
    }
}

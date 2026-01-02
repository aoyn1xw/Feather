import SwiftUI

/// A SwiftUI header view for CoreSign with rotating subtitles
/// Changes subtitle when user switches tabs or when app returns to foreground
struct CoreSignHeaderView: View {
    // MARK: - State
    @State private var currentSubtitleIndex: Int = 0
    @State private var isAnimating = false
    @State private var showCredits = false
    var hideAboutButton: Bool = false

    // MARK: - Subtitle Definitions
    /// All available subtitle options as individual localized keys
    private let subtitles: [LocalizedStringKey] = [
        "subtitle.ae_lovers",
        "subtitle.kravashit",
        "subtitle.wsf_top",
        "subtitle.just_when",
        "subtitle.no_competition",
        "subtitle.love_ragebaiting",
        "subtitle.drizzy_kendrick",
        "subtitle.crashouts",
        "subtitle.random_project",
        "subtitle.want_s",
        "subtitle.use_coresign",
        "subtitle.made_in",
        "subtitle.swiftui"
    ]
    
    private var currentSubtitle: LocalizedStringKey {
        subtitles[currentSubtitleIndex]
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // App Icon
                if let icon = UIImage(named: "AppIcon") {
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.accentColor, .accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "app.badge")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text("CoreSign")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    // Rotating Subtitle
                    Text(currentSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                        .id(currentSubtitleIndex)
                }

                Spacer()
                
                VStack(alignment: .trailing, spacing: 10) {
                    // Version Badge with modern design
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.accentColor)
                        Text("v1.0.4")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.12))
                    )
                    
                    // Credits Button with modern design
                    if !hideAboutButton {
                        Button {
                            showCredits = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.3.fill")
                                    .font(.caption)
                                Text(.localized("Credits"))
                                    .font(.callout)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.accentColor)
                            )
                            .shadow(color: .accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
        )
        .padding(.horizontal)
        .onAppear {
            setupLifecycleObservers()
            rotateSubtitle()
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
    }

    // MARK: - Methods

    /// Sets up observers for app lifecycle and tab changes
    private func setupLifecycleObservers() {
        // Observe when app becomes active (foreground)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            rotateSubtitle()
        }

        // Observe when app will resign active (background)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Optional: Could pause animations here if needed
        }
    }

    /// Rotates to a new random subtitle with animation
    private func rotateSubtitle() {
        guard !subtitles.isEmpty else { return }

        // Get a random subtitle index different from current
        var newIndex = Int.random(in: 0..<subtitles.count)

        // Ensure it's different from current (if we have multiple options)
        if subtitles.count > 1 {
            var attempts = 0
            while newIndex == currentSubtitleIndex && attempts < 10 {
                newIndex = Int.random(in: 0..<subtitles.count)
                attempts += 1
            }
        }

        // Animate the change
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentSubtitleIndex = newIndex
        }
    }

    /// Public method to trigger subtitle rotation (call this when tab changes)
    func onTabChange() {
        rotateSubtitle()
    }
}

// MARK: - Preview
#Preview {
    CoreSignHeaderView()
        .padding()
}

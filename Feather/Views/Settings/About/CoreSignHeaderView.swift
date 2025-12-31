import SwiftUI

/// A SwiftUI header view for CoreSign with rotating subtitles
/// Changes subtitle when user switches tabs or when app returns to foreground
struct CoreSignHeaderView: View {
    // MARK: - State
    @State private var currentSubtitle: LocalizedStringKey = "subtitle.crashouts"
    @State private var isAnimating = false

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

    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "app.badge")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text("CoreSign")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    // Rotating Subtitle
                    Text(currentSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                        .id(currentSubtitle) // Force view recreation on change
                }

                Spacer()

                // Version Badge
                Text("v1.0")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.15))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .onAppear {
            setupLifecycleObservers()
            rotateSubtitle()
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

        // Get a random subtitle different from current
        var newSubtitle = subtitles.randomElement() ?? subtitles[0]

        // Ensure it's different from current (if we have multiple options)
        if subtitles.count > 1 {
            var attempts = 0
            while newSubtitle == currentSubtitle && attempts < 10 {
                newSubtitle = subtitles.randomElement() ?? subtitles[0]
                attempts += 1
            }
        }

        // Animate the change
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentSubtitle = newSubtitle
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

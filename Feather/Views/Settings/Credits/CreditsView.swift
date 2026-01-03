import SwiftUI
import NimbleViews

// MARK: - Credits Item Model
struct CreditItem {
	let username: String
	let githubUsername: String // Username to fetch from GitHub API
	let role: String
	let githubUrl: String
	let gradientColors: [Color]
	let icon: String
}

// MARK: - View
struct CreditsView: View {
	@State private var animationOffset: CGFloat = 0
	@State private var cardScale: CGFloat = 0.8
	@State private var cardOpacity: Double = 0
	@State private var rotationAngle: Double = 0
	
	private let credits: [CreditItem] = [
		CreditItem(
			username: "aoyn1xw",
			githubUsername: "aoyn1xw",
			role: .localized("Developer"),
			githubUrl: "https://github.com/aoyn1xw",
			gradientColors: [SwiftUI.Color(hex: "#0077BE"), SwiftUI.Color(hex: "#00A8E8")],
			icon: "person.fill"
		),
		CreditItem(
			username: "dylans2010",
			githubUsername: "dylans2010",
			role: .localized("Designer"),
			githubUrl: "https://github.com/dylans2010",
			gradientColors: [SwiftUI.Color(hex: "#ff7a83"), SwiftUI.Color(hex: "#FF2D55")],
			icon: "paintbrush.fill"
		),
		CreditItem(
			username: "Feather",
			githubUsername: "khcrysalis",
			role: .localized("Original Developer Team"),
			githubUrl: "https://github.com/khcrysalis/Feather",
			gradientColors: [SwiftUI.Color(hex: "#4CD964"), SwiftUI.Color(hex: "#4860e8")],
			icon: "star.fill"
		)
	]
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Credits")) {
			Section {
				VStack(spacing: 24) {
					// Title with gradient and rotation animation
					VStack(spacing: 12) {
						Image(systemName: "person.3.fill")
							.font(.system(size: 42, weight: .bold))
							.foregroundStyle(
								LinearGradient(
									colors: [.purple, .blue, .cyan],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.scaleEffect(cardScale)
							.opacity(cardOpacity)
							.rotationEffect(.degrees(rotationAngle))
						
						Text(.localized("Credits"))
							.font(.title)
							.bold()
							.scaleEffect(cardScale)
							.opacity(cardOpacity)
					}
					.frame(maxWidth: .infinity)
					.padding(.top, 8)
					
					// Credit Cards
					ForEach(Array(credits.enumerated()), id: \.offset) { index, credit in
						GitHubCreditCard(
							credit: credit,
							delay: Double(index) * 0.1 + 0.1
						)
					}
				}
				.padding(.vertical, 12)
			}
			.listRowBackground(EmptyView())
		}
		.onAppear {
			// Animate title appearance
			withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
				cardScale = 1.0
				cardOpacity = 1.0
			}
			
			// Continuous subtle rotation animation
			withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
				rotationAngle = 360
			}
		}
	}
}

// MARK: - GitHub Credit Card View
struct GitHubCreditCard: View {
	let credit: CreditItem
	let delay: Double
	
	@StateObject private var viewModel = GitHubUserViewModel()
	@State private var cardScale: CGFloat = 0.8
	@State private var cardOpacity: Double = 0
	@State private var shimmerOffset: CGFloat = -200
	
	var body: some View {
		Button {
			guard let url = URL(string: credit.githubUrl) else { return }
			UIApplication.open(url)
		} label: {
			ZStack {
				// Gradient background with enhanced effects
				LinearGradient(
					colors: credit.gradientColors + [credit.gradientColors[0].opacity(0.5)],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
				.opacity(0.15)
				
				// Shimmer effect
				LinearGradient(
					colors: [
						.clear,
						credit.gradientColors[0].opacity(0.3),
						.clear
					],
					startPoint: .leading,
					endPoint: .trailing
				)
				.frame(width: 100)
				.offset(x: shimmerOffset)
				.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
				
				// Card content
				HStack(spacing: 16) {
					// Profile picture or icon with gradient
					ZStack {
						if let avatarImage = viewModel.avatarImage {
							Image(uiImage: avatarImage)
								.resizable()
								.aspectRatio(contentMode: .fill)
								.frame(width: 56, height: 56)
								.clipShape(Circle())
								.overlay(
									Circle()
										.stroke(
											LinearGradient(
												colors: credit.gradientColors,
												startPoint: .topLeading,
												endPoint: .bottomTrailing
											),
											lineWidth: 2
										)
								)
								.shadow(color: credit.gradientColors[0].opacity(0.4), radius: 8, x: 0, y: 4)
						} else {
							// Fallback to icon while loading or on error
							Circle()
								.fill(
									LinearGradient(
										colors: credit.gradientColors,
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 56, height: 56)
								.shadow(color: credit.gradientColors[0].opacity(0.3), radius: 8, x: 0, y: 4)
							
							if viewModel.isLoading {
								// Loading indicator
								ProgressView()
									.tint(.white)
							} else {
								// Icon when not loading and no avatar
								Image(systemName: credit.icon)
									.font(.system(size: 24, weight: .semibold))
									.foregroundStyle(.white)
							}
						}
					}
					
					// Text content
					VStack(alignment: .leading, spacing: 4) {
						Text(viewModel.user?.name ?? credit.username)
							.font(.headline)
							.fontWeight(.bold)
							.foregroundStyle(.primary)
						
						Text(credit.role)
							.font(.subheadline)
							.foregroundStyle(.secondary)
						
						if let bio = viewModel.user?.bio, !bio.isEmpty {
							Text(bio)
								.font(.caption)
								.foregroundStyle(.secondary)
								.lineLimit(2)
								.padding(.top, 2)
						}
					}
					
					Spacer()
					
					// Arrow with gradient
					Image(systemName: "arrow.up.right")
						.font(.system(size: 18, weight: .semibold))
						.foregroundStyle(
							LinearGradient(
								colors: credit.gradientColors,
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
				}
				.padding(16)
			}
			.frame(maxWidth: .infinity)
			.frame(minHeight: 88)
			.background(Color(uiColor: .secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.stroke(
						LinearGradient(
							colors: credit.gradientColors.map { $0.opacity(0.4) },
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 1.5
					)
			)
			.shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
			.scaleEffect(cardScale)
			.opacity(cardOpacity)
		}
		.buttonStyle(ScaleButtonStyle())
		.onAppear {
			// Fetch GitHub user data using the explicit GitHub username
			viewModel.fetchUser(username: credit.githubUsername)
			
			// Stagger card animations
			withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(delay)) {
				cardScale = 1.0
				cardOpacity = 1.0
			}
			
			// Shimmer animation
			withAnimation(.linear(duration: 2).repeatForever(autoreverses: false).delay(delay)) {
				shimmerOffset = 400
			}
		}
	}
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? 0.95 : 1.0)
			.animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
	}
}

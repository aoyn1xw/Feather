import SwiftUI
import NimbleViews

// MARK: - View
struct CreditsView: View {
	@State private var animationOffset: CGFloat = 0
	@State private var cardScale: CGFloat = 0.8
	@State private var cardOpacity: Double = 0
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Credits")) {
			Section {
				VStack(spacing: 24) {
					// Title with gradient
					VStack(spacing: 12) {
						Image(systemName: "person.3.fill")
							.font(.system(size: 42, weight: .bold))
							.foregroundStyle(
								LinearGradient(
									colors: [.purple, .blue],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.scaleEffect(cardScale)
							.opacity(cardOpacity)
						
						Text(.localized("Credits"))
							.font(.title)
							.bold()
							.scaleEffect(cardScale)
							.opacity(cardOpacity)
					}
					.frame(maxWidth: .infinity)
					.padding(.top, 8)
					
					// Developer Card
					_creditCard(
						name: "aoyn1xw",
						role: .localized("Developer"),
						githubUrl: "https://github.com/aoyn1xw",
						gradientColors: [Color(hex: "#B496DC"), Color(hex: "#848ef9")],
						icon: "person.fill",
						delay: 0.1
					)
					
					// Designer Card
					_creditCard(
						name: "dylans2010",
						role: .localized("Designer"),
						githubUrl: "https://github.com/dylans2010",
						gradientColors: [Color(hex: "#ff7a83"), Color(hex: "#FF2D55")],
						icon: "paintbrush.fill",
						delay: 0.2
					)
					
					// Original Developer Team Card
					_creditCard(
						name: "Feather",
						role: .localized("Original Developer Team"),
						githubUrl: "https://github.com/khcrysalis/Feather",
						gradientColors: [Color(hex: "#4CD964"), Color(hex: "#4860e8")],
						icon: "star.fill",
						delay: 0.3
					)
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
		}
	}
	
	@ViewBuilder
	private func _creditCard(
		name: String,
		role: String,
		githubUrl: String,
		gradientColors: [Color],
		icon: String,
		delay: Double
	) -> some View {
		Button {
			UIApplication.open(githubUrl)
		} label: {
			ZStack {
				// Gradient background
				LinearGradient(
					colors: gradientColors,
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
				.opacity(0.15)
				
				// Card content
				HStack(spacing: 16) {
					// Icon with gradient
					ZStack {
						Circle()
							.fill(
								LinearGradient(
									colors: gradientColors,
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 56, height: 56)
							.shadow(color: gradientColors[0].opacity(0.3), radius: 8, x: 0, y: 4)
						
						Image(systemName: icon)
							.font(.system(size: 24, weight: .semibold))
							.foregroundStyle(.white)
					}
					
					// Text content
					VStack(alignment: .leading, spacing: 4) {
						Text(name)
							.font(.headline)
							.fontWeight(.bold)
							.foregroundStyle(.primary)
						
						Text(role)
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					
					Spacer()
					
					// Arrow with gradient
					Image(systemName: "arrow.up.right")
						.font(.system(size: 18, weight: .semibold))
						.foregroundStyle(
							LinearGradient(
								colors: gradientColors,
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
				}
				.padding(16)
			}
			.frame(maxWidth: .infinity)
			.frame(height: 88)
			.background(Color(uiColor: .secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.stroke(
						LinearGradient(
							colors: gradientColors.map { $0.opacity(0.3) },
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 1
					)
			)
			.shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
			.scaleEffect(cardScale)
			.opacity(cardOpacity)
		}
		.buttonStyle(ScaleButtonStyle())
		.onAppear {
			// Stagger card animations
			withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(delay)) {
				cardScale = 1.0
				cardOpacity = 1.0
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

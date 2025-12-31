import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
	@State private var _isPulsing = false
	@State private var dominantColor: Color = .accentColor
	@State private var _rotationAngle: Double = 0
	
	var app: AppInfoPresentable
	@ObservedObject var viewModel: InstallerStatusViewModel
	
	var body: some View {
		VStack(spacing: 12) {
			_appIcon()
				.scaleEffect(_isPulsing ? 0.90 : 0.85)
				.animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: _isPulsing)
				.onAppear {
					_isPulsing = true
					extractDominantColor()
					startRotation()
				}
		}
	}
	
	@ViewBuilder
	private func _appIcon() -> some View {
		ZStack {
			// Outer glow effect that pulses with dominant color
			Circle()
				.fill(
					RadialGradient(
						colors: [
							dominantColor.opacity(viewModel.isCompleted ? 0.4 : 0.3),
							dominantColor.opacity(0.1),
							Color.clear
						],
						center: .center,
						startRadius: 20,
						endRadius: 60
					)
				)
				.frame(width: 100, height: 100)
				.scaleEffect(_isPulsing ? 1.1 : 1.0)
				.animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: _isPulsing)
			
			// Rotating ring with gradient
			if !viewModel.isCompleted {
				Circle()
					.stroke(
						AngularGradient(
							colors: [
								dominantColor.opacity(0.8),
								dominantColor.opacity(0.4),
								dominantColor.opacity(0.1),
								Color.clear,
								dominantColor.opacity(0.8)
							],
							center: .center,
							startAngle: .degrees(0),
							endAngle: .degrees(360)
						),
						lineWidth: 3
					)
					.frame(width: 70, height: 70)
					.rotationEffect(.degrees(_rotationAngle))
			}
			
			// Shadow layer for depth
			FRAppIconView(app: app)
				.opacity(0.15)
				.frame(width: 54, height: 54)
				.blur(radius: 4)
				.offset(y: 3)
			
			// Main app icon with mask
			FRAppIconView(app: app)
				.frame(width: 54, height: 54)
				.mask(
					ZStack {
						Circle().strokeBorder(Color.white, lineWidth: 4.5)
						PieShape(progress: viewModel.overallProgress)
							.scaleEffect(viewModel.isCompleted ? 2.2 : 1)
							.animation(.spring(response: 0.6, dampingFraction: 0.7), value: viewModel.isCompleted)
					}
				)
				.animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.overallProgress)
				.shadow(color: dominantColor.opacity(0.4), radius: 8, x: 0, y: 4)
			
			// Success overlay with dynamic color
			if viewModel.isCompleted {
				ZStack {
					Circle()
						.fill(dominantColor.opacity(0.2))
						.frame(width: 54, height: 54)
					
					Image(systemName: "checkmark.circle.fill")
						.font(.system(size: 28))
						.foregroundStyle(
							LinearGradient(
								colors: [dominantColor, dominantColor.opacity(0.8)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
				}
				.transition(.scale.combined(with: .opacity))
			}
		}
	}
	
	private func startRotation() {
		withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
			_rotationAngle = 360
		}
	}
	
	private func extractDominantColor() {
		// Extract dominant color from app icon if possible
		Task {
			if let iconURL = app.iconURL,
			   let data = try? Data(contentsOf: iconURL),
			   let uiImage = UIImage(data: data),
			   let cgImage = uiImage.cgImage {
				
				let ciImage = CIImage(cgImage: cgImage)
				let filter = CIFilter(name: "CIAreaAverage")
				filter?.setValue(ciImage, forKey: kCIInputImageKey)
				filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
				
				guard let outputImage = filter?.outputImage else { return }
				
				var pixel = [UInt8](repeating: 0, count: 4)
				CIContext().render(
					outputImage,
					toBitmap: &pixel,
					rowBytes: 4,
					bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
					format: .RGBA8,
					colorSpace: nil
				)
				
				let r = Double(pixel[0]) / 255.0
				let g = Double(pixel[1]) / 255.0
				let b = Double(pixel[2]) / 255.0
				
				await MainActor.run {
					dominantColor = Color(red: r, green: g, blue: b)
				}
			}
		}
	}
	
	struct PieShape: Shape {
		var progress: Double
		
		func path(in rect: CGRect) -> Path {
			var path = Path()
			let center = CGPoint(x: rect.midX, y: rect.midY)
			let radius = min(rect.width, rect.height) / 2
			let startAngle = Angle(degrees: -90)
			let endAngle = Angle(degrees: -90 + progress * 360)
			
			path.move(to: center)
			path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
			path.closeSubpath()
			
			return path
		}
		
		var animatableData: Double {
			get { progress }
			set { progress = newValue }
		}
	}
}

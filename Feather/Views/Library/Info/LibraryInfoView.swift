import SwiftUI
import NimbleViews
import Zsign

// MARK: - View
struct LibraryInfoView: View {
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
	var app: AppInfoPresentable
	@State private var dominantColors: [Color] = []
	@State private var isLoadingColors = true
	
	// MARK: Body
    var body: some View {
		ZStack {
			// Full gradient background based on app icon colors
			if _useGradients && !dominantColors.isEmpty {
				LinearGradient(
					colors: dominantColors.count > 1 
						? [
							dominantColors[0].opacity(0.2),
							dominantColors[1].opacity(0.15),
							Color(uiColor: .systemGroupedBackground),
							dominantColors[0].opacity(0.1)
						]
						: [
							dominantColors[0].opacity(0.2),
							dominantColors[0].opacity(0.1),
							Color(uiColor: .systemGroupedBackground)
						],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				.ignoresSafeArea()
			}
			
			NBNavigationView(app.name ?? "", displayMode: .inline) {
				List {
					Section {} header: {
						VStack(spacing: 16) {
							ZStack {
								// Glow effect behind icon
								if _useGradients && !dominantColors.isEmpty {
									Circle()
										.fill(
											RadialGradient(
												colors: dominantColors.count > 1
													? [dominantColors[0].opacity(0.4), dominantColors[1].opacity(0.2), Color.clear]
													: [dominantColors[0].opacity(0.4), Color.clear],
												center: .center,
												startRadius: 5,
												endRadius: 60
											)
										)
										.frame(width: 120, height: 120)
								}
								
								FRAppIconView(app: app, size: 100)
									.shadow(
										color: dominantColors.isEmpty ? .black.opacity(0.2) : dominantColors[0].opacity(0.5),
										radius: 12,
										x: 0,
										y: 6
									)
							}
							
							VStack(spacing: 4) {
								Text(app.name ?? .localized("Unknown"))
									.font(.title2)
									.fontWeight(.bold)
								
								if let version = app.version, let identifier = app.identifier {
									Text("\(version) • \(identifier)")
										.font(.subheadline)
										.foregroundStyle(.secondary)
								}
							}
							
							if let date = app.date {
								Text("Added \(date.formatted(date: .abbreviated, time: .omitted))")
									.font(.caption)
									.foregroundStyle(.tertiary)
							}
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 20)
					}
					.listRowBackground(Color.clear)
					
					_detailsSection(for: app)
					_certSection(for: app)
					_bundleSection(for: app)
					_executableSection(for: app)
					
					Section {
						Button(.localized("Open in Files"), systemImage: "folder") {
							UIApplication.open(Storage.shared.getUuidDirectory(for: app)!.toSharedDocumentsURL()!)
						}
					}
				}
				.scrollContentBackground(.hidden)
				.toolbar {
					NBToolbarButton(role: .close)
				}
			}
		}
		.onAppear {
			extractAppIconColors()
		}
    }
	
	// Extract multiple dominant colors from app icon
	private func extractAppIconColors() {
		Task {
			guard let iconData = await getAppIconData() else {
				dominantColors = [.accentColor]
				isLoadingColors = false
				return
			}
			
			guard let uiImage = UIImage(data: iconData),
				  let cgImage = uiImage.cgImage else {
				dominantColors = [.accentColor]
				isLoadingColors = false
				return
			}
			
			// Get average color (primary)
			let ciImage = CIImage(cgImage: cgImage)
			let filter = CIFilter(name: "CIAreaAverage")
			filter?.setValue(ciImage, forKey: kCIInputImageKey)
			filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
			
			var colors: [Color] = []
			
			if let outputImage = filter?.outputImage {
				var pixel = [UInt8](repeating: 0, count: 4)
				let context = CIContext()
				context.render(
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
				colors.append(Color(red: r, green: g, blue: b))
			}
			
			// Try to extract a second color from a different region
			let quarterExtent = CGRect(
				x: ciImage.extent.width * 0.25,
				y: ciImage.extent.height * 0.25,
				width: ciImage.extent.width * 0.5,
				height: ciImage.extent.height * 0.5
			)
			
			let filter2 = CIFilter(name: "CIAreaAverage")
			filter2?.setValue(ciImage, forKey: kCIInputImageKey)
			filter2?.setValue(CIVector(cgRect: quarterExtent), forKey: kCIInputExtentKey)
			
			if let outputImage2 = filter2?.outputImage {
				var pixel2 = [UInt8](repeating: 0, count: 4)
				let context = CIContext()
				context.render(
					outputImage2,
					toBitmap: &pixel2,
					rowBytes: 4,
					bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
					format: .RGBA8,
					colorSpace: nil
				)
				
				let r2 = Double(pixel2[0]) / 255.0
				let g2 = Double(pixel2[1]) / 255.0
				let b2 = Double(pixel2[2]) / 255.0
				let secondColor = Color(red: r2, green: g2, blue: b2)
				
				// Only add if significantly different from first color
				if !colors.isEmpty {
					let diff = abs(r2 - (colors[0].cgColor?.components?[0] ?? 0)) +
							   abs(g2 - (colors[0].cgColor?.components?[1] ?? 0)) +
							   abs(b2 - (colors[0].cgColor?.components?[2] ?? 0))
					if diff > 0.3 {
						colors.append(secondColor)
					}
				}
			}
			
			await MainActor.run {
				dominantColors = colors.isEmpty ? [.accentColor] : colors
				isLoadingColors = false
			}
		}
	}
	
	private func getAppIconData() async -> Data? {
		// Get icon from app
		guard let iconPath = Storage.shared.getAppIconFile(for: app) else { return nil }
		return try? Data(contentsOf: iconPath)
	}
}

// MARK: - Extension: View
extension LibraryInfoView {
	@ViewBuilder
	private func _detailsSection(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("Details")) {
			if let name = app.name {
				_detailRow(
					icon: "textformat",
					title: .localized("Name"),
					value: name,
					color: dominantColors.isEmpty ? .blue : dominantColors[0]
				)
			}
			
			if let ver = app.version {
				_detailRow(
					icon: "number",
					title: .localized("Version"),
					value: ver,
					color: dominantColors.count > 1 ? dominantColors[1] : (dominantColors.isEmpty ? .green : dominantColors[0])
				)
			}
			
			if let id = app.identifier {
				_detailRow(
					icon: "tag",
					title: .localized("Bundle ID"),
					value: id,
					color: dominantColors.isEmpty ? .purple : dominantColors[0].opacity(0.8)
				)
			}
			
			if app.isSigned {
				_detailRow(
					icon: "checkmark.seal.fill",
					title: .localized("Status"),
					value: .localized("Signed"),
					color: .green
				)
			} else {
				_detailRow(
					icon: "xmark.seal.fill",
					title: .localized("Status"),
					value: .localized("Unsigned"),
					color: .orange
				)
			}
		}
	}
	
	@ViewBuilder
	private func _detailRow(icon: String, title: String, value: String, color: Color) -> some View {
		HStack(spacing: 12) {
			ZStack {
				if _useGradients && !dominantColors.isEmpty {
					RoundedRectangle(cornerRadius: 8)
						.fill(
							LinearGradient(
								colors: [color.opacity(0.3), color.opacity(0.15)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.frame(width: 32, height: 32)
				} else {
					RoundedRectangle(cornerRadius: 8)
						.fill(color.opacity(0.15))
						.frame(width: 32, height: 32)
				}
				
				Image(systemName: icon)
					.font(.title3)
					.foregroundStyle(color)
			}
			
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(value)
					.font(.body)
					.fontWeight(.medium)
			}
			
			Spacer()
		}
		.copyableText(value)
	}
	
	@ViewBuilder
	private func _certSection(for app: AppInfoPresentable) -> some View {
		if let cert = Storage.shared.getCertificate(from: app) {
			NBSection(.localized("Certificate")) {
				CertificatesCellView(
					cert: cert
				)
			}
		}
	}
	
	@ViewBuilder
	private func _bundleSection(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("Bundle")) {
			NavigationLink(.localized("Alternative Icons")) {
				SigningAlternativeIconView(app: app, appIcon: .constant(nil), isModifing: .constant(false))
			}
			NavigationLink(.localized("Frameworks & PlugIns")) {
				SigningFrameworksView(app: app, options: .constant(nil))
			}
		}
	}
	
	@ViewBuilder
	private func _executableSection(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("Executable")) {
			NavigationLink(.localized("Dylibs")) {
				SigningDylibView(app: app, options: .constant(nil))
			}
		}
	}
}

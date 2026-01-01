import SwiftUI
import Combine
import NimbleExtensions

struct DownloadHeaderView: View {
	@ObservedObject var downloadManager: DownloadManager
	
	var body: some View {
		ZStack {
			if !downloadManager.manualDownloads.isEmpty {
				VStack(spacing: 0) {
					VStack(spacing: 16) {
						if let firstDownload = downloadManager.manualDownloads.first {
							DownloadItemView(download: firstDownload)
							
							if downloadManager.manualDownloads.count > 1 {
								HStack {
									Spacer()
									HStack(spacing: 6) {
										Image(systemName: "arrow.down.circle.fill")
											.font(.caption2)
											.foregroundStyle(Color.accentColor)
										Text(verbatim: "+\(downloadManager.manualDownloads.count - 1) more")
											.font(.caption)
											.fontWeight(.medium)
											.foregroundColor(.secondary)
									}
									.padding(.horizontal, 12)
									.padding(.vertical, 6)
									.background(
										Capsule()
											.fill(Color.accentColor.opacity(0.1))
									)
								}
							}
						}
					}
					.padding(20)
					.background(
						RoundedRectangle(cornerRadius: 20, style: .continuous)
							.fill(
								LinearGradient(
									colors: [
										Color(UIColor.secondarySystemBackground),
										Color(UIColor.tertiarySystemBackground)
									],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.overlay(
								RoundedRectangle(cornerRadius: 20, style: .continuous)
									.stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
							)
							.shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
					)
					.padding(.horizontal, 16)
				}
				.transition(.asymmetric(
					insertion: .move(edge: .top).combined(with: .opacity),
					removal: .move(edge: .top).combined(with: .opacity)
				))
			}
		}
		.animation(.spring(response: 0.5, dampingFraction: 0.8), value: downloadManager.manualDownloads.count)
	}
}

struct DownloadItemView: View {
	let download: Download
	@State private var progress: Double = 0
	@State private var bytesDownloaded: Int64 = 0
	@State private var totalBytes: Int64 = 0
	@State private var unpackageProgress: Double = 0
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(spacing: 12) {
				// Animated download icon
				ZStack {
					Circle()
						.fill(
							LinearGradient(
								colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.frame(width: 44, height: 44)
					
					Image(systemName: overallProgress >= 1.0 ? "checkmark.circle.fill" : "arrow.down.circle.fill")
						.font(.title2)
						.foregroundStyle(
							LinearGradient(
								colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.modifier(SymbolEffectModifier(trigger: overallProgress >= 1.0))
				}
				.shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
				
				VStack(alignment: .leading, spacing: 4) {
					Text(download.fileName)
						.font(.subheadline)
						.fontWeight(.semibold)
						.lineLimit(1)
						.foregroundStyle(.primary)
					
					HStack(spacing: 8) {
						Text(verbatim: "\(Int(overallProgress * 100))%")
							.font(.caption)
							.fontWeight(.medium)
							.foregroundColor(.accentColor)
							.modifier(NumericTextTransitionModifier())
						
						if totalBytes > 0 {
							Text("•")
								.font(.caption2)
								.foregroundColor(.secondary)
							Text(verbatim: "\($bytesDownloaded.wrappedValue.formattedByteCount) / \(totalBytes.formattedByteCount)")
								.font(.caption)
								.foregroundColor(.secondary)
								.modifier(NumericTextTransitionModifier())
						}
					}
				}
			}
			
			// Enhanced progress bar with gradient
			ZStack(alignment: .leading) {
				// Background track
				Capsule()
					.fill(Color(UIColor.tertiarySystemFill))
					.frame(height: 6)
				
				// Progress fill with animated gradient
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
					.frame(width: progressBarWidth, height: 6)
					.shadow(color: Color.accentColor.opacity(0.5), radius: 4, x: 0, y: 2)
					.animation(.spring(response: 0.5, dampingFraction: 0.8), value: overallProgress)
			}
		}
		.onReceive(download.$progress) { self.progress = $0 }
		.onReceive(download.$bytesDownloaded) { self.bytesDownloaded = $0 }
		.onReceive(download.$totalBytes) { self.totalBytes = $0 }
		.onReceive(download.$unpackageProgress) { self.unpackageProgress = $0 }
	}
	
	private var overallProgress: Double {
		download.onlyArchiving
		? unpackageProgress
		: (0.3 * unpackageProgress) + (0.7 * progress)
	}
	
	private var progressBarWidth: CGFloat {
		max(6, CGFloat(overallProgress) * UIScreen.main.bounds.width * 0.85)
	}
}

// MARK: - Helper ViewModifier for iOS 16 compatibility
struct SymbolEffectModifier: ViewModifier {
    let trigger: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .symbolEffect(.bounce, value: trigger)
        } else {
            content
                .scaleEffect(trigger ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: trigger)
        }
    }
}

struct NumericTextTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentTransition(.numericText())
        } else {
            content
                .animation(.easeInOut(duration: 0.2), value: UUID())
        }
    }
}


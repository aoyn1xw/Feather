//  Created by samsam on 7/25/25.
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews

struct DownloadButtonView: View {
	let app: ASRepository.App
	@ObservedObject private var downloadManager = DownloadManager.shared

	@State private var downloadProgress: Double = 0
	@State private var cancellable: AnyCancellable?

	var body: some View {
		ZStack {
			if let currentDownload = downloadManager.getDownload(by: app.currentUniqueId) {
				ZStack {
					Circle()
						.stroke(Color.accentColor.opacity(0.2), lineWidth: 2.5)
						.frame(width: 34, height: 34)
					
					Circle()
						.trim(from: 0, to: downloadProgress)
						.stroke(
							LinearGradient(
								colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							),
							style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
						)
						.rotationEffect(.degrees(-90))
						.frame(width: 34, height: 34)
						.animation(.smooth, value: downloadProgress)

					Image(systemName: downloadProgress >= 0.75 ? "checkmark" : "stop.fill")
						.foregroundStyle(.tint)
						.font(.system(size: 12, weight: .bold))
						.scaleEffect(downloadProgress >= 0.75 ? 1.1 : 0.9)
						.animation(.spring(response: 0.3, dampingFraction: 0.7), value: downloadProgress >= 0.75)
				}
				.onTapGesture {
					if downloadProgress <= 0.75 {
						downloadManager.cancelDownload(currentDownload)
					}
				}
				.compatTransition()
			} else {
				Button {
					if let url = app.currentDownloadUrl {
						_ = downloadManager.startDownload(from: url, id: app.currentUniqueId)
					}
				} label: {
					Text(.localized("Get"))
						.lineLimit(0)
						.font(.headline.bold())
						.foregroundStyle(.white)
						.padding(.horizontal, 28)
						.padding(.vertical, 8)
						.background(
							LinearGradient(
								colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.clipShape(Capsule())
						.shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
				}
				.buttonStyle(.borderless)
				.compatTransition()
			}
		}
		.onAppear(perform: setupObserver)
		.onDisappear { cancellable?.cancel() }
		.onChange(of: downloadManager.downloads.description) { _ in
			setupObserver()
		}
		.animation(.spring(response: 0.4, dampingFraction: 0.8), value: downloadManager.getDownload(by: app.currentUniqueId) != nil)
	}

	private func setupObserver() {
		cancellable?.cancel()
		guard let download = downloadManager.getDownload(by: app.currentUniqueId) else {
			downloadProgress = 0
			return
		}
		downloadProgress = download.overallProgress

		let publisher = Publishers.CombineLatest(
			download.$progress,
			download.$unpackageProgress
		)

		cancellable = publisher.sink { _, _ in
			downloadProgress = download.overallProgress
		}
	}
}

import SwiftUI
import NimbleViews
import IDeviceSwift

// MARK: - View
struct TunnelView: View {
	@State private var _isImportingPairingPresenting = false
	
	@State var doesHavePairingFile = false
	@State private var isLocalDevVpnAvailable = false
	
	// MARK: Body
    var body: some View {
		Group {
			Section {
				_tunnelInfo()
				TunnelHeaderView()
			} footer: {
				if doesHavePairingFile {
					Text(.localized("Seems like you've gotten your hands on your pairing file!"))
						.foregroundStyle(
							LinearGradient(
								colors: [Color.green, Color.green.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
				} else {
					Text(.localized("No pairing file found, please import it."))
						.foregroundStyle(
							LinearGradient(
								colors: [Color.orange, Color.orange.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
				}
			}
			
			Section {
				Button {
					_isImportingPairingPresenting = true
				} label: {
					HStack(spacing: 16) {
						ZStack {
							Circle()
								.fill(
									LinearGradient(
										colors: [Color.blue, Color.cyan, Color.blue.opacity(0.8)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 44, height: 44)
								.shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 4)
							
							Image(systemName: "square.and.arrow.down")
								.font(.title3)
								.foregroundStyle(.white)
						}
						
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Import Pairing File"))
								.font(.body)
								.fontWeight(.semibold)
								.foregroundStyle(.primary)
							Text(.localized("Required for device connection"))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.tertiary)
					}
					.padding(.vertical, 4)
				}
				
				Button {
					HeartbeatManager.shared.start(true)
					
					DispatchQueue.global(qos: .userInitiated).async {
						if !HeartbeatManager.shared.checkSocketConnection().isConnected {
							DispatchQueue.main.async {
								UIAlertController.showAlertWithOk(
									title: "Socket",
									message: "Unable to connect to TCP. Make sure you have loopback VPN enabled and you are on WiFi or Airplane mode."
								)
							}
						}
					}
				} label: {
					HStack(spacing: 16) {
						ZStack {
							Circle()
								.fill(
									LinearGradient(
										colors: [Color.green, Color.mint, Color.green.opacity(0.8)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 44, height: 44)
								.shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 4)
							
							Image(systemName: "arrow.counterclockwise")
								.font(.title3)
								.foregroundStyle(.white)
						}
						
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Restart Heartbeat"))
								.font(.body)
								.fontWeight(.semibold)
								.foregroundStyle(.primary)
							Text(.localized("Reconnect to device"))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.tertiary)
					}
					.padding(.vertical, 4)
				}
			}
			
			NBSection(.localized("Help")) {
				Button {
					UIApplication.open("https://github.com/StephenDev0/StikDebug-Guide/blob/main/pairing_file.md")
				} label: {
					HStack(spacing: 16) {
						ZStack {
							Circle()
								.fill(
									LinearGradient(
										colors: [Color.purple, Color.pink, Color.purple.opacity(0.8)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 44, height: 44)
								.shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 4)
							
							Image(systemName: "questionmark.circle")
								.font(.title3)
								.foregroundStyle(.white)
						}
						
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Pairing File Guide"))
								.font(.body)
								.fontWeight(.semibold)
								.foregroundStyle(.primary)
							Text(.localized("Learn how to get it"))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						Image(systemName: "arrow.up.right")
							.font(.caption)
							.foregroundStyle(.tertiary)
					}
					.padding(.vertical, 4)
				}
				
				if isLocalDevVpnAvailable {
					Button {
						UIApplication.open("localdevvpn://enable?scheme=feather")
					} label: {
						HStack(spacing: 16) {
							ZStack {
								Circle()
									.fill(
										LinearGradient(
											colors: [Color.indigo, Color.blue, Color.indigo.opacity(0.8)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 44, height: 44)
									.shadow(color: Color.indigo.opacity(0.4), radius: 10, x: 0, y: 4)
								
								Image(systemName: "link")
									.font(.title3)
									.foregroundStyle(.white)
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Connect to LocalDevVPN"))
									.font(.body)
									.fontWeight(.semibold)
									.foregroundStyle(.primary)
								Text(.localized("Enable VPN connection"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
							
							Spacer()
							
							Image(systemName: "arrow.up.right")
								.font(.caption)
								.foregroundStyle(.tertiary)
						}
						.padding(.vertical, 4)
					}
				} else {
					Button {
						UIApplication.open("https://apps.apple.com/us/app/localdevvpn/id6755608044")
					} label: {
						HStack(spacing: 16) {
							ZStack {
								Circle()
									.fill(
										LinearGradient(
											colors: [Color.orange, Color.yellow, Color.orange.opacity(0.8)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 44, height: 44)
									.shadow(color: Color.orange.opacity(0.4), radius: 10, x: 0, y: 4)
								
								Image(systemName: "arrow.down.app")
									.font(.title3)
									.foregroundStyle(.white)
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Download LocalDevVPN"))
									.font(.body)
									.fontWeight(.semibold)
									.foregroundStyle(.primary)
								Text(.localized("Required for installation"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
							
							Spacer()
							
							Image(systemName: "arrow.up.right")
								.font(.caption)
								.foregroundStyle(.tertiary)
						}
						.padding(.vertical, 4)
					}
				}
			}
		}
		.sheet(isPresented: $_isImportingPairingPresenting) {
			FileImporterRepresentableView(
				allowedContentTypes:  [.xmlPropertyList, .plist, .mobiledevicepairing],
				onDocumentsPicked: { urls in
					guard let selectedFileURL = urls.first else { return }
					FR.movePairing(selectedFileURL)
					doesHavePairingFile = true
				}
			)
			.ignoresSafeArea()
		}
		.onAppear {
			doesHavePairingFile = FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile())
			? true
			: false
			
			if let url = URL(string: "localdevvpn://") {
				isLocalDevVpnAvailable = UIApplication.shared.canOpenURL(url)
			} else {
				isLocalDevVpnAvailable = false
			}
		}
    }
	
	@ViewBuilder
	private func _tunnelInfo() -> some View {
		HStack(spacing: 16) {
			ZStack {
				Circle()
					.fill(
						LinearGradient(
							colors: [
								Color.blue.opacity(0.2),
								Color.cyan.opacity(0.15),
								Color.blue.opacity(0.1)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: 60, height: 60)
					.shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 4)
				
				Image(systemName: "heart.circle.fill")
					.font(.system(size: 32))
					.foregroundStyle(
						LinearGradient(
							colors: [Color.blue, Color.cyan, Color.blue.opacity(0.8)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
			}
			
			VStack(alignment: .leading, spacing: 6) {
				Text(.localized("Heartbeat"))
					.font(.headline)
					.foregroundStyle(
						LinearGradient(
							colors: [Color.primary, Color.blue.opacity(0.6)],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
				Text(.localized("The heartbeat is activated in the background, it will restart when the app is re-opened or prompted. If the status below is pulsing, that means its healthy."))
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		}
		.padding(.vertical, 8)
	}
}
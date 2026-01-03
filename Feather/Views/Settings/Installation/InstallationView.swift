import SwiftUI
import NimbleViews

// MARK: - View
struct InstallationView: View {
	@AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
	@AppStorage("Feather.useTunnel") private var _useTunnel: Bool = false
	
	// MARK: Body
    var body: some View {
		NBList(.localized("Installation")) {
			ServerView()
			
			// Tunnel Toggle Section
			NBSection(.localized("Connection Method")) {
				Toggle(isOn: $_useTunnel) {
					HStack(spacing: 12) {
						ZStack {
							Circle()
								.fill(
									LinearGradient(
										colors: _useTunnel 
											? [Color.green, Color.mint, Color.green.opacity(0.8)]
											: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 40, height: 40)
								.shadow(color: _useTunnel ? Color.green.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 3)
							
							Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
								.font(.system(size: 18))
								.foregroundStyle(_useTunnel ? .white : .secondary)
						}
						
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Tunnel"))
								.font(.body)
								.foregroundStyle(.primary)
							
							Text(.localized("Use iDevice and pairing file method"))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
					.padding(.vertical, 4)
				}
				.toggleStyle(SwitchToggleStyle(tint: .green))
			}
			
			// Only show TunnelView when Tunnel is enabled
			if _useTunnel {
				TunnelView()
			}
		}
    }
}

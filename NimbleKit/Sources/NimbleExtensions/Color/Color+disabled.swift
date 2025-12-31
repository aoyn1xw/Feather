import SwiftUI

extension Color {
	/// Disabled color
	/// - Parameter color: Color
	/// - Returns: "Disabled" version of specified color
	static public func disabled() -> Color {
		.secondary.opacity(0.8)
	}
}

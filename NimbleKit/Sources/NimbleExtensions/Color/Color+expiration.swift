import SwiftUI

extension Color {
	static public func expiration(days: Int) -> Color {
		switch days {
		case ..<14:
			return .red
		case 14..<30:
			return .orange
		case 30..<60:
			return .yellow
		default:
			return .green
		}
	}
}

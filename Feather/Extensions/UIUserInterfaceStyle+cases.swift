import UIKit

extension UIUserInterfaceStyle: @retroactive CaseIterable {
	public static var allCases: [UIUserInterfaceStyle] {
		[.unspecified, .dark, .light]
	}
	
	var label: String {
		switch self {
		case .unspecified: .localized("Default")
		case .dark: .localized("Dark")
		case .light: .localized("Light")
		@unknown default: .localized("Unknown")
		}
	}
}

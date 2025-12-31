import SwiftUI

public struct NBListAdaptable<Content>: View where Content: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	
	private var _content: Content
	
	public init(@ViewBuilder content: () -> Content) {
		self._content = content()
	}
	
	public var body: some View {
		if horizontalSizeClass == .compact {
			List {
				_content
			}
			.listStyle(.plain)
		} else {
			NBGrid {
				_content
			}
		}
	}
}

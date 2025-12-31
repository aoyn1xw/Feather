import SwiftUI

extension View {
	@ViewBuilder
	public func compatTransition() -> some View {
		if #available(iOS 17.0, *) {
			self.transition(.blurReplace)
		} else {
			self.transition(AnyTransition.opacity.combined(with: .scale).combined(with: .opacity))
		}
	}
}

import SwiftUI

extension Binding {
	public func optional() -> Binding<Value?> {
		Binding<Value?>(
			get: { self.wrappedValue },
			set: { if let value = $0 { self.wrappedValue = value } }
		)
	}
}

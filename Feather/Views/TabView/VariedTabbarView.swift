import SwiftUI

struct VariedTabbarView: View {
	init() {}
	
	var body: some View {
		if #available(iOS 18, *) {
			ExtendedTabbarView()
		} else {
			TabbarView()
		}
	}
}

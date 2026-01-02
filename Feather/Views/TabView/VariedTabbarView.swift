import SwiftUI

struct VariedTabbarView: View {
	@AppStorage("feature_experimentalUI") var experimentalUI = false
	
	init() {}
	
	var body: some View {
		if experimentalUI {
			// Experimental UI
			ExperimentalTabbarView()
		} else {
			// Original UI
			if #available(iOS 18, *) {
				ExtendedTabbarView()
			} else {
				TabbarView()
			}
		}
	}
}

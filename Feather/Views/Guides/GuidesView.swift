import SwiftUI
import NimbleViews

// MARK: - GuidesView
struct GuidesView: View {
var body: some View {
NBNavigationView(.localized("Guides")) {
VStack(spacing: 20) {
Spacer()

Image(systemName: "book.fill")
.font(.system(size: 70))
.foregroundStyle(.secondary)

Text(.localized("Guides are coming soon"))
.font(.title2)
.fontWeight(.semibold)
.foregroundStyle(.primary)

Text(.localized("Check back later for helpful guides and tutorials."))
.font(.subheadline)
.foregroundStyle(.secondary)
.multilineTextAlignment(.center)
.padding(.horizontal, 40)

Spacer()
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
}
}
}

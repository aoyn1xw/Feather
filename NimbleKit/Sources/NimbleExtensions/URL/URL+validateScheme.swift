import Foundation.NSURL

extension URL {
	public func validatedScheme(after marker: String) -> String? {
		guard let range = absoluteString.range(of: marker) else { return nil }
		let path = String(absoluteString[range.upperBound...])
		guard path.hasPrefix("https://") else { return nil }
		return path
	}
}

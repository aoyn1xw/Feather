import UIKit.UIImage

extension UIImage {
	static public func fromFile(_ url: URL?) -> UIImage? {
		guard let url = url else {
			return nil
		}
		
		return UIImage(contentsOfFile: url.path)
	}
}


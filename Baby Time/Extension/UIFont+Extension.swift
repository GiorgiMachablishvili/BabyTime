

import UIKit

extension UIFont {
    //MARK: font extension
    static func funnelDesplayBold(size: CGFloat) -> UIFont {
        return UIFont(name: "FunnelDisplay-Bold", size: size) ?? .systemFont(ofSize: size)
    }

    static func funnelDesplayMedium(size: CGFloat) -> UIFont {
        return UIFont(name: "FunnelDisplay-Medium", size: size) ?? .systemFont(ofSize: size)
    }

    static func funnelDesplayRegular(size: CGFloat) -> UIFont {
        return UIFont(name: "FunnelDisplay-Regular", size: size) ?? .systemFont(ofSize: size)
    }

    static func funnelDesplayExtraBold(size: CGFloat) -> UIFont {
        return UIFont(name: "FunnelDisplay-ExtraBold", size: size) ?? .systemFont(ofSize: size)
    }

    static func funnelDesplayLight(size: CGFloat) -> UIFont {
        return UIFont(name: "FunnelDisplay-Light", size: size) ?? .systemFont(ofSize: size)
    }

    static func funnelDesplaySemiBold(size: CGFloat) -> UIFont {
        return UIFont(name: "FunnelDisplay-SemiBold", size: size) ?? .systemFont(ofSize: size)
    }
}

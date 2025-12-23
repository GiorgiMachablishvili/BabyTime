


import UIKit

extension UIView {
    func makeRoundCorners(_ radius: CGFloat) {
        self.layer.cornerRadius = radius  * Constraint.xCoeff
        self.layer.masksToBounds = true
    }
}

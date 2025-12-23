
import UIKit


class Constraint {
    static let deviceHeight = UIScreen.main.bounds.height
    static let deviceWidth = UIScreen.main.bounds.width

    //MARK: figma file device width 390
    static var xCoeff: CGFloat {
        return deviceWidth / 390
    }

    //MARK: figma file device height 844
    static var yCoeff: CGFloat {
        return deviceHeight / 844
    }
}

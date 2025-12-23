

import UIKit
import SnapKit

class MainViewController: UIViewController {

    private lazy var babyButton: UIButton = {
        let view = UIButton(type: .system)
        view.backgroundColor = .systemOrange

        let image = UIImage(systemName: "person")
        view.setImage(image, for: .normal)
        view.tintColor = .white

        view.makeRoundCorners(33)
        view.clipsToBounds = true

        return view
    }()

    private lazy var yourBabyLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Your Baby"
        view.textAlignment = .left
        view.font = UIFont.preferredFont(forTextStyle: .title1)
        view.textColor = .black
        return view
    }()


    private lazy var babyInfoLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Set up baby profile in Setting"
        view.textAlignment = .left
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.textColor = .gray
        return view
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupConstraints()

    }

    private func setupUI() {
        view.addSubview(babyButton)
        view.addSubview(yourBabyLabel)
        view.addSubview(babyInfoLabel)
    }

    private func setupConstraints() {
        babyButton.snp.remakeConstraints { (make) in
            make.top.equalTo(view.snp.top).offset(60 * Constraint.xCoeff)
            make.leading.equalTo(view.snp.leading).offset(20 * Constraint.yCoeff)
            make.width.height.equalTo(66)
        }

        yourBabyLabel.snp.remakeConstraints { (make) in
            make.bottom.equalTo(babyButton.snp.centerY).offset(-2 * Constraint.yCoeff)
            make.leading.equalTo(babyButton.snp.trailing).offset(20 * Constraint.yCoeff)
        }

        babyInfoLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(babyButton.snp.centerY).offset(2 * Constraint.yCoeff)
            make.leading.equalTo(babyButton.snp.trailing).offset(20 * Constraint.yCoeff)
        }

    }


}

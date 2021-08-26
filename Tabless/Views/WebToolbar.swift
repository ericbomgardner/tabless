import UIKit

class WebToolbar: UIView {
    let backButton = UIButton()
    let forwardButton = UIButton()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white

        let buttonsByImageName = [
            backButton: "chevron.left",
            forwardButton: "chevron.right",
        ]
        for (button, systemImageName) in buttonsByImageName {
            button.tintColor = .lightGray
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(UIImage(systemName: systemImageName,
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)),
                            for: .normal)
        }

        let stackView = UIStackView(arrangedSubviews: [backButton, forwardButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.backgroundColor = .white
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8).isActive = true
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

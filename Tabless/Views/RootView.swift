import UIKit
import WebKit

class RootView: UIView {

    let searchView = SearchView()
    let tView = UILabel()
    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .custom)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18)
        let settingsIcon = UIImage(systemName: "gearshape.fill", withConfiguration: symbolConfig)
        button.setImage(settingsIcon, for: .normal)
        button.tintColor = UIColor.lightGray
        button.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        return button
    }()

    private var tViewTopConstraint: NSLayoutConstraint!
    private(set) var searchViewBottomConstraint: NSLayoutConstraint!

    init() {
        super.init(frame: .zero)

        tView.text = "T"
        tView.textColor = UIColor.lightGray
        tView.backgroundColor = UIColor.clear

        backgroundColor = UIColor(named: "Background")

        addSubview(tView)
        addSubview(settingsButton)
        addSubview(searchView)

        tView.translatesAutoresizingMaskIntoConstraints = false
        tViewTopConstraint = tView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 80)
        tViewTopConstraint.isActive = true
        tView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        updateTextSize()

        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 4).isActive = true
        settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true

        searchView.translatesAutoresizingMaskIntoConstraints = false
        searchView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor).isActive = true
        searchView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor).isActive = true
        searchViewBottomConstraint = searchView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        searchViewBottomConstraint.isActive = true
        let searchViewCenterConstraint = searchView.centerYAnchor.constraint(equalTo: centerYAnchor)
        searchViewCenterConstraint.priority = .defaultHigh
        searchViewCenterConstraint.isActive = true
        searchView.heightAnchor.constraint(equalToConstant: searchView.height(for: .search)).isActive = true

        searchView.configure(for: .search)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTextSize() {
        let tViewTextSize: CGFloat = traitCollection.isLarge ? 80 : 64
        tView.font = UIFont.boldSystemFont(ofSize: tViewTextSize)
    }

    @objc private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: Sizing

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateTextSize()

        // TODO: Resize search view
    }
}

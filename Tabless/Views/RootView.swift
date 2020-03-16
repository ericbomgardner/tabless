import UIKit
import WebKit

class RootView: UIView {

    let searchView = SearchView()
    let tView = TView()

    private var tViewTopConstraint: NSLayoutConstraint!

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor(named: "Background")

        addSubview(tView)
        addSubview(searchView)

        tView.translatesAutoresizingMaskIntoConstraints = false
        tViewTopConstraint = tView.topAnchor.constraint(equalTo: topAnchor, constant: 80)
        tViewTopConstraint.isActive = true
        tView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        updateTextSize()

        searchView.translatesAutoresizingMaskIntoConstraints = false
        searchView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor).isActive = true
        searchView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor).isActive = true
        searchView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        searchView.heightAnchor.constraint(equalToConstant: searchView.height(for: .search)).isActive = true

        searchView.configure(for: .search)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTextSize() {
        let tViewTextSize: CGFloat = traitCollection.isLarge ? 80 : 64
        tView.tLabel.font = UIFont.boldSystemFont(ofSize: tViewTextSize)
    }

    // MARK: Sizing

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateTextSize()

        // TODO: Resize search view
    }
}

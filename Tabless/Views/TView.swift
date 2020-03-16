import UIKit

class TView: UIView {

    enum State {
        case showingT
        case showingWebIndicator
        case showingSearchIndicator
    }

    var state: State = .showingT {
        didSet {
            updateViewForCurrentState()
        }
    }

    let tLabel: UILabel = {
        let label = UILabel()
        #if DEBUG
        label.text = "T."
        #else
        label.text = "T"
        #endif
        label.textColor = UIColor.lightGray
        return label
    }()
    let webIndicatorImageView: UIImageView = {
        let image = UIImage(named: "Web")?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.lightGray
        return imageView
    }()
    let searchIndicatorImageView: UIImageView = {
        let image = UIImage(named: "Search")?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.lightGray
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear

        addSubview(tLabel)
        tLabel.translatesAutoresizingMaskIntoConstraints = false
        tLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        tLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        addSubview(webIndicatorImageView)
        webIndicatorImageView.translatesAutoresizingMaskIntoConstraints = false
        webIndicatorImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        webIndicatorImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        webIndicatorImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        webIndicatorImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        addSubview(searchIndicatorImageView)
        searchIndicatorImageView.translatesAutoresizingMaskIntoConstraints = false
        searchIndicatorImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        searchIndicatorImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        searchIndicatorImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        searchIndicatorImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        updateViewForCurrentState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateViewForCurrentState() {
        switch state {
        case .showingT:
            tLabel.isHidden = false
            webIndicatorImageView.isHidden = true
            searchIndicatorImageView.isHidden = true
        case .showingWebIndicator:
            tLabel.isHidden = true
            webIndicatorImageView.isHidden = false
            searchIndicatorImageView.isHidden = true
        case .showingSearchIndicator:
            tLabel.isHidden = true
            webIndicatorImageView.isHidden = true
            searchIndicatorImageView.isHidden = false
        }
    }
}

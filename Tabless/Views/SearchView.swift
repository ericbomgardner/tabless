import UIKit

protocol SearchViewDelegate: class {
    func searchSubmitted(_ text: String)
    func searchCleared()
}

enum Activity {
    case search
    case web
}

class SearchView: UITextField {
    weak var searchDelegate: SearchViewDelegate?

    private var activity: Activity?

    private var shouldPreventResigningFirstReponder = true

    init() {
        super.init(frame: CGRect.zero)

        returnKeyType = .go
        placeholder = "Let's go."
        clearButtonMode = UITextFieldViewMode.always
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func height(for activity: Activity) -> CGFloat {
        switch activity {
        case .search:
            return traitCollection.isLarge ? 80 : 60
        case .web:
            return traitCollection.isLarge ? 60 : 40
        }
    }

    func configure(for activity: Activity) {
        switch activity {
        case .search:
            text = ""
            font = UIFont.systemFont(ofSize: traitCollection.isLarge ? 40 : 30)
        case .web:
            font = UIFont.systemFont(ofSize: traitCollection.isLarge ? 20 : 14)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if let activity = activity {
            configure(for: activity)
        }
    }

    override var canResignFirstResponder: Bool {
        if shouldPreventResigningFirstReponder {
            return false
        }
        return super.canResignFirstResponder
    }
}

extension SearchView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            shouldPreventResigningFirstReponder = false
            textField.resignFirstResponder()
            searchDelegate?.searchSubmitted(text)
        }
        return false
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        searchDelegate?.searchCleared()
        return true
    }
}

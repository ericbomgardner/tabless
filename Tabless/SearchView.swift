import UIKit

protocol SearchViewDelegate: class {
    func searchSubmitted(_ text: String)
    func searchCleared()
}

class SearchView: UITextField {
    weak var searchDelegate: SearchViewDelegate?

    private var activity: Activity?

    init() {
        super.init(frame: CGRect.zero)

        translatesAutoresizingMaskIntoConstraints = false

        returnKeyType = .go
        placeholder = "Let's go."
        clearButtonMode = UITextFieldViewMode.always
        delegate = self

        configure(for: .search)
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
}

extension SearchView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let _ = textField.text {
            textField.resignFirstResponder()
        }
        return false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            searchDelegate?.searchSubmitted(text)
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        searchDelegate?.searchCleared()
        return true
    }
}

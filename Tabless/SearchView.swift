import UIKit

protocol SearchViewDelegate: class {
    func searchSubmitted(_ text: String)
    func searchCleared()
}

class SearchView: UITextField {
    weak var searchDelegate: SearchViewDelegate?

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

    class func height(for activity: Activity) -> CGFloat {
        switch activity {
        case .search:
            return 60
        case .web:
            return 40
        }
    }

    func configure(for activity: Activity) {
        switch activity {
        case .search:
            text = ""
            font = UIFont.systemFont(ofSize: 30)
        case .web:
            font = UIFont.systemFont(ofSize: 14)
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

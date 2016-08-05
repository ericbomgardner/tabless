//
//  SearchView.swift
//  Tabless
//
//  Created by Eric Bomgardner on 8/4/16.
//  Copyright © 2016 Eric Bomgardner. All rights reserved.
//

import UIKit

protocol SearchViewDelegate: class {
    func searchSubmitted(text: String)
    func searchCleared()
}

class SearchView: UITextField {
    weak var searchDelegate: SearchViewDelegate?

    init() {
        super.init(frame: CGRect.zero)

        translatesAutoresizingMaskIntoConstraints = false

        returnKeyType = .Go
        placeholder = "Let's go."
        clearButtonMode = UITextFieldViewMode.Always
        delegate = self

        configure(for: .Search)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func height(for activity: Activity) -> CGFloat {
        switch activity {
        case .Search:
            return 60
        case .Web:
            return 40
        }
    }

    func configure(for activity: Activity) {
        switch activity {
        case .Search:
            text = ""
            font = UIFont.systemFontOfSize(30)
        case .Web:
            font = UIFont.systemFontOfSize(14)
        }

    }
}

extension SearchView: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let _ = textField.text {
            textField.resignFirstResponder()
        }
        return false
    }

    func textFieldDidEndEditing(textField: UITextField) {
        if let text = textField.text {
            searchDelegate?.searchSubmitted(text)
        }
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        searchDelegate?.searchCleared()
        return true
    }
}

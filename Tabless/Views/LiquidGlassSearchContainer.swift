import UIKit

protocol LiquidGlassSearchDelegate: AnyObject {
    func searchSubmitted(_ text: String)
    func searchCleared()
    func copyURLRequested()
    func openInDefaultBrowserRequested()
}

/// A native iOS toolbar with integrated search bar providing liquid glass appearance
class LiquidGlassSearchContainer: UIView {

    weak var searchDelegate: LiquidGlassSearchDelegate?

    let toolbar = UIToolbar()
    let searchBar = UISearchBar()

    private var menuButton: UIBarButtonItem!

    init() {
        super.init(frame: .zero)

        setupToolbar()
        setupSearchBar()
        setupMenuButton()
        layoutToolbarItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupToolbar() {
        // UIToolbar automatically provides the frosted glass blur effect
        // Use default style for adaptive material that matches Safari
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        // Remove any custom background to allow adaptive material
        toolbar.isTranslucent = true
        toolbar.barStyle = .default

        addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupSearchBar() {
        // Configure search bar for minimal, modern appearance
        searchBar.placeholder = "Let's go."
        searchBar.returnKeyType = .go
        searchBar.autocapitalizationType = .none
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self

        // Make search bar background transparent to show toolbar blur
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
    }

    private func setupMenuButton() {
        // Create menu with actions
        let copyURLAction = UIAction(
            title: "Copy URL",
            image: UIImage(systemName: "doc.on.doc")
        ) { [weak self] _ in
            self?.searchDelegate?.copyURLRequested()
        }

        let openInBrowserAction = UIAction(
            title: "Open in Default Browser",
            image: UIImage(systemName: "safari")
        ) { [weak self] _ in
            self?.searchDelegate?.openInDefaultBrowserRequested()
        }

        let menu = UIMenu(children: [copyURLAction, openInBrowserAction])

        // Create button with three-dot icon (Safari style - no circle)
        menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: nil,
            action: nil
        )
        menuButton.menu = menu
    }

    private func layoutToolbarItems() {
        // Set search bar width before wrapping in bar button item
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        // Make search bar take most of the space, leaving room for the menu button
        let searchBarWidth = UIScreen.main.bounds.width - 100

        NSLayoutConstraint.activate([
            searchBar.widthAnchor.constraint(equalToConstant: searchBarWidth)
        ])

        // Wrap search bar in a bar button item
        let searchBarItem = UIBarButtonItem(customView: searchBar)

        // Create flexible space to separate items
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        // Layout: [searchBar] [flexible space] [menuButton]
        // This creates distinct, separated buttons like Safari
        toolbar.items = [searchBarItem, flexibleSpace, menuButton]
    }

    var text: String? {
        get { searchBar.text }
        set { searchBar.text = newValue }
    }

    override func becomeFirstResponder() -> Bool {
        return searchBar.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return searchBar.resignFirstResponder()
    }

    /// Returns the search bar's frame in the toolbar's coordinate space
    func searchBarFrameInToolbar() -> CGRect {
        // Search bar is inside toolbar as a custom view of a bar button item
        // Convert its frame to toolbar coordinates
        return searchBar.convert(searchBar.bounds, to: toolbar)
    }
}

extension LiquidGlassSearchContainer: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            searchBar.resignFirstResponder()
            searchDelegate?.searchSubmitted(text)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Clear action
        if searchText.isEmpty {
            searchDelegate?.searchCleared()
        }
    }
}

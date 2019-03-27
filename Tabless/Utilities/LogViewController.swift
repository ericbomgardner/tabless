import UIKit

class LogViewController: UIViewController {

    private let logTextView = UITextView(frame: .zero)

    override func viewDidLoad() {
        view.backgroundColor = UIColor.white

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(doneTapped))

        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(title: "Clear log",
                            style: .plain,
                            target: self,
                            action: #selector(clearTapped)),
            UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Copy to clipboard",
                            style: .plain,
                            target: self,
                            action: #selector(copyTapped))
        ]

        logTextView.isEditable = false
        view.addSubview(logTextView)
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        logTextView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        logTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        logTextView.text = Logger.shared.read()
    }

    @objc private func doneTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func clearTapped() {
        let alert = UIAlertController(title: "Clear log?",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "Clear", style: .destructive, handler: { _ in
            Logger.shared.clear()
            self.logTextView.text = Logger.shared.read()
        }))
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    @objc private func copyTapped() {
        UIPasteboard.general.string = logTextView.text
        let alert = UIAlertController(title: "Log copied to clipboard!",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

import UIKit
import WebKit

/// Container for search, progress, and web views
class WebContainerView: UIView {

    let glassSearchContainer = LiquidGlassSearchContainer()
    let progressView = ProgressView()
    let webView: WKWebView = WebView()

    private(set) var searchContainerBottomConstraint: NSLayoutConstraint!

    private let safeAreaGradientView = UIView()
    private let gradientLayer = CAGradientLayer()

    // Progress container that matches the bubble shape
    private let progressContainer = UIView()
    private var progressContainerLeadingConstraint: NSLayoutConstraint!
    private var progressContainerTrailingConstraint: NSLayoutConstraint!
    private var progressContainerTopConstraint: NSLayoutConstraint!
    private var progressContainerHeightConstraint: NSLayoutConstraint!

    // Display link for smooth updates during bubble animations
    private var displayLink: CADisplayLink?
    private var lastBubbleFrame: CGRect = .zero

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor(named: "Background")

        // Add webView first so it's behind everything
        addSubview(webView)

        // Add Safari-style gradient at top for safe area visibility
        addSubview(safeAreaGradientView)
        setupSafeAreaGradient()

        addSubview(glassSearchContainer)

        // Add progress container to toolbar (matches bubble shape)
        glassSearchContainer.toolbar.addSubview(progressContainer)
        progressContainer.clipsToBounds = true
        progressContainer.backgroundColor = .clear
        progressContainer.isUserInteractionEnabled = false  // Don't block touches to search bar

        // Add progress view to bottom of container
        progressContainer.addSubview(progressView)
        progressView.alpha = 0.3
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: progressContainer.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])

        // WebView extends to full screen
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Progress container constraints, will be updated in layoutSubviews to match bubble
        progressContainer.translatesAutoresizingMaskIntoConstraints = false
        progressContainerLeadingConstraint = progressContainer.leadingAnchor.constraint(
            equalTo: glassSearchContainer.toolbar.leadingAnchor
        )
        progressContainerTrailingConstraint = progressContainer.trailingAnchor.constraint(
            equalTo: glassSearchContainer.toolbar.trailingAnchor
        )
        progressContainerTopConstraint = progressContainer.topAnchor.constraint(
            equalTo: glassSearchContainer.toolbar.topAnchor
        )
        progressContainerHeightConstraint = progressContainer.heightAnchor.constraint(
            equalToConstant: 0
        )
        NSLayoutConstraint.activate([
            progressContainerLeadingConstraint,
            progressContainerTrailingConstraint,
            progressContainerTopConstraint,
            progressContainerHeightConstraint
        ])

        // Set up display link for smooth progress bar updates during bubble animations
        setupDisplayLink()

        // Liquid glass search toolbar at bottom
        glassSearchContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            glassSearchContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassSearchContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        // Bottom constraint that we can animate with keyboard
        searchContainerBottomConstraint = glassSearchContainer.bottomAnchor.constraint(
            equalTo: safeAreaLayoutGuide.bottomAnchor
        )
        searchContainerBottomConstraint.isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSafeAreaGradient() {
        safeAreaGradientView.translatesAutoresizingMaskIntoConstraints = false
        safeAreaGradientView.isUserInteractionEnabled = false

        // Position at top of view
        NSLayoutConstraint.activate([
            safeAreaGradientView.topAnchor.constraint(equalTo: topAnchor),
            safeAreaGradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            safeAreaGradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            safeAreaGradientView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
        ])

        // Configure gradient: white from 0 opacity (bottom) to ~0.5 opacity (top)
        gradientLayer.colors = [
            UIColor.white.withAlphaComponent(0.5).cgColor,  // Top
            UIColor.white.withAlphaComponent(0.0).cgColor   // Bottom
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        safeAreaGradientView.layer.addSublayer(gradientLayer)
    }

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgressContainer))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateProgressContainer() {
        updateProgressContainerForBubble()
    }

    private func findGlassView(in view: UIView) -> UIView? {
        if String(describing: type(of: view)).contains("UIPlatformGlassInteractionView") {
            return view
        }
        for subview in view.subviews {
            if let found = findGlassView(in: subview) {
                return found
            }
        }
        return nil
    }

    private func updateProgressContainerForBubble() {
        // Find the actual UIPlatformGlassInteractionView (the real bubble)
        var searchBubbleFrame: CGRect?

        if let glassView = findGlassView(in: glassSearchContainer.toolbar) {
            searchBubbleFrame = glassView.convert(glassView.bounds, to: glassSearchContainer.toolbar)
        }

        // Use search bubble frame if found, otherwise fall back to search bar frame
        let searchBarFrame = glassSearchContainer.searchBarFrameInToolbar()
        let bubbleFrame = searchBubbleFrame ?? searchBarFrame

        // Only update if the frame actually changed
        guard bubbleFrame != lastBubbleFrame else { return }
        lastBubbleFrame = bubbleFrame

        // Update progress container to match bubble frame exactly
        progressContainerLeadingConstraint.constant = bubbleFrame.minX
        progressContainerTrailingConstraint.constant = bubbleFrame.maxX - glassSearchContainer.toolbar.bounds.width
        progressContainerTopConstraint.constant = bubbleFrame.minY
        progressContainerHeightConstraint.constant = bubbleFrame.height

        // Apply rounded rect mask to container matching bubble shape
        let bubbleCornerRadius = bubbleFrame.height / 2
        let maskRect = CGRect(x: 0, y: 0, width: bubbleFrame.width, height: bubbleFrame.height)
        let maskPath = UIBezierPath(
            roundedRect: maskRect,
            cornerRadius: bubbleCornerRadius
        )
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        progressContainer.layer.mask = maskLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update gradient frame to match the view
        gradientLayer.frame = safeAreaGradientView.bounds

        // Update progress container to match bubble
        updateProgressContainerForBubble()
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: Sizing

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // TODO: Resize search/progress views
    }
}

import UIKit
import WebKit

/// Container for search, progress, and web views
class WebContainerView: UIView {

    let glassSearchContainer = LiquidGlassSearchContainer()
    let progressView = ProgressView()
    let webView: WKWebView = WebView()

    static let defaultSearchContainerBottomConstraint: CGFloat = -16
    
    private(set) var searchContainerBottomConstraint: NSLayoutConstraint!

    private let safeAreaGradientView = UIView()
    private let gradientLayer = CAGradientLayer()

    // Bottom content fade overlay (matches page background color)
    private let bottomFadeView = UIView()
    private let bottomFadeGradient = CAGradientLayer()

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
        updateObscuredContentInsets()

        // Add Safari-style gradient at top for safe area visibility
        addSubview(safeAreaGradientView)
        setUpSafeAreaGradient()

        // Add bottom fade overlay (color-matched to page background)
        // Must be added after glassSearchContainer since we constrain to it,
        // but inserted behind it in the view hierarchy
        addSubview(glassSearchContainer)
        insertSubview(bottomFadeView, belowSubview: glassSearchContainer)
        setUpBottomFade()

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
        setUpDisplayLink()

        // Liquid glass search toolbar at bottom
        glassSearchContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            glassSearchContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            glassSearchContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])

        // Bottom constraint that we can animate with keyboard
        searchContainerBottomConstraint = glassSearchContainer.bottomAnchor.constraint(
            equalTo: safeAreaLayoutGuide.bottomAnchor, constant: Self.defaultSearchContainerBottomConstraint
        )
        searchContainerBottomConstraint.isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpSafeAreaGradient() {
        safeAreaGradientView.translatesAutoresizingMaskIntoConstraints = false
        safeAreaGradientView.isUserInteractionEnabled = false

        // Position at top of view
        NSLayoutConstraint.activate([
            safeAreaGradientView.topAnchor.constraint(equalTo: topAnchor),
            safeAreaGradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            safeAreaGradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            safeAreaGradientView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
        ])

        // Configure gradient layer (colors set by updateFadeColor)
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        safeAreaGradientView.layer.addSublayer(gradientLayer)

        // Default to white, will be updated when page loads
        gradientLayer.colors = [
            UIColor.white.withAlphaComponent(0.5).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
    }

    private func setUpBottomFade() {
        bottomFadeView.translatesAutoresizingMaskIntoConstraints = false
        bottomFadeView.isUserInteractionEnabled = false

        // Position from top of search container down through bottom safe area
        NSLayoutConstraint.activate([
            bottomFadeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomFadeView.topAnchor.constraint(equalTo: glassSearchContainer.topAnchor),
            bottomFadeView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Configure gradient: transparent at top, page color at bottom
        // Default to white, will be updated when page loads
        updateFadeColors(top: .white, bottom: .white)

        bottomFadeView.layer.addSublayer(bottomFadeGradient)
    }

    /// Updates top and bottom fade gradients to match sampled page colors
    func updateFadeColors(top topColor: UIColor, bottom bottomColor: UIColor) {
        // Update top fade: solid at top, transparent at bottom
        gradientLayer.colors = [
            topColor.withAlphaComponent(0.5).cgColor,  // Top (semi-transparent)
            topColor.withAlphaComponent(0.0).cgColor   // Bottom (transparent)
        ]

        // Update bottom fade: transparent at top, solid at bottom
        bottomFadeGradient.colors = [
            bottomColor.withAlphaComponent(0.0).cgColor,  // Top (transparent)
            bottomColor.withAlphaComponent(0.5).cgColor   // Bottom (semi-transparent)
        ]
        bottomFadeGradient.locations = [0, 1]
        bottomFadeGradient.startPoint = CGPoint(x: 0.5, y: 0)
        bottomFadeGradient.endPoint = CGPoint(x: 0.5, y: 1)
    }

    private func setUpDisplayLink() {
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

    private func updateObscuredContentInsets() {
        if #available(iOS 26.0, *), let window {
            webView.obscuredContentInsets = .init(top: window.safeAreaInsets.top, left: 0, bottom: window.safeAreaInsets.bottom + 50 /* Approximate height of toolbar */, right: 0)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update gradient frame to match the view
        gradientLayer.frame = safeAreaGradientView.bounds

        // Update bottom fade gradient frame
        bottomFadeGradient.frame = bottomFadeView.bounds

        // Update progress container to match bubble
        updateProgressContainerForBubble()
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: Sizing

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateObscuredContentInsets()
    }
}

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    lazy var rootViewController = RootViewController(stateClearer: stateClearer)
    let stateClearer = StateClearer()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UserDefaults.standard.pinInitialSearchEngine()

        #if DEBUG
        #else
            // Clear any accidentally-existing debug logs in non-debug app builds
            //
            // This logging could have occurred in releases containing 128b2cb and not 025e419,
            // which was releases 1.0.1, 1.1, and 1.2.
            DispatchQueue.global(qos: .background).async {
                DebugLogger.clearAllLogs()
            }
        #endif

        return true
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var rootViewController: RootViewController {
        (UIApplication.shared.delegate as! AppDelegate).rootViewController
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        self.window = window

        window.makeKeyAndVisible()

        openURL(from: connectionOptions.urlContexts)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        openURL(from: URLContexts)
    }

    private func openURL(from urlContexts: Set<UIOpenURLContext>) {
        guard let url = urlContexts.first?.url,
            url.scheme == "http" || url.scheme == "https"
        else {
            return
        }
        rootViewController.openURL(url)
    }
}

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private lazy var rootViewController = RootViewController(stateClearer: stateClearer)
    let stateClearer = StateClearer()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if os(visionOS)
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 1920, height: 1080))
        #else
        let window = UIWindow(frame: UIScreen.main.bounds)
        #endif
        window.rootViewController = rootViewController
        self.window = window

        window.makeKeyAndVisible()

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

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
    {
        if url.scheme == "http" || url.scheme == "https" {
            rootViewController.openURL(url)
            return true
        }
        return false
    }
}

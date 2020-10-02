import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private lazy var rootViewController = RootViewController(stateClearer: stateClearer)
    let stateClearer = StateClearer()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = rootViewController
        self.window = window

        window.makeKeyAndVisible()

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

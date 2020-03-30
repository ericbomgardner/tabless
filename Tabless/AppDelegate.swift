import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let stateClearer = StateClearer()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let rootViewController = RootViewController(stateClearer: stateClearer)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = rootViewController
        self.window = window

        window.makeKeyAndVisible()

        return true
    }
}

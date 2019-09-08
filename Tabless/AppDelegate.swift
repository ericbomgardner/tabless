import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var stateClearer: StateClearer!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        stateClearer = StateClearer(application: application)

        let rootViewController = RootViewController(stateClearer: stateClearer)
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        self.window = window

        window.makeKeyAndVisible()

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        stateClearer.beginClearTimer()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        stateClearer.cancelPendingStateClears()
    }
}

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var stateClearer: StateClearer!

    static var isKeyboardHidingDefinitelyBad: Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Logger.shared.clear()
        print("applicationDidFinishLaunchingWithOptions", to: &Logger.shared)

        stateClearer = StateClearer(application: application)

        let rootViewController = RootViewController(stateClearer: stateClearer)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = rootViewController
        self.window = window

        window.makeKeyAndVisible()

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground", to: &Logger.shared)

        stateClearer.beginClearTimer()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("applicationWillEnterForeground", to: &Logger.shared)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive", to: &Logger.shared)

        stateClearer.cancelPendingStateClears()
    }
}

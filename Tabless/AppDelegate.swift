import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var view: UIView?
    var stateClearer: StateClearer!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        stateClearer = StateClearer(application: application)

        let rootViewController = RootViewController(stateClearer: stateClearer)
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        window.backgroundColor = .white
        self.window = window

        window.makeKeyAndVisible()

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        stateClearer.beginClearTimer()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if let window = window, let view = (window.rootViewController as? UINavigationController)?.viewControllers.last?.view {
            UIView.animate(withDuration: 0.15) {
                view.alpha = 0.06
            }
            self.view = view
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIView.animate(withDuration: 0.25) {
            self.view?.alpha = 1.0
        }
        stateClearer.cancelPendingStateClears()
    }
}
